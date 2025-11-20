C     IO_UTILS.F - I/O utilities and helper routines for NEC2D
C     This file contains block I/O routines, parsing utilities, file operations,
C     and mathematical helper functions including BLCKOT/BLCKIN, PRNT, READGM,
C     READMN, UPCASE, CPUSEC, ATGN2, CANG, DB10, and ENF.
C
      MODULE NEC2_IO
      USE NEC2_COMMON
      END MODULE NEC2_IO
C
      SUBROUTINE BLCKOT (AR,NUNIT,IX1,IX2,NBLKS,NEOF)
C ***
C     DOUBLE PRECISION 6/4/85
C
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     BLCKOT CONTROLS THE READING AND WRITING OF MATRIX BLOCKS ON FILES
C     FOR THE OUT-OF-CORE MATRIX SOLUTION.
C
C      LOGICAL ENF
      COMPLEX*16 AR
      DIMENSION AR(1)
      I1=(IX1+1)/2
      I2=(IX2+1)/2
1     WRITE (NUNIT) (AR(J),J=I1,I2)
      RETURN
      ENTRY BLCKIN(AR,NUNIT,IX1,IX2,NBLKS,NEOF)
      I1=(IX1+1)/2
      I2=(IX2+1)/2
      DO 2 I=1,NBLKS
      READ (NUNIT,END=3) (AR(J),J=I1,I2)
C     IF (ENF(NUNIT)) GO TO 3
2     CONTINUE
      RETURN
3     WRITE(*,4)  NUNIT,NBLKS,NEOF
      IF (NEOF.NE.777) STOP
      NEOF=0
      RETURN
C
4     FORMAT (13H  EOF ON UNIT,I3,9H  NBLKS= ,I3,8H  NEOF= ,I5)
      END
      SUBROUTINE PRNT(IN1,IN2,IN3,FL1,FL2,FL3,FL4,FL5,FL6,CTYPE)
C
C     Purpose:
C     PRNT prints the input data for impedance loading, inserting blanks
C     for numbers that are zero.
C
C     INPUT:
C     IN1-3 = INTEGER VALUES TO BE PRINTED
C     FL1-6 = REAL VALUES TO BE PRINTED
C     CTYPE = CHARACTER STRING TO BE PRINTED
C
      IMPLICIT REAL*8(A-H,O-Z)
      CHARACTER CTYPE*(*), CINT(3)*5, CFLT(6)*13
C
      DO 1 I=1,3
1     CINT(I)='     '
      IF(IN1.EQ.0.AND.IN2.EQ.0.AND.IN3.EQ.0)THEN
         CINT(1)='  ALL'
      ELSE
         IF(IN1.NE.0)WRITE(CINT(1),90)IN1
         IF(IN2.NE.0)WRITE(CINT(2),90)IN2
         IF(IN3.NE.0)WRITE(CINT(3),90)IN3
      END IF
      DO 2 I=1,6
2     CFLT(I)='     '
      IF(ABS(FL1).GT.1.E-30)WRITE(CFLT(1),91)FL1
      IF(ABS(FL2).GT.1.E-30)WRITE(CFLT(2),91)FL2
      IF(ABS(FL3).GT.1.E-30)WRITE(CFLT(3),91)FL3
      IF(ABS(FL4).GT.1.E-30)WRITE(CFLT(4),91)FL4
      IF(ABS(FL5).GT.1.E-30)WRITE(CFLT(5),91)FL5
      IF(ABS(FL6).GT.1.E-30)WRITE(CFLT(6),91)FL6
      WRITE(*,92)(CINT(I),I=1,3),(CFLT(I),I=1,6),CTYPE
      RETURN
C
90    FORMAT(I5)
91    FORMAT(1P,E13.4)
92    FORMAT(/,3X,3A,3X,6A,3X,A)
      END
      SUBROUTINE READGM(INUNIT,CODE,I1,I2,R1,R2,R3,R4,R5,R6,R7)
C
C  READGM reads a geometry record and parses it.
C
C  *****  Passed variables
C     CODE        two letter mnemonic code
C     I1 - I2     integer values from record
C     R1 - R7     real values from record
C
      IMPLICIT REAL*8(A-H,O-Z)
      CHARACTER*(*) CODE
      DIMENSION INTVAL(2),REAVAL(7)
C
C  Call the routine to read the record and parse it.
C
      CALL PARSIT(INUNIT,2,7,CODE,INTVAL,REAVAL,IEOF)
C
C  Set the return variables to the buffer array elements.
C
      IF(IEOF.LT.0)CODE='GE'
      I1=INTVAL(1)
      I2=INTVAL(2)
      R1=REAVAL(1)
      R2=REAVAL(2)
      R3=REAVAL(3)
      R4=REAVAL(4)
      R5=REAVAL(5)
      R6=REAVAL(6)
      R7=REAVAL(7)
      RETURN
      END
      SUBROUTINE READMN(INUNIT,CODE,I1,I2,I3,I4,F1,F2,F3,F4,F5,F6)
C
C  READMN reads a control record and parses it.
C
      IMPLICIT REAL*8(A-H,O-Z)
      CHARACTER*(*) CODE
      DIMENSION INTVAL(4),REAVAL(6)
C
C  Call the routine to read the record and parse it.
C
      CALL PARSIT(INUNIT,4,6,CODE,INTVAL,REAVAL,IEOF)
C
C  Set the return variables to the buffer array elements.
      IF(IEOF.LT.0)CODE='EN'
      I1=INTVAL(1)
      I2=INTVAL(2)
      I3=INTVAL(3)
      I4=INTVAL(4)
      F1=REAVAL(1)
      F2=REAVAL(2)
      F3=REAVAL(3)
      F4=REAVAL(4)
      F5=REAVAL(5)
      F6=REAVAL(6)
      RETURN
      END
      SUBROUTINE UPCASE( INTEXT, OUTTXT, LENGTH )
C
C  UPCASE finds the length of INTEXT and converts it to upper case.
C
        CHARACTER *(*) INTEXT, OUTTXT
C
C
        LENGTH = LEN( INTEXT )
        DO 3000 I=1,LENGTH
             J  = ICHAR( INTEXT(I:I) )
             IF (J .GE. 96) J = J - 32
             OUTTXT(I:I) = CHAR( J )
 3000   CONTINUE
        RETURN
        END
      SUBROUTINE CPUSEC (CPUSECD)
      USE NEC2_COMMON
C
C     Purpose:
C     CPUSEC returns cpu time in seconds.  Must be customized!!!
C
C     VAX or other (modify subroutine stopwtch):
C
      REAL*8 CPUSECD
      CALL STOPWTCH(CPUSECS,WALLTOT,CPUSPLT,WALLSPLT)
      CPUSECD=60.*CPUSECS
C     MACINTOSH:
C      CPUSECD= LONG(362)/60.0
      RETURN
      END
C
      FUNCTION ATGN2 (X,Y)
C ***
C     DOUBLE PRECISION 6/4/85
C
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     ATGN2 IS ARCTANGENT FUNCTION MODIFIED TO RETURN 0. WHEN X=Y=0.
C
      IF (X) 3,1,3
1     IF (Y) 3,2,3
2     ATGN2=0.
      RETURN
3     ATGN2=ATAN2(X,Y)
      RETURN
      END
      FUNCTION CANG (Z)
C ***
C     DOUBLE PRECISION 6/4/85
C
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     CANG RETURNS THE PHASE ANGLE OF A COMPLEX NUMBER IN DEGREES.
C
      COMPLEX*16 Z
      CANG=ATGN2(DIMAG(Z),DREAL(Z))*57.29577951D+0
      RETURN
      END
      FUNCTION DB10 (X)
C ***
C     DOUBLE PRECISION 6/4/85
C
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     FUNCTION DB-- RETURNS DB FOR MAGNITUDE (FIELD) OR MAG**2 (POWER) I
C
      F=10.
      GO TO 1
      ENTRY DB20(X)
      F=20.
1     IF (X.LT.1.D-20) GO TO 2
      DB10=F*LOG10(X)
      RETURN
2     DB10=-999.99
      RETURN
      END
      LOGICAL FUNCTION ENF(NUNIT)
C ***
C     DOUBLE PRECISION 6/4/85
C
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C*********** THIS ROUTINE NOT USED ON VAX **************
C     IF (EOF,NUNIT) 1,2
1     ENF=.TRUE.
      RETURN
2     ENF=.FALSE.
      RETURN
      END
