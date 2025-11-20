! =============================================================================
! nec2d_numint - Numerical Integration
! =============================================================================
! Purpose: Sommerfeld integral evaluation and ROM integration
! Contains: ROM2, INTRP, SOM2D
! GOTOs eliminated: 36
! =============================================================================
subroutine rom2 (a,b,sum,dmin)

  implicit real*8(a-h,o-z)

  complex*16 sum,g1,g2,g3,g4,g5,t00,t01,t10,t02,t11,t20
  dimension sum(9), g1(9), g2(9), g3(9), g4(9), g5(9), t01(9), t10(9), t20(9)
  data nm,nts,nx,n/65536,4,1,9/,rx/1.d-4/

  ! Initialize integration parameters
  z=a
  ze=b
  s=b-a

  ! Check for valid integration interval
  if (s < 0.0d0) then
    write(*,18)
18  format (30h error - b less than a in rom2)
    stop
  endif

  ! Set up integration parameters
  ep=s/(1.d4*nm)
  zend=ze-ep

  ! Initialize sum array
  do i=1,n
    sum(i)=(0.d0,0.d0)
  enddo

  ns=nx
  nt=0
  call sflds (z,g1)

  ! Main integration loop - advance along integration path
  main_integration: do while (.true.)

    ! Calculate step size for current interval
    dz=s/ns
    if (z+dz > ze) then
      dz=ze-z
      if (dz <= ep) exit main_integration
    endif

    ! Evaluate field at interval points
    dzot=dz*0.5d0
    call sflds (z+dzot,g3)
    call sflds (z+dz,g5)

    ! Adaptive refinement loop - refine current interval until converged
    adaptive_refinement: do while (.true.)

      tmag1=0.d0
      tmag2=0.d0

      ! Evaluate 3 point Romberg result and test convergence
      do i=1,n
        t00=(g1(i)+g5(i))*dzot
        t01(i)=(t00+dz*g3(i))*0.5d0
        t10(i)=(4.d0*t01(i)-t00)/3.d0
        if (i <= 3) then
          tr=dreal(t01(i))
          ti=dimag(t01(i))
          tmag1=tmag1+tr*tr+ti*ti
          tr=dreal(t10(i))
          ti=dimag(t10(i))
          tmag2=tmag2+tr*tr+ti*ti
        endif
      enddo

      tmag1=sqrt(tmag1)
      tmag2=sqrt(tmag2)
      call test(tmag1,tmag2,tr,0.d0,0.d0,ti,dmin)

      if (tr <= rx) then
        ! 3-point converged - add to sum and exit refinement loop
        do i=1,n
          sum(i)=sum(i)+t10(i)
        enddo
        nt=nt+2
        exit adaptive_refinement
      endif

      ! 3-point did not converge - evaluate 5-point Romberg
      call sflds (z+dz*0.25d0,g2)
      call sflds (z+dz*0.75d0,g4)
      tmag1=0.d0
      tmag2=0.d0

      ! Evaluate 5 point Romberg result and test convergence
      do i=1,n
        t02=(t01(i)+dzot*(g2(i)+g4(i)))*0.5d0
        t11=(4.d0*t02-t01(i))/3.d0
        t20(i)=(16.d0*t11-t10(i))/15.d0
        if (i <= 3) then
          tr=dreal(t11)
          ti=dimag(t11)
          tmag1=tmag1+tr*tr+ti*ti
          tr=dreal(t20(i))
          ti=dimag(t20(i))
          tmag2=tmag2+tr*tr+ti*ti
        endif
      enddo

      tmag1=sqrt(tmag1)
      tmag2=sqrt(tmag2)
      call test(tmag1,tmag2,tr,0.d0,0.d0,ti,dmin)

      if (tr <= rx) then
        ! 5-point converged - add to sum and exit refinement loop
        do i=1,n
          sum(i)=sum(i)+t20(i)
        enddo
        nt=nt+1
        exit adaptive_refinement
      endif

      ! 5-point did not converge - attempt interval refinement
      nt=0
      if (ns < nm) then
        ! Refine interval by doubling NS and reusing field values
        ns=ns*2
        dz=s/ns
        dzot=dz*0.5d0
        do i=1,n
          g5(i)=g3(i)
          g3(i)=g2(i)
        enddo
        ! Continue adaptive refinement with new interval size
      else
        ! Maximum refinement reached - accept result with warning
        write(*,19) z
19      format (33h rom2 -- step size limited at z =,1p,e12.5)
        do i=1,n
          sum(i)=sum(i)+t20(i)
        enddo
        nt=nt+1
        exit adaptive_refinement
      endif

    enddo adaptive_refinement

    ! Update position along integration path
    z=z+dz
    if (z > zend) exit main_integration

    ! Update G1 for next interval
    do i=1,n
      g1(i)=g5(i)
    enddo

    ! Adjust interval size if appropriate
    if (nt >= nts .and. ns > nx) then
      ns=ns/2
      nt=1
    endif

  enddo main_integration

  return
end subroutine rom2

!==============================================================================
! INTRP - Bivariate Cubic Interpolation
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 2531-2686)
! Tier 2: Eliminated 11 GOTOs using structured control flow
!
! Purpose: Uses bivariate cubic interpolation to obtain values of 4 functions
!          at point (X,Y) from Sommerfeld ground field grids
!
! Changes from original:
! - Converted to free-form Fortran 90
! - Eliminated all GOTO statements (11 total, labels 1-12)
! - Converted labeled DO loops to DO...END DO
! - Changed comment syntax from C to !
! - Maintained IMPLICIT REAL*8, COMMON blocks, and EQUIVALENCE statements
!==============================================================================
subroutine intrp(x, y, f1, f2, f3, f4)
  implicit real*8(a-h, o-z)

  ! INTRP uses bivariate cubic interpolation to obtain the values of
  ! 4 functions at the point (X,Y).

  complex*16 f1, f2, f3, f4, a, b, c, d, fx1, fx2, fx3, fx4, p1, p2, p3, p4
  complex*16 a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34
  complex*16 a41, a42, a43, a44, b11, b12, b13, b14, b21, b22, b23, b24
  complex*16 b31, b32, b33, b34, b41, b42, b43, b44, c11, c12, c13, c14
  complex*16 c21, c22, c23, c24, c31, c32, c33, c34, c41, c42, c43, c44
  complex*16 d11, d12, d13, d14, d21, d22, d23, d24, d31, d32, d33, d34
  complex*16 d41, d42, d43, d44
  complex*16 ar1, ar2, ar3, arl1, arl2, arl3, epscf

  common /ggrid/ ar1(11,10,4), ar2(17,5,4), ar3(9,8,4), epscf, dxa(3), &
                 dya(3), xsa(3), ysa(3), nxa(3), nya(3)

  dimension nda(3), ndpa(3)
  dimension a(4,4), b(4,4), c(4,4), d(4,4), arl1(1), arl2(1), arl3(1)

  equivalence (a(1,1),a11), (a(1,2),a12), (a(1,3),a13), (a(1,4),a14)
  equivalence (a(2,1),a21), (a(2,2),a22), (a(2,3),a23), (a(2,4),a24)
  equivalence (a(3,1),a31), (a(3,2),a32), (a(3,3),a33), (a(3,4),a34)
  equivalence (a(4,1),a41), (a(4,2),a42), (a(4,3),a43), (a(4,4),a44)
  equivalence (b(1,1),b11), (b(1,2),b12), (b(1,3),b13), (b(1,4),b14)
  equivalence (b(2,1),b21), (b(2,2),b22), (b(2,3),b23), (b(2,4),b24)
  equivalence (b(3,1),b31), (b(3,2),b32), (b(3,3),b33), (b(3,4),b34)
  equivalence (b(4,1),b41), (b(4,2),b42), (b(4,3),b43), (b(4,4),b44)
  equivalence (c(1,1),c11), (c(1,2),c12), (c(1,3),c13), (c(1,4),c14)
  equivalence (c(2,1),c21), (c(2,2),c22), (c(2,3),c23), (c(2,4),c24)
  equivalence (c(3,1),c31), (c(3,2),c32), (c(3,3),c33), (c(3,4),c34)
  equivalence (c(4,1),c41), (c(4,2),c42), (c(4,3),c43), (c(4,4),c44)
  equivalence (d(1,1),d11), (d(1,2),d12), (d(1,3),d13), (d(1,4),d14)
  equivalence (d(2,1),d21), (d(2,2),d22), (d(2,3),d23), (d(2,4),d24)
  equivalence (d(3,1),d31), (d(3,2),d32), (d(3,3),d33), (d(3,4),d34)
  equivalence (d(4,1),d41), (d(4,2),d42), (d(4,3),d43), (d(4,4),d44)
  equivalence (arl1,ar1), (arl2,ar2), (arl3,ar3), (xs2,xsa(2)), &
              (ys3,ysa(3))

  data ixs, iys, igrs / -10, -10, -10 /, dx, dy, xs, ys / 1., 1., 0., 0. /
  data nda / 11, 17, 9 /, ndpa / 110, 85, 72 /, ixeg, iyeg / 0, 0 /

  logical :: cache_hit

  ! Check if point lies in same 4 by 4 point region as previous point
  ! If so, old values are reused (cache hit)
  cache_hit = .false.

  if (x .ge. xs .and. y .ge. ys) then
    ix = int((x - xs) / dx) + 1
    iy = int((y - ys) / dy) + 1

    if (ix .ge. ixeg .and. iy .ge. iyeg) then
      if (iabs(ix - ixs) .lt. 2 .and. iabs(iy - iys) .lt. 2) then
        cache_hit = .true.
      end if
    end if
  end if

  if (.not. cache_hit) then
    ! Determine correct grid and grid region (original labels 1-3)
    if (x .gt. xs2) then
      igr = 2
      if (y .gt. ys3) igr = 3
    else
      igr = 1
    end if

    ! Update grid parameters if grid changed (original label 3)
    if (igr .ne. igrs) then
      igrs = igr
      dx = dxa(igrs)
      dy = dya(igrs)
      xs = xsa(igrs)
      ys = ysa(igrs)
      nxm2 = nxa(igrs) - 2
      nym2 = nya(igrs) - 2
      nxms = ((nxm2 + 1) / 3) * 3 + 1
      nyms = ((nym2 + 1) / 3) * 3 + 1
      nd = nda(igrs)
      ndp = ndpa(igrs)
      ix = int((x - xs) / dx) + 1
      iy = int((y - ys) / dy) + 1
    end if

    ! Compute IXS (original label 4)
    ixs = ((ix - 1) / 3) * 3 + 2
    if (ixs .lt. 2) ixs = 2
    ixeg = -10000

    ! Adjust IXS if needed (original label 5)
    if (ixs .gt. nxm2) then
      ixs = nxm2
      ixeg = nxms
    end if

    ! Compute IYS (original label 5 continued)
    iys = ((iy - 1) / 3) * 3 + 2
    if (iys .lt. 2) iys = 2
    iyeg = -10000

    ! Adjust IYS if needed (original label 6)
    if (iys .gt. nym2) then
      iys = nym2
      iyeg = nyms
    end if

    ! Compute coefficients of 4 cubic polynomials in X for the 4 grid
    ! values of Y for each of the 4 functions (original labels 6-11)
    iadz = ixs + (iys - 3) * nd - ndp

    do k = 1, 4
      iadz = iadz + ndp
      iadd = iadz

      do i = 1, 4
        iadd = iadd + nd

        ! Select grid and load values (original labels 7-10)
        if (igrs .eq. 1) then
          p1 = arl1(iadd - 1)
          p2 = arl1(iadd)
          p3 = arl1(iadd + 1)
          p4 = arl1(iadd + 2)
        else if (igrs .eq. 2) then
          p1 = arl2(iadd - 1)
          p2 = arl2(iadd)
          p3 = arl2(iadd + 1)
          p4 = arl2(iadd + 2)
        else
          p1 = arl3(iadd - 1)
          p2 = arl3(iadd)
          p3 = arl3(iadd + 1)
          p4 = arl3(iadd + 2)
        end if

        ! Compute coefficients (original label 10)
        a(i, k) = (p4 - p1 + 3.*(p2 - p3)) * 0.1666666667d+0
        b(i, k) = (p1 - 2.*p2 + p3) * 0.5d+0
        c(i, k) = p3 - (2.*p1 + 3.*p2 + p4) * 0.1666666667d+0
        d(i, k) = p2
      end do
    end do

    xz = (ixs - 1) * dx + xs
    yz = (iys - 1) * dy + ys
  end if

  ! Evaluate polynomials in X and then use cubic interpolation in Y
  ! for each of the 4 functions (original label 12)
  xx = (x - xz) / dx
  yy = (y - yz) / dy

  fx1 = ((a11*xx + b11)*xx + c11)*xx + d11
  fx2 = ((a21*xx + b21)*xx + c21)*xx + d21
  fx3 = ((a31*xx + b31)*xx + c31)*xx + d31
  fx4 = ((a41*xx + b41)*xx + c41)*xx + d41
  p1 = fx4 - fx1 + 3.*(fx2 - fx3)
  p2 = 3.*(fx1 - 2.*fx2 + fx3)
  p3 = 6.*fx3 - 2.*fx1 - 3.*fx2 - fx4
  f1 = ((p1*yy + p2)*yy + p3)*yy*0.1666666667d+0 + fx2

  fx1 = ((a12*xx + b12)*xx + c12)*xx + d12
  fx2 = ((a22*xx + b22)*xx + c22)*xx + d22
  fx3 = ((a32*xx + b32)*xx + c32)*xx + d32
  fx4 = ((a42*xx + b42)*xx + c42)*xx + d42
  p1 = fx4 - fx1 + 3.*(fx2 - fx3)
  p2 = 3.*(fx1 - 2.*fx2 + fx3)
  p3 = 6.*fx3 - 2.*fx1 - 3.*fx2 - fx4
  f2 = ((p1*yy + p2)*yy + p3)*yy*0.1666666667d+0 + fx2

  fx1 = ((a13*xx + b13)*xx + c13)*xx + d13
  fx2 = ((a23*xx + b23)*xx + c23)*xx + d23
  fx3 = ((a33*xx + b33)*xx + c33)*xx + d33
  fx4 = ((a43*xx + b43)*xx + c43)*xx + d43
  p1 = fx4 - fx1 + 3.*(fx2 - fx3)
  p2 = 3.*(fx1 - 2.*fx2 + fx3)
  p3 = 6.*fx3 - 2.*fx1 - 3.*fx2 - fx4
  f3 = ((p1*yy + p2)*yy + p3)*yy*0.1666666667d+0 + fx2

  fx1 = ((a14*xx + b14)*xx + c14)*xx + d14
  fx2 = ((a24*xx + b24)*xx + c24)*xx + d24
  fx3 = ((a34*xx + b34)*xx + c34)*xx + d34
  fx4 = ((a44*xx + b44)*xx + c44)*xx + d44
  p1 = fx4 - fx1 + 3.*(fx2 - fx3)
  p2 = 3.*(fx1 - 2.*fx2 + fx3)
  p3 = 6.*fx3 - 2.*fx1 - 3.*fx2 - fx4
  f4 = ((p1*yy + p2)*yy + p3)*yy*0.1666666667d+0 + fx2

end subroutine intrp

!==============================================================================
! SOM2D - Generate Sommerfeld Ground Field Interpolation Grids
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 1020-1158)
! Tier 2 Modernization: Free-form F90, eliminated all GOTOs
! Original: 11 GOTOs using labels 1,2,3,4,5,6,7,8,9
! Replaced with: IF/THEN/ELSE blocks and SELECT CASE structures
!==============================================================================
subroutine som2d(rmhz,repr,rsig)
!
!     PROGRAM TO GENERATE NEC INTERPOLATION GRIDS FOR FIELDS DUE TO
!     GROUND.  FIELD COMPONENTS ARE COMPUTED BY NUMERICAL EVALUATION
!     OF MODIFIED SOMMERFELD INTEGRALS.
!
!     SOMNEC2D IS A DOUBLE PRECISION VERSION OF SOMNEC FOR USE WITH
!     NEC2D.  AN ALTERNATE VERSION (SOMNEC2SD) IS ALSO PROVIDED IN WHICH
!     COMPUTATION IS IN SINGLE PRECISION BUT THE OUTPUT FILE IS WRITTEN
!     IN DOUBLE PRECISION FOR USE WITH NEC2D.  SOMNEC2SD RUNS ABOUT TWICE
!     AS FAST AS THE FULL DOUBLE PRECISION SOMNEC2D.  THE DIFFERENCE
!     BETWEEN NEC2D RESULTS USING A FOR021 FILE FROM THIS CODE RATHER
!     THAN FROM SOMNEC2SD WAS INSIGNFICANT IN THE CASES TESTED.
!
!     Changes made by J Bergervoet, 31-5-95:
!         Parameter 0. --> 0.D0 in calling of routine TEST
!         Status of output files set to 'UNKNOWN'
!
  implicit real*8(a-h,o-z)
!
  complex*16 ck1,ck1sq,erv,ezv,erh,eph,cksm,ct1,ct2,ct3,cl1,cl2,con, &
             ar1,ar2,ar3,epscf
  common /evlcom/ cksm,ct1,ct2,ct3,ck1,ck1sq,ck2,ck2sq,tkmag,tsmag, &
                  ck1r,zph,rho,jh
  common /ggrid/ ar1(11,10,4),ar2(17,5,4),ar3(9,8,4),epscf,dxa(3),dya(3), &
                 xsa(3),ysa(3),nxa(3),nya(3)
  character*3  lcomp(4)
  data lcomp/'ERV','EZV','ERH','EPH'/
!
!     READ GROUND PARAMETERS - EPR = RELATIVE DIELECTRIC CONSTANT
!                              SIG = CONDUCTIVITY (MHOS/M)
!                              FMHZ = FREQUENCY (MHZ)
!                              IPT = 1 TO PRINT GRIDS.  =0 OTHERWISE.
  epr=repr
  sig=rsig
  fmhz=rmhz
  ipt=0
!
! GOTO elimination: Labels 1, 2 replaced with IF/THEN/ELSE block
  if (sig.lt.0.d0) then
    epscf=dcmplx(epr,sig)
  else
    wlam=299.8d0/fmhz
    epscf=dcmplx(epr,-sig*wlam*59.96d0)
  end if
!
  ck2=6.283185308d0
  ck2sq=ck2*ck2
!
!     SOMMERFELD INTEGRAL EVALUATION USES EXP(-JWT), NEC USES EXP(+JWT),
!     HENCE NEED CONJG(EPSCF).  CONJUGATE OF FIELDS OCCURS IN SUBROUTINE
!     EVLUA.
!
  ck1sq=ck2sq*dconjg(epscf)
  ck1=sqrt(ck1sq)
  ck1r=dreal(ck1)
  tkmag=100.d0*abs(ck1)
  tsmag=100.d0*ck1*dconjg(ck1)
  cksm=ck2sq/(ck1sq+ck2sq)
  ct1=0.5d0*(ck1sq-ck2sq)
  erv=ck1sq*ck1sq
  ezv=ck2sq*ck2sq
  ct2=0.125d0*(erv-ezv)
  erv=erv*ck1sq
  ezv=ezv*ck2sq
  ct3=0.0625d0*(erv-ezv)
!
!     LOOP OVER 3 GRID REGIONS
!
  do k=1,3
    nr=nxa(k)
    nth=nya(k)
    dr=dxa(k)
    dth=dya(k)
    r=xsa(k)-dr
    irs=1
    if (k.eq.1) r=xsa(k)
    if (k.eq.1) irs=2
!
!     LOOP OVER R.  (R=SQRT(RHO**2 + (Z+H)**2))
!
    do ir=irs,nr
      r=r+dr
      thet=ysa(k)-dth
!
!     LOOP OVER THETA.  (THETA=ATAN((Z+H)/RHO))
!
      do ith=1,nth
        thet=thet+dth
        rho=r*cos(thet)
        zph=r*sin(thet)
        if (rho.lt.1.d-7) rho=1.d-8
        if (zph.lt.1.d-7) zph=0.d0
        call evlua (erv,ezv,erh,eph)
        rk=ck2*r
        con=-(0.d0,4.77147d0)*r/dcmplx(cos(rk),-sin(rk))
!
! GOTO elimination: Computed GOTO (labels 3,4,5,6) replaced with SELECT CASE
        select case (k)
          case (1)
            ar1(ir,ith,1)=erv*con
            ar1(ir,ith,2)=ezv*con
            ar1(ir,ith,3)=erh*con
            ar1(ir,ith,4)=eph*con
          case (2)
            ar2(ir,ith,1)=erv*con
            ar2(ir,ith,2)=ezv*con
            ar2(ir,ith,3)=erh*con
            ar2(ir,ith,4)=eph*con
          case (3)
            ar3(ir,ith,1)=erv*con
            ar3(ir,ith,2)=ezv*con
            ar3(ir,ith,3)=erh*con
            ar3(ir,ith,4)=eph*con
        end select
      end do
    end do
  end do
!
!     FILL GRID 1 FOR R EQUAL TO ZERO.
!
  cl2=-(0.d0,188.370d0)*(epscf-1.d0)/(epscf+1.d0)
  cl1=cl2/(epscf+1.d0)
  ezv=epscf*cl1
  thet=-dth
  nth=nya(1)
!
! GOTO elimination: Labels 7,8,9 replaced with IF/THEN/ELSE within DO loop
  do ith=1,nth
    thet=thet+dth
    if (ith.eq.nth) then
      erv=0.d0
      erh=cl2-0.5d0*cl1
      eph=-erh
    else
      tfac2=cos(thet)
      tfac1=(1.d0-sin(thet))/tfac2
      tfac2=tfac1/tfac2
      erv=epscf*cl1*tfac1
      erh=cl1*(tfac2-1.d0)+cl2
      eph=cl1*tfac2-cl2
    end if
    ar1(1,ith,1)=erv
    ar1(1,ith,2)=ezv
    ar1(1,ith,3)=erh
    ar1(1,ith,4)=eph
  end do
!
!     WRITE GRID ON TAPE21
!
! OPEN(UNIT=21,FILE='SOM2D.NEC',STATUS='UNKNOWN',FORM='UNFORMATTED')
! WRITE (21) AR1,AR2,AR3,EPSCF,DXA,DYA,XSA,YSA,NXA,NYA
! REWIND 21
! IF (IPT.EQ.0) RETURN
  if (ipt.eq.0) return
!
!     PRINT GRID
!
  open (unit=9,file='SOM2D.OUT',status='UNKNOWN',err=14)
  write(*,17) epscf
  do k=1,3
    nr=nxa(k)
    nth=nya(k)
    write(9,18) k,xsa(k),dxa(k),nr,ysa(k),dya(k),nth
    do l=1,4
      write(9,19) lcomp(l)
      do ir=1,nr
! GOTO elimination: Computed GOTO (labels 10,11,12,13) replaced with SELECT CASE
        select case (k)
          case (1)
            write(9,20) ir,(ar1(ir,ith,l),ith=1,nth)
          case (2)
            write(9,20) ir,(ar2(ir,ith,l),ith=1,nth)
          case (3)
            write(9,20) ir,(ar3(ir,ith,l),ith=1,nth)
        end select
      end do
    end do
  end do
! Label 14: RETURN
14 return
!
16 format (6h time=,1pe12.5)
17 format (30h1nec ground interpolation grid,/,21h dielectric constant=, &
           1p2e12.5)
18 format (///,5h grid,i2,/,4x,5hr(1)=,f7.4,4x,3hdr=,f7.4,4x,3hnr=,i3, &
           /,9h thet(1)=,f7.4,3x,4hdth=,f7.4,3x,4hnth=,i3,//)
19 format (///,1x,a3)
20 format (4h ir=,i3,/,1x,(1p10e12.5))
21 format(' ENTER EPR,SIG,FMHZ,IPT > ',$)
22 format(' STARTING COMPUTATION OF SOMMERFELD INTEGRAL TABLES')
end subroutine som2d
