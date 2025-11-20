! =============================================================================
! nec2d_geomproc - Geometry and Matrix Processing
! =============================================================================
! Purpose: H field computation, matrix factorization, patch subdivision
! Contains: HSFLD, LFACTR, PATCH, SUBPH
! GOTOs eliminated: 39
! =============================================================================
subroutine hsfld (xi,yi,zi,ai)
  implicit real*8(a-h,o-z)

  complex*16 exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc,zrati,zrati2,t1
  complex*16 hpk,hps,hpc,qx,qy,qz,rrv,rrh,zratx,frati

  common /dataj/ s,b,xj,yj,zj,cabj,sabj,salpj,exk,eyk,ezk,exs,eys, &
                 ezs,exc,eyc,ezc,rkh,ind1,indd1,ind2,indd2,iexk,ipgnd
  common /gnd/zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl, &
              ksymp,ifar,iperf

  data eta/376.73/

  xij=xi-xj
  yij=yi-yj
  rfl=-1.

  ! Symmetry loop (formerly DO 7)
  do ip=1,ksymp
    rfl=-rfl
    salpr=salpj*rfl
    zij=zi-rfl*zj
    zp=xij*cabj+yij*sabj+zij*salpr
    rhox=xij-cabj*zp
    rhoy=yij-sabj*zp
    rhoz=zij-salpr*zp
    rh=sqrt(rhox*rhox+rhoy*rhoy+rhoz*rhoz+ai*ai)

    ! Handle zero RH case (formerly GO TO 1 / GO TO 7)
    if (rh.le.1.d-10) then
      exk=0.
      eyk=0.
      ezk=0.
      exs=0.
      eys=0.
      ezs=0.
      exc=0.
      eyc=0.
      ezc=0.
      cycle  ! Skip to next iteration
    end if

    ! Label 1: Normalize and compute field components
    rhox=rhox/rh
    rhoy=rhoy/rh
    rhoz=rhoz/rh
    phx=sabj*rhoz-salpr*rhoy
    phy=salpr*rhox-cabj*rhoz
    phz=cabj*rhoy-sabj*rhox
    call hsflx (s,rh,zp,hpk,hps,hpc)

    ! Check iteration number (formerly GO TO 6)
    if (ip.ne.2) then
      ! Label 6: First iteration - set initial field values
      exk=hpk*phx
      eyk=hpk*phy
      ezk=hpk*phz
      exs=hps*phx
      eys=hps*phy
      ezs=hps*phz
      exc=hpc*phx
      eyc=hpc*phy
      ezc=hpc*phz
    else
      ! Second iteration - apply ground effects
      ! Check for perfect ground (formerly GO TO 5)
      if (iperf.eq.1) then
        ! Label 5: Perfect ground case
        exk=exk-hpk*phx
        eyk=eyk-hpk*phy
        ezk=ezk-hpk*phz
        exs=exs-hps*phx
        eys=eys-hps*phy
        ezs=ezs-hps*phz
        exc=exc-hpc*phx
        eyc=eyc-hpc*phy
        ezc=ezc-hpc*phz
      else
        ! Imperfect ground case
        zratx=zrati
        rmag=sqrt(zp*zp+rh*rh)
        xymag=sqrt(xij*xij+yij*yij)

        ! Set parameters for radial wire ground screen (formerly GO TO 2)
        if (nradl.ne.0) then
          xspec=(xi*zj+zi*xj)/(zi+zj)
          yspec=(yi*zj+zi*yj)/(zi+zj)
          rhospc=sqrt(xspec*xspec+yspec*yspec+t2*t2)
          if (rhospc.le.scrwl) then
            rrv=t1*rhospc*log(rhospc/t2)
            zratx=(rrv*zrati)/(eta*zrati+rrv)
          end if
        end if

        ! Label 2: Calculation of reflection coefficients when ground is specified
        ! (formerly GO TO 3 / GO TO 4)
        if (xymag.le.1.d-6) then
          px=0.
          py=0.
          cth=1.
          rrv=(1.,0.)
        else
          ! Label 3
          px=-yij/xymag
          py=xij/xymag
          cth=zij/rmag
          rrv=sqrt(1.-zratx*zratx*(1.-cth*cth))
        end if

        ! Label 4: Compute reflection coefficients
        rrh=zratx*cth
        rrh=-(rrh-rrv)/(rrh+rrv)
        rrv=zratx*rrv
        rrv=(cth-rrv)/(cth+rrv)
        qy=(phx*px+phy*py)*(rrv-rrh)
        qx=qy*px+phx*rrh
        qy=qy*py+phy*rrh
        qz=phz*rrh
        exk=exk-hpk*qx
        eyk=eyk-hpk*qy
        ezk=ezk-hpk*qz
        exs=exs-hps*qx
        eys=eys-hps*qy
        ezs=ezs-hps*qz
        exc=exc-hpc*qx
        eyc=eyc-hpc*qy
        ezc=ezc-hpc*qz
      end if
    end if

  end do  ! IP loop (formerly label 7)

  return
end subroutine hsfld

!==============================================================================
! LFACTR - Gauss-Doolittle LU Factorization
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 2388-2498)
! Original: Fixed-form Fortran 77 with 14 GOTOs
! Modernized: Free-form Fortran 90 with structured control flow
!
! Purpose: Performs Gauss-Doolittle manipulations on two blocks of the
!          transposed matrix in core storage. The Gauss-Doolittle algorithm
!          is presented on pages 411-416 of A. Ralston -- A First Course in
!          Numerical Analysis. Comments below refer to comments in Ralston's
!          text.
!
! GOTOs eliminated: 14 (labels 1-16)
!==============================================================================
subroutine lfactr(a, nrow, ix1, ix2, ip)
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)

  complex*16 a, d, ajr
  integer r, r1, r2, pj, pr
  logical l1, l2, l3
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat,icasx, &
                  nbbx,npbx,nlbx,nbbl,npbl,nlbl
  common /scratm/ d(2*maxseg)
  dimension a(nrow,1), ip(nrow)

  iflg = 0

  ! Initialize R1, R2, J1, J2
  l1 = ix1.eq.1 .and. ix2.eq.2
  l2 = (ix2-1).eq.ix1
  l3 = ix2.eq.nblsym

  if (l1) then
    r1 = 1
    r2 = 2*npsym
    j1 = 1
    j2 = -1
  else
    r1 = npsym+1
    r2 = 2*npsym
    j1 = (ix1-1)*npsym+1
    if (l2) then
      j2 = j1+npsym-2
    else
      j2 = j1+npsym-1
    end if
  end if

  if (l3) r2 = npsym+nlsym

  do r = r1, r2
    ! Step 1
    do k = j1, nrow
      d(k) = a(k,r)
    end do

    ! Steps 2 and 3
    if (l1 .or. l2) j2 = j2+1

    if (j1 .le. j2) then
      ixj = 0
      do j = j1, j2
        ixj = ixj+1
        pj = ip(j)
        ajr = d(pj)
        a(j,r) = ajr
        d(pj) = d(j)
        jp1 = j+1
        do i = jp1, nrow
          d(i) = d(i) - a(i,ixj)*ajr
        end do
      end do
    end if

    ! Step 4
    j2p1 = j2+1

    if (l1 .or. l2) then
      ! Pivot selection
      dmax = dreal(d(j2p1)*dconjg(d(j2p1)))
      ip(j2p1) = j2p1
      j2p2 = j2+2

      if (j2p2 .le. nrow) then
        do i = j2p2, nrow
          elmag = dreal(d(i)*dconjg(d(i)))
          if (elmag .ge. dmax) then
            dmax = elmag
            ip(j2p1) = i
          end if
        end do
      end if

      if (dmax .lt. 1.d-10) iflg = 1
      pr = ip(j2p1)
      a(j2p1,r) = d(pr)
      d(pr) = d(j2p1)

      ! Step 5
      if (j2p2 .le. nrow) then
        ajr = 1./a(j2p1,r)
        do i = j2p2, nrow
          a(i,r) = d(i)*ajr
        end do
      end if

      if (iflg .ne. 0) then
        write(*,17) j2, dmax
        iflg = 0
      end if

    else
      ! Non-pivot path
      if (nrow .ge. j2p1) then
        do i = j2p1, nrow
          a(i,r) = d(i)
        end do
      end if
    end if

  end do

  return

17 format (1h ,6hpivot(,i3,2h)=,1p,e16.8)
end subroutine lfactr

!==============================================================================
! PATCH - Patch Geometry Generation
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 3201-3335)
! Tier 2: Eliminate GOTOs, convert to free-form Fortran 90
!
! Purpose: Generates and modifies patch geometry data
!
! Patch Types (NTP):
!   NX=0, NY=1: Arbitrary patch
!   NX=0, NY=2: Rectangular patch
!   NX=0, NY=3: Triangular patch
!   NX=0, NY=4: Quadrilateral patch
!   NX>0, NY>0: NX×NY rectangular surface
!
! GOTOs eliminated: 15 (labels 1-9)
!   - Converted patch type selection to structured IF/THEN/ELSE
!   - Eliminated singularity handling jumps
!   - Replaced labeled DO loops with modern DO...END DO
!==============================================================================
subroutine patch (nx,ny,x1,y1,z1,x2,y2,z2,x3,y3,z3,x4,y4,z4)
!
! DOUBLE PRECISION 6/4/85
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)
!
! PATCH GENERATES AND MODIFIES PATCH GEOMETRY DATA
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
       alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
       itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /angl/ salp(maxseg)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1)
  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), &
       (t2z,itag)

! NEW PATCHES.  FOR NX=0, NY=1,2,3,4 PATCH IS (RESPECTIVELY)
! ARBITRARY, RECTAGULAR, TRIANGULAR, OR QUADRILATERAL.
! FOR NX AND NY .GT. 0 A RECTANGULAR SURFACE IS PRODUCED WITH
! NX BY NY RECTANGULAR PATCHES.

  m=m+1
  mi=ld+1-m
  ntp=ny
  if (nx.gt.0) ntp=2

  if (ntp.le.1) then
    ! Arbitrary patch (NTP=1)
    x(mi)=x1
    y(mi)=y1
    z(mi)=z1
    bi(mi)=z2
    znv=cos(x2)
    xnv=znv*cos(y2)
    ynv=znv*sin(y2)
    znv=sin(x2)
    xa=sqrt(xnv*xnv+ynv*ynv)

    if (xa.lt.1.d-6) then
      ! Singularity case - normal nearly vertical
      t1x(mi)=1.
      t1y(mi)=0.
      t1z(mi)=0.
    else
      ! Normal case - compute tangent perpendicular to normal
      t1x(mi)=-ynv/xa
      t1y(mi)=xnv/xa
      t1z(mi)=0.
    end if

  else
    ! Non-arbitrary patches (NTP=2,3,4)
    s1x=x2-x1
    s1y=y2-y1
    s1z=z2-z1
    s2x=x3-x2
    s2y=y3-y2
    s2z=z3-z2

    if (nx.ne.0) then
      ! For rectangular surface generation, divide sides by NX and NY
      s1x=s1x/nx
      s1y=s1y/nx
      s1z=s1z/nx
      s2x=s2x/ny
      s2y=s2y/ny
      s2z=s2z/ny
    end if

    ! Compute normal vector from cross product
    xnv=s1y*s2z-s1z*s2y
    ynv=s1z*s2x-s1x*s2z
    znv=s1x*s2y-s1y*s2x
    xa=sqrt(xnv*xnv+ynv*ynv+znv*znv)
    xnv=xnv/xa
    ynv=ynv/xa
    znv=znv/xa

    ! Compute first tangent vector
    xst=sqrt(s1x*s1x+s1y*s1y+s1z*s1z)
    t1x(mi)=s1x/xst
    t1y(mi)=s1y/xst
    t1z(mi)=s1z/xst

    if (ntp.le.2) then
      ! Rectangular patch (NTP=2)
      x(mi)=x1+.5*(s1x+s2x)
      y(mi)=y1+.5*(s1y+s2y)
      z(mi)=z1+.5*(s1z+s2z)
      bi(mi)=xa

    else if (ntp.eq.3) then
      ! Triangular patch (NTP=3)
      x(mi)=(x1+x2+x3)/3.
      y(mi)=(y1+y2+y3)/3.
      z(mi)=(z1+z2+z3)/3.
      bi(mi)=.5*xa

    else
      ! Quadrilateral patch (NTP=4)
      s1x=x3-x1
      s1y=y3-y1
      s1z=z3-z1
      s2x=x4-x1
      s2y=y4-y1
      s2z=z4-z1
      xn2=s1y*s2z-s1z*s2y
      yn2=s1z*s2x-s1x*s2z
      zn2=s1x*s2y-s1y*s2x
      xst=sqrt(xn2*xn2+yn2*yn2+zn2*zn2)
      salpn=1./(3.*(xa+xst))
      x(mi)=(xa*(x1+x2+x3)+xst*(x1+x3+x4))*salpn
      y(mi)=(xa*(y1+y2+y3)+xst*(y1+y3+y4))*salpn
      z(mi)=(xa*(z1+z2+z3)+xst*(z1+z3+z4))*salpn
      bi(mi)=.5*(xa+xst)
      s1x=(xnv*xn2+ynv*yn2+znv*zn2)/xst
      if (s1x.le.0.9998) then
        write(*,14)
        stop
      end if
    end if
  end if

  ! Compute second tangent vector (common to all patch types)
  t2x(mi)=ynv*t1z(mi)-znv*t1y(mi)
  t2y(mi)=znv*t1x(mi)-xnv*t1z(mi)
  t2z(mi)=xnv*t1y(mi)-ynv*t1x(mi)
  salp(mi)=1.

  ! Generate NX×NY rectangular surface if NX>0
  if (nx.gt.0) then
    m=m+nx*ny-1
    xn2=x(mi)-s1x-s2x
    yn2=y(mi)-s1y-s2y
    zn2=z(mi)-s1z-s2z
    xs=t1x(mi)
    ys=t1y(mi)
    zs=t1z(mi)
    xt=t2x(mi)
    yt=t2y(mi)
    zt=t2z(mi)
    mi=mi+1

    do iy=1,ny
      xn2=xn2+s2x
      yn2=yn2+s2y
      zn2=zn2+s2z
      do ix=1,nx
        xst=ix
        mi=mi-1
        x(mi)=xn2+xst*s1x
        y(mi)=yn2+xst*s1y
        z(mi)=zn2+xst*s1z
        bi(mi)=xa
        salp(mi)=1.
        t1x(mi)=xs
        t1y(mi)=ys
        t1z(mi)=zs
        t2x(mi)=xt
        t2y(mi)=yt
        t2z(mi)=zt
      end do
    end do
  end if

  ipsym=0
  np=n
  mp=m
  return

14 format ('ERROR -- CORNERS OF QUADRILATERAL PATCH DO NOT LIE IN A PLANE')

end subroutine patch

!==============================================================================
! SUBPH - Sub-Patch Handler
!==============================================================================
! Modernized from nec2dxs.f (ENTRY point in PATCH, lines 7517-7576)
! Purpose: Subdivides a patch or creates sub-patches
!==============================================================================
subroutine subph (nx,ny,x1,y1,z1,x2,y2,z2,x3,y3,z3,x4,y4,z4)
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)

  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
       alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
       itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /angl/ salp(maxseg)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1)
  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), &
       (t2z,itag)

  ! Shift patches if needed (formerly GO TO 10)
  if (ny.le.0 .and. nx.ne.m) then
    nxp=nx+1
    ix=ld-m
    do iy=nxp,m
      ix=ix+1
      nyp=ix-3
      x(nyp)=x(ix)
      y(nyp)=y(ix)
      z(nyp)=z(ix)
      bi(nyp)=bi(ix)
      salp(nyp)=salp(ix)
      t1x(nyp)=t1x(ix)
      t1y(nyp)=t1y(ix)
      t1z(nyp)=t1z(ix)
      t2x(nyp)=t2x(ix)
      t2y(nyp)=t2y(ix)
      t2z(nyp)=t2z(ix)
    end do
  end if

  ! Label 10: Setup for subdividing patch
  mi=ld+1-nx
  xs=x(mi)
  ys=y(mi)
  zs=z(mi)
  xa=bi(mi)*.25
  xst=sqrt(xa)*.5
  s1x=t1x(mi)
  s1y=t1y(mi)
  s1z=t1z(mi)
  s2x=t2x(mi)
  s2y=t2y(mi)
  s2z=t2z(mi)
  saln=salp(mi)
  xt=xst
  yt=xst

  ! Determine starting index (formerly GO TO 11/12)
  if (ny.gt.0) then
    m=m+1
    mp=mp+1
    mia=ld+1-m
  else
    mia=mi
  end if

  ! Create 4 sub-patches (formerly DO 13)
  do ix=1,4
    x(mia)=xs+xt*s1x+yt*s2x
    y(mia)=ys+xt*s1y+yt*s2y
    z(mia)=zs+xt*s1z+yt*s2z
    bi(mia)=xa
    t1x(mia)=s1x
    t1y(mia)=s1y
    t1z(mia)=s1z
    t2x(mia)=s2x
    t2y(mia)=s2y
    t2z(mia)=s2z
    salp(mia)=saln
    if (ix.eq.2) yt=-yt
    if (ix.eq.1.or.ix.eq.3) xt=-xt
    mia=mia-1
  end do

  m=m+3
  if (nx.le.mp) mp=mp+3
  if (ny.gt.0) z(mi)=10000.

  return
end subroutine subph
