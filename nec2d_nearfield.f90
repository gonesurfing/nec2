! =============================================================================
! nec2d_nearfield - Near Field Calculations
! =============================================================================
! Purpose: Near field E and H computation at observation points
! Contains: INTX, NHFLD, HINTG
! GOTOs eliminated: 30
! =============================================================================
subroutine intx(el1,el2,b,ij,sgr,sgi)
!
! intx performs numerical integration of exp(jkr)/r by the method of
! variable interval width romberg integration. the integrand value
! is supplied by subroutine gf.
!
  implicit real*8(a-h,o-z)
  data nx,nm,nts,rx/1,65536,4,1.d-4/

  z=el1
  ze=el2
  if (ij == 0) ze=0.d0
  s=ze-z
  fnm=nm
  ep=s/(10.d0*fnm)
  zend=ze-ep
  sgr=0.d0
  sgi=0.d0
  ns=nx
  nt=0
  call gf(z,g1r,g1i)

  ! Main integration loop with adaptive step sizing
  do while (.true.)
    fns=ns
    dz=s/fns
    zp=z+dz

    ! Check if interval extends beyond endpoint
    if (zp > ze) then
      dz=ze-z
      if (abs(dz) <= ep) exit
    end if

    ! Compute interval midpoint and evaluate integrand
    dzot=dz*0.5d0
    zp=z+dzot
    call gf(zp,g3r,g3i)
    zp=z+dz
    call gf(zp,g5r,g5i)

    ! Refinement loop
    do while (.true.)
      ! 3-point Romberg integration
      t00r=(g1r+g5r)*dzot
      t00i=(g1i+g5i)*dzot
      t01r=(t00r+dz*g3r)*0.5d0
      t01i=(t00i+dz*g3i)*0.5d0
      t10r=(4.d0*t01r-t00r)/3.d0
      t10i=(4.d0*t01i-t00i)/3.d0

      ! Test convergence of 3-point Romberg result
      call test(t01r,t10r,te1r,t01i,t10i,te1i,0.d0)

      if (te1i <= rx .and. te1r <= rx) then
        ! 3-point result converged
        sgr=sgr+t10r
        sgi=sgi+t10i
        nt=nt+2
        exit
      end if

      ! 3-point not converged - try 5-point Romberg
      zp=z+dz*0.25d0
      call gf(zp,g2r,g2i)
      zp=z+dz*0.75d0
      call gf(zp,g4r,g4i)

      t02r=(t01r+dzot*(g2r+g4r))*0.5d0
      t02i=(t01i+dzot*(g2i+g4i))*0.5d0
      t11r=(4.d0*t02r-t01r)/3.d0
      t11i=(4.d0*t02i-t01i)/3.d0
      t20r=(16.d0*t11r-t10r)/15.d0
      t20i=(16.d0*t11i-t10i)/15.d0

      ! Test convergence of 5-point Romberg result
      call test(t11r,t20r,te2r,t11i,t20i,te2i,0.d0)

      if (te2i <= rx .and. te2r <= rx) then
        ! 5-point result converged
        sgr=sgr+t20r
        sgi=sgi+t20i
        nt=nt+1
        exit
      end if

      ! 5-point not converged - refine the grid
      nt=0

      if (ns >= nm) then
        ! Maximum subdivision reached - accept best result with warning
        write(*,20) z
        sgr=sgr+t20r
        sgi=sgi+t20i
        nt=nt+1
        exit
      else
        ! Halve step size and retry this interval
        ns=ns*2
        fns=ns
        dz=s/fns
        dzot=dz*0.5d0
        g5r=g3r
        g5i=g3i
        g3r=g2r
        g3i=g2i
        ! Continue inner loop to recompute with finer grid
      end if
    end do

    ! Move to next interval
    z=z+dz
    if (z >= zend) exit
    g1r=g5r
    g1i=g5i

    ! Adaptive step size control
    if (nt >= nts) then
      if (ns > nx) then
        ns=ns/2
        nt=1
      end if
    end if
  end do

  ! Add contribution of near singularity for diagonal term
  if (ij == 0) then
    sgr=2.d0*(sgr+log((sqrt(b*b+s*s)+s)/b))
    sgi=2.d0*sgi
  end if

20 format(24h step size limited at z=,f10.5)

end subroutine intx

subroutine nhfld(xob,yob,zob,hx,hy,hz)
!
! nhfld computes the near field at specified points in space after
! the structure currents have been computed.
!
  use nec2d_params
  implicit real*8(a-h,o-z)
  complex*16 hx,hy,hz,cur,acx,bcx,ccx,exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc
  complex*16 zrati,zrati2,frati,t1,con
  complex*16 expx,exmx,expy,exmy,expz,exmz
  complex*16 eypx,eymx,eypy,eymy,eypz,eymz
  complex*16 ezpx,ezmx,ezpy,ezmy,ezpz,ezmz

  common /gnd/ zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl, &
               ksymp,ifar,iperf
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
                alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
                itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /angl/ salp(maxseg)
  common /crnt/ air(maxseg),aii(maxseg),bir(maxseg),bii(maxseg), &
                cir(maxseg),cii(maxseg),cur(3*maxseg)
  common /dataj/ s,b,xj,yj,zj,cabj,sabj,salpj,exk,eyk,ezk,exs,eys, &
                 ezs,exc,eyc,ezc,rkh,ind1,indd1,ind2,indd2,iexk,ipgnd

  dimension cab(1),sab(1)
  dimension t1x(1),t1y(1),t1z(1),t2x(1),t2y(1),t2z(1),xs(1),ys(1),zs(1)

  equivalence (t1x,si),(t1y,alp),(t1z,bet),(t2x,icon1),(t2y,icon2), &
              (t2z,itag),(xs,x),(ys,y),(zs,z)
  equivalence (t1xj,cabj),(t1yj,sabj),(t1zj,salpj),(t2xj,b),(t2yj,ind1), &
              (t2zj,ind2)
  equivalence (cab,alp),(sab,bet)

  if (iperf == 2) then
    ! Get H by finite difference of E for Sommerfeld ground
    delt=1.e-3
    con=(0.d0,4.2246e-4)
    call nefld(xob+delt,yob,zob,expx,eypx,ezpx)
    call nefld(xob-delt,yob,zob,exmx,eymx,ezmx)
    call nefld(xob,yob+delt,zob,expy,eypy,ezpy)
    call nefld(xob,yob-delt,zob,exmy,eymy,ezmy)
    call nefld(xob,yob,zob+delt,expz,eypz,ezpz)
    call nefld(xob,yob,zob-delt,exmz,eymz,ezmz)
    hx=con*(ezpy-ezmy-eypz+eymz)/(2.d0*delt)
    hy=con*(expz-exmz-ezpx+ezmx)/(2.d0*delt)
    hz=con*(eypx-eymx-expy+exmy)/(2.d0*delt)
    return
  end if

  ! Normal field calculation - initialize fields
  hx=(0.d0,0.d0)
  hy=(0.d0,0.d0)
  hz=(0.d0,0.d0)
  ax=0.d0

  ! Process wire segments if any exist
  if (n /= 0) then
    ! Find the wire radius (AX) for near field calculation
    do i=1,n
      xj=xob-x(i)
      yj=yob-y(i)
      zj=zob-z(i)
      zp=cab(i)*xj+sab(i)*yj+salp(i)*zj

      if (abs(zp) <= 0.5001d0*si(i)) then
        zp=xj*xj+yj*yj+zj*zj-zp*zp
        xj=bi(i)
        if (zp <= 0.9d0*xj*xj) then
          ax=xj
          exit
        end if
      end if
    end do

    ! Compute field contributions from wire segments
    do i=1,n
      s=si(i)
      b=bi(i)
      xj=x(i)
      yj=y(i)
      zj=z(i)
      cabj=cab(i)
      sabj=sab(i)
      salpj=salp(i)
      call hsfld(xob,yob,zob,ax)
      acx=dcmplx(air(i),aii(i))
      bcx=dcmplx(bir(i),bii(i))
      ccx=dcmplx(cir(i),cii(i))
      hx=hx+exk*acx+exs*bcx+exc*ccx
      hy=hy+eyk*acx+eys*bcx+eyc*ccx
      hz=hz+ezk*acx+ezs*bcx+ezc*ccx
    end do
  end if

  if (m == 0) return

  ! Process patches
  jc=n
  jl=ld+1
  do i=1,m
    jl=jl-1
    s=bi(jl)
    xj=x(jl)
    yj=y(jl)
    zj=z(jl)
    t1xj=t1x(jl)
    t1yj=t1y(jl)
    t1zj=t1z(jl)
    t2xj=t2x(jl)
    t2yj=t2y(jl)
    t2zj=t2z(jl)
    call hintg(xob,yob,zob)
    jc=jc+3
    acx=t1xj*cur(jc-2)+t1yj*cur(jc-1)+t1zj*cur(jc)
    bcx=t2xj*cur(jc-2)+t2yj*cur(jc-1)+t2zj*cur(jc)
    hx=hx+acx*exk+bcx*exs
    hy=hy+acx*eyk+bcx*eys
    hz=hz+acx*ezk+bcx*ezs
  end do

end subroutine nhfld

subroutine hintg(xi,yi,zi)
!
! hintg computes the h field of a patch current
!
  implicit real*8(a-h,o-z)
  complex*16 exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc,zrati,zrati2,gam
  complex*16 f1x,f1y,f1z,f2x,f2y,f2z,rrv,rrh,t1,frati

  common /dataj/ s,b,xj,yj,zj,cabj,sabj,salpj,exk,eyk,ezk,exs,eys, &
                 ezs,exc,eyc,ezc,rkh,ind1,indd1,ind2,indd2,iexk,ipgnd
  common /gnd/ zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl, &
               ksymp,ifar,iperf

  equivalence (t1xj,cabj),(t1yj,sabj),(t1zj,salpj),(t2xj,b),(t2yj,ind1), &
              (t2zj,ind2)

  data fpi/12.56637062d0/,tp/6.283185308d0/

  rx=xi-xj
  ry=yi-yj
  rfl=-1.d0
  exk=(0.d0,0.d0)
  eyk=(0.d0,0.d0)
  ezk=(0.d0,0.d0)
  exs=(0.d0,0.d0)
  eys=(0.d0,0.d0)
  ezs=(0.d0,0.d0)

  do ip=1,ksymp
    rfl=-rfl
    rz=zi-zj*rfl
    rsq=rx*rx+ry*ry+rz*rz

    ! Skip this iteration if distance is too small
    if (rsq < 1.d-20) cycle

    r=sqrt(rsq)
    rk=tp*r
    cr=cos(rk)
    sr=sin(rk)
    gam=-(dcmplx(cr,-sr)+rk*dcmplx(sr,cr))/(fpi*rsq*r)*s
    exc=gam*rx
    eyc=gam*ry
    ezc=gam*rz
    t1zr=t1zj*rfl
    t2zr=t2zj*rfl
    f1x=eyc*t1zr-ezc*t1yj
    f1y=ezc*t1xj-exc*t1zr
    f1z=exc*t1yj-eyc*t1xj
    f2x=eyc*t2zr-ezc*t2yj
    f2y=ezc*t2xj-exc*t2zr
    f2z=exc*t2yj-eyc*t2xj

    ! Apply ground reflection on second iteration (ip=2)
    if (ip /= 1) then
      if (iperf == 1) then
        ! Perfect ground - simple sign reversal
        f1x=-f1x
        f1y=-f1y
        f1z=-f1z
        f2x=-f2x
        f2y=-f2y
        f2z=-f2z
      else
        ! Imperfect ground - calculate reflection coefficients
        xymag=sqrt(rx*rx+ry*ry)

        if (xymag <= 1.d-6) then
          ! Vertical incidence case
          px=0.d0
          py=0.d0
          cth=1.d0
          rrv=(1.d0,0.d0)
        else
          ! General case
          px=-ry/xymag
          py=rx/xymag
          cth=rz/r
          rrv=sqrt(1.d0-zrati*zrati*(1.d0-cth*cth))
        end if

        ! Calculate reflection coefficients
        rrh=zrati*cth
        rrh=(rrh-rrv)/(rrh+rrv)
        rrv=zrati*rrv
        rrv=-(cth-rrv)/(cth+rrv)

        ! Apply reflection to f1 components
        gam=(f1x*px+f1y*py)*(rrv-rrh)
        f1x=f1x*rrh+gam*px
        f1y=f1y*rrh+gam*py
        f1z=f1z*rrh

        ! Apply reflection to f2 components
        gam=(f2x*px+f2y*py)*(rrv-rrh)
        f2x=f2x*rrh+gam*px
        f2y=f2y*rrh+gam*py
        f2z=f2z*rrh
      end if
    end if

    ! Accumulate field components
    exk=exk+f1x
    eyk=eyk+f1y
    ezk=ezk+f1z
    exs=exs+f2x
    eys=eys+f2y
    ezs=ezs+f2z
  end do

end subroutine hintg

! -----------------------------------------------------------------------------
! nefld - extracted from nec2dxs_integrated.f
! -----------------------------------------------------------------------------
  subroutine nefld (xob,yob,zob,ex,ey,ez)
! ***
!     DOUBLE PRECISION 6/4/85
!
  use nec2d_params
  implicit real*8(a-h,o-z)
! ***
!
!     NEFLD COMPUTES THE NEAR FIELD AT SPECIFIED POINTS IN SPACE AFTER
!     THE STRUCTURE CURRENTS HAVE BEEN COMPUTED.
!
  complex*16 ex,ey,ez,cur,acx,bcx,ccx,exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc,zrati,zrati2,t1,frati
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg),alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg), &
    icon2(2*maxseg),itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /angl/ salp(maxseg)
  common /crnt/ air(maxseg),aii(maxseg),bir(maxseg),bii(maxseg),cir(maxseg),cii(maxseg),cur(3*maxseg)
  common /dataj/ s,b,xj,yj,zj,cabj,sabj,salpj,exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc,rkh,ind1,indd1,ind2,indd2,iexk,ipgnd
  common /gnd/zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl,ksymp,ifar,iperf
  dimension cab(1), sab(1), t1x(1), t1y(1), t1z(1), t2x(1), t2y(1),t2z(1)
  equivalence (cab,alp), (sab,bet)
  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), (t2z,itag)
  equivalence (t1xj,cabj), (t1yj,sabj), (t1zj,salpj), (t2xj,b), (t2yj,ind1), (t2zj,ind2)
  ex=(0.,0.)
  ey=(0.,0.)
  ez=(0.,0.)
  ax=0.
  if (n.eq.0) go to 20
  do 1 i=1,n
  xj=xob-x(i)
  yj=yob-y(i)
  zj=zob-z(i)
  zp=cab(i)*xj+sab(i)*yj+salp(i)*zj
  if (abs(zp).gt.0.5001*si(i)) go to 1
  zp=xj*xj+yj*yj+zj*zj-zp*zp
  xj=bi(i)
  if (zp.gt.0.9*xj*xj) go to 1
  ax=xj
  go to 2
1 continue
2 do 19 i=1,n
  s=si(i)
  b=bi(i)
  xj=x(i)
  yj=y(i)
  zj=z(i)
  cabj=cab(i)
  sabj=sab(i)
  salpj=salp(i)
  if (iexk.eq.0) go to 18
  ipr=icon1(i)
  if (ipr.gt.10000) go to 9
  if (ipr) 3,8,4
3 ipr=-ipr
  if (-icon1(ipr).ne.i) go to 9
  go to 6
4 if (ipr.ne.i) go to 5
  if (cabj*cabj+sabj*sabj.gt.1.d-8) go to 9
  go to 7
5 if (icon2(ipr).ne.i) go to 9
6 xi=abs(cabj*cab(ipr)+sabj*sab(ipr)+salpj*salp(ipr))
  if (xi.lt.0.999999d+0) go to 9
  if (abs(bi(ipr)/b-1.).gt.1.d-6) go to 9
7 ind1=0
  go to 10
8 ind1=1
  go to 10
9 ind1=2
10 ipr=icon2(i)
  if (ipr.gt.10000) go to 17
  if (ipr) 11,16,12
11 ipr=-ipr
  if (-icon2(ipr).ne.i) go to 17
  go to 14
12 if (ipr.ne.i) go to 13
  if (cabj*cabj+sabj*sabj.gt.1.d-8) go to 17
  go to 15
13 if (icon1(ipr).ne.i) go to 17
14 xi=abs(cabj*cab(ipr)+sabj*sab(ipr)+salpj*salp(ipr))
  if (xi.lt.0.999999d+0) go to 17
  if (abs(bi(ipr)/b-1.).gt.1.d-6) go to 17
15 ind2=0
  go to 18
16 ind2=1
  go to 18
17 ind2=2
18 continue
  call efld (xob,yob,zob,ax,1)
  acx=dcmplx(air(i),aii(i))
  bcx=dcmplx(bir(i),bii(i))
  ccx=dcmplx(cir(i),cii(i))
  ex=ex+exk*acx+exs*bcx+exc*ccx
  ey=ey+eyk*acx+eys*bcx+eyc*ccx
19 ez=ez+ezk*acx+ezs*bcx+ezc*ccx
  if (m.eq.0) return
20 jc=n
  jl=ld+1
  do 21 i=1,m
  jl=jl-1
  s=bi(jl)
  xj=x(jl)
  yj=y(jl)
  zj=z(jl)
  t1xj=t1x(jl)
  t1yj=t1y(jl)
  t1zj=t1z(jl)
  t2xj=t2x(jl)
  t2yj=t2y(jl)
  t2zj=t2z(jl)
  jc=jc+3
  acx=t1xj*cur(jc-2)+t1yj*cur(jc-1)+t1zj*cur(jc)
  bcx=t2xj*cur(jc-2)+t2yj*cur(jc-1)+t2zj*cur(jc)
  do 21 ip=1,ksymp
  ipgnd=ip
  call unere (xob,yob,zob)
  ex=ex+acx*exk+bcx*exs
  ey=ey+acx*eyk+bcx*eys
21 ez=ez+acx*ezk+bcx*ezs
  return
  end
