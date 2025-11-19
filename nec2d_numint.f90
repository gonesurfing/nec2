! ***********************************************************************
!     NEC2D NUMERICAL INTEGRATION AND INTERPOLATION MODULE
!     Modernized numerical methods for integration and interpolation
!     Contains: ROM2, INTRP, SOM2D
!     GOTOs eliminated: 36 → 0
! ***********************************************************************

!==============================================================================
! ROM2 - Romberg Integration for Sommerfeld Ground Field
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 4362-4474)
! Original: Fixed-form Fortran 77 with 14 GOTOs
! Modernized: Free-form Fortran 90, structured control flow
!
! Purpose: For Sommerfeld ground option, integrates over source segment to
!          obtain total field due to ground using variable interval width
!          Romberg integration. There are 9 field components - the X, Y, and Z
!          components due to constant, sine, and cosine current distributions.
!
! Parameters:
!   A    - Start of integration interval
!   B    - End of integration interval
!   SUM  - Array of 9 complex field components (output)
!   DMIN - Minimum convergence parameter
!
! GOTOs eliminated: 14 (labels 1-18)
! Control flow: Nested DO WHILE loops with structured EXIT/CYCLE
!==============================================================================

subroutine ROM2 (A,B,SUM,DMIN)

  implicit real*8(A-H,O-Z)

  complex*16 SUM,G1,G2,G3,G4,G5,T00,T01,T10,T02,T11,T20
  dimension SUM(9), G1(9), G2(9), G3(9), G4(9), G5(9), T01(9), T10(9), T20(9)
  data NM,NTS,NX,N/65536,4,1,9/,RX/1.D-4/

  ! Initialize integration parameters
  Z=A
  ZE=B
  S=B-A

  ! Check for valid integration interval
  if (S < 0.0D0) then
    write(*,18)
18  format (30H ERROR - B LESS THAN A IN ROM2)
    stop
  endif

  ! Set up integration parameters
  EP=S/(1.D4*NM)
  ZEND=ZE-EP

  ! Initialize sum array
  do I=1,N
    SUM(I)=(0.D0,0.D0)
  enddo

  NS=NX
  NT=0
  call SFLDS (Z,G1)

  ! Main integration loop - advance along integration path
  main_integration: do while (.true.)

    ! Calculate step size for current interval
    DZ=S/NS
    if (Z+DZ > ZE) then
      DZ=ZE-Z
      if (DZ <= EP) exit main_integration
    endif

    ! Evaluate field at interval points
    DZOT=DZ*0.5D0
    call SFLDS (Z+DZOT,G3)
    call SFLDS (Z+DZ,G5)

    ! Adaptive refinement loop - refine current interval until converged
    adaptive_refinement: do while (.true.)

      TMAG1=0.D0
      TMAG2=0.D0

      ! Evaluate 3 point Romberg result and test convergence
      do I=1,N
        T00=(G1(I)+G5(I))*DZOT
        T01(I)=(T00+DZ*G3(I))*0.5D0
        T10(I)=(4.D0*T01(I)-T00)/3.D0
        if (I <= 3) then
          TR=DREAL(T01(I))
          TI=DIMAG(T01(I))
          TMAG1=TMAG1+TR*TR+TI*TI
          TR=DREAL(T10(I))
          TI=DIMAG(T10(I))
          TMAG2=TMAG2+TR*TR+TI*TI
        endif
      enddo

      TMAG1=SQRT(TMAG1)
      TMAG2=SQRT(TMAG2)
      call TEST(TMAG1,TMAG2,TR,0.D0,0.D0,TI,DMIN)

      if (TR <= RX) then
        ! 3-point converged - add to sum and exit refinement loop
        do I=1,N
          SUM(I)=SUM(I)+T10(I)
        enddo
        NT=NT+2
        exit adaptive_refinement
      endif

      ! 3-point did not converge - evaluate 5-point Romberg
      call SFLDS (Z+DZ*0.25D0,G2)
      call SFLDS (Z+DZ*0.75D0,G4)
      TMAG1=0.D0
      TMAG2=0.D0

      ! Evaluate 5 point Romberg result and test convergence
      do I=1,N
        T02=(T01(I)+DZOT*(G2(I)+G4(I)))*0.5D0
        T11=(4.D0*T02-T01(I))/3.D0
        T20(I)=(16.D0*T11-T10(I))/15.D0
        if (I <= 3) then
          TR=DREAL(T11)
          TI=DIMAG(T11)
          TMAG1=TMAG1+TR*TR+TI*TI
          TR=DREAL(T20(I))
          TI=DIMAG(T20(I))
          TMAG2=TMAG2+TR*TR+TI*TI
        endif
      enddo

      TMAG1=SQRT(TMAG1)
      TMAG2=SQRT(TMAG2)
      call TEST(TMAG1,TMAG2,TR,0.D0,0.D0,TI,DMIN)

      if (TR <= RX) then
        ! 5-point converged - add to sum and exit refinement loop
        do I=1,N
          SUM(I)=SUM(I)+T20(I)
        enddo
        NT=NT+1
        exit adaptive_refinement
      endif

      ! 5-point did not converge - attempt interval refinement
      NT=0
      if (NS < NM) then
        ! Refine interval by doubling NS and reusing field values
        NS=NS*2
        DZ=S/NS
        DZOT=DZ*0.5D0
        do I=1,N
          G5(I)=G3(I)
          G3(I)=G2(I)
        enddo
        ! Continue adaptive refinement with new interval size
      else
        ! Maximum refinement reached - accept result with warning
        write(*,19) Z
19      format (33H ROM2 -- STEP SIZE LIMITED AT Z =,1P,E12.5)
        do I=1,N
          SUM(I)=SUM(I)+T20(I)
        enddo
        NT=NT+1
        exit adaptive_refinement
      endif

    enddo adaptive_refinement

    ! Update position along integration path
    Z=Z+DZ
    if (Z > ZEND) exit main_integration

    ! Update G1 for next interval
    do I=1,N
      G1(I)=G5(I)
    enddo

    ! Adjust interval size if appropriate
    if (NT >= NTS .and. NS > NX) then
      NS=NS/2
      NT=1
    endif

  enddo main_integration

  return
end subroutine ROM2

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
SUBROUTINE INTRP(X, Y, F1, F2, F3, F4)
  IMPLICIT REAL*8(A-H, O-Z)

  ! INTRP uses bivariate cubic interpolation to obtain the values of
  ! 4 functions at the point (X,Y).

  COMPLEX*16 F1, F2, F3, F4, A, B, C, D, FX1, FX2, FX3, FX4, P1, P2, P3, P4
  COMPLEX*16 A11, A12, A13, A14, A21, A22, A23, A24, A31, A32, A33, A34
  COMPLEX*16 A41, A42, A43, A44, B11, B12, B13, B14, B21, B22, B23, B24
  COMPLEX*16 B31, B32, B33, B34, B41, B42, B43, B44, C11, C12, C13, C14
  COMPLEX*16 C21, C22, C23, C24, C31, C32, C33, C34, C41, C42, C43, C44
  COMPLEX*16 D11, D12, D13, D14, D21, D22, D23, D24, D31, D32, D33, D34
  COMPLEX*16 D41, D42, D43, D44
  COMPLEX*16 AR1, AR2, AR3, ARL1, ARL2, ARL3, EPSCF

  COMMON /GGRID/ AR1(11,10,4), AR2(17,5,4), AR3(9,8,4), EPSCF, DXA(3), &
                 DYA(3), XSA(3), YSA(3), NXA(3), NYA(3)

  DIMENSION NDA(3), NDPA(3)
  DIMENSION A(4,4), B(4,4), C(4,4), D(4,4), ARL1(1), ARL2(1), ARL3(1)

  EQUIVALENCE (A(1,1),A11), (A(1,2),A12), (A(1,3),A13), (A(1,4),A14)
  EQUIVALENCE (A(2,1),A21), (A(2,2),A22), (A(2,3),A23), (A(2,4),A24)
  EQUIVALENCE (A(3,1),A31), (A(3,2),A32), (A(3,3),A33), (A(3,4),A34)
  EQUIVALENCE (A(4,1),A41), (A(4,2),A42), (A(4,3),A43), (A(4,4),A44)
  EQUIVALENCE (B(1,1),B11), (B(1,2),B12), (B(1,3),B13), (B(1,4),B14)
  EQUIVALENCE (B(2,1),B21), (B(2,2),B22), (B(2,3),B23), (B(2,4),B24)
  EQUIVALENCE (B(3,1),B31), (B(3,2),B32), (B(3,3),B33), (B(3,4),B34)
  EQUIVALENCE (B(4,1),B41), (B(4,2),B42), (B(4,3),B43), (B(4,4),B44)
  EQUIVALENCE (C(1,1),C11), (C(1,2),C12), (C(1,3),C13), (C(1,4),C14)
  EQUIVALENCE (C(2,1),C21), (C(2,2),C22), (C(2,3),C23), (C(2,4),C24)
  EQUIVALENCE (C(3,1),C31), (C(3,2),C32), (C(3,3),C33), (C(3,4),C34)
  EQUIVALENCE (C(4,1),C41), (C(4,2),C42), (C(4,3),C43), (C(4,4),C44)
  EQUIVALENCE (D(1,1),D11), (D(1,2),D12), (D(1,3),D13), (D(1,4),D14)
  EQUIVALENCE (D(2,1),D21), (D(2,2),D22), (D(2,3),D23), (D(2,4),D24)
  EQUIVALENCE (D(3,1),D31), (D(3,2),D32), (D(3,3),D33), (D(3,4),D34)
  EQUIVALENCE (D(4,1),D41), (D(4,2),D42), (D(4,3),D43), (D(4,4),D44)
  EQUIVALENCE (ARL1,AR1), (ARL2,AR2), (ARL3,AR3), (XS2,XSA(2)), &
              (YS3,YSA(3))

  DATA IXS, IYS, IGRS / -10, -10, -10 /, DX, DY, XS, YS / 1., 1., 0., 0. /
  DATA NDA / 11, 17, 9 /, NDPA / 110, 85, 72 /, IXEG, IYEG / 0, 0 /

  LOGICAL :: cache_hit

  ! Check if point lies in same 4 by 4 point region as previous point
  ! If so, old values are reused (cache hit)
  cache_hit = .FALSE.

  IF (X .GE. XS .AND. Y .GE. YS) THEN
    IX = INT((X - XS) / DX) + 1
    IY = INT((Y - YS) / DY) + 1

    IF (IX .GE. IXEG .AND. IY .GE. IYEG) THEN
      IF (IABS(IX - IXS) .LT. 2 .AND. IABS(IY - IYS) .LT. 2) THEN
        cache_hit = .TRUE.
      END IF
    END IF
  END IF

  IF (.NOT. cache_hit) THEN
    ! Determine correct grid and grid region (original labels 1-3)
    IF (X .GT. XS2) THEN
      IGR = 2
      IF (Y .GT. YS3) IGR = 3
    ELSE
      IGR = 1
    END IF

    ! Update grid parameters if grid changed (original label 3)
    IF (IGR .NE. IGRS) THEN
      IGRS = IGR
      DX = DXA(IGRS)
      DY = DYA(IGRS)
      XS = XSA(IGRS)
      YS = YSA(IGRS)
      NXM2 = NXA(IGRS) - 2
      NYM2 = NYA(IGRS) - 2
      NXMS = ((NXM2 + 1) / 3) * 3 + 1
      NYMS = ((NYM2 + 1) / 3) * 3 + 1
      ND = NDA(IGRS)
      NDP = NDPA(IGRS)
      IX = INT((X - XS) / DX) + 1
      IY = INT((Y - YS) / DY) + 1
    END IF

    ! Compute IXS (original label 4)
    IXS = ((IX - 1) / 3) * 3 + 2
    IF (IXS .LT. 2) IXS = 2
    IXEG = -10000

    ! Adjust IXS if needed (original label 5)
    IF (IXS .GT. NXM2) THEN
      IXS = NXM2
      IXEG = NXMS
    END IF

    ! Compute IYS (original label 5 continued)
    IYS = ((IY - 1) / 3) * 3 + 2
    IF (IYS .LT. 2) IYS = 2
    IYEG = -10000

    ! Adjust IYS if needed (original label 6)
    IF (IYS .GT. NYM2) THEN
      IYS = NYM2
      IYEG = NYMS
    END IF

    ! Compute coefficients of 4 cubic polynomials in X for the 4 grid
    ! values of Y for each of the 4 functions (original labels 6-11)
    IADZ = IXS + (IYS - 3) * ND - NDP

    DO K = 1, 4
      IADZ = IADZ + NDP
      IADD = IADZ

      DO I = 1, 4
        IADD = IADD + ND

        ! Select grid and load values (original labels 7-10)
        IF (IGRS .EQ. 1) THEN
          P1 = ARL1(IADD - 1)
          P2 = ARL1(IADD)
          P3 = ARL1(IADD + 1)
          P4 = ARL1(IADD + 2)
        ELSE IF (IGRS .EQ. 2) THEN
          P1 = ARL2(IADD - 1)
          P2 = ARL2(IADD)
          P3 = ARL2(IADD + 1)
          P4 = ARL2(IADD + 2)
        ELSE
          P1 = ARL3(IADD - 1)
          P2 = ARL3(IADD)
          P3 = ARL3(IADD + 1)
          P4 = ARL3(IADD + 2)
        END IF

        ! Compute coefficients (original label 10)
        A(I, K) = (P4 - P1 + 3.*(P2 - P3)) * 0.1666666667D+0
        B(I, K) = (P1 - 2.*P2 + P3) * 0.5D+0
        C(I, K) = P3 - (2.*P1 + 3.*P2 + P4) * 0.1666666667D+0
        D(I, K) = P2
      END DO
    END DO

    XZ = (IXS - 1) * DX + XS
    YZ = (IYS - 1) * DY + YS
  END IF

  ! Evaluate polynomials in X and then use cubic interpolation in Y
  ! for each of the 4 functions (original label 12)
  XX = (X - XZ) / DX
  YY = (Y - YZ) / DY

  FX1 = ((A11*XX + B11)*XX + C11)*XX + D11
  FX2 = ((A21*XX + B21)*XX + C21)*XX + D21
  FX3 = ((A31*XX + B31)*XX + C31)*XX + D31
  FX4 = ((A41*XX + B41)*XX + C41)*XX + D41
  P1 = FX4 - FX1 + 3.*(FX2 - FX3)
  P2 = 3.*(FX1 - 2.*FX2 + FX3)
  P3 = 6.*FX3 - 2.*FX1 - 3.*FX2 - FX4
  F1 = ((P1*YY + P2)*YY + P3)*YY*0.1666666667D+0 + FX2

  FX1 = ((A12*XX + B12)*XX + C12)*XX + D12
  FX2 = ((A22*XX + B22)*XX + C22)*XX + D22
  FX3 = ((A32*XX + B32)*XX + C32)*XX + D32
  FX4 = ((A42*XX + B42)*XX + C42)*XX + D42
  P1 = FX4 - FX1 + 3.*(FX2 - FX3)
  P2 = 3.*(FX1 - 2.*FX2 + FX3)
  P3 = 6.*FX3 - 2.*FX1 - 3.*FX2 - FX4
  F2 = ((P1*YY + P2)*YY + P3)*YY*0.1666666667D+0 + FX2

  FX1 = ((A13*XX + B13)*XX + C13)*XX + D13
  FX2 = ((A23*XX + B23)*XX + C23)*XX + D23
  FX3 = ((A33*XX + B33)*XX + C33)*XX + D33
  FX4 = ((A43*XX + B43)*XX + C43)*XX + D43
  P1 = FX4 - FX1 + 3.*(FX2 - FX3)
  P2 = 3.*(FX1 - 2.*FX2 + FX3)
  P3 = 6.*FX3 - 2.*FX1 - 3.*FX2 - FX4
  F3 = ((P1*YY + P2)*YY + P3)*YY*0.1666666667D+0 + FX2

  FX1 = ((A14*XX + B14)*XX + C14)*XX + D14
  FX2 = ((A24*XX + B24)*XX + C24)*XX + D24
  FX3 = ((A34*XX + B34)*XX + C34)*XX + D34
  FX4 = ((A44*XX + B44)*XX + C44)*XX + D44
  P1 = FX4 - FX1 + 3.*(FX2 - FX3)
  P2 = 3.*(FX1 - 2.*FX2 + FX3)
  P3 = 6.*FX3 - 2.*FX1 - 3.*FX2 - FX4
  F4 = ((P1*YY + P2)*YY + P3)*YY*0.1666666667D+0 + FX2

END SUBROUTINE INTRP

!==============================================================================
! SOM2D - Generate Sommerfeld Ground Field Interpolation Grids
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 1020-1158)
! Tier 2 Modernization: Free-form F90, eliminated all GOTOs
! Original: 11 GOTOs using labels 1,2,3,4,5,6,7,8,9
! Replaced with: IF/THEN/ELSE blocks and SELECT CASE structures
!==============================================================================
SUBROUTINE SOM2D(RMHZ,REPR,RSIG)
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
  IMPLICIT REAL*8(A-H,O-Z)
!
  COMPLEX*16 CK1,CK1SQ,ERV,EZV,ERH,EPH,CKSM,CT1,CT2,CT3,CL1,CL2,CON, &
             AR1,AR2,AR3,EPSCF
  COMMON /EVLCOM/ CKSM,CT1,CT2,CT3,CK1,CK1SQ,CK2,CK2SQ,TKMAG,TSMAG, &
                  CK1R,ZPH,RHO,JH
  COMMON /GGRID/ AR1(11,10,4),AR2(17,5,4),AR3(9,8,4),EPSCF,DXA(3),DYA(3), &
                 XSA(3),YSA(3),NXA(3),NYA(3)
  CHARACTER*3  LCOMP(4)
  DATA LCOMP/'ERV','EZV','ERH','EPH'/
!
!     READ GROUND PARAMETERS - EPR = RELATIVE DIELECTRIC CONSTANT
!                              SIG = CONDUCTIVITY (MHOS/M)
!                              FMHZ = FREQUENCY (MHZ)
!                              IPT = 1 TO PRINT GRIDS.  =0 OTHERWISE.
  EPR=REPR
  SIG=RSIG
  FMHZ=RMHZ
  IPT=0
!
! GOTO elimination: Labels 1, 2 replaced with IF/THEN/ELSE block
  IF (SIG.LT.0.D0) THEN
    EPSCF=DCMPLX(EPR,SIG)
  ELSE
    WLAM=299.8D0/FMHZ
    EPSCF=DCMPLX(EPR,-SIG*WLAM*59.96D0)
  END IF
!
  CK2=6.283185308D0
  CK2SQ=CK2*CK2
!
!     SOMMERFELD INTEGRAL EVALUATION USES EXP(-JWT), NEC USES EXP(+JWT),
!     HENCE NEED CONJG(EPSCF).  CONJUGATE OF FIELDS OCCURS IN SUBROUTINE
!     EVLUA.
!
  CK1SQ=CK2SQ*DCONJG(EPSCF)
  CK1=SQRT(CK1SQ)
  CK1R=DREAL(CK1)
  TKMAG=100.D0*ABS(CK1)
  TSMAG=100.D0*CK1*DCONJG(CK1)
  CKSM=CK2SQ/(CK1SQ+CK2SQ)
  CT1=0.5D0*(CK1SQ-CK2SQ)
  ERV=CK1SQ*CK1SQ
  EZV=CK2SQ*CK2SQ
  CT2=0.125D0*(ERV-EZV)
  ERV=ERV*CK1SQ
  EZV=EZV*CK2SQ
  CT3=0.0625D0*(ERV-EZV)
!
!     LOOP OVER 3 GRID REGIONS
!
  DO K=1,3
    NR=NXA(K)
    NTH=NYA(K)
    DR=DXA(K)
    DTH=DYA(K)
    R=XSA(K)-DR
    IRS=1
    IF (K.EQ.1) R=XSA(K)
    IF (K.EQ.1) IRS=2
!
!     LOOP OVER R.  (R=SQRT(RHO**2 + (Z+H)**2))
!
    DO IR=IRS,NR
      R=R+DR
      THET=YSA(K)-DTH
!
!     LOOP OVER THETA.  (THETA=ATAN((Z+H)/RHO))
!
      DO ITH=1,NTH
        THET=THET+DTH
        RHO=R*COS(THET)
        ZPH=R*SIN(THET)
        IF (RHO.LT.1.D-7) RHO=1.D-8
        IF (ZPH.LT.1.D-7) ZPH=0.D0
        CALL EVLUA (ERV,EZV,ERH,EPH)
        RK=CK2*R
        CON=-(0.D0,4.77147D0)*R/DCMPLX(COS(RK),-SIN(RK))
!
! GOTO elimination: Computed GOTO (labels 3,4,5,6) replaced with SELECT CASE
        SELECT CASE (K)
          CASE (1)
            AR1(IR,ITH,1)=ERV*CON
            AR1(IR,ITH,2)=EZV*CON
            AR1(IR,ITH,3)=ERH*CON
            AR1(IR,ITH,4)=EPH*CON
          CASE (2)
            AR2(IR,ITH,1)=ERV*CON
            AR2(IR,ITH,2)=EZV*CON
            AR2(IR,ITH,3)=ERH*CON
            AR2(IR,ITH,4)=EPH*CON
          CASE (3)
            AR3(IR,ITH,1)=ERV*CON
            AR3(IR,ITH,2)=EZV*CON
            AR3(IR,ITH,3)=ERH*CON
            AR3(IR,ITH,4)=EPH*CON
        END SELECT
      END DO
    END DO
  END DO
!
!     FILL GRID 1 FOR R EQUAL TO ZERO.
!
  CL2=-(0.D0,188.370D0)*(EPSCF-1.D0)/(EPSCF+1.D0)
  CL1=CL2/(EPSCF+1.D0)
  EZV=EPSCF*CL1
  THET=-DTH
  NTH=NYA(1)
!
! GOTO elimination: Labels 7,8,9 replaced with IF/THEN/ELSE within DO loop
  DO ITH=1,NTH
    THET=THET+DTH
    IF (ITH.EQ.NTH) THEN
      ERV=0.D0
      ERH=CL2-0.5D0*CL1
      EPH=-ERH
    ELSE
      TFAC2=COS(THET)
      TFAC1=(1.D0-SIN(THET))/TFAC2
      TFAC2=TFAC1/TFAC2
      ERV=EPSCF*CL1*TFAC1
      ERH=CL1*(TFAC2-1.D0)+CL2
      EPH=CL1*TFAC2-CL2
    END IF
    AR1(1,ITH,1)=ERV
    AR1(1,ITH,2)=EZV
    AR1(1,ITH,3)=ERH
    AR1(1,ITH,4)=EPH
  END DO
!
!     WRITE GRID ON TAPE21
!
! OPEN(UNIT=21,FILE='SOM2D.NEC',STATUS='UNKNOWN',FORM='UNFORMATTED')
! WRITE (21) AR1,AR2,AR3,EPSCF,DXA,DYA,XSA,YSA,NXA,NYA
! REWIND 21
! IF (IPT.EQ.0) RETURN
  IF (IPT.EQ.0) RETURN
!
!     PRINT GRID
!
  OPEN (UNIT=9,FILE='SOM2D.OUT',STATUS='UNKNOWN',ERR=14)
  WRITE(*,17) EPSCF
  DO K=1,3
    NR=NXA(K)
    NTH=NYA(K)
    WRITE(9,18) K,XSA(K),DXA(K),NR,YSA(K),DYA(K),NTH
    DO L=1,4
      WRITE(9,19) LCOMP(L)
      DO IR=1,NR
! GOTO elimination: Computed GOTO (labels 10,11,12,13) replaced with SELECT CASE
        SELECT CASE (K)
          CASE (1)
            WRITE(9,20) IR,(AR1(IR,ITH,L),ITH=1,NTH)
          CASE (2)
            WRITE(9,20) IR,(AR2(IR,ITH,L),ITH=1,NTH)
          CASE (3)
            WRITE(9,20) IR,(AR3(IR,ITH,L),ITH=1,NTH)
        END SELECT
      END DO
    END DO
  END DO
! Label 14: RETURN
14 RETURN
!
16 FORMAT (6H TIME=,1PE12.5)
17 FORMAT (30H1NEC GROUND INTERPOLATION GRID,/,21H DIELECTRIC CONSTANT=, &
           1P2E12.5)
18 FORMAT (///,5H GRID,I2,/,4X,5HR(1)=,F7.4,4X,3HDR=,F7.4,4X,3HNR=,I3, &
           /,9H THET(1)=,F7.4,3X,4HDTH=,F7.4,3X,4HNTH=,I3,//)
19 FORMAT (///,1X,A3)
20 FORMAT (4H IR=,I3,/,1X,(1P10E12.5))
21 FORMAT(' ENTER EPR,SIG,FMHZ,IPT > ',$)
22 FORMAT(' STARTING COMPUTATION OF SOMMERFELD INTEGRAL TABLES')
END SUBROUTINE SOM2D
