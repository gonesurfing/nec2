C     PARSIT.F - Input record parser for NEC2D
C     Parses input records, extracting opcode, integer and real values.
C     Called by READGM and READMN for geometry and control records.
C
      SUBROUTINE PARSIT(INUNIT,MAXINT,MAXREA,CMND,INTFLD,REAFLD,IEOF)
      USE NEC2_COMMON

C  UPDATED:  21 July 87

C  Called by:   READGM    READMN

C  PARSIT reads an input record and parses it.

C  *****  Passed variables
C     MAXINT     total number of integers in record
C     MAXREA     total number of real values in record
C     CMND       two letter mnemonic code
C     INTFLD     integer values from record
C     REAFLD     real values from record

C  *****  Internal Variables
C     BGNFLD     list of starting indices
C     BUFFER     text buffer
C     ENDFLD     list of ending indices
C     FLDTRM     flag to indicate that pointer is in field position
C     REC        input line as read
C     TOTCOL     total number of columns in REC
C     TOTFLD     number of numeric fields
      IMPLICIT REAL*8(A-H,O-Z)
C     Local COMMON block declaration
      CHARACTER NGFNAM*80
      COMMON /NGFNAM/NGFNAM
      CHARACTER  CMND*2, BUFFER*20, REC*80
      INTEGER    INTFLD(MAXINT)
      INTEGER    BGNFLD(12), ENDFLD(12), TOTCOL, TOTFLD
      LOGICAL    FLDTRM
      DIMENSION  REAFLD(MAXREA)
C
      READ(INUNIT, 8000, IOSTAT=IEOF) REC
      CALL UPCASE( REC, REC, TOTCOL )
C
C  Store opcode and clear field arrays.
C
      CMND= REC(1:2)
      DO 3000 I=1,MAXINT
           INTFLD(I)= 0
 3000 CONTINUE
      DO 3010 I=1,MAXREA
           REAFLD(I)= 0.0
 3010 CONTINUE
      DO 3020 I=1,12
           BGNFLD(I)= 0
           ENDFLD(I)= 0
 3020 CONTINUE
C
C  Find the beginning and ending of each field as well as the total number of
C  fields.
C
      TOTFLD= 0
      FLDTRM= .FALSE.
      LAST= MAXREA + MAXINT
      DO 4000 J=3,TOTCOL
           K= ICHAR( REC(J:J) )
C
C  Check for end of line comment (`!').  This is a new modification to allow
C  VAX-like comments at the end of data records, i.e.
C       GW 1 7 0 0 0 0 0 .5 .0001 ! DIPOLE WIRE
C       GE ! END OF GEOMETRY
C
      IF (K .EQ. 33) THEN
         IF (FLDTRM) ENDFLD(TOTFLD)= J - 1
         GO TO 5000
C
C  Set the ending index when the character is a comma or space and the pointer
C  is in a field position (FLDTRM = .TRUE.).
C
          ELSE IF (K .EQ. 32  .OR.  K .EQ. 44) THEN
             IF (FLDTRM) THEN
                ENDFLD(TOTFLD)= J - 1
                FLDTRM= .FALSE.
             ENDIF
C
C  Set the beginning index when the character is not a comma or space and the
C  pointer is not currently in a field position (FLDTRM = .FALSE).
C
          ELSE IF (.NOT. FLDTRM) THEN
              TOTFLD= TOTFLD + 1
              FLDTRM= .TRUE.
              BGNFLD(TOTFLD)= J
          ENDIF
 4000   CONTINUE
        IF (FLDTRM) ENDFLD(TOTFLD)= TOTCOL

C  Check to see if the total number of value fields is within the precribed
C  limits.

 5000   IF ((CMND .EQ. 'WG').OR.(CMND .EQ. 'GF')) THEN
           NGFNAM='NGF2D.NEC'
        END IF
        IF (TOTFLD .EQ. 0) THEN
             RETURN
        ELSE IF (TOTFLD .GT. LAST) THEN
             WRITE(*, 8001 )
             GOTO 9010
        ENDIF
        J= MIN( TOTFLD, MAXINT )

C  Parse out integer values and store into integer buffer array.

        DO 5090 I=1,J
             LENGTH= ENDFLD(I) - BGNFLD(I) + 1
             BUFFER= REC(BGNFLD(I):ENDFLD(I))
             IF (((CMND .EQ. 'WG').OR.(CMND .EQ. 'GF')).AND.
     1           (BUFFER(1:1) .NE. '0').AND.(BUFFER(1:1) .NE. '1')) THEN
                NGFNAM= REC(BGNFLD(I):ENDFLD(I))
                RETURN
             END IF
             IND= INDEX( BUFFER(1:LENGTH), '.' )
             IF (IND .GT. 0  .AND.  IND .LT. LENGTH) GO TO 9000
             IF (IND .EQ. LENGTH) LENGTH= LENGTH - 1
             READ( BUFFER(1:LENGTH), *, ERR=9000 ) INTFLD(I)
 5090   CONTINUE

C  Parse out real values and store into real buffer array.

        IF (TOTFLD .GT. MAXINT) THEN
             J= MAXINT + 1
             DO 6000 I=J,TOTFLD
                  LENGTH= ENDFLD(I) - BGNFLD(I) + 1
                  BUFFER= REC(BGNFLD(I):ENDFLD(I))
                  IND= INDEX( BUFFER(1:LENGTH), '.' )
                  IF (IND .EQ. 0) THEN
                       INDE= INDEX( BUFFER(1:LENGTH), 'E' )
                       LENGTH= LENGTH + 1
                       IF (INDE .EQ. 0) THEN
                            BUFFER(LENGTH:LENGTH)= '.'
                       ELSE
                            BUFFER= BUFFER(1:INDE-1)//'.'//
     1                               BUFFER(INDE:LENGTH-1)
                       ENDIF
                  ENDIF
                  READ( BUFFER(1:LENGTH), *, ERR=9000 ) REAFLD(I-MAXINT)
 6000        CONTINUE
        ENDIF
        RETURN

C  Print out text of record line when error occurs.

 9000   IF (I .LE. MAXINT) THEN
             WRITE(*, 8002 ) I
        ELSE
             I= I - MAXINT
             WRITE(*, 8003 ) I
        ENDIF
 9010   WRITE(*, 8004 ) REC
        STOP 'CARD ERROR'
C
C  Input formats and output messages.
C
 8000   FORMAT (A80)
 8001   FORMAT (//,' ***** CARD ERROR - TOO MANY FIELDS IN RECORD')
 8002   FORMAT (//,' ***** CARD ERROR - INVALID NUMBER AT INTEGER',
     1          ' POSITION ',I1)
 8003   FORMAT (//,' ***** CARD ERROR - INVALID NUMBER AT REAL',
     1          ' POSITION ',I1)
 8004   FORMAT (' ***** TEXT -->  ',A80)
        END
