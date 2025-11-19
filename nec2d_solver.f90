!==============================================================================
! NEC2D Solver Module - Modernized Matrix Solution Routines
!==============================================================================
! Created: 2025-11-19
! Purpose: Matrix partitioning, factorization, and solution routines
!
! Modernization Level: Tier 2
!   - Free-form Fortran 90
!   - All GOTOs eliminated (35 total)
!   - Retains IMPLICIT REAL*8, COMMON blocks, EQUIVALENCE
!
! Subroutines:
!   1. FBLOCK  - Set parameters for out-of-core matrix solution (14 GOTOs)
!   2. SOLGF   - Solve for current in NGF procedure (10 GOTOs)
!   3. SOLVES  - Solve with symmetry transformations (11 GOTOs)
!==============================================================================

SUBROUTINE FBLOCK (NROW,NCOL,IMAX,IRNGF,IPSYM)
! ============================================================================
! Modernized from: nec2dxs_integrated.f, lines 1763-1869
! GOTOs eliminated: 14 (converted to structured IF/THEN/ELSE control flow)
! Changes:
!   - Converted to free-form Fortran 90
!   - Eliminated all GOTO statements using structured control flow
!   - Improved logical flow with nested IF/ELSE blocks
!   - Error GOTOs (12,13) converted to inline error handling
!   - Conditional jumps converted to IF/THEN/ELSE structures
! ============================================================================
! FBLOCK SETS PARAMETERS FOR OUT-OF-CORE SOLUTION FOR THE PRIMARY MATRIX (A)
!
  IMPLICIT REAL*8(A-H,O-Z)
  INCLUDE 'NEC2D3000.INC'

  COMPLEX*16 SSX,DETER
  COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,ICASX, &
                  NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  COMMON /SMAT/ SSX(16,16)

  LOGICAL :: NEED_SYMMETRY_SETUP

  IMX1=IMAX-IRNGF
  NEED_SYMMETRY_SETUP = .FALSE.

  ! Original GOTO 2 (line 1776) eliminated: restructured as IF/ELSE block
  IF (NROW*NCOL <= IMX1) THEN
    ! Matrix fits in core - simple case
    NBLOKS=1
    NPBLK=NROW
    NLAST=NROW
    IMAT=NROW*NCOL
    ! Original GOTO 1 (line 1781) eliminated: restructured as IF/ELSE
    IF (NROW == NCOL) THEN
      ICASE=1
      RETURN  ! Early return for symmetric in-core case
    ELSE
      ! Label 1: Non-symmetric in-core case
      ICASE=2
      ! Original GOTO 5 (line 1785) eliminated: set flag to continue to symmetry setup
      NEED_SYMMETRY_SETUP = .TRUE.
    END IF
  ELSE
    ! Label 2: Matrix doesn't fit in core - out-of-core solution needed
    ! Original GOTO 3 (line 1786) eliminated: restructured as IF/ELSE
    IF (NROW == NCOL) THEN
      ! Symmetric matrix out-of-core partitioning
      ICASE=3
      NPBLK=IMAX/(2*NCOL)
      NPSYM=IMX1/NCOL
      IF (NPSYM < NPBLK) NPBLK=NPSYM
      ! Original GOTO 12 (line 1791) eliminated: structured error check
      IF (NPBLK < 1) THEN
        ! Label 12: Error - insufficient storage
        WRITE(*,17) NROW,NCOL
        STOP
      END IF
      NBLOKS=(NROW-1)/NPBLK
      NLAST=NROW-NBLOKS*NPBLK
      NBLOKS=NBLOKS+1
      NBLSYM=NBLOKS
      NPSYM=NPBLK
      NLSYM=NLAST
      IMAT=NPBLK*NCOL
      WRITE(*,14) NBLOKS,NPBLK,NLAST
      ! Original GOTO 11 (line 1800) eliminated: direct RETURN
      RETURN  ! Early return for symmetric out-of-core case
    ELSE
      ! Label 3: Non-symmetric matrix out-of-core partitioning
      NPBLK=IMAX/NCOL
      ! Original GOTO 12 (line 1802) eliminated: structured error check
      IF (NPBLK < 1) THEN
        ! Label 12: Error - insufficient storage
        WRITE(*,17) NROW,NCOL
        STOP
      END IF
      IF (NPBLK > NROW) NPBLK=NROW
      NBLOKS=(NROW-1)/NPBLK
      NLAST=NROW-NBLOKS*NPBLK
      NBLOKS=NBLOKS+1
      WRITE(*,14) NBLOKS,NPBLK,NLAST
      ! Original GOTO 4 (line 1808) eliminated: restructured as IF/ELSE
      IF (NROW*NROW <= IMX1) THEN
        ! Label 4: Submatrices fit in core
        ICASE=4
        NBLSYM=1
        NPSYM=NROW
        NLSYM=NROW
        IMAT=NROW*NROW
        WRITE(*,15)
        ! Original GOTO 5 (line 1815) eliminated: set flag to continue to symmetry setup
        NEED_SYMMETRY_SETUP = .TRUE.
      ELSE
        ! Submatrix partitioning needed
        ICASE=5
        NPSYM=IMAX/(2*NROW)
        NBLSYM=IMX1/NROW
        IF (NBLSYM < NPSYM) NPSYM=NBLSYM
        ! Original GOTO 12 (line 1820) eliminated: structured error check
        IF (NPSYM < 1) THEN
          ! Label 12: Error - insufficient storage
          WRITE(*,17) NROW,NCOL
          STOP
        END IF
        NBLSYM=(NROW-1)/NPSYM
        NLSYM=NROW-NBLSYM*NPSYM
        NBLSYM=NBLSYM+1
        WRITE(*,16) NBLSYM,NPSYM,NLSYM
        IMAT=NPSYM*NROW
        ! Fall through to symmetry setup (ICASE=5 always needs it)
        NEED_SYMMETRY_SETUP = .TRUE.
      END IF
    END IF
  END IF

  ! Only execute symmetry setup for cases that need it (ICASE 2, 4, 5)
  IF (NEED_SYMMETRY_SETUP) THEN
    ! Label 5: Symmetry setup section
    NOP=NCOL/NROW
    ! Original GOTO 13 (line 1827) eliminated: structured error check
    IF (NOP*NROW /= NCOL) THEN
      ! Label 13: Symmetry error
      WRITE(*,18) NROW,NCOL
      STOP
    END IF

    ! Original GOTO 7 (line 1828) eliminated: restructured as IF/ELSE
    IF (IPSYM > 0) THEN
      ! Label 7: SET UP SSX MATRIX FOR PLANE SYMMETRY
      KK=1
      SSX(1,1)=(1.,0.)
      ! Original GOTO 8 (line 1844) eliminated: structured error check
      IF ((NOP /= 2) .AND. (NOP /= 4) .AND. (NOP /= 8)) THEN
        STOP
      END IF
      ! Label 8: Continue plane symmetry setup
      KA=NOP/2
      IF (NOP == 8) KA=3
      DO K=1,KA
        DO I=1,KK
          DO J=1,KK
            DETER=SSX(I,J)
            SSX(I,J+KK)=DETER
            SSX(I+KK,J+KK)=-DETER
            SSX(I+KK,J)=DETER
          END DO
        END DO
        KK=KK*2
      END DO
    ELSE
      ! SET UP SSX MATRIX FOR ROTATIONAL SYMMETRY
      PHAZ=6.2831853072D+0/NOP
      DO I=2,NOP
        DO J=I,NOP
          ARG=PHAZ*DFLOAT(I-1)*DFLOAT(J-1)
          SSX(I,J)=DCMPLX(COS(ARG),SIN(ARG))
          SSX(J,I)=SSX(I,J)
        END DO
      END DO
      ! Original GOTO 11 (line 1838) eliminated: fall through to return
    END IF
  END IF

  ! Label 11: Normal return point
  RETURN

14 FORMAT (//35H MATRIX FILE STORAGE -  NO. BLOCKS=,I5, &
           19H COLUMNS PER BLOCK=,I5,23H COLUMNS IN LAST BLOCK=,I5)
15 FORMAT (25H SUBMATRICIES FIT IN CORE)
16 FORMAT (38H SUBMATRIX PARTITIONING -  NO. BLOCKS=,I5, &
           19H COLUMNS PER BLOCK=,I5,23H COLUMNS IN LAST BLOCK=,I5)
17 FORMAT (40H ERROR - INSUFFICIENT STORAGE FOR MATRIX,2I5)
18 FORMAT (28H SYMMETRY ERROR - NROW,NCOL=,2I5)

END SUBROUTINE FBLOCK


!===============================================================================
! SOLGF - Solve for current in Numerical Green's Function procedure
!===============================================================================
! Modernized from: nec2dxs_integrated.f, lines 4120-4240
! Modernization: Tier 2 - Free-form F90, eliminate 10 GOTOs, keep IMPLICIT/COMMON
!
! GOTO eliminations:
!   1. Line 4137: IF (N2C.GT.0) GO TO 1 → IF-THEN-ELSE structure
!   2. Line 4140: GO TO 22 → Removed (end of THEN block)
!   3. Line 4141: IF (N1.EQ.N.OR.M1.EQ.0) GO TO 5 → IF-THEN for conditional skip
!   4. Line 4156: IF (NEQS.EQ.0) GO TO 7 → IF-THEN for conditional skip
!   5. Line 4180: IF (ICASX.GT.1) GO TO 11 → IF-THEN-ELSE structure
!   6. Line 4182: GO TO 13 → Removed (end of THEN block)
!   7. Line 4183: IF (ICASX.EQ.4) GO TO 12 → Nested IF-THEN-ELSE
!   8. Line 4188: GO TO 13 → Removed (end of THEN block)
!   9. Line 4221: IF (N1.EQ.N.OR.M1.EQ.0) GO TO 20 → IF-THEN for conditional skip
!  10. Line 4233: IF (NSCON.EQ.0) GO TO 22 → IF-THEN for conditional execution
!===============================================================================
SUBROUTINE SOLGF (A,B,C,D,XY,IP,NP,N1,N,MP,M1,M,N1C,N2C,N2CZ)
  ! DOUBLE PRECISION 6/4/85
  !
  INCLUDE 'NEC2D3000.INC'
  IMPLICIT REAL*8(A-H,O-Z)
  ! SOLVE FOR CURRENT IN N.G.F. PROCEDURE
  COMPLEX*16 A,B,C,D,SUM,XY,Y
  COMMON /SCRATM/ Y(2*MAXSEG)
  COMMON /SEGJ/ AX(JMAX),BX(JMAX),CX(JMAX),JCO(JMAX), &
    JSNO,ISCON(50),NSCON,IPCON(10),NPCON
  COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT, &
    ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  DIMENSION A(1), B(N1C,1), C(N1C,1), D(N2CZ,1), IP(1), XY(1)

  IFL=14
  IF (ICASX.GT.0) IFL=13

  ! GOTO 1,2 eliminated: Restructured as IF-THEN-ELSE
  IF (N2C.GT.0) THEN
    ! N.G.F. SOLUTION

    ! GOTO 3 eliminated: Conditional execution with IF-THEN
    IF (N1.NE.N .AND. M1.NE.0) THEN
      ! REORDER EXCITATION ARRAY
      N2=N1+1
      JJ=N+1
      NPM=N+2*M1
      DO I=N2,NPM
        Y(I)=XY(I)
      END DO
      J=N1
      DO I=JJ,NPM
        J=J+1
        XY(J)=Y(I)
      END DO
      DO I=N2,N
        J=J+1
        XY(J)=Y(I)
      END DO
    END IF

    NEQS=NSCON+2*NPCON

    ! GOTO 4 eliminated: Conditional execution with IF-THEN
    IF (NEQS.NE.0) THEN
      NEQ=N1C+N2C
      NEQS=NEQ-NEQS+1
      ! COMPUTE INV(A)E1
      DO I=NEQS,NEQ
        XY(I)=(0.,0.)
      END DO
    END IF

    CALL SOLVES (A,IP,XY,N1C,1,NP,N1,MP,M1,13,IFL)
    NI=0
    NPB=NPBL

    ! COMPUTE E2-C(INV(A)E1)
    DO JJ=1,NBBL
      IF (JJ.EQ.NBBL) NPB=NLBL
      IF (ICASX.GT.1) READ (15) ((C(I,J),I=1,N1C),J=1,NPB)
      II=N1C+NI
      DO I=1,NPB
        SUM=(0.,0.)
        DO J=1,N1C
          SUM=SUM+C(J,I)*XY(J)
        END DO
        J=II+I
        XY(J)=XY(J)-SUM
      END DO
      NI=NI+NPBL
    END DO
    IF (ICASX.GT.1) REWIND 15
    JJ=N1C+1

    ! COMPUTE INV(D)(E2-C(INV(A)E1)) = I2
    ! GOTO 5,6,7,8 eliminated: Restructured as nested IF-THEN-ELSE
    IF (ICASX.LE.1) THEN
      CALL SOLVE (N2C,D,IP(JJ),XY(JJ),N2C)
    ELSE
      IF (ICASX.NE.4) THEN
        NI=N2C*N2C
        READ (11) (B(J,1),J=1,NI)
        REWIND 11
        CALL SOLVE (N2C,B,IP(JJ),XY(JJ),N2C)
      ELSE
        NBLSYS=NBLSYM
        NPSYS=NPSYM
        NLSYS=NLSYM
        ICASS=ICASE
        NBLSYM=NBBL
        NPSYM=NPBL
        NLSYM=NLBL
        ICASE=3
        REWIND 11
        REWIND 16
        CALL LTSOLV (B,N2C,IP(JJ),XY(JJ),N2C,1,11,16)
        REWIND 11
        REWIND 16
        NBLSYM=NBLSYS
        NPSYM=NPSYS
        NLSYM=NLSYS
        ICASE=ICASS
      END IF
    END IF

    NI=0
    NPB=NPBL

    ! COMPUTE INV(A)E1-(INV(A)B)I2 = I1
    DO JJ=1,NBBL
      IF (JJ.EQ.NBBL) NPB=NLBL
      IF (ICASX.GT.1) READ (14) ((B(I,J),I=1,N1C),J=1,NPB)
      II=N1C+NI
      DO I=1,N1C
        SUM=(0.,0.)
        DO J=1,NPB
          JP=II+J
          SUM=SUM+B(I,J)*XY(JP)
        END DO
        XY(I)=XY(I)-SUM
      END DO
      NI=NI+NPBL
    END DO
    IF (ICASX.GT.1) REWIND 14

    ! GOTO 9 eliminated: Conditional execution with IF-THEN
    IF (N1.NE.N .AND. M1.NE.0) THEN
      ! REORDER CURRENT ARRAY
      DO I=N2,NPM
        Y(I)=XY(I)
      END DO
      JJ=N1C+1
      J=N1
      DO I=JJ,NPM
        J=J+1
        XY(J)=Y(I)
      END DO
      DO I=N2,N1C
        J=J+1
        XY(J)=Y(I)
      END DO
    END IF

    ! GOTO 10 eliminated: Conditional execution with IF-THEN
    IF (NSCON.NE.0) THEN
      J=NEQS-1
      DO I=1,NSCON
        J=J+1
        JJ=ISCON(I)
        XY(JJ)=XY(J)
      END DO
    END IF

  ELSE
    ! NORMAL SOLUTION. NOT N.G.F.
    CALL SOLVES (A,IP,XY,N1C,1,NP,N,MP,M,13,IFL)
  END IF

  RETURN
END SUBROUTINE SOLGF


! ============================================================================
! Modernized SOLVES subroutine - Tier 2 conversion to F90 free form
! Source: nec2dxs_integrated.f, lines 4241-4362
! GOTOs eliminated: 11
! Modernization: Replaced all GOTO statements with structured control flow
! ============================================================================
SUBROUTINE SOLVES (A,IP,B,NEQ,NRH,NP,N,MP,M,IFL1,IFL2)
  INCLUDE 'NEC2D3000.INC'
  IMPLICIT REAL*8(A-H,O-Z)
!
! SUBROUTINE SOLVES, FOR SYMMETRIC STRUCTURES, HANDLES THE
! TRANSFORMATION OF THE RIGHT HAND SIDE VECTOR AND SOLUTION OF THE
! MATRIX EQ.
!
  COMPLEX*16 A,B,Y,SUM,SSX
  COMMON /SMAT/ SSX(16,16)
  COMMON /SCRATM/ Y(2*MAXSEG)
  COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,&
    ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  DIMENSION A(1), IP(1), B(NEQ,NRH)

  NPEQ=NP+2*MP
  NOP=NEQ/NPEQ
  FNOP=NOP
  FNORM=1./FNOP
  NROW=NEQ
  IF (ICASE.GT.3) NROW=NPEQ

  ! GOTO 1 eliminated: IF (NOP.EQ.1) GO TO 11 (line 4265)
  ! Replaced with IF-ELSE to skip forward transformation when NOP=1
  IF (NOP.NE.1) THEN
    DO IC=1,NRH
      ! GOTO 2 eliminated: IF (N.EQ.0.OR.M.EQ.0) GO TO 6 (line 4267)
      ! Replaced with IF-ELSE to conditionally execute reordering
      IF (N.NE.0 .AND. M.NE.0) THEN
        DO I=1,NEQ
          Y(I)=B(I,IC)
        END DO
        KK=2*MP
        IA=NP
        IB=N
        J=NP
        DO K=1,NOP
          ! GOTO 3 eliminated: IF (K.EQ.1) GO TO 3 (line 4275)
          ! GOTO 4 eliminated: IF (K.EQ.NOP) GO TO 5 (line 4280)
          ! Replaced with IF-ELSE to handle first/last iterations differently
          IF (K.NE.1) THEN
            DO I=1,NP
              IA=IA+1
              J=J+1
              B(J,IC)=Y(IA)
            END DO
          END IF
          IF (K.NE.NOP) THEN
            DO I=1,KK
              IB=IB+1
              J=J+1
              B(J,IC)=Y(IB)
            END DO
          END IF
        END DO
      END IF

      ! TRANSFORM MATRIX EQ. RHS VECTOR ACCORDING TO SYMMETRY MODES
      ! (label 6 in original code)
      DO I=1,NPEQ
        DO K=1,NOP
          IA=I+(K-1)*NPEQ
          Y(K)=B(IA,IC)
        END DO
        SUM=Y(1)
        DO K=2,NOP
          SUM=SUM+Y(K)
        END DO
        B(I,IC)=SUM*FNORM
        DO K=2,NOP
          IA=I+(K-1)*NPEQ
          SUM=Y(1)
          DO J=2,NOP
            SUM=SUM+Y(J)*DCONJG(SSX(K,J))
          END DO
          B(IA,IC)=SUM*FNORM
        END DO
      END DO
    END DO
  END IF

  ! GOTO 5 eliminated: IF (ICASE.LT.3) GO TO 12 (line 4303)
  ! Replaced with IF-ELSE to conditionally rewind files
  ! (label 11 in original code)
  IF (ICASE.GE.3) THEN
    REWIND IFL1
    REWIND IFL2
  END IF

  ! SOLVE EACH MODE EQUATION
  ! (label 12 in original code)
  DO KK=1,NOP
    IA=(KK-1)*NPEQ+1
    IB=IA
    ! GOTO 6 eliminated: IF (ICASE.NE.4) GO TO 13 (line 4312)
    ! Replaced with IF-ELSE to conditionally read matrix
    IF (ICASE.EQ.4) THEN
      I=NPEQ*NPEQ
      READ (IFL1) (A(J),J=1,I)
      IB=1
    END IF
    ! (label 13 in original code)
    ! GOTO 7 eliminated: IF (ICASE.EQ.3.OR.ICASE.EQ.5) GO TO 15 (line 4316)
    ! GOTO 8 eliminated: GO TO 16 (line 4319)
    ! Replaced with IF-ELSE-IF to select appropriate solver
    IF (ICASE.EQ.3 .OR. ICASE.EQ.5) THEN
      ! (label 15 in original code)
      CALL LTSOLV (A,NPEQ,IP(IA),B(IA,1),NEQ,NRH,IFL1,IFL2)
    ELSE
      DO IC=1,NRH
        CALL SOLVE (NPEQ,A(IB),IP(IA),B(IA,IC),NROW)
      END DO
    END IF
    ! (label 16 in original code)
  END DO

  IF (NOP.EQ.1) RETURN

  ! INVERSE TRANSFORM THE MODE SOLUTIONS
  DO IC=1,NRH
    DO I=1,NPEQ
      DO K=1,NOP
        IA=I+(K-1)*NPEQ
        Y(K)=B(IA,IC)
      END DO
      SUM=Y(1)
      DO K=2,NOP
        SUM=SUM+Y(K)
      END DO
      B(I,IC)=SUM
      DO K=2,NOP
        IA=I+(K-1)*NPEQ
        SUM=Y(1)
        DO J=2,NOP
          SUM=SUM+Y(J)*SSX(K,J)
        END DO
        B(IA,IC)=SUM
      END DO
    END DO

    ! GOTO 9 eliminated: IF (N.EQ.0.OR.M.EQ.0) GO TO 26 (line 4341)
    ! Replaced with IF-ELSE to conditionally execute inverse reordering
    IF (N.NE.0 .AND. M.NE.0) THEN
      DO I=1,NEQ
        Y(I)=B(I,IC)
      END DO
      KK=2*MP
      IA=NP
      IB=N
      J=NP
      DO K=1,NOP
        ! GOTO 10 eliminated: IF (K.EQ.1) GO TO 23 (line 4349)
        ! GOTO 11 eliminated: IF (K.EQ.NOP) GO TO 25 (line 4354)
        ! Replaced with IF-ELSE to handle first/last iterations differently
        IF (K.NE.1) THEN
          DO I=1,NP
            IA=IA+1
            J=J+1
            B(IA,IC)=Y(J)
          END DO
        END IF
        IF (K.NE.NOP) THEN
          DO I=1,KK
            IB=IB+1
            J=J+1
            B(IB,IC)=Y(J)
          END DO
        END IF
      END DO
    END IF
    ! (label 26 in original code)
  END DO

  RETURN
END SUBROUTINE SOLVES
