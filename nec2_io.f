C     MODULE NEC2_IO
C     I/O utilities and helper routines for NEC2D
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
        subroutine stopwtch(cputot,walltot,cpusplt,wallsplt)
        use nec2_common
c
c       This routine operates as a stopwatch.
c       When first called, the routine initializes the clock.
c       On subsequent calls, the routine returns:
c
c       Outputs: cputot   -- elapsed CPU time since initialization
c                walltot  -- elapsed wallclock time since initialization
c                cpusplt  -- split (delta) CPU time since previous call
c                wallsplt -- split wallclock time since previous call
c
c       These outputs will all be zero (or very close to it) on the
c       first (initialization) call.
c
c       Internal times (cpuinit,wallinit,cpunow,wallnow) are stored in
c       seconds.  cpuinit  and cpunow  are stored as reals,
c                 wallinit and wallnow are stored as integers.
c       Output times are converted to real minutes.
c
c History:
c   Date       Author            Reason
c   ---------  ----------------  ------------------------------------
c    early-90  Scott L. Ray      initial version
c      mid-90  Scott L. Ray      support for additional machines
c   14-JAN-91                    ---- Version 2.2/release    ----
c   23-MAY-91  Scott L. Ray      UNICOS branch
c   29-JAN-92  Scott L. Ray      FPS and NLTSS support dropped
c   29-JAN-92  Scott L. Ray      switch to cpp conditional compilation
c   18-SEP-92      Conditional compilation disabled for use in NEC
c
c  (C) Copyright 1990, 1992.
c  The Regents of the University of California.  All rights reserved.
c ----------------------------------------------------------------------
c
c parameter list
c
        real cputot,walltot,cpusplt,wallsplt
c
c locals (non sysdep)
c
        logical initiz
        integer wallinit,walllast,wallnow
        real cpuinit,cpulast,cpunow
        save initiz,cpuinit,cpulast,wallinit,walllast
c
c locals (sysdep)
c
C#include "machines.h"
C#ifdef VAX_VMS
C        integer istatus,iwall,icpu
C        real rwall
C        dimension iwall(2)
C#endif
C#ifdef SUN4TIMER
        integer time
        real tarray
        dimension tarray(2)
C#endif
C#ifdef CONVEX
C        real time, secnds, tarray
C        dimension tarray(2)
C        external secnds
C#endif
C#ifdef IBM_RISC
c        integer icpu
c        integer mclock
C#endif
C#ifdef IRIS4D
C        external time
C#endif
C#ifdef STARDENT
C        integer stime
C        real tarray
C        dimension tarray(2)
C#endif
C#ifdef UNICOS
C        real rwall
C#endif
c
c data initialization
c
        data initiz/.false./
c
c ----------------------------------------------------------------------
c
        if (.not. initiz) then
c
c ...      set the flag showing that the clock has been initialized
c
           initiz = .true.
c
c ...      set the initial times to default value of zero.  These may
c          be changed, depending on how an individual machine handles
c          its timer.
c
           cpuinit  = 0.0
           wallinit = 0
c
c ...      initialize the timer (may not be necessary on all machines)
c
C#ifdef VAX_VMS
C           istatus = lib$init_timer()
C#endif
c
C#ifdef SUN4TIMER
c          CPU timer on SUN4 initializes automatically on job startup.
c          However, we want t=0 to be defined when this routine is first
c          called.  Hence, define initial CPU time here.
c          Wall clock timer counts in seconds from 1-Jan-70  Thus,
c          initial wall clock time is non-zero.  It is obtained here.
c 
           cpuinit  = etime(tarray)
           wallinit = time()
C#endif
c
C#ifdef CONVEX
C           cpuinit = etime(tarray)
C           time = secnds(0.0)
C           wallinit = ifix(time)
C#endif
c
C#ifdef IBM_RISC
c          no known wall clock timer
c
c           icpu = mclock( )
c           cpuinit  = float(icpu)/100.0
c           wallinit = 0
C#endif
c
C#ifdef STARDENT
c          CPU timer on STARDENT initializes automatically on job
c          startup.
c          However, we want t=0 to be defined when this routine is first
c          called.  Hence, define initial CPU time here.
c          Wall clock timer counts in seconds from 1-Jan-70  Thus,
c          initial wall clock time is non-zero.  It is obtained here.
c
C           cpuinit  = etime(tarray)
C           wallinit = stime()
C#endif
c
C#ifdef UNICOS
c          I hope that the "second" routine is true UNICOS and not a
c          local (LLNL) feature that was added on to keep things
c          consistent with NLTSS.
c          The "timef" routine returns real milliseconds; first
c          call initializes the timer and should return zero (not
c          that we care -- this routine works by taking differences).
c
C           call second(cpuinit)
C           call timef(rwall)
C           wallinit = ifix(rwall*1.0e-03)
C#endif
c
c ...      since this is the first call to this routine,
c          initialize the previous call times to the initial time.
c
           cpulast  =  cpuinit
           walllast = wallinit
c
        end if
c
c ...   Find the current cpu and wall times
c
C#ifdef HASTIMER
C#ifdef VAX_VMS
c
c       function "lib$stat_timer" is called as:
c       error_status = lib$stat_timer(input_code,output_result,junk)
c       where,
c        input_code = 1 returns elapsed wall clock time in VAX_VMS
c           binary internal format.  This format takes 64 bits to store,
c           hence output_result should be a 32 bit integer array of
c           length 2.
c           This internal format is converted to a floating point number
c           by calling "lib$cvtf_from_internal_time".  This function
c           is poorly documented in the VAX_VMS manuals.  Here are some
c           details:  First argument = 28 ==> result in real hours
c                                    = 29 ==> result in real minutes
c                                    = 30 ==> result in real seconds
c           The input to "lib$cvtf_from_internal_time" goes in the 3rd
c           argument, the result is returned in the 2nd argument.
c           input_code = 2 returns elapsed cpu time as an integer in
c           units of 10msec.  This is converted to seconds here.
c 
C        istatus = lib$stat_timer(1,iwall,)
C        istatus = lib$cvtf_from_internal_time(30,rwall,iwall)
C        wallnow = rwall
C        istatus = lib$stat_timer(2,icpu,)
C        cpunow = icpu*(10.0e-3)
C#endif
c
C#ifdef SUN4TIMER
c       there is some ambiguity in the manual as to how to use
c       etime.  Function returns:
c          "elapsed execution time" = tarray(1) + tarray(2)
c                                   = user time + system time
c       I am uncertain whether to let cpunow = return value or
c       else tarray(1).
c
        cpunow  = etime(tarray)
        wallnow = time()
C#endif
c
C#ifdef CONVEX
C           cpunow = etime(tarray)
C           time = secnds(0.0)
C           wallnow = ifix(time)
C#endif
c
C#ifdef IBM_RISC
c       no known wall clock timer
c
c        icpu = mclock( )
c        cpunow  = float(icpu)/100.0
c        wallnow = 0
C#endif
c
C#ifdef STARDENT
c       there is some ambiguity in the manual as to how to use
c       etime.  Function returns:
c          "elapsed execution time" = tarray(1) + tarray(2)
c                                   = user time + system time
c       I am uncertain whether to let cpunow = return value or
c       else tarray(1).
c 
C        cpunow  = etime(tarray)
C        wallnow = stime()
C#endif
c
C#ifdef UNICOS
c       I hope that the "second" routine is true UNICOS and not a
c       local (LLNL) feature that was added on to keep things
c       consistent with NLTSS.
c       The "timef" routine returns real milliseconds.
c
C        call second(cpunow)
C        call timef(rwall)
C        wallnow = ifix(rwall*1.0e-03)
C#endif
C#else
c       for machines without timers or with unknown timers,
c       set things to zero now to ensure that something is returned
C        cpunow  = 0.0
C        wallnow = 0
C#endif
c
c ...   calculate elapsed and split cpu and wall clock times,
c       convert to minutes on output.
c
        cputot   = (cpunow  - cpuinit )/60.0
        walltot  = float(wallnow - wallinit)/60.0
        cpusplt  = (cpunow  - cpulast )/60.0
        wallsplt = float(wallnow - walllast)/60.0
c
c ...   save "now" times in "last" times
c
        cpulast  = cpunow
        walllast = wallnow
c
        return
c **********************************************************************
        end
      SUBROUTINE GFIL (IPRT)
      USE NEC2_COMMON
C ***
C     DOUBLE PRECISION 6/4/85
C
C     INCLUDE/PARAMETER now from USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     GFIL READS THE N.G.F. FILE
C
C     Local COMMON block declarations
      COMPLEX*16 CM,SSX,ZARRAY,AR1,AR2,AR3,EPSCF
      CHARACTER NGFNAM*80
      COMMON /CMB/CM(IRESRV)
      COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG),
     1ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG),
     2ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
      COMMON /SMAT/ SSX(16,16)
      COMMON /ANGL/ SALP(MAXSEG)
      COMMON /ZLOAD/ ZARRAY(MAXSEG),NLOAD,NLODF
      COMMON/SAVE/EPSR,SIG,SCRWLT,SCRWRT,FMHZ,IP(2*MAXSEG),KCOM
      COMMON/CSAVE/COM(19,5)
      COMMON /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL,
     1KSYMP,IFAR,IPERF
      COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,
     1ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
      COMMON /GGRID/ AR1(11,10,4),AR2(17,5,4),AR3(9,8,4),EPSCF,DXA(3),
     1DYA(3),XSA(3),YSA(3),NXA(3),NYA(3)
      COMMON /NGFNAM/NGFNAM
C
C*** ERROR CORRECTED 11/20/89 *******************************
      DIMENSION T2X(1),T2Y(1),T2Z(1)
      EQUIVALENCE (T2X,ICON1),(T2Y,ICON2),(T2Z,ITAG)
C***
      DATA IGFL/20/
      OPEN(UNIT=IGFL,FILE=NGFNAM,FORM='UNFORMATTED',STATUS='OLD',ERR=30)
      GO TO 31
30    STOP
31    REWIND IGFL
      READ (IGFL) N1,NP,M1,MP,WLAM,FMHZ,IPSYM,KSYMP,IPERF,NRADL,EPSR,SIG
     1,SCRWLT,SCRWRT,NLODF,KCOM
      N=N1
      M=M1
      N2=N1+1
      M2=M1+1
      IF (N1.EQ.0) GO TO 2
C     READ SEG. DATA AND CONVERT BACK TO END COORD. IN UNITS OF METERS
      READ (IGFL) (X(I),I=1,N1),(Y(I),I=1,N1),(Z(I),I=1,N1)
      READ (IGFL) (SI(I),I=1,N1),(BI(I),I=1,N1),(ALP(I),I=1,N1)
      READ (IGFL) (BET(I),I=1,N1),(SALP(I),I=1,N1)
      READ (IGFL) (ICON1(I),I=1,N1),(ICON2(I),I=1,N1)
      READ (IGFL) (ITAG(I),I=1,N1)
      IF (NLODF.NE.0) READ (IGFL) (ZARRAY(I),I=1,N1)
      DO 1 I=1,N1
      XI=X(I)*WLAM
      YI=Y(I)*WLAM
      ZI=Z(I)*WLAM
      DX=SI(I)*.5*WLAM
      X(I)=XI-ALP(I)*DX
      Y(I)=YI-BET(I)*DX
      Z(I)=ZI-SALP(I)*DX
      SI(I)=XI+ALP(I)*DX
      ALP(I)=YI+BET(I)*DX
      BET(I)=ZI+SALP(I)*DX
      BI(I)=BI(I)*WLAM
1     CONTINUE
2     IF (M1.EQ.0) GO TO 4
      J=LD-M1+1
C     READ PATCH DATA AND CONVERT TO METERS
      READ (IGFL) (X(I),I=J,LD),(Y(I),I=J,LD),(Z(I),I=J,LD)
      READ (IGFL) (SI(I),I=J,LD),(BI(I),I=J,LD),(ALP(I),I=J,LD)
      READ (IGFL) (BET(I),I=J,LD),(SALP(I),I=J,LD)
C*** ERROR CORRECTED 11/20/89 *******************************
      READ (IGFL) (T2X(I),I=J,LD),(T2Y(I),I=J,LD)
      READ (IGFL) (T2Z(I),I=J,LD)
C      READ (IGFL) (ICON1(I),I=J,LD),(ICON2(I),I=J,LD)
C      READ (IGFL) (ITAG(I),I=J,LD)
C
      DX=WLAM*WLAM
      DO 3 I=J,LD
      X(I)=X(I)*WLAM
      Y(I)=Y(I)*WLAM
      Z(I)=Z(I)*WLAM
3     BI(I)=BI(I)*DX
4     READ (IGFL) ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT
      IF (IPERF.EQ.2) READ (IGFL) AR1,AR2,AR3,EPSCF,DXA,DYA,XSA,YSA,NXA,
     1NYA
      NEQ=N1+2*M1
      NPEQ=NP+2*MP
      NOP=NEQ/NPEQ
      IF (NOP.GT.1) READ (IGFL) ((SSX(I,J),I=1,NOP),J=1,NOP)
      READ (IGFL) (IP(I),I=1,NEQ),COM
C     READ MATRIX A AND WRITE TAPE13 FOR OUT OF CORE
      IF (ICASE.GT.2) GO TO 5
      IOUT=NEQ*NPEQ
      READ (IGFL) (CM(I),I=1,IOUT)
      GO TO 10
5     REWIND 13
      IF (ICASE.NE.4) GO TO 7
      IOUT=NPEQ*NPEQ
      DO 6 K=1,NOP
      READ (IGFL) (CM(J),J=1,IOUT)
6     WRITE (13) (CM(J),J=1,IOUT)
      GO TO 9
7     IOUT=NPSYM*NPEQ*2
      NBL2=2*NBLSYM
      DO 8 IOP=1,NOP
      DO 8 I=1,NBL2
      CALL BLCKIN (CM,IGFL,1,IOUT,1,206)
8     CALL BLCKOT (CM,13,1,IOUT,1,205)
9     REWIND 13
10    REWIND IGFL
C     WRITE(*,N) G.F. HEADING
      WRITE(*,16)
      WRITE(*,14)
      WRITE(*,14)
      WRITE(*,17)
      WRITE(*,18)  N1,M1
      IF (NOP.GT.1) WRITE(*,19)  NOP
      WRITE(*,20)  IMAT,ICASE
      IF (ICASE.LT.3) GO TO 11
      NBL2=NEQ*NPEQ
      WRITE(*,21)  NBL2
11    WRITE(*,22)  FMHZ
      IF (KSYMP.EQ.2.AND.IPERF.EQ.1) WRITE(*,23)
      IF (KSYMP.EQ.2.AND.IPERF.EQ.0) WRITE(*,27)
      IF (KSYMP.EQ.2.AND.IPERF.EQ.2) WRITE(*,28)
      IF (KSYMP.EQ.2.AND.IPERF.NE.1) WRITE(*,24)  EPSR,SIG
      WRITE(*,17)
      DO 12 J=1,KCOM
12    WRITE(*,15)  (COM(I,J),I=1,19)
      WRITE(*,17)
      WRITE(*,14)
      WRITE(*,14)
      WRITE(*,16)
      IF (IPRT.EQ.0) RETURN
      WRITE(*,25)
      DO 13 I=1,N1
13    WRITE(*,26)  I,X(I),Y(I),Z(I),SI(I),ALP(I),BET(I)
      RETURN
C
14    FORMAT (5X,50H**************************************************,
     134H**********************************)
15    FORMAT (5X,3H** ,19A4,3H **)
16    FORMAT (////)
17    FORMAT (5X,2H**,80X,2H**)
18    FORMAT (5X,29H** NUMERICAL GREEN'S FUNCTION,53X,2H**,/,5X,17H** NO
     1. SEGMENTS =,I4,10X,13HNO. PATCHES =,I4,34X,2H**)
19    FORMAT (5X,27H** NO. SYMMETRIC SECTIONS =,I4,51X,2H**)
20    FORMAT (5X,34H** N.G.F. MATRIX -  CORE STORAGE =,I7,23H COMPLEX NU
     1MBERS,  CASE,I2,16X,2H**)
21    FORMAT (5X,2H**,19X,13HMATRIX SIZE =,I7,16H COMPLEX NUMBERS,25X,2H
     1**)
22    FORMAT (5X,14H** FREQUENCY =,1P,E12.5,5H MHZ.,51X,2H**)
23    FORMAT (5X,17H** PERFECT GROUND,65X,2H**)
24    FORMAT (5X,44H** GROUND PARAMETERS - DIELECTRIC CONSTANT =,1P,
     1E12.5,26X,2H**,/,5X,2H**,21X,14HCONDUCTIVITY =,E12.5,8H MHOS/M.,
     225X,2H**)
25    FORMAT (39X,31HNUMERICAL GREEN'S FUNCTION DATA,/,41X,27HCOORDINATE
     1S OF SEGMENT ENDS,/,51X,8H(METERS),/,5X,4HSEG.,11X,19H- - - END ON
     2E - - -,26X,19H- - - END TWO - - -,/,6X,3HNO.,6X,1HX,14X,1HY,14X,1
     3HZ,14X,1HX,14X,1HY,14X,1HZ)
26    FORMAT (1X,I7,1P,6E15.6)
27    FORMAT (5X,55H** FINITE GROUND.  REFLECTION COEFFICIENT APPROXIMAT
     1ION,27X,2H**)
28    FORMAT (5X,38H** FINITE GROUND.  SOMMERFELD SOLUTION,44X,2H**)
      END
      SUBROUTINE GFOUT
      USE NEC2_COMMON
C ***
C     DOUBLE PRECISION 6/4/85
C
C     INCLUDE/PARAMETER now from USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     WRITE N.G.F. FILE
C
C     Local COMMON block declarations
      COMPLEX*16 CM,SSX,ZARRAY,AR1,AR2,AR3,EPSCF
      CHARACTER NGFNAM*80
      COMMON /CMB/CM(IRESRV)
      COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG),
     1ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG),
     2ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
      COMMON /SMAT/ SSX(16,16)
      COMMON /ANGL/ SALP(MAXSEG)
      COMMON /ZLOAD/ ZARRAY(MAXSEG),NLOAD,NLODF
      COMMON/SAVE/EPSR,SIG,SCRWLT,SCRWRT,FMHZ,IP(2*MAXSEG),KCOM
      COMMON/CSAVE/COM(19,5)
      COMMON /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL,
     1KSYMP,IFAR,IPERF
      COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,
     1ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
      COMMON /GGRID/ AR1(11,10,4),AR2(17,5,4),AR3(9,8,4),EPSCF,DXA(3),
     1DYA(3),XSA(3),YSA(3),NXA(3),NYA(3)
      COMMON /NGFNAM/NGFNAM
C
C*** ERROR CORRECTED 11/20/89 *******************************
      DIMENSION T2X(1),T2Y(1),T2Z(1)
      EQUIVALENCE (T2X,ICON1),(T2Y,ICON2),(T2Z,ITAG)
C***
      DATA IGFL/20/
      OPEN(UNIT=IGFL,FILE=NGFNAM,FORM='UNFORMATTED',STATUS='UNKNOWN')
      NEQ=N+2*M
      NPEQ=NP+2*MP
      NOP=NEQ/NPEQ
      WRITE (IGFL) N,NP,M,MP,WLAM,FMHZ,IPSYM,KSYMP,IPERF,NRADL,EPSR,
     1SIG,SCRWLT,SCRWRT,NLOAD,KCOM
      IF (N.EQ.0) GO TO 1
      WRITE (IGFL) (X(I),I=1,N),(Y(I),I=1,N),(Z(I),I=1,N)
      WRITE (IGFL) (SI(I),I=1,N),(BI(I),I=1,N),(ALP(I),I=1,N)
      WRITE (IGFL) (BET(I),I=1,N),(SALP(I),I=1,N)
      WRITE (IGFL) (ICON1(I),I=1,N),(ICON2(I),I=1,N)
      WRITE (IGFL) (ITAG(I),I=1,N)
      IF (NLOAD.GT.0) WRITE (IGFL) (ZARRAY(I),I=1,N)
1     IF (M.EQ.0) GO TO 2
      J=LD-M+1
      WRITE (IGFL) (X(I),I=J,LD),(Y(I),I=J,LD),(Z(I),I=J,LD)
      WRITE (IGFL) (SI(I),I=J,LD),(BI(I),I=J,LD),(ALP(I),I=J,LD)
      WRITE (IGFL) (BET(I),I=J,LD),(SALP(I),I=J,LD)
C
C*** ERROR CORRECTED 11/20/89 *******************************
                                                             
      WRITE (IGFL) (T2X(I),I=J,LD),(T2Y(I),I=J,LD)
      WRITE (IGFL) (T2Z(I),I=J,LD)
C      WRITE (IGFL) (ICON1(I),I=J,LD),(ICON2(I),I=J,LD)
C      WRITE (IGFL) (ITAG(I),I=J,LD)
C
2     WRITE (IGFL) ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT
      IF (IPERF.EQ.2) WRITE (IGFL) AR1,AR2,AR3,EPSCF,DXA,DYA,XSA,YSA,NXA
     1,NYA
      IF (NOP.GT.1) WRITE (IGFL) ((SSX(I,J),I=1,NOP),J=1,NOP)
      WRITE (IGFL) (IP(I),I=1,NEQ),COM
      IF (ICASE.GT.2) GO TO 3
      IOUT=NEQ*NPEQ
      WRITE (IGFL) (CM(I),I=1,IOUT)
      GO TO 12
3     IF (ICASE.NE.4) GO TO 5
      REWIND 13
      I=NPEQ*NPEQ
      DO 4 K=1,NOP
      READ (13) (CM(J),J=1,I)
4     WRITE (IGFL) (CM(J),J=1,I)
      REWIND 13
      GO TO 12
5     REWIND 13
      REWIND 14
      IF (ICASE.EQ.5) GO TO 8
      IOUT=NPBLK*NEQ*2
      DO 6 I=1,NBLOKS
      CALL BLCKIN (CM,13,1,IOUT,1,201)
6     CALL BLCKOT (CM,IGFL,1,IOUT,1,202)
      DO 7 I=1,NBLOKS
      CALL BLCKIN (CM,14,1,IOUT,1,203)
7     CALL BLCKOT (CM,IGFL,1,IOUT,1,204)
      GO TO 12
8     IOUT=NPSYM*NPEQ*2
      DO 11 IOP=1,NOP
      DO 9 I=1,NBLSYM
      CALL BLCKIN (CM,13,1,IOUT,1,205)
9     CALL BLCKOT (CM,IGFL,1,IOUT,1,206)
      DO 10 I=1,NBLSYM
      CALL BLCKIN (CM,14,1,IOUT,1,207)
10    CALL BLCKOT (CM,IGFL,1,IOUT,1,208)
11    CONTINUE
      REWIND 13
      REWIND 14
12    REWIND IGFL
      WRITE(*,13)  IGFL,IMAT
      RETURN
C
13    FORMAT (///,44H ****NUMERICAL GREEN'S FUNCTION FILE ON TAPE,I3,5H
     1****,/,5X,16HMATRIX STORAGE -,I7,16H COMPLEX NUMBERS,///)
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
C

