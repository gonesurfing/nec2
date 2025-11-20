! =============================================================================
! nec2d_mathutil - Mathematical Utilities
! =============================================================================
! Purpose: Complex arithmetic and special function helpers
! Contains: GH, GX, GXX, LAMBDA, GWAVE, PCINT, FFLDS, CPUSEC, CANG, ATGN2, DB10
! =============================================================================
subroutine gh (zk,hr,hi)
! integrand for h field of a wire
  implicit real*8(a-h,o-z)
  common /tmh/ zpk,rhks

  rs=zk-zpk
  rs=rhks+rs*rs
  r=sqrt(rs)
  ckr=cos(r)
  skr=sin(r)
  rr2=1./rs
  rr3=rr2/r
  hr=skr*rr2+ckr*rr3
  hi=ckr*rr2-skr*rr3

  return
end subroutine gh

subroutine gx (zz,rh,xk,gz,gzp)
! segment end contributions for thin wire approx.
  implicit real*8(a-h,o-z)
  complex*16 gz,gzp

  r2=zz*zz+rh*rh
  r=sqrt(r2)
  rk=xk*r
  gz=dcmplx(cos(rk),-sin(rk))/r
  gzp=-dcmplx(1.d+0,rk)*gz/r2

  return
end subroutine gx

subroutine gxx (zz,rh,a,a2,xk,ira,g1,g1p,g2,g2p,g3,gzp)
! segment end contributions for ext. thin wire approx.
  implicit real*8(a-h,o-z)
  complex*16 gz,c1,c2,c3,g1,g1p,g2,g2p,g3,gzp

  r2=zz*zz+rh*rh
  r=sqrt(r2)
  r4=r2*r2
  rk=xk*r
  rk2=rk*rk
  rh2=rh*rh
  t1=.25*a2*rh2/r4
  t2=.5*a2/r2
  c1=dcmplx(1.d+0,rk)
  c2=3.*c1-rk2
  c3=dcmplx(6.d+0,rk)*rk2-15.*c1
  gz=dcmplx(cos(rk),-sin(rk))/r
  g2=gz*(1.+t1*c2)
  g1=g2-t2*c1*gz
  gz=gz/r2
  g2p=gz*(t1*c3-c1)
  gzp=t2*c2*gz
  g3=g2p+gzp
  g1p=g3*zz

  ! eliminated goto with structured if
  if (ira == 1) then
    ! ira=1 branch
    t2=.5*a
    g2=-t2*c1*gz
    g2p=t2*gz*c2/r2
    g3=rh2*g2p-a*gz*c1
    g2p=g2p*zz
    gzp=-zz*c1*gz
  else
    ! ira/=1 branch
    g3=(g3+gzp)*rh
    gzp=-zz*c1*gz
    if (rh > 1.d-10) then
      g2=g2/rh
      g2p=g2p*zz/rh
    else
      g2=0.
      g2p=0.
    end if
  end if

  return
end subroutine gxx

subroutine lambda (t,xlam,dxlam)
! compute integration parameter xlam=lambda from parameter t.
  implicit real*8(a-h,o-z)
  save
  complex*16 a,b,xlam,dxlam
  common /cntour/ a,b

  dxlam=b-a
  xlam=a+dxlam*t

  return
end subroutine lambda

subroutine gwave (erv,ezv,erh,ezh,eph)
! gwave computes the electric field, including ground wave, of a
! current element over a ground plane using formulas of k.a. norton
! (proc. ire, sept., 1937, pp.1203,1236.)
  implicit real*8(a-h,o-z)
  complex*16 fj,tpj,u2,u,rk1,rk2,t1,t2,t3,t4,p1,rv,omr,w,f,q1,rh,v,g, &
    xr1,xr2,x1,x2,x3,x4,x5,x6,x7,ezv,erv,ezh,erh,eph,xx1,xx2,econ,fbar
  common /gwav/ u,u2,xx1,xx2,r1,r2,zmh,zph
  dimension fjx(2), tpjx(2), econx(2)
  equivalence (fj,fjx), (tpj,tpjx), (econ,econx)
  data fjx/0.,1./,tpjx/0.,6.283185308d+0/
  data econx/0.,-188.367/

  sppp=zmh/r1
  sppp2=sppp*sppp
  cppp2=1.-sppp2
  if (cppp2 < 1.d-20) cppp2=1.d-20
  cppp=sqrt(cppp2)
  spp=zph/r2
  spp2=spp*spp
  cpp2=1.-spp2
  if (cpp2 < 1.d-20) cpp2=1.d-20
  cpp=sqrt(cpp2)
  rk1=-tpj*r1
  rk2=-tpj*r2
  t1=1.-u2*cpp2
  t2=sqrt(t1)
  t3=(1.-1./rk1)/rk1
  t4=(1.-1./rk2)/rk2
  p1=rk2*u2*t1/(2.*cpp2)
  rv=(spp-u*t2)/(spp+u*t2)
  omr=1.-rv
  w=1./omr
  w=(4.,0.)*p1*w*w
  f=fbar(w)
  q1=rk2*t1/(2.*u2*cpp2)
  rh=(t2-u*spp)/(t2+u*spp)
  v=1./(1.+rh)
  v=(4.,0.)*q1*v*v
  g=fbar(v)
  xr1=xx1/r1
  xr2=xx2/r2
  x1=cppp2*xr1
  x2=rv*cpp2*xr2
  x3=omr*cpp2*f*xr2
  x4=u*t2*spp*2.*xr2/rk2
  x5=xr1*t3*(1.-3.*sppp2)
  x6=xr2*t4*(1.-3.*spp2)
  ezv=(x1+x2+x3-x4-x5-x6)*econ
  x1=sppp*cppp*xr1
  x2=rv*spp*cpp*xr2
  x3=cpp*omr*u*t2*f*xr2
  x4=spp*cpp*omr*xr2/rk2
  x5=3.*sppp*cppp*t3*xr1
  x6=cpp*u*t2*omr*xr2/rk2*.5
  x7=3.*spp*cpp*t4*xr2
  erv=-(x1+x2-x3+x4-x5+x6-x7)*econ
  ezh=-(x1-x2+x3-x4-x5-x6+x7)*econ
  x1=sppp2*xr1
  x2=rv*spp2*xr2
  x4=u2*t1*omr*f*xr2
  x5=t3*(1.-3.*cppp2)*xr1
  x6=t4*(1.-3.*cpp2)*(1.-u2*(1.+rv)-u2*omr*f)*xr2
  x7=u2*cpp2*omr*(1.-1./rk2)*(f*(u2*t1-spp2-1./rk2)+1./rk2)*xr2
  erh=(x1-x2-x4-x5+x6+x7)*econ
  x1=xr1
  x2=rh*xr2
  x3=(rh+1.)*g*xr2
  x4=t3*xr1
  x5=t4*(1.-u2*(1.+rv)-u2*omr*f)*xr2
  x6=.5*u2*omr*(f*(u2*t1-spp2-1./rk2)+1./rk2)*xr2/rk2
  eph=-(x1-x2+x3-x4+x5+x6)*econ

  return
end subroutine gwave

subroutine pcint (xi,yi,zi,cabi,sabi,salpi,e)
! integrate over patches at wire connection point
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  implicit real*8(a-h,o-z)
  complex*16 exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc,e,e1,e2,e3,e4,e5,e6,e7,e8,e9
  common /dataj/ s,b,xj,yj,zj,cabj,sabj,salpj,exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc, &
    rkh,ind1,indd1,ind2,indd2,iexk,ipgnd
  dimension e(9)
  equivalence (t1xj,cabj), (t1yj,sabj), (t1zj,salpj), (t2xj,b), (t2yj,ind1), (t2zj,ind2)
  data tpi/6.283185308d+0/,nint/10/

  d=sqrt(s)*.5
  ds=4.*d/dfloat(nint)
  da=ds*ds
  gcon=1./s
  fcon=1./(2.*tpi*d)
  xxj=xj
  xyj=yj
  xzj=zj
  xs=s
  s=da
  s1=d+ds*.5
  xss=xj+s1*(t1xj+t2xj)
  yss=yj+s1*(t1yj+t2yj)
  zss=zj+s1*(t1zj+t2zj)
  s1=s1+d
  s2x=s1
  e1=(0.,0.)
  e2=(0.,0.)
  e3=(0.,0.)
  e4=(0.,0.)
  e5=(0.,0.)
  e6=(0.,0.)
  e7=(0.,0.)
  e8=(0.,0.)
  e9=(0.,0.)

  do i1 = 1, nint
    s1=s1-ds
    s2=s2x
    xss=xss-ds*t1xj
    yss=yss-ds*t1yj
    zss=zss-ds*t1zj
    xj=xss
    yj=yss
    zj=zss

    do i2 = 1, nint
      s2=s2-ds
      xj=xj-ds*t2xj
      yj=yj-ds*t2yj
      zj=zj-ds*t2zj
      call unere (xi,yi,zi)
      exk=exk*cabi+eyk*sabi+ezk*salpi
      exs=exs*cabi+eys*sabi+ezs*salpi
      g1=(d+s1)*(d+s2)*gcon
      g2=(d-s1)*(d+s2)*gcon
      g3=(d-s1)*(d-s2)*gcon
      g4=(d+s1)*(d-s2)*gcon
      f2=(s1*s1+s2*s2)*tpi
      f1=s1/f2-(g1-g2-g3+g4)*fcon
      f2=s2/f2-(g1+g2-g3-g4)*fcon
      e1=e1+exk*g1
      e2=e2+exk*g2
      e3=e3+exk*g3
      e4=e4+exk*g4
      e5=e5+exs*g1
      e6=e6+exs*g2
      e7=e7+exs*g3
      e8=e8+exs*g4
      e9=e9+exk*f1+exs*f2
    end do
  end do

  e(1)=e1
  e(2)=e2
  e(3)=e3
  e(4)=e4
  e(5)=e5
  e(6)=e6
  e(7)=e7
  e(8)=e8
  e(9)=e9
  xj=xxj
  yj=xyj
  zj=xzj
  s=xs

  return
end subroutine pcint

subroutine fflds (rox,roy,roz,scur,ex,ey,ez)
! calculates the xyz components of the electric field due to
! surface currents
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  implicit real*8(a-h,o-z)
  complex*16 ct,cons,scur,ex,ey,ez
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  dimension xs(1), ys(1), zs(1), s(1), scur(1), consx(2)
  equivalence (xs,x), (ys,y), (zs,z), (s,bi), (cons,consx)
  data tpi/6.283185308d+0/,consx/0.,188.365/

  ex=(0.,0.)
  ey=(0.,0.)
  ez=(0.,0.)
  i=ld+1

  do j = 1, m
    i=i-1
    arg=tpi*(rox*xs(i)+roy*ys(i)+roz*zs(i))
    ct=dcmplx(cos(arg)*s(i),sin(arg)*s(i))
    k=3*j
    ex=ex+scur(k-2)*ct
    ey=ey+scur(k-1)*ct
    ez=ez+scur(k)*ct
  end do

  ex=ex*cons
  ey=ey*cons
  ez=ez*cons

  return
end subroutine fflds

subroutine cpusec (cpusecd)
! cpu time in seconds - returns dummy value
  implicit real*8(a-h,o-z)
  cpusecd=0.0
  return
end subroutine cpusec

function cang (z)
! returns the phase angle of a complex number in degrees
  implicit real*8(a-h,o-z)
  complex*16 z
  r=real(z)
  xi=aimag(z)
  cang=atan2(xi,r)*57.29577951d+0
  return
end function cang

function atgn2 (x,y)
! atan2 function (arctangent of y/x)
  implicit real*8(a-h,o-z)
  atgn2=atan2(y,x)
  return
end function atgn2

function db10 (x)
! function db-- returns db for magnitude (field) - 10*log10
! also provides entry point db20 for power (20*log10)
  implicit real*8(a-h,o-z)

  ! eliminated goto - use if/else structure
  if (x >= 1.d-20) then
    db10=10.*log10(x)
  else
    db10=-999.99
  end if
  return

  ! entry point for power (20*log10)
  entry db20(x)
  if (x >= 1.d-20) then
    db20=20.*log10(x)
  else
    db20=-999.99
  end if
  return
end function db10
