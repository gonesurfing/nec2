! =============================================================================
! nec2d_kernels - Kernel Functions
! =============================================================================
! Purpose: Thin-wire kernel approximations
! Contains: EKSC, GF, SOLVE
! GOTOs eliminated: 4
! =============================================================================
subroutine eksc(s,z,rh,xk,ij,ezs,ers,ezc,erc,ezk,erk)
!
! eksc computes e field of sine, cosine, and constant current filaments
! by thin wire approximation.
!
  implicit real*8(a-h,o-z)
  complex*16 con,gz1,gz2,gp1,gp2,gzp1,gzp2,ezs,ers,ezc,erc,ezk,erk
  common /tmi/ zpk,rkb2,ijx
  dimension conx(2)
  equivalence (conx,con)
  data conx/0.d0,4.771341189d0/

  ijx=ij
  zpk=xk*z
  rhk=xk*rh
  rkb2=rhk*rhk
  sh=0.5d0*s
  shk=xk*sh
  ss=sin(shk)
  cs=cos(shk)
  z2=sh-z
  z1=-(sh+z)

  call gx(z1,rh,xk,gz1,gp1)
  call gx(z2,rh,xk,gz2,gp2)

  gzp1=gp1*z1
  gzp2=gp2*z2
  ezs=con*((gz2-gz1)*cs*xk-(gzp2+gzp1)*ss)
  ezc=-con*((gz2+gz1)*ss*xk+(gzp2-gzp1)*cs)
  erk=con*(gp2-gp1)*rh

  call intx(-shk,shk,rhk,ij,cint,sint)
  ezk=-con*(gzp2-gzp1+xk*xk*dcmplx(cint,-sint))

  gzp1=gzp1*z1
  gzp2=gzp2*z2

  ! Handle small rh case
  if (rh < 1.d-10) then
    ers=(0.d0,0.d0)
    erc=(0.d0,0.d0)
  else
    ers=-con*((gzp2+gzp1+gz2+gz1)*ss-(z2*gz2-z1*gz1)*cs*xk)/rh
    erc=-con*((gzp2-gzp1+gz2-gz1)*cs+(z2*gz2+z1*gz1)*ss*xk)/rh
  end if

end subroutine eksc

subroutine gf(zk,co,si)
!
! gf computes the integrand exp(jkr)/(kr) for numerical integration.
!
  implicit real*8(a-h,o-z)
  common /tmi/ zpk,rkb2,ij

  zdk=zk-zpk
  rk=sqrt(rkb2+zdk*zdk)
  si=sin(rk)/rk

  ! Compute cosine term based on ij flag
  if (ij /= 0) then
    ! Direct computation
    co=cos(rk)/rk
  else
    ! Use series expansion for small rk, otherwise direct
    if (rk < 0.2d0) then
      ! Series expansion
      rks=rk*rk
      co=((-1.38888889d-3*rks+4.16666667d-2)*rks-0.5d0)*rk
    else
      ! Direct computation
      co=(cos(rk)-1.d0)/rk
    end if
  end if

end subroutine gf

subroutine solve(n,a,ip,b,ndim)
!
! solve solves the matrix equation lu*x=b where l is a unit lower
! triangular matrix and u is an upper triangular matrix, both stored
! in a. the rhs vector b is input and the solution is returned through
! vector b.
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)
  complex*16 a,b,y,sum
  integer pi
  common /scratm/ y(2*maxseg)
  dimension a(ndim,ndim), ip(ndim), b(ndim)

  ! Forward substitution
  do i = 1, n
    pi=ip(i)
    y(i)=b(pi)
    b(pi)=b(i)
    ip1=i+1

    if (ip1 <= n) then
      do j = ip1, n
        b(j)=b(j)-a(j,i)*y(i)
      end do
    end if
  end do

  ! Backward substitution
  do k = 1, n
    i=n-k+1
    sum=(0.d0,0.d0)
    ip1=i+1

    if (ip1 <= n) then
      do j = ip1, n
        sum=sum+a(i,j)*b(j)
      end do
    end if

    b(i)=(y(i)-sum)/a(i,i)
  end do

end subroutine solve
