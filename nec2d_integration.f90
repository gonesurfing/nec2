! =============================================================================
! nec2d_integration - Numerical Integration
! =============================================================================
! Purpose: Integration routines for kernel evaluations
! Contains: HFK, FACTR
! GOTOs eliminated: 9
! =============================================================================
subroutine hfk(el1,el2,rhk,zpkx,sgr,sgi)
!
! hfk computes the h field of a uniform current filament by
! numerical integration using variable interval width romberg integration.
!
  implicit real*8(a-h,o-z)
  common /tmh/ zpk,rhks
  data nx,nm,nts,rx/1,65536,4,1.d-4/

  zpk=zpkx
  rhks=rhk*rhk
  z=el1
  ze=el2
  s=ze-z
  ep=s/(10.d0*nm)
  zend=ze-ep
  sgr=0.d0
  sgi=0.d0
  ns=nx
  nt=0
  call gh(z,g1r,g1i)

  ! Main integration loop
  do while (.true.)
    dz=s/ns
    zp=z+dz

    ! Check if step exceeds endpoint
    if (zp > ze) then
      dz=ze-z
      if (abs(dz) <= ep) exit  ! Done
    end if

    dzot=dz*0.5d0
    zp=z+dzot
    call gh(zp,g3r,g3i)
    zp=z+dz
    call gh(zp,g5r,g5i)

    ! Romberg integration refinement loop
    do while (.true.)
      t00r=(g1r+g5r)*dzot
      t00i=(g1i+g5i)*dzot
      t01r=(t00r+dz*g3r)*0.5d0
      t01i=(t00i+dz*g3i)*0.5d0
      t10r=(4.d0*t01r-t00r)/3.d0
      t10i=(4.d0*t01i-t00i)/3.d0

      ! Test convergence of 3 point romberg result
      call test(t01r,t10r,te1r,t01i,t10i,te1i,0.d0)

      if (te1i <= rx .and. te1r <= rx) then
        ! 3-point converged
        sgr=sgr+t10r
        sgi=sgi+t10i
        nt=nt+2
        exit
      end if

      ! Need 5-point refinement
      zp=z+dz*0.25d0
      call gh(zp,g2r,g2i)
      zp=z+dz*0.75d0
      call gh(zp,g4r,g4i)
      t02r=(t01r+dzot*(g2r+g4r))*0.5d0
      t02i=(t01i+dzot*(g2i+g4i))*0.5d0
      t11r=(4.d0*t02r-t01r)/3.d0
      t11i=(4.d0*t02i-t01i)/3.d0
      t20r=(16.d0*t11r-t10r)/15.d0
      t20i=(16.d0*t11i-t10i)/15.d0

      ! Test convergence of 5 point romberg result
      call test(t11r,t20r,te2r,t11i,t20i,te2i,0.d0)

      if (te2i <= rx .and. te2r <= rx) then
        ! 5-point converged
        sgr=sgr+t20r
        sgi=sgi+t20i
        nt=nt+1
        exit
      end if

      ! Not converged - refine step
      nt=0
      if (ns >= nm) then
        ! Step size limit reached
        write(*,18) z
        sgr=sgr+t20r
        sgi=sgi+t20i
        nt=nt+1
        exit
      else
        ! Halve step size and retry
        ns=ns*2
        dz=s/ns
        dzot=dz*0.5d0
        g5r=g3r
        g5i=g3i
        g3r=g2r
        g3i=g2i
        ! Continue refinement loop
      end if
    end do

    ! Advance to next step
    z=z+dz
    if (z >= zend) exit
    g1r=g5r
    g1i=g5i

    ! Adjust step size if needed
    if (nt >= nts) then
      if (ns > nx) then
        ns=ns/2
        nt=1
      end if
    end if
  end do

  ! Scale final result
  sgr=sgr*rhk*0.5d0
  sgi=sgi*rhk*0.5d0

18 format(24h step size limited at z=,f10.5)

end subroutine hfk

subroutine factr(n,a,ip,ndim)
!
! factr factors a matrix into a unit lower triangular matrix
! and an upper triangular matrix using the gauss-doolittle algorithm
! presented on pages 411-416 of a. ralston--a first course in
! numerical analysis. comments below refer to comments in ralstons
! text. (matrix transposed.)
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)
  complex*16 a,d,arj
  dimension a(ndim,ndim), ip(ndim)
  common /scratm/ d(2*maxseg)
  integer r,rm1,rp1,pj,pr

  ! Un-transpose the matrix for gauss elimination
  do i = 2, n
    do j = 1, i-1
      arj=a(i,j)
      a(i,j)=a(j,i)
      a(j,i)=arj
    end do
  end do

  iflg=0

  do r = 1, n
    ! Step 1
    do k = 1, n
      d(k)=a(k,r)
    end do

    ! Steps 2 and 3
    rm1=r-1
    if (rm1 >= 1) then
      do j = 1, rm1
        pj=ip(j)
        arj=d(pj)
        a(j,r)=arj
        d(pj)=d(j)
        jp1=j+1
        do i = jp1, n
          d(i)=d(i)-a(i,j)*arj
        end do
      end do
    end if

    ! Step 4 - find pivot
    dmax=dreal(d(r)*dconjg(d(r)))
    ip(r)=r
    rp1=r+1

    if (rp1 <= n) then
      do i = rp1, n
        elmag=dreal(d(i)*dconjg(d(i)))
        if (elmag >= dmax) then
          dmax=elmag
          ip(r)=i
        end if
      end do
    end if

    if (dmax < 1.d-10) iflg=1
    pr=ip(r)
    a(r,r)=d(pr)
    d(pr)=d(r)

    ! Step 5 - divide by pivot
    if (rp1 <= n) then
      arj=1.d0/a(r,r)
      do i = rp1, n
        a(i,r)=d(i)*arj
      end do
    end if

    if (iflg /= 0) then
      write(*,10) r,dmax
      iflg=0
    end if
  end do

10 format(1h ,6hpivot(,i3,2h)=,1p,e16.8)

end subroutine factr
