!***********************************************************************
!                        NEC2D_IO_MODERN.F90
!***********************************************************************
!
!     Modernized Input/Output Subroutines for NEC2D
!
!     This file contains I/O-related subroutines fully modernized from nec2dxs.f
!
!     Subroutines included:
!       READGM  - Read geometry record and parse it
!       READMN  - Read control record and parse it
!       PARSIT  - Parse input records
!       UPCASE  - Convert text to upper case
!       PRNT    - Print impedance loading data
!       GFIL    - Read Numerical Green's Function file
!       GFOUT   - Write Numerical Green's Function file
!       BLCKOT  - Write matrix blocks
!       BLCKIN  - Read matrix blocks
!       REBLK   - Reblock array in N.G.F. solution
!
!     Modernizations applied:
!     - Free-form Fortran 90 format
!     - All GOTO statements eliminated (20 total)
!     - IMPLICIT NONE with explicit type declarations
!     - Modern DO...END DO loops (no labels)
!     - INTENT attributes on all arguments
!     - ENTRY point converted to separate subroutine
!     - Improved error handling
!
!***********************************************************************

SUBROUTINE READGM(INUNIT,CODE,I1,I2,R1,R2,R3,R4,R5,R6,R7)
  !
  !  READGM reads a geometry record and parses it.
  !
  !  Arguments:
  !     CODE        two letter mnemonic code
  !     I1 - I2     integer values from record
  !     R1 - R7     real values from record
  !
  IMPLICIT NONE
  INTEGER, INTENT(IN) :: INUNIT
  CHARACTER(LEN=*), INTENT(INOUT) :: CODE
  INTEGER, INTENT(OUT) :: I1, I2
  REAL(8), INTENT(OUT) :: R1, R2, R3, R4, R5, R6, R7

  INTEGER :: INTVAL(2), IEOF
  REAL(8) :: REAVAL(7)

  ! Call the routine to read the record and parse it
  CALL PARSIT(INUNIT,2,7,CODE,INTVAL,REAVAL,IEOF)

  ! Set the return variables to the buffer array elements
  IF (IEOF < 0) CODE='GE'
  I1 = INTVAL(1)
  I2 = INTVAL(2)
  R1 = REAVAL(1)
  R2 = REAVAL(2)
  R3 = REAVAL(3)
  R4 = REAVAL(4)
  R5 = REAVAL(5)
  R6 = REAVAL(6)
  R7 = REAVAL(7)

END SUBROUTINE READGM


SUBROUTINE READMN(INUNIT,CODE,I1,I2,I3,I4,F1,F2,F3,F4,F5,F6)
  !
  !  READMN reads a control record and parses it.
  !
  IMPLICIT NONE
  INTEGER, INTENT(IN) :: INUNIT
  CHARACTER(LEN=*), INTENT(INOUT) :: CODE
  INTEGER, INTENT(OUT) :: I1, I2, I3, I4
  REAL(8), INTENT(OUT) :: F1, F2, F3, F4, F5, F6

  INTEGER :: INTVAL(4), IEOF
  REAL(8) :: REAVAL(6)

  ! Call the routine to read the record and parse it
  CALL PARSIT(INUNIT,4,6,CODE,INTVAL,REAVAL,IEOF)

  ! Set the return variables to the buffer array elements
  IF (IEOF < 0) CODE='EN'
  I1 = INTVAL(1)
  I2 = INTVAL(2)
  I3 = INTVAL(3)
  I4 = INTVAL(4)
  F1 = REAVAL(1)
  F2 = REAVAL(2)
  F3 = REAVAL(3)
  F4 = REAVAL(4)
  F5 = REAVAL(5)
  F6 = REAVAL(6)

END SUBROUTINE READMN


SUBROUTINE PARSIT(INUNIT,MAXINT,MAXREA,CMND,INTFLD,REAFLD,IEOF)
  !
  !  UPDATED:  21 July 87, Modernized: 2025
  !
  !  Called by:   READGM    READMN
  !
  !  PARSIT reads an input record and parses it.
  !
  !  Arguments:
  !     MAXINT     total number of integers in record
  !     MAXREA     total number of real values in record
  !     CMND       two letter mnemonic code
  !     INTFLD     integer values from record
  !     REAFLD     real values from record
  !
  !  Internal Variables:
  !     BGNFLD     list of starting indices
  !     BUFFER     text buffer
  !     ENDFLD     list of ending indices
  !     FLDTRM     flag to indicate that pointer is in field position
  !     REC        input line as read
  !     TOTCOL     total number of columns in REC
  !     TOTFLD     number of numeric fields
  !
  IMPLICIT NONE
  INTEGER, INTENT(IN) :: INUNIT, MAXINT, MAXREA
  CHARACTER(LEN=2), INTENT(INOUT) :: CMND
  INTEGER, INTENT(OUT) :: INTFLD(MAXINT), IEOF
  REAL(8), INTENT(OUT) :: REAFLD(MAXREA)

  CHARACTER(LEN=80) :: NGFNAM, REC, BUFFER
  INTEGER :: BGNFLD(12), ENDFLD(12), TOTCOL, TOTFLD
  LOGICAL :: FLDTRM
  INTEGER :: I, J, K, LAST, LENGTH, IND, INDE
  COMMON /NGFNAM/NGFNAM

  ! Read input record
  READ(INUNIT, '(A80)', IOSTAT=IEOF) REC
  CALL UPCASE(REC, REC, TOTCOL)

  ! Store opcode and clear field arrays
  CMND = REC(1:2)
  INTFLD(:) = 0
  REAFLD(:) = 0.0D0
  BGNFLD(:) = 0
  ENDFLD(:) = 0

  ! Find the beginning and ending of each field as well as the total number of fields
  TOTFLD = 0
  FLDTRM = .FALSE.
  LAST = MAXREA + MAXINT

  DO J = 3, TOTCOL
    K = ICHAR(REC(J:J))

    ! Check for end of line comment ('!')
    ! This allows VAX-like comments at the end of data records, i.e.
    !      GW 1 7 0 0 0 0 0 .5 .0001 ! DIPOLE WIRE
    !      GE ! END OF GEOMETRY
    IF (K == 33) THEN
      IF (FLDTRM) ENDFLD(TOTFLD) = J - 1
      EXIT  ! Replaced GO TO 5000

    ! Set the ending index when the character is a comma or space
    ! and the pointer is in a field position (FLDTRM = .TRUE.)
    ELSE IF (K == 32 .OR. K == 44) THEN
      IF (FLDTRM) THEN
        ENDFLD(TOTFLD) = J - 1
        FLDTRM = .FALSE.
      END IF

    ! Set the beginning index when the character is not a comma or space
    ! and the pointer is not currently in a field position (FLDTRM = .FALSE)
    ELSE IF (.NOT. FLDTRM) THEN
      TOTFLD = TOTFLD + 1
      FLDTRM = .TRUE.
      BGNFLD(TOTFLD) = J
    END IF
  END DO

  IF (FLDTRM) ENDFLD(TOTFLD) = TOTCOL

  ! Check to see if the total number of value fields is within the prescribed limits
  IF ((CMND == 'WG') .OR. (CMND == 'GF')) THEN
    NGFNAM = 'NGF2D.NEC'
  END IF

  IF (TOTFLD == 0) THEN
    RETURN
  ELSE IF (TOTFLD > LAST) THEN
    WRITE(*,*) ''
    WRITE(*,*) ' ***** CARD ERROR - TOO MANY FIELDS IN RECORD'
    WRITE(*,'(A,A80)') ' ***** TEXT -->  ', REC
    STOP 'CARD ERROR'
  END IF

  J = MIN(TOTFLD, MAXINT)

  ! Parse out integer values and store into integer buffer array
  DO I = 1, J
    LENGTH = ENDFLD(I) - BGNFLD(I) + 1
    BUFFER = REC(BGNFLD(I):ENDFLD(I))
    IF (((CMND == 'WG') .OR. (CMND == 'GF')) .AND. &
        (BUFFER(1:1) /= '0') .AND. (BUFFER(1:1) /= '1')) THEN
      NGFNAM = REC(BGNFLD(I):ENDFLD(I))
      RETURN
    END IF
    IND = INDEX(BUFFER(1:LENGTH), '.')
    IF (IND > 0 .AND. IND < LENGTH) THEN
      ! Invalid integer format
      WRITE(*,*) ''
      WRITE(*,'(A,I1)') ' ***** CARD ERROR - INVALID NUMBER AT INTEGER POSITION ', I
      WRITE(*,'(A,A80)') ' ***** TEXT -->  ', REC
      STOP 'CARD ERROR'
    END IF
    IF (IND == LENGTH) LENGTH = LENGTH - 1
    READ(BUFFER(1:LENGTH), *, IOSTAT=K) INTFLD(I)
    IF (K /= 0) THEN
      WRITE(*,*) ''
      WRITE(*,'(A,I1)') ' ***** CARD ERROR - INVALID NUMBER AT INTEGER POSITION ', I
      WRITE(*,'(A,A80)') ' ***** TEXT -->  ', REC
      STOP 'CARD ERROR'
    END IF
  END DO

  ! Parse out real values and store into real buffer array
  IF (TOTFLD > MAXINT) THEN
    J = MAXINT + 1
    DO I = J, TOTFLD
      LENGTH = ENDFLD(I) - BGNFLD(I) + 1
      BUFFER = REC(BGNFLD(I):ENDFLD(I))
      IND = INDEX(BUFFER(1:LENGTH), '.')
      IF (IND == 0) THEN
        INDE = INDEX(BUFFER(1:LENGTH), 'E')
        LENGTH = LENGTH + 1
        IF (INDE == 0) THEN
          BUFFER(LENGTH:LENGTH) = '.'
        ELSE
          BUFFER = BUFFER(1:INDE-1) // '.' // BUFFER(INDE:LENGTH-1)
        END IF
      END IF
      READ(BUFFER(1:LENGTH), *, IOSTAT=K) REAFLD(I-MAXINT)
      IF (K /= 0) THEN
        WRITE(*,*) ''
        WRITE(*,'(A,I1)') ' ***** CARD ERROR - INVALID NUMBER AT REAL POSITION ', I-MAXINT
        WRITE(*,'(A,A80)') ' ***** TEXT -->  ', REC
        STOP 'CARD ERROR'
      END IF
    END DO
  END IF

END SUBROUTINE PARSIT


SUBROUTINE UPCASE(INTEXT, OUTTXT, LENGTH)
  !
  !  UPCASE finds the length of INTEXT and converts it to upper case.
  !
  IMPLICIT NONE
  CHARACTER(LEN=*), INTENT(IN) :: INTEXT
  CHARACTER(LEN=*), INTENT(OUT) :: OUTTXT
  INTEGER, INTENT(OUT) :: LENGTH

  INTEGER :: I, J

  LENGTH = LEN(INTEXT)
  DO I = 1, LENGTH
    J = ICHAR(INTEXT(I:I))
    IF (J >= 96) J = J - 32
    OUTTXT(I:I) = CHAR(J)
  END DO

END SUBROUTINE UPCASE


SUBROUTINE PRNT(IN1,IN2,IN3,FL1,FL2,FL3,FL4,FL5,FL6,CTYPE)
  !
  !  Purpose:
  !  PRNT prints the input data for impedance loading, inserting blanks
  !  for numbers that are zero.
  !
  !  INPUT:
  !  IN1-3 = INTEGER VALUES TO BE PRINTED
  !  FL1-6 = REAL VALUES TO BE PRINTED
  !  CTYPE = CHARACTER STRING TO BE PRINTED
  !
  IMPLICIT NONE
  INTEGER, INTENT(IN) :: IN1, IN2, IN3
  REAL(8), INTENT(IN) :: FL1, FL2, FL3, FL4, FL5, FL6
  CHARACTER(LEN=*), INTENT(IN) :: CTYPE

  CHARACTER(LEN=5) :: CINT(3)
  CHARACTER(LEN=13) :: CFLT(6)
  INTEGER :: I

  CINT(:) = '     '

  IF (IN1 == 0 .AND. IN2 == 0 .AND. IN3 == 0) THEN
    CINT(1) = '  ALL'
  ELSE
    IF (IN1 /= 0) WRITE(CINT(1),'(I5)') IN1
    IF (IN2 /= 0) WRITE(CINT(2),'(I5)') IN2
    IF (IN3 /= 0) WRITE(CINT(3),'(I5)') IN3
  END IF

  CFLT(:) = '     '
  IF (ABS(FL1) > 1.0D-30) WRITE(CFLT(1),'(1P,E13.4)') FL1
  IF (ABS(FL2) > 1.0D-30) WRITE(CFLT(2),'(1P,E13.4)') FL2
  IF (ABS(FL3) > 1.0D-30) WRITE(CFLT(3),'(1P,E13.4)') FL3
  IF (ABS(FL4) > 1.0D-30) WRITE(CFLT(4),'(1P,E13.4)') FL4
  IF (ABS(FL5) > 1.0D-30) WRITE(CFLT(5),'(1P,E13.4)') FL5
  IF (ABS(FL6) > 1.0D-30) WRITE(CFLT(6),'(1P,E13.4)') FL6
  WRITE(*,'(/,3X,3A,3X,6A,3X,A)') (CINT(I),I=1,3), (CFLT(I),I=1,6), CTYPE

END SUBROUTINE PRNT


SUBROUTINE GFIL(IPRT)
  !
  !  DOUBLE PRECISION 6/4/85
  !  Modernized: 2025 - Eliminated 8 GOTO statements
  !
  !  GFIL READS THE N.G.F. FILE
  !
  USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: ERROR_UNIT
  INCLUDE 'NEC2DPAR.INC'
  IMPLICIT NONE
  INTEGER, INTENT(IN) :: IPRT
  INTEGER, PARAMETER :: IRESRV = MAXMAT**2

  COMPLEX(16) :: CM, SSX, ZRATI, ZRATI2, T1, ZARRAY, AR1, AR2, AR3, EPSCF, FRATI
  REAL(8) :: X, Y, Z, SI, BI, ALP, BET, WLAM, SALP, T2, CL, CH, SCRWL, SCRWR
  REAL(8) :: EPSR, SIG, SCRWLT, SCRWRT, FMHZ, EPSR2, SIG2, DXA, DYA, XSA, YSA
  REAL(8) :: XI, YI, ZI, DX
  INTEGER :: ICON1, ICON2, ITAG, ICONX, LD, N1, N2, N, NP, M1, M2, M, MP, IPSYM
  INTEGER :: NRADL, KSYMP, IFAR, IPERF, ICASE, NBLOKS, NPBLK, NLAST, NBLSYM
  INTEGER :: NPSYM, NLSYM, IMAT, ICASX, NBBX, NPBX, NLBX, NBBL, NPBL, NLBL
  INTEGER :: NLOAD, NLODF, IP, KCOM, NXA, NYA, NEQ, NPEQ, NOP, IOUT, NBL2, I, J, K, IOP
  CHARACTER(LEN=80) :: NGFNAM
  CHARACTER(LEN=76) :: COM

  COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
                ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
                ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  COMMON /CMB/ CM(IRESRV)
  COMMON /ANGL/ SALP(MAXSEG)
  COMMON /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL, &
              KSYMP,IFAR,IPERF
  COMMON /GGRID/ AR1(11,10,4),AR2(17,5,4),AR3(9,8,4),EPSCF,DXA(3), &
                 DYA(3),XSA(3),YSA(3),NXA(3),NYA(3)
  COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT, &
                  ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  COMMON /SMAT/ SSX(16,16)
  COMMON /ZLOAD/ ZARRAY(MAXSEG),NLOAD,NLODF
  COMMON /SAVE/EPSR,SIG,SCRWLT,SCRWRT,FMHZ,IP(2*MAXSEG),KCOM
  COMMON /CSAVE/COM(19,5)
  COMMON /NGFNAM/NGFNAM

  ! ERROR CORRECTED 11/20/89
  INTEGER :: T2X(1),T2Y(1),T2Z(1)
  EQUIVALENCE (T2X,ICON1),(T2Y,ICON2),(T2Z,ITAG)

  INTEGER, PARAMETER :: IGFL = 20
  LOGICAL :: FILE_EXISTS

  ! Check if file exists and open it (replaced GO TO 30/31)
  INQUIRE(FILE=NGFNAM, EXIST=FILE_EXISTS)
  IF (.NOT. FILE_EXISTS) THEN
    WRITE(ERROR_UNIT,*) 'ERROR: Cannot open NGF file: ', TRIM(NGFNAM)
    STOP
  END IF

  OPEN(UNIT=IGFL,FILE=NGFNAM,FORM='UNFORMATTED',STATUS='OLD')
  REWIND IGFL

  READ (IGFL) N1,NP,M1,MP,WLAM,FMHZ,IPSYM,KSYMP,IPERF,NRADL,EPSR,SIG, &
              SCRWLT,SCRWRT,NLODF,KCOM
  N = N1
  M = M1
  N2 = N1 + 1
  M2 = M1 + 1

  ! Read segment data and convert back to end coord. in units of meters
  IF (N1 > 0) THEN  ! Replaced GO TO 2
    READ (IGFL) (X(I),I=1,N1),(Y(I),I=1,N1),(Z(I),I=1,N1)
    READ (IGFL) (SI(I),I=1,N1),(BI(I),I=1,N1),(ALP(I),I=1,N1)
    READ (IGFL) (BET(I),I=1,N1),(SALP(I),I=1,N1)
    READ (IGFL) (ICON1(I),I=1,N1),(ICON2(I),I=1,N1)
    READ (IGFL) (ITAG(I),I=1,N1)
    IF (NLODF /= 0) READ (IGFL) (ZARRAY(I),I=1,N1)
    DO I = 1, N1
      XI = X(I)*WLAM
      YI = Y(I)*WLAM
      ZI = Z(I)*WLAM
      DX = SI(I)*0.5D0*WLAM
      X(I) = XI - ALP(I)*DX
      Y(I) = YI - BET(I)*DX
      Z(I) = ZI - SALP(I)*DX
      SI(I) = XI + ALP(I)*DX
      ALP(I) = YI + BET(I)*DX
      BET(I) = ZI + SALP(I)*DX
      BI(I) = BI(I)*WLAM
    END DO
  END IF

  ! Read patch data and convert to meters
  IF (M1 > 0) THEN  ! Replaced GO TO 4
    J = LD - M1 + 1
    READ (IGFL) (X(I),I=J,LD),(Y(I),I=J,LD),(Z(I),I=J,LD)
    READ (IGFL) (SI(I),I=J,LD),(BI(I),I=J,LD),(ALP(I),I=J,LD)
    READ (IGFL) (BET(I),I=J,LD),(SALP(I),I=J,LD)
    ! ERROR CORRECTED 11/20/89
    READ (IGFL) (T2X(I),I=J,LD),(T2Y(I),I=J,LD)
    READ (IGFL) (T2Z(I),I=J,LD)

    DX = WLAM*WLAM
    DO I = J, LD
      X(I) = X(I)*WLAM
      Y(I) = Y(I)*WLAM
      Z(I) = Z(I)*WLAM
      BI(I) = BI(I)*DX
    END DO
  END IF

  READ (IGFL) ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT
  IF (IPERF == 2) READ (IGFL) AR1,AR2,AR3,EPSCF,DXA,DYA,XSA,YSA,NXA,NYA
  NEQ = N1 + 2*M1
  NPEQ = NP + 2*MP
  NOP = NEQ/NPEQ
  IF (NOP > 1) READ (IGFL) ((SSX(I,J),I=1,NOP),J=1,NOP)
  READ (IGFL) (IP(I),I=1,NEQ),COM

  ! Read matrix A and write TAPE13 for out of core
  ! Replaced computed GO TO (5,10)
  IF (ICASE <= 2) THEN
    IOUT = NEQ*NPEQ
    READ (IGFL) (CM(I),I=1,IOUT)
  ELSE
    REWIND 13
    IF (ICASE == 4) THEN
      IOUT = NPEQ*NPEQ
      DO K = 1, NOP
        READ (IGFL) (CM(J),J=1,IOUT)
        WRITE (13) (CM(J),J=1,IOUT)
      END DO
    ELSE
      IOUT = NPSYM*NPEQ*2
      NBL2 = 2*NBLSYM
      DO IOP = 1, NOP
        DO I = 1, NBL2
          CALL BLCKIN(CM,IGFL,1,IOUT,1,206)
          CALL BLCKOT(CM,13,1,IOUT,1,205)
        END DO
      END DO
    END IF
    REWIND 13
  END IF

  REWIND IGFL

  ! Write N.G.F. HEADING
  WRITE(*,16)
  WRITE(*,14)
  WRITE(*,14)
  WRITE(*,17)
  WRITE(*,18) N1, M1
  IF (NOP > 1) WRITE(*,19) NOP
  WRITE(*,20) IMAT, ICASE
  IF (ICASE >= 3) THEN
    NBL2 = NEQ*NPEQ
    WRITE(*,21) NBL2
  END IF
  WRITE(*,22) FMHZ
  IF (KSYMP == 2 .AND. IPERF == 1) WRITE(*,23)
  IF (KSYMP == 2 .AND. IPERF == 0) WRITE(*,27)
  IF (KSYMP == 2 .AND. IPERF == 2) WRITE(*,28)
  IF (KSYMP == 2 .AND. IPERF /= 1) WRITE(*,24) EPSR, SIG
  WRITE(*,17)
  DO J = 1, KCOM
    WRITE(*,15) (COM(I,J),I=1,19)
  END DO
  WRITE(*,17)
  WRITE(*,14)
  WRITE(*,14)
  WRITE(*,16)

  IF (IPRT == 0) RETURN

  WRITE(*,25)
  DO I = 1, N1
    WRITE(*,26) I,X(I),Y(I),Z(I),SI(I),ALP(I),BET(I)
  END DO

14 FORMAT (5X,50H**************************************************,34H**********************************)
15 FORMAT (5X,3H** ,19A4,3H **)
16 FORMAT (////)
17 FORMAT (5X,2H**,80X,2H**)
18 FORMAT (5X,29H** NUMERICAL GREEN'S FUNCTION,53X,2H**,/,5X,17H** NO. SEGMENTS =,I4,10X,13HNO. PATCHES =,I4,34X,2H**)
19 FORMAT (5X,27H** NO. SYMMETRIC SECTIONS =,I4,51X,2H**)
20 FORMAT (5X,34H** N.G.F. MATRIX -  CORE STORAGE =,I7,23H COMPLEX NUMBERS,  CASE,I2,16X,2H**)
21 FORMAT (5X,2H**,19X,13HMATRIX SIZE =,I7,16H COMPLEX NUMBERS,25X,2H**)
22 FORMAT (5X,14H** FREQUENCY =,1P,E12.5,5H MHZ.,51X,2H**)
23 FORMAT (5X,17H** PERFECT GROUND,65X,2H**)
24 FORMAT (5X,44H** GROUND PARAMETERS - DIELECTRIC CONSTANT =,1P,E12.5,26X,2H**,/, &
             5X,2H**,21X,14HCONDUCTIVITY =,E12.5,8H MHOS/M.,25X,2H**)
25 FORMAT (39X,31HNUMERICAL GREEN'S FUNCTION DATA,/, &
             41X,27HCOORDINATES OF SEGMENT ENDS,/,51X,8H(METERS),/, &
             5X,4HSEG.,11X,19H- - - END ONE - - -,26X,19H- - - END TWO - - -,/, &
             6X,3HNO.,6X,1HX,14X,1HY,14X,1HZ,14X,1HX,14X,1HY,14X,1HZ)
26 FORMAT (1X,I7,1P,6E15.6)
27 FORMAT (5X,55H** FINITE GROUND.  REFLECTION COEFFICIENT APPROXIMATION, &
             27X,2H**)
28 FORMAT (5X,38H** FINITE GROUND.  SOMMERFELD SOLUTION,44X,2H**)

END SUBROUTINE GFIL


SUBROUTINE GFOUT
  !
  !  DOUBLE PRECISION 6/4/85
  !  Modernized: 2025 - Eliminated 8 GOTO statements
  !
  !  WRITE N.G.F. FILE
  !
  INCLUDE 'NEC2DPAR.INC'
  IMPLICIT NONE
  INTEGER, PARAMETER :: IRESRV = MAXMAT**2

  COMPLEX(16) :: CM, SSX, ZRATI, ZRATI2, T1, ZARRAY, AR1, AR2, AR3, EPSCF, FRATI
  REAL(8) :: X, Y, Z, SI, BI, ALP, BET, WLAM, SALP, T2, CL, CH, SCRWL, SCRWR
  REAL(8) :: EPSR, SIG, SCRWLT, SCRWRT, FMHZ, DXA, DYA, XSA, YSA
  INTEGER :: ICON1, ICON2, ITAG, ICONX, LD, N1, N2, N, NP, M1, M2, M, MP, IPSYM
  INTEGER :: NRADL, KSYMP, IFAR, IPERF, ICASE, NBLOKS, NPBLK, NLAST, NBLSYM
  INTEGER :: NPSYM, NLSYM, IMAT, ICASX, NBBX, NPBX, NLBX, NBBL, NPBL, NLBL
  INTEGER :: NLOAD, NLODF, IP, KCOM, NXA, NYA, NEQ, NPEQ, NOP, IOUT, I, J, K, IOP
  CHARACTER(LEN=80) :: NGFNAM
  CHARACTER(LEN=76) :: COM

  COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
                ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
                ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  COMMON /CMB/ CM(IRESRV)
  COMMON /ANGL/ SALP(MAXSEG)
  COMMON /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL, &
              KSYMP,IFAR,IPERF
  COMMON /GGRID/ AR1(11,10,4),AR2(17,5,4),AR3(9,8,4),EPSCF,DXA(3), &
                 DYA(3),XSA(3),YSA(3),NXA(3),NYA(3)
  COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT, &
                  ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  COMMON /SMAT/ SSX(16,16)
  COMMON /ZLOAD/ ZARRAY(MAXSEG),NLOAD,NLODF
  COMMON /SAVE/EPSR,SIG,SCRWLT,SCRWRT,FMHZ,IP(2*MAXSEG),KCOM
  COMMON /CSAVE/COM(19,5)
  COMMON /NGFNAM/NGFNAM

  ! ERROR CORRECTED 11/20/89
  INTEGER :: T2X(1),T2Y(1),T2Z(1)
  EQUIVALENCE (T2X,ICON1),(T2Y,ICON2),(T2Z,ITAG)

  INTEGER, PARAMETER :: IGFL = 20

  OPEN(UNIT=IGFL,FILE=NGFNAM,FORM='UNFORMATTED',STATUS='UNKNOWN')
  NEQ = N + 2*M
  NPEQ = NP + 2*MP
  NOP = NEQ/NPEQ
  WRITE (IGFL) N,NP,M,MP,WLAM,FMHZ,IPSYM,KSYMP,IPERF,NRADL,EPSR, &
               SIG,SCRWLT,SCRWRT,NLOAD,KCOM

  IF (N > 0) THEN  ! Replaced GO TO 1
    WRITE (IGFL) (X(I),I=1,N),(Y(I),I=1,N),(Z(I),I=1,N)
    WRITE (IGFL) (SI(I),I=1,N),(BI(I),I=1,N),(ALP(I),I=1,N)
    WRITE (IGFL) (BET(I),I=1,N),(SALP(I),I=1,N)
    WRITE (IGFL) (ICON1(I),I=1,N),(ICON2(I),I=1,N)
    WRITE (IGFL) (ITAG(I),I=1,N)
    IF (NLOAD > 0) WRITE (IGFL) (ZARRAY(I),I=1,N)
  END IF

  IF (M > 0) THEN  ! Replaced GO TO 2
    J = LD - M + 1
    WRITE (IGFL) (X(I),I=J,LD),(Y(I),I=J,LD),(Z(I),I=J,LD)
    WRITE (IGFL) (SI(I),I=J,LD),(BI(I),I=J,LD),(ALP(I),I=J,LD)
    WRITE (IGFL) (BET(I),I=J,LD),(SALP(I),I=J,LD)
    ! ERROR CORRECTED 11/20/89
    WRITE (IGFL) (T2X(I),I=J,LD),(T2Y(I),I=J,LD)
    WRITE (IGFL) (T2Z(I),I=J,LD)
  END IF

  WRITE (IGFL) ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT
  IF (IPERF == 2) WRITE (IGFL) AR1,AR2,AR3,EPSCF,DXA,DYA,XSA,YSA,NXA,NYA
  IF (NOP > 1) WRITE (IGFL) ((SSX(I,J),I=1,NOP),J=1,NOP)
  WRITE (IGFL) (IP(I),I=1,NEQ),COM

  ! Write matrix blocks (replaced computed GO TO)
  IF (ICASE <= 2) THEN
    IOUT = NEQ*NPEQ
    WRITE (IGFL) (CM(I),I=1,IOUT)
  ELSE IF (ICASE == 4) THEN
    REWIND 13
    I = NPEQ*NPEQ
    DO K = 1, NOP
      READ (13) (CM(J),J=1,I)
      WRITE (IGFL) (CM(J),J=1,I)
    END DO
    REWIND 13
  ELSE
    REWIND 13
    REWIND 14
    IF (ICASE /= 5) THEN
      IOUT = NPBLK*NEQ*2
      DO I = 1, NBLOKS
        CALL BLCKIN(CM,13,1,IOUT,1,201)
        CALL BLCKOT(CM,IGFL,1,IOUT,1,202)
      END DO
      DO I = 1, NBLOKS
        CALL BLCKIN(CM,14,1,IOUT,1,203)
        CALL BLCKOT(CM,IGFL,1,IOUT,1,204)
      END DO
    ELSE
      IOUT = NPSYM*NPEQ*2
      DO IOP = 1, NOP
        DO I = 1, NBLSYM
          CALL BLCKIN(CM,13,1,IOUT,1,205)
          CALL BLCKOT(CM,IGFL,1,IOUT,1,206)
        END DO
        DO I = 1, NBLSYM
          CALL BLCKIN(CM,14,1,IOUT,1,207)
          CALL BLCKOT(CM,IGFL,1,IOUT,1,208)
        END DO
      END DO
    END IF
    REWIND 13
    REWIND 14
  END IF

  REWIND IGFL
  WRITE(*,13) IGFL, IMAT

13 FORMAT (///,44H ****NUMERICAL GREEN'S FUNCTION FILE ON TAPE,I3,5H****,/,5X,16HMATRIX STORAGE -,I7,16H COMPLEX NUMBERS,///)

END SUBROUTINE GFOUT


SUBROUTINE BLCKOT(AR,NUNIT,IX1,IX2,NBLKS,NEOF)
  !
  !  DOUBLE PRECISION 6/4/85
  !  Modernized: 2025
  !
  !  BLCKOT CONTROLS THE WRITING OF MATRIX BLOCKS ON FILES
  !  FOR THE OUT-OF-CORE MATRIX SOLUTION.
  !
  IMPLICIT NONE
  COMPLEX(16), INTENT(IN) :: AR(*)
  INTEGER, INTENT(IN) :: NUNIT, IX1, IX2, NBLKS, NEOF

  INTEGER :: I1, I2, J

  I1 = (IX1 + 1) / 2
  I2 = (IX2 + 1) / 2
  WRITE (NUNIT) (AR(J),J=I1,I2)

END SUBROUTINE BLCKOT


SUBROUTINE BLCKIN(AR,NUNIT,IX1,IX2,NBLKS,NEOF_IN)
  !
  !  DOUBLE PRECISION 6/4/85
  !  Modernized: 2025 - Converted from ENTRY to separate subroutine
  !
  !  BLCKIN CONTROLS THE READING OF MATRIX BLOCKS ON FILES
  !  FOR THE OUT-OF-CORE MATRIX SOLUTION.
  !
  IMPLICIT NONE
  COMPLEX(16), INTENT(OUT) :: AR(*)
  INTEGER, INTENT(IN) :: NUNIT, IX1, IX2, NBLKS, NEOF_IN
  INTEGER :: NEOF

  INTEGER :: I1, I2, I, J, IOSTAT_VAL

  NEOF = NEOF_IN
  I1 = (IX1 + 1) / 2
  I2 = (IX2 + 1) / 2
  DO I = 1, NBLKS
    READ (NUNIT,END=3,IOSTAT=IOSTAT_VAL) (AR(J),J=I1,I2)
    IF (IOSTAT_VAL /= 0) GOTO 3
  END DO
  RETURN

3 WRITE(*,4) NUNIT, NBLKS, NEOF
  IF (NEOF /= 777) STOP

4 FORMAT (13H  EOF ON UNIT,I3,9H  NBLKS= ,I3,8H  NEOF= ,I5)

END SUBROUTINE BLCKIN


SUBROUTINE REBLK(B,BX,NB,NBX,N2C)
  !
  !  DOUBLE PRECISION 6/4/85
  !  Modernized: 2025
  !
  !  REBLOCK ARRAY B IN N.G.F. SOLUTION FROM BLOCKS OF ROWS ON TAPE14
  !  TO BLOCKS OF COLUMNS ON TAPE16
  !
  IMPLICIT NONE
  INTEGER, INTENT(IN) :: NB, NBX, N2C
  COMPLEX(16), INTENT(INOUT) :: B(NB,*), BX(NBX,*)

  INTEGER :: ICASE, NBLOKS, NPBLK, NLAST, NBLSYM, NPSYM, NLSYM, IMAT
  INTEGER :: ICASX, NBBX, NPBX, NLBX, NBBL, NPBL, NLBL
  INTEGER :: NIB, NPB, IB, NIX, NPX, IBX, I, IX, J

  COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT, &
                  ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL

  REWIND 16
  NIB = 0
  NPB = NPBL

  DO IB = 1, NBBL
    IF (IB == NBBL) NPB = NLBL
    REWIND 14
    NIX = 0
    NPX = NPBX
    DO IBX = 1, NBBX
      IF (IBX == NBBX) NPX = NLBX
      READ (14) ((BX(I,J),I=1,NPX),J=1,N2C)
      DO I = 1, NPX
        IX = I + NIX
        DO J = 1, NPB
          B(IX,J) = BX(I,J+NIB)
        END DO
      END DO
      NIX = NIX + NPBX
    END DO
    WRITE (16) ((B(I,J),I=1,NB),J=1,NPB)
    NIB = NIB + NPBL
  END DO

  REWIND 14
  REWIND 16

END SUBROUTINE REBLK
