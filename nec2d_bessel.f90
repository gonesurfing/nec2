! =============================================================================
! nec2d_bessel - Bessel and Hankel Functions
! =============================================================================
! Purpose: Special mathematical functions for electromagnetic calculations
! Contains: BESSEL, HANKEL
! =============================================================================
subroutine bessel (z,j0,j0p)
! bessel evaluates the zero-order bessel function and its derivative
! for complex argument z.
  implicit real*8(a-h,o-z)
  save
  complex*16 j0,j0p,p0z,p1z,q0z,q1z,z,zi,zi2,zk,fj,cz,sz,j0x,j0px
  dimension m(101), a1(25), a2(25), fjx(2)
  equivalence (fj,fjx)
  data c3,p10,p20,q10,q20/.7978845608,.0703125,.1121520996,.125,.0732421875/
  data p11,p21,q11,q21/.1171875,.1441955566,.375,.1025390625/
  data pof,init/.7853981635,0/,fjx/0.,1./

  ! eliminated goto - initialize constants on first call
  if (init == 0) then
    do k = 1, 25
      a1(k)=-.25d0/(k*k)
      a2(k)=1.d0/(k+1.d0)
    end do

    do i = 1, 101
      test=1.d0
      do k = 1, 24
        init=k
        test=-test*i*a1(k)
        if (test < 1.d-6) exit
      end do
      m(i)=init
    end do
  end if

  ! main calculation begins
  zms=z*dconjg(z)

  ! eliminated goto - handle small argument case
  if (zms <= 1.e-12) then
    j0=(1.,0.)
    j0p=-.5*z
    return
  end if

  ib=0
  if (zms > 37.21) then
    ! use only asymptotic expansion
    ib=0
  else if (zms > 36.) then
    ! blend region - use both expansions
    ib=1
  else
    ! use only series expansion
    ib=0
  end if

  ! eliminated goto - structured choice between expansions
  if (zms <= 37.21) then
    ! series expansion
    iz=1.+zms
    miz=m(iz)
    j0=(1.,0.)
    j0p=j0
    zk=j0
    zi=z*z

    do k = 1, miz
      zk=zk*a1(k)*zi
      j0=j0+zk
      j0p=j0p+a2(k)*zk
    end do

    j0p=-.5*z*j0p

    if (ib == 0) return

    j0x=j0
    j0px=j0p
  end if

  ! asymptotic expansion
  zi=1./z
  zi2=zi*zi
  p0z=1.+(p20*zi2-p10)*zi2
  p1z=1.+(p11-p21*zi2)*zi2
  q0z=(q20*zi2-q10)*zi
  q1z=(q11-q21*zi2)*zi
  zk=exp(fj*(z-pof))
  zi2=1./zk
  cz=.5*(zk+zi2)
  sz=fj*.5*(zi2-zk)
  zk=c3*sqrt(zi)
  j0=zk*(p0z*cz-q0z*sz)
  j0p=-zk*(p1z*sz+q1z*cz)

  if (ib == 0) return

  ! blend series and asymptotic expansions
  zms=cos((sqrt(zms)-6.)*31.41592654)
  j0=.5*(j0x*(1.+zms)+j0*(1.-zms))
  j0p=.5*(j0px*(1.+zms)+j0p*(1.-zms))

  return
end subroutine bessel

subroutine hankel (z,h0,h0p)
! hankel evaluates hankel function of the first kind, order zero,
! and its derivative for complex argument z.
  implicit real*8(a-h,o-z)
  save
  complex*16 clogz,h0,h0p,j0,j0p,p0z,p1z,q0z,q1z,y0,y0p,z,zi,zi2,zk,fj
  dimension m(101), a1(25), a2(25), a3(25), a4(25), fjx(2)
  equivalence (fj,fjx)
  data pi,gamma,c1,c2,c3,p10,p20/3.141592654,.5772156649,-.0245785095, &
    .3674669052,.7978845608,.0703125,.1121520996/
  data q10,q20,p11,p21,q11,q21/.125,.0732421875,.1171875,.1441955566, &
    .375,.1025390625/
  data pof,init/.7853981635,0/,fjx/0.,1./

  ! eliminated goto - initialize constants on first call
  if (init == 0) then
    psi=-gamma

    do k = 1, 25
      a1(k)=-.25d0/(k*k)
      a2(k)=1.d0/(k+1.d0)
      psi=psi+1.d0/k
      a3(k)=psi+psi
      a4(k)=(psi+psi+1.d0/(k+1.d0))/(k+1.d0)
    end do

    do i = 1, 101
      test=1.d0
      do k = 1, 24
        init=k
        test=-test*i*a1(k)
        if (test*a3(k) < 1.d-6) exit
      end do
      m(i)=init
    end do
  end if

  ! main calculation begins
  zms=z*dconjg(z)

  ! eliminated goto - check for zero argument
  if (zms == 0.) then
    write(*,9)
9   format (34h error - hankel not valid for z=0.)
    stop
  end if

  ib=0
  if (zms > 16.81) then
    ! use only asymptotic expansion
    ib=0
  else if (zms > 16.) then
    ! blend region - use both expansions
    ib=1
  else
    ! use only series expansion
    ib=0
  end if

  ! eliminated goto - structured choice between expansions
  if (zms <= 16.81) then
    ! series expansion
    iz=1.+zms
    miz=m(iz)
    j0=(1.,0.)
    j0p=j0
    y0=(0.,0.)
    y0p=y0
    zk=j0
    zi=z*z

    do k = 1, miz
      zk=zk*a1(k)*zi
      j0=j0+zk
      j0p=j0p+a2(k)*zk
      y0=y0+a3(k)*zk
      y0p=y0p+a4(k)*zk
    end do

    j0p=-.5*z*j0p
    clogz=log(.5*z)
    y0=(2.*j0*clogz-y0)/pi+c2
    y0p=(2./z+2.*j0p*clogz+.5*y0p*z)/pi+c1*z
    h0=j0+fj*y0
    h0p=j0p+fj*y0p

    if (ib == 0) return

    y0=h0
    y0p=h0p
  end if

  ! asymptotic expansion
  zi=1./z
  zi2=zi*zi
  p0z=1.+(p20*zi2-p10)*zi2
  p1z=1.+(p11-p21*zi2)*zi2
  q0z=(q20*zi2-q10)*zi
  q1z=(q11-q21*zi2)*zi
  zk=exp(fj*(z-pof))*sqrt(zi)*c3
  h0=zk*(p0z+fj*q0z)
  h0p=fj*zk*(p1z+fj*q1z)

  if (ib == 0) return

  ! blend series and asymptotic expansions
  zms=cos((sqrt(zms)-4.)*31.41592654)
  h0=.5*(y0*(1.+zms)+h0*(1.-zms))
  h0p=.5*(y0p*(1.+zms)+h0p*(1.-zms))

  return
end subroutine hankel
