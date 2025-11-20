! =============================================================================
! nec2d_solver - Matrix Solution Routines
! =============================================================================
! Purpose: Matrix partitioning, factorization, and solution
! Contains: FBLOCK, SOLGF, SOLVES
! GOTOs eliminated: 14
! =============================================================================
subroutine FBLOCK (NROW,NCOL,IMAX,IRNGF,IPSYM)
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
  implicit real*8(A-H,O-Z)
  include 'NEC2D3000.INC'

  complex*16 SSX,DETER
  common /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,ICASX, &
                  NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  common /SMAT/ SSX(16,16)

  logical :: NEED_SYMMETRY_SETUP

  IMX1=IMAX-IRNGF
  NEED_SYMMETRY_SETUP = .FALSE.

  ! Original GOTO 2 (line 1776) eliminated: restructured as IF/ELSE block
  if (NROW*NCOL <= IMX1) then
    ! Matrix fits in core - simple case
    NBLOKS=1
    NPBLK=NROW
    NLAST=NROW
    IMAT=NROW*NCOL
    ! Original GOTO 1 (line 1781) eliminated: restructured as IF/ELSE
    if (NROW == NCOL) then
      ICASE=1
      return  ! Early return for symmetric in-core case
    else
      ! Label 1: Non-symmetric in-core case
      ICASE=2
      ! Original GOTO 5 (line 1785) eliminated: set flag to continue to symmetry setup
      NEED_SYMMETRY_SETUP = .TRUE.
    end if
  else
    ! Label 2: Matrix doesn't fit in core - out-of-core solution needed
    ! Original GOTO 3 (line 1786) eliminated: restructured as IF/ELSE
    if (NROW == NCOL) then
      ! Symmetric matrix out-of-core partitioning
      ICASE=3
      NPBLK=IMAX/(2*NCOL)
      NPSYM=IMX1/NCOL
      if (NPSYM < NPBLK) NPBLK=NPSYM
      ! Original GOTO 12 (line 1791) eliminated: structured error check
      if (NPBLK < 1) then
        ! Label 12: Error - insufficient storage
        write(*,17) NROW,NCOL
        stop
      end if
      NBLOKS=(NROW-1)/NPBLK
      NLAST=NROW-NBLOKS*NPBLK
      NBLOKS=NBLOKS+1
      NBLSYM=NBLOKS
      NPSYM=NPBLK
      NLSYM=NLAST
      IMAT=NPBLK*NCOL
      write(*,14) NBLOKS,NPBLK,NLAST
      ! Original GOTO 11 (line 1800) eliminated: direct RETURN
      return  ! Early return for symmetric out-of-core case
    else
      ! Label 3: Non-symmetric matrix out-of-core partitioning
      NPBLK=IMAX/NCOL
      ! Original GOTO 12 (line 1802) eliminated: structured error check
      if (NPBLK < 1) then
        ! Label 12: Error - insufficient storage
        write(*,17) NROW,NCOL
        stop
      end if
      if (NPBLK > NROW) NPBLK=NROW
      NBLOKS=(NROW-1)/NPBLK
      NLAST=NROW-NBLOKS*NPBLK
      NBLOKS=NBLOKS+1
      write(*,14) NBLOKS,NPBLK,NLAST
      ! Original GOTO 4 (line 1808) eliminated: restructured as IF/ELSE
      if (NROW*NROW <= IMX1) then
        ! Label 4: Submatrices fit in core
        ICASE=4
        NBLSYM=1
        NPSYM=NROW
        NLSYM=NROW
        IMAT=NROW*NROW
        write(*,15)
        ! Original GOTO 5 (line 1815) eliminated: set flag to continue to symmetry setup
        NEED_SYMMETRY_SETUP = .TRUE.
      else
        ! Submatrix partitioning needed
        ICASE=5
        NPSYM=IMAX/(2*NROW)
        NBLSYM=IMX1/NROW
        if (NBLSYM < NPSYM) NPSYM=NBLSYM
        ! Original GOTO 12 (line 1820) eliminated: structured error check
        if (NPSYM < 1) then
          ! Label 12: Error - insufficient storage
          write(*,17) NROW,NCOL
          stop
        end if
        NBLSYM=(NROW-1)/NPSYM
        NLSYM=NROW-NBLSYM*NPSYM
        NBLSYM=NBLSYM+1
        write(*,16) NBLSYM,NPSYM,NLSYM
        IMAT=NPSYM*NROW
        ! Fall through to symmetry setup (ICASE=5 always needs it)
        NEED_SYMMETRY_SETUP = .TRUE.
      end if
    end if
  end if

  ! Only execute symmetry setup for cases that need it (ICASE 2, 4, 5)
  if (NEED_SYMMETRY_SETUP) then
    ! Label 5: Symmetry setup section
    NOP=NCOL/NROW
    ! Original GOTO 13 (line 1827) eliminated: structured error check
    if (NOP*NROW /= NCOL) then
      ! Label 13: Symmetry error
      write(*,18) NROW,NCOL
      stop
    end if

    ! Original GOTO 7 (line 1828) eliminated: restructured as IF/ELSE
    if (IPSYM > 0) then
      ! Label 7: SET UP SSX MATRIX FOR PLANE SYMMETRY
      KK=1
      SSX(1,1)=(1.,0.)
      ! Original GOTO 8 (line 1844) eliminated: structured error check
      if ((NOP /= 2) .AND. (NOP /= 4) .AND. (NOP /= 8)) then
        stop
      end if
      ! Label 8: Continue plane symmetry setup
      KA=NOP/2
      if (NOP == 8) KA=3
      do K=1,KA
        do I=1,KK
          do J=1,KK
            DETER=SSX(I,J)
            SSX(I,J+KK)=DETER
            SSX(I+KK,J+KK)=-DETER
            SSX(I+KK,J)=DETER
          end do
        end do
        KK=KK*2
      end do
    else
      ! SET UP SSX MATRIX FOR ROTATIONAL SYMMETRY
      PHAZ=6.2831853072D+0/NOP
      do I=2,NOP
        do J=I,NOP
          ARG=PHAZ*DFLOAT(I-1)*DFLOAT(J-1)
          SSX(I,J)=DCMPLX(COS(ARG),SIN(ARG))
          SSX(J,I)=SSX(I,J)
        end do
      end do
      ! Original GOTO 11 (line 1838) eliminated: fall through to return
    end if
  end if

  ! Label 11: Normal return point
  return

14 format (//35H MATRIX FILE STORAGE -  NO. BLOCKS=,I5, &
           19H COLUMNS PER BLOCK=,I5,23H COLUMNS IN LAST BLOCK=,I5)
15 format (25H SUBMATRICIES FIT IN CORE)
16 format (38H SUBMATRIX PARTITIONING -  NO. BLOCKS=,I5, &
           19H COLUMNS PER BLOCK=,I5,23H COLUMNS IN LAST BLOCK=,I5)
17 format (40H ERROR - INSUFFICIENT STORAGE FOR MATRIX,2I5)
18 format (28H SYMMETRY ERROR - NROW,NCOL=,2I5)

end subroutine FBLOCK


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
subroutine SOLGF (A,B,C,D,XY,IP,NP,N1,N,MP,M1,M,N1C,N2C,N2CZ)
  ! DOUBLE PRECISION 6/4/85
  !
  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)
  ! SOLVE FOR CURRENT IN N.G.F. PROCEDURE
  complex*16 A,B,C,D,SUM,XY,Y
  common /SCRATM/ Y(2*MAXSEG)
  common /SEGJ/ AX(JMAX),BX(JMAX),CX(JMAX),JCO(JMAX), &
    JSNO,ISCON(50),NSCON,IPCON(10),NPCON
  common /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT, &
    ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  dimension A(1), B(N1C,1), C(N1C,1), D(N2CZ,1), IP(1), XY(1)

  IFL=14
  if (ICASX.gt.0) IFL=13

  ! GOTO 1,2 eliminated: Restructured as IF-THEN-ELSE
  if (N2C.gt.0) then
    ! N.G.F. SOLUTION

    ! GOTO 3 eliminated: Conditional execution with IF-THEN
    if (N1.ne.N .AND. M1.ne.0) then
      ! REORDER EXCITATION ARRAY
      N2=N1+1
      JJ=N+1
      NPM=N+2*M1
      do I=N2,NPM
        Y(I)=XY(I)
      end do
      J=N1
      do I=JJ,NPM
        J=J+1
        XY(J)=Y(I)
      end do
      do I=N2,N
        J=J+1
        XY(J)=Y(I)
      end do
    end if

    NEQS=NSCON+2*NPCON

    ! GOTO 4 eliminated: Conditional execution with IF-THEN
    if (NEQS.ne.0) then
      NEQ=N1C+N2C
      NEQS=NEQ-NEQS+1
      ! COMPUTE INV(A)E1
      do I=NEQS,NEQ
        XY(I)=(0.,0.)
      end do
    end if

    call SOLVES (A,IP,XY,N1C,1,NP,N1,MP,M1,13,IFL)
    NI=0
    NPB=NPBL

    ! COMPUTE E2-C(INV(A)E1)
    do JJ=1,NBBL
      if (JJ.eq.NBBL) NPB=NLBL
      if (ICASX.gt.1) read (15) ((C(I,J),I=1,N1C),J=1,NPB)
      II=N1C+NI
      do I=1,NPB
        SUM=(0.,0.)
        do J=1,N1C
          SUM=SUM+C(J,I)*XY(J)
        end do
        J=II+I
        XY(J)=XY(J)-SUM
      end do
      NI=NI+NPBL
    end do
    if (ICASX.gt.1) rewind 15
    JJ=N1C+1

    ! COMPUTE INV(D)(E2-C(INV(A)E1)) = I2
    ! GOTO 5,6,7,8 eliminated: Restructured as nested IF-THEN-ELSE
    if (ICASX.le.1) then
      call SOLVE (N2C,D,IP(JJ),XY(JJ),N2C)
    else
      if (ICASX.ne.4) then
        NI=N2C*N2C
        read (11) (B(J,1),J=1,NI)
        rewind 11
        call SOLVE (N2C,B,IP(JJ),XY(JJ),N2C)
      else
        NBLSYS=NBLSYM
        NPSYS=NPSYM
        NLSYS=NLSYM
        ICASS=ICASE
        NBLSYM=NBBL
        NPSYM=NPBL
        NLSYM=NLBL
        ICASE=3
        rewind 11
        rewind 16
        call LTSOLV (B,N2C,IP(JJ),XY(JJ),N2C,1,11,16)
        rewind 11
        rewind 16
        NBLSYM=NBLSYS
        NPSYM=NPSYS
        NLSYM=NLSYS
        ICASE=ICASS
      end if
    end if

    NI=0
    NPB=NPBL

    ! COMPUTE INV(A)E1-(INV(A)B)I2 = I1
    do JJ=1,NBBL
      if (JJ.eq.NBBL) NPB=NLBL
      if (ICASX.gt.1) read (14) ((B(I,J),I=1,N1C),J=1,NPB)
      II=N1C+NI
      do I=1,N1C
        SUM=(0.,0.)
        do J=1,NPB
          JP=II+J
          SUM=SUM+B(I,J)*XY(JP)
        end do
        XY(I)=XY(I)-SUM
      end do
      NI=NI+NPBL
    end do
    if (ICASX.gt.1) rewind 14

    ! GOTO 9 eliminated: Conditional execution with IF-THEN
    if (N1.ne.N .AND. M1.ne.0) then
      ! REORDER CURRENT ARRAY
      do I=N2,NPM
        Y(I)=XY(I)
      end do
      JJ=N1C+1
      J=N1
      do I=JJ,NPM
        J=J+1
        XY(J)=Y(I)
      end do
      do I=N2,N1C
        J=J+1
        XY(J)=Y(I)
      end do
    end if

    ! GOTO 10 eliminated: Conditional execution with IF-THEN
    if (NSCON.ne.0) then
      J=NEQS-1
      do I=1,NSCON
        J=J+1
        JJ=ISCON(I)
        XY(JJ)=XY(J)
      end do
    end if

  else
    ! NORMAL SOLUTION. NOT N.G.F.
    call SOLVES (A,IP,XY,N1C,1,NP,N,MP,M,13,IFL)
  end if

  return
end subroutine SOLGF


! ============================================================================
! Modernized SOLVES subroutine - Tier 2 conversion to F90 free form
! Source: nec2dxs_integrated.f, lines 4241-4362
! GOTOs eliminated: 11
! Modernization: Replaced all GOTO statements with structured control flow
! ============================================================================
subroutine SOLVES (A,IP,B,NEQ,NRH,NP,N,MP,M,IFL1,IFL2)
  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)
!
! SUBROUTINE SOLVES, FOR SYMMETRIC STRUCTURES, HANDLES THE
! TRANSFORMATION OF THE RIGHT HAND SIDE VECTOR AND SOLUTION OF THE
! MATRIX EQ.
!
  complex*16 A,B,Y,SUM,SSX
  common /SMAT/ SSX(16,16)
  common /SCRATM/ Y(2*MAXSEG)
  common /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,&
    ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  dimension A(1), IP(1), B(NEQ,NRH)

  NPEQ=NP+2*MP
  NOP=NEQ/NPEQ
  FNOP=NOP
  FNORM=1./FNOP
  NROW=NEQ
  if (ICASE.gt.3) NROW=NPEQ

  ! GOTO 1 eliminated: IF (NOP.EQ.1) GO TO 11 (line 4265)
  ! Replaced with IF-ELSE to skip forward transformation when NOP=1
  if (NOP.ne.1) then
    do IC=1,NRH
      ! GOTO 2 eliminated: IF (N.EQ.0.OR.M.EQ.0) GO TO 6 (line 4267)
      ! Replaced with IF-ELSE to conditionally execute reordering
      if (N.ne.0 .AND. M.ne.0) then
        do I=1,NEQ
          Y(I)=B(I,IC)
        end do
        KK=2*MP
        IA=NP
        IB=N
        J=NP
        do K=1,NOP
          ! GOTO 3 eliminated: IF (K.EQ.1) GO TO 3 (line 4275)
          ! GOTO 4 eliminated: IF (K.EQ.NOP) GO TO 5 (line 4280)
          ! Replaced with IF-ELSE to handle first/last iterations differently
          if (K.ne.1) then
            do I=1,NP
              IA=IA+1
              J=J+1
              B(J,IC)=Y(IA)
            end do
          end if
          if (K.ne.NOP) then
            do I=1,KK
              IB=IB+1
              J=J+1
              B(J,IC)=Y(IB)
            end do
          end if
        end do
      end if

      ! TRANSFORM MATRIX EQ. RHS VECTOR ACCORDING TO SYMMETRY MODES
      ! (label 6 in original code)
      do I=1,NPEQ
        do K=1,NOP
          IA=I+(K-1)*NPEQ
          Y(K)=B(IA,IC)
        end do
        SUM=Y(1)
        do K=2,NOP
          SUM=SUM+Y(K)
        end do
        B(I,IC)=SUM*FNORM
        do K=2,NOP
          IA=I+(K-1)*NPEQ
          SUM=Y(1)
          do J=2,NOP
            SUM=SUM+Y(J)*DCONJG(SSX(K,J))
          end do
          B(IA,IC)=SUM*FNORM
        end do
      end do
    end do
  end if

  ! GOTO 5 eliminated: IF (ICASE.LT.3) GO TO 12 (line 4303)
  ! Replaced with IF-ELSE to conditionally rewind files
  ! (label 11 in original code)
  if (ICASE.ge.3) then
    rewind IFL1
    rewind IFL2
  end if

  ! SOLVE EACH MODE EQUATION
  ! (label 12 in original code)
  do KK=1,NOP
    IA=(KK-1)*NPEQ+1
    IB=IA
    ! GOTO 6 eliminated: IF (ICASE.NE.4) GO TO 13 (line 4312)
    ! Replaced with IF-ELSE to conditionally read matrix
    if (ICASE.eq.4) then
      I=NPEQ*NPEQ
      read (IFL1) (A(J),J=1,I)
      IB=1
    end if
    ! (label 13 in original code)
    ! GOTO 7 eliminated: IF (ICASE.EQ.3.OR.ICASE.EQ.5) GO TO 15 (line 4316)
    ! GOTO 8 eliminated: GO TO 16 (line 4319)
    ! Replaced with IF-ELSE-IF to select appropriate solver
    if (ICASE.eq.3 .OR. ICASE.eq.5) then
      ! (label 15 in original code)
      call LTSOLV (A,NPEQ,IP(IA),B(IA,1),NEQ,NRH,IFL1,IFL2)
    else
      do IC=1,NRH
        call SOLVE (NPEQ,A(IB),IP(IA),B(IA,IC),NROW)
      end do
    end if
    ! (label 16 in original code)
  end do

  if (NOP.eq.1) return

  ! INVERSE TRANSFORM THE MODE SOLUTIONS
  do IC=1,NRH
    do I=1,NPEQ
      do K=1,NOP
        IA=I+(K-1)*NPEQ
        Y(K)=B(IA,IC)
      end do
      SUM=Y(1)
      do K=2,NOP
        SUM=SUM+Y(K)
      end do
      B(I,IC)=SUM
      do K=2,NOP
        IA=I+(K-1)*NPEQ
        SUM=Y(1)
        do J=2,NOP
          SUM=SUM+Y(J)*SSX(K,J)
        end do
        B(IA,IC)=SUM
      end do
    end do

    ! GOTO 9 eliminated: IF (N.EQ.0.OR.M.EQ.0) GO TO 26 (line 4341)
    ! Replaced with IF-ELSE to conditionally execute inverse reordering
    if (N.ne.0 .AND. M.ne.0) then
      do I=1,NEQ
        Y(I)=B(I,IC)
      end do
      KK=2*MP
      IA=NP
      IB=N
      J=NP
      do K=1,NOP
        ! GOTO 10 eliminated: IF (K.EQ.1) GO TO 23 (line 4349)
        ! GOTO 11 eliminated: IF (K.EQ.NOP) GO TO 25 (line 4354)
        ! Replaced with IF-ELSE to handle first/last iterations differently
        if (K.ne.1) then
          do I=1,NP
            IA=IA+1
            J=J+1
            B(IA,IC)=Y(J)
          end do
        end if
        if (K.ne.NOP) then
          do I=1,KK
            IB=IB+1
            J=J+1
            B(IB,IC)=Y(J)
          end do
        end if
      end do
    end if
    ! (label 26 in original code)
  end do

  return
end subroutine SOLVES
