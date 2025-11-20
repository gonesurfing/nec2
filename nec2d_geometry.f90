! =============================================================================
! nec2d_geometry - Geometry Processing
! =============================================================================
! Purpose: Arc, helix, and geometry transformation routines
! Contains: ARC, WIRE, HELIX, MOVE
! =============================================================================
subroutine arc (itg,ns,rada,ang1,ang2,rad)
! ***
! double precision 6/4/85
!
! arc generates segment geometry data for an arc of ns segments
!
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  implicit real*8(a-h,o-z)
!
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  dimension x2(1), y2(1), z2(1)
  equivalence (x2,si), (y2,alp), (z2,bet)
  data ta/.01745329252d+0/

  ist=n+1
  n=n+ns
  np=n
  mp=m
  ipsym=0
  if (ns < 1) return

  ! Check arc angle validity
  if (abs(ang2-ang1) >= 360.00001d+0) then
    write(*,3)
3   format (40h error -- arc angle exceeds 360. degrees)
    stop
  end if

  ! Generate arc segments
  ang=ang1*ta
  dang=(ang2-ang1)*ta/ns
  xs1=rada*cos(ang)
  zs1=rada*sin(ang)

  do i = ist, n
    ang=ang+dang
    xs2=rada*cos(ang)
    zs2=rada*sin(ang)
    x(i)=xs1
    y(i)=0.
    z(i)=zs1
    x2(i)=xs2
    y2(i)=0.
    z2(i)=zs2
    xs1=xs2
    zs1=zs2
    bi(i)=rad
    itag(i)=itg
  end do

  return
end subroutine arc

subroutine wire (xw1,yw1,zw1,xw2,yw2,zw2,rad,rdel,rrad,ns,itg)
! ***
! double precision 6/4/85
!
! subroutine wire generates segment geometry data for a straight
! wire of ns segments.
!
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  implicit real*8(a-h,o-z)
!
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  dimension x2(1), y2(1), z2(1)
  equivalence (x2(1),si(1)), (y2(1),alp(1)), (z2(1),bet(1))

  ist=n+1
  n=n+ns
  np=n
  mp=m
  ipsym=0
  if (ns < 1) return

  xd=xw2-xw1
  yd=yw2-yw1
  zd=zw2-zw1

  ! Check if segments have equal spacing (rdel ~= 1.0)
  if (abs(rdel-1.) >= 1.d-6) then
    ! Tapered segment spacing
    delz=sqrt(xd*xd+yd*yd+zd*zd)
    xd=xd/delz
    yd=yd/delz
    zd=zd/delz
    delz=delz*(1.-rdel)/(1.-rdel**ns)
    rd=rdel
  else
    ! Equal spacing
    fns=ns
    xd=xd/fns
    yd=yd/fns
    zd=zd/fns
    delz=1.
    rd=1.
  end if

  ! Generate wire segments
  radz=rad
  xs1=xw1
  ys1=yw1
  zs1=zw1

  do i = ist, n
    itag(i)=itg
    xs2=xs1+xd*delz
    ys2=ys1+yd*delz
    zs2=zs1+zd*delz
    x(i)=xs1
    y(i)=ys1
    z(i)=zs1
    x2(i)=xs2
    y2(i)=ys2
    z2(i)=zs2
    bi(i)=radz
    delz=delz*rd
    radz=radz*rrad
    xs1=xs2
    ys1=ys2
    zs1=zs2
  end do

  x2(n)=xw2
  y2(n)=yw2
  z2(n)=zw2

  return
end subroutine wire

subroutine helix(s,hl,a1,b1,a2,b2,rad,ns,itg)
! ***
! double precision 6/4/85
!
! subroutine helix generates segment geometry data for a helix of ns segments
!
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  implicit real*8(a-h,o-z)
!
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  dimension x2(1),y2(1),z2(1)
  equivalence (x2(1),si(1)), (y2(1),alp(1)), (z2(1),bet(1))
  data pi/3.1415926d+0/

  ist=n+1
  n=n+ns
  np=n
  mp=m
  ipsym=0
  if(ns < 1) return

  turns=abs(hl/s)
  zinc=abs(hl/ns)
  z(ist)=0.

  do i = ist, n
    bi(i)=rad
    itag(i)=itg
    if(i /= ist) z(i)=z(i-1)+zinc
    z2(i)=z(i)+zinc

    ! Check if constant or tapered helix
    if(a2 /= a1) then
      ! Tapered helix
      if(b2 == 0) b2=a2
      x(i)=(a1+(a2-a1)*z(i)/abs(hl))*cos(2.*pi*z(i)/s)
      y(i)=(b1+(b2-b1)*z(i)/abs(hl))*sin(2.*pi*z(i)/s)
      x2(i)=(a1+(a2-a1)*z2(i)/abs(hl))*cos(2.*pi*z2(i)/s)
      y2(i)=(b1+(b2-b1)*z2(i)/abs(hl))*sin(2.*pi*z2(i)/s)
    else
      ! Constant radius helix
      if(b1 == 0) b1=a1
      x(i)=a1*cos(2.*pi*z(i)/s)
      y(i)=b1*sin(2.*pi*z(i)/s)
      x2(i)=a1*cos(2.*pi*z2(i)/s)
      y2(i)=b1*sin(2.*pi*z2(i)/s)
    end if

    ! Check helix direction (left-hand vs right-hand)
    if(hl <= 0) then
      copy=x(i)
      x(i)=y(i)
      y(i)=copy
      copy=x2(i)
      x2(i)=y2(i)
      y2(i)=copy
    end if
  end do

  ! Output helix parameters
  if(a2 /= a1) then
    ! Tapered helix - output cone angle
    sangle=atan(a2/(abs(hl)+(abs(hl)*a1)/(a2-a1)))
    write(*,104) sangle
104 format(5x,'the cone angle of the spiral is',f10.4)
    return
  end if

  ! Constant radius helix - output pitch and turn length
  if(a1 /= b1) then
    ! Elliptical helix
    if(a1 >= b1) then
      hmaj=2.*a1
      hmin=2.*b1
    else
      hmaj=2.*b1
      hmin=2.*a1
    end if
    hdia=sqrt((hmaj**2+hmin**2)/2*hmaj)
    turn=2.*pi*hdia
    pitch=(180./pi)*atan(s/(pi*hdia))
  else
    ! Circular helix
    hdia=2.*a1
    turn=hdia*pi
    pitch=atan(s/(pi*hdia))
    turn=turn/cos(pitch)
    pitch=180.*pitch/pi
  end if

  write(*,105) pitch,turn
105 format(5x,'the pitch angle is',f10.4/5x,'the length of wire/turn is',f10.4)

  return
end subroutine helix

subroutine move (rox,roy,roz,xs,ys,zs,its,nrpt,itgi)
! ***
! double precision 6/4/85
!
! subroutine move moves the structure with respect to its
! coordinate system or reproduces structure in new positions.
! structure is rotated about x,y,z axes by rox,roy,roz
! respectively, then shifted by xs,ys,zs
!
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  implicit real*8(a-h,o-z)
!
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /angl/ salp(maxseg)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1), x2(1), y2(1), z2(1)
  equivalence (x2(1),si(1)), (y2(1),alp(1)), (z2(1),bet(1))
  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), (t2z,itag)

  if (abs(rox)+abs(roy) > 1.d-10) ipsym=ipsym*3

  ! Compute rotation matrix elements
  sps=sin(rox)
  cps=cos(rox)
  sth=sin(roy)
  cth=cos(roy)
  sph=sin(roz)
  cph=cos(roz)
  xx=cph*cth
  xy=cph*sth*sps-sph*cps
  xz=cph*sth*cps+sph*sps
  yx=sph*cth
  yy=sph*sth*sps+cph*cps
  yz=sph*sth*cps-cph*sps
  zx=-sth
  zy=cth*sps
  zz=cth*cps

  nrp=nrpt
  if (nrpt == 0) nrp=1
  ix=1

  ! Process wire segments (if any)
  if (n >= n2) then
    i1=isegno(its,1)
    if (i1 < n2) i1=n2
    ix=i1
    k=n
    if (nrpt == 0) k=i1-1

    do ir = 1, nrp
      do i = i1, n
        k=k+1
        xi=x(i)
        yi=y(i)
        zi=z(i)
        x(k)=xi*xx+yi*xy+zi*xz+xs
        y(k)=xi*yx+yi*yy+zi*yz+ys
        z(k)=xi*zx+yi*zy+zi*zz+zs
        xi=x2(i)
        yi=y2(i)
        zi=z2(i)
        x2(k)=xi*xx+yi*xy+zi*xz+xs
        y2(k)=xi*yx+yi*yy+zi*yz+ys
        z2(k)=xi*zx+yi*zy+zi*zz+zs
        bi(k)=bi(i)
        itag(k)=itag(i)
        if(itag(i) /= 0) itag(k)=itag(i)+itgi
      end do
      i1=n+1
      n=k
    end do
  end if

  ! Process patch (surface) elements (if any)
  if (m >= m2) then
    i1=m2
    k=m
    ldi=ld+1
    if (nrpt == 0) k=m1

    do ii = 1, nrp
      do i = i1, m
        k=k+1
        ir=ldi-i
        kr=ldi-k
        xi=x(ir)
        yi=y(ir)
        zi=z(ir)
        x(kr)=xi*xx+yi*xy+zi*xz+xs
        y(kr)=xi*yx+yi*yy+zi*yz+ys
        z(kr)=xi*zx+yi*zy+zi*zz+zs
        xi=t1x(ir)
        yi=t1y(ir)
        zi=t1z(ir)
        t1x(kr)=xi*xx+yi*xy+zi*xz
        t1y(kr)=xi*yx+yi*yy+zi*yz
        t1z(kr)=xi*zx+yi*zy+zi*zz
        xi=t2x(ir)
        yi=t2y(ir)
        zi=t2z(ir)
        t2x(kr)=xi*xx+yi*xy+zi*xz
        t2y(kr)=xi*yx+yi*yy+zi*yz
        t2z(kr)=xi*zx+yi*zy+zi*zz
        salp(kr)=salp(ir)
        bi(kr)=bi(ir)
      end do
      i1=m+1
      m=k
    end do
  end if

  if ((nrpt == 0) .and. (ix == 1)) return
  np=n
  mp=m
  ipsym=0

  return
end subroutine move
