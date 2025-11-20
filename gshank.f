C     GSHANK.F - Sommerfeld integral integration with Shank's algorithm
C     Integrates the 6 Sommerfeld integrals from START to infinity
C     (until convergence) in LAMBDA. At the break point, BK, the step
C     increment may be changed from DELA to DELB. Shank's algorithm to
C     accelerate convergence of a slowly converging series is used.
C
      SUBROUTINE GSHANK (START,DELA,SUM,NANS,SEED,IBK,BK,DELB)
C
C     GSHANK INTEGRATES THE 6 SOMMERFELD INTEGRALS FROM START TO
C     INFINITY (UNTIL CONVERGENCE) IN LAMBDA.  AT THE BREAK POINT, BK,
C     THE STEP INCREMENT MAY BE CHANGED FROM DELA TO DELB.  SHANK S
C     ALGORITHM TO ACCELERATE CONVERGENCE OF A SLOWLY CONVERGING SERIES
C     IS USED
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
      SAVE
      COMPLEX*16 START,DELA,SUM,SEED,BK,DELB,A,B,Q1,Q2,ANS1,ANS2,A1,A2,
     1AS1,AS2,DEL,AA
      COMMON /CNTOUR/ A,B
      DIMENSION Q1(6,20), Q2(6,20), ANS1(6), ANS2(6), SUM(6), SEED(6)
      DATA CRIT/1.E-4/,MAXH/20/
      RBK=DREAL(BK)
      DEL=DELA
      IBX=0
      IF (IBK.EQ.0) IBX=1
      DO 1 I=1,NANS
1     ANS2(I)=SEED(I)
      B=START
2     DO 20 INT=1,MAXH
      INX=INT
      A=B
      B=B+DEL
      IF (IBX.EQ.0.AND.DREAL(B).GE.RBK) GO TO 5
      CALL ROM1 (NANS,SUM,2)
      DO 3 I=1,NANS
3     ANS1(I)=ANS2(I)+SUM(I)
      A=B
      B=B+DEL
      IF (IBX.EQ.0.AND.DREAL(B).GE.RBK) GO TO 6
      CALL ROM1 (NANS,SUM,2)
      DO 4 I=1,NANS
4     ANS2(I)=ANS1(I)+SUM(I)
      GO TO 11
C     HIT BREAK POINT.  RESET SEED AND START OVER.
5     IBX=1
      GO TO 7
6     IBX=2
7     B=BK
      DEL=DELB
      CALL ROM1 (NANS,SUM,2)
      IF (IBX.EQ.2) GO TO 9
      DO 8 I=1,NANS
8     ANS2(I)=ANS2(I)+SUM(I)
      GO TO 2
9     DO 10 I=1,NANS
10    ANS2(I)=ANS1(I)+SUM(I)
      GO TO 2
11    DEN=0.
      DO 18 I=1,NANS
      AS1=ANS1(I)
      AS2=ANS2(I)
      IF (INT.LT.2) GO TO 17
      DO 16 J=2,INT
      JM=J-1
      AA=Q2(I,JM)
      A1=Q1(I,JM)+AS1-2.*AA
      IF (DREAL(A1).EQ.0..AND.DIMAG(A1).EQ.0.) GO TO 12
      A2=AA-Q1(I,JM)
      A1=Q1(I,JM)-A2*A2/A1
      GO TO 13
12    A1=Q1(I,JM)
13    A2=AA+AS2-2.*AS1
      IF (DREAL(A2).EQ.0..AND.DIMAG(A2).EQ.0.) GO TO 14
      A2=AA-(AS1-AA)*(AS1-AA)/A2
      GO TO 15
14    A2=AA
15    Q1(I,JM)=AS1
      Q2(I,JM)=AS2
      AS1=A1
16    AS2=A2
17    Q1(I,INT)=AS1
      Q2(I,INT)=AS2
      AMG=ABS(DREAL(AS2))+ABS(DIMAG(AS2))
      IF (AMG.GT.DEN) DEN=AMG
18    CONTINUE
      DENM=1.E-3*DEN*CRIT
      JM=INT-3
      IF (JM.LT.1) JM=1
      DO 19 J=JM,INT
      DO 19 I=1,NANS
      A1=Q2(I,J)
      DEN=(ABS(DREAL(A1))+ABS(DIMAG(A1)))*CRIT
      IF (DEN.LT.DENM) DEN=DENM
      A1=Q1(I,J)-A1
      AMG=ABS(DREAL(A1))+ABS(DIMAG(A1))
      IF (AMG.GT.DEN) GO TO 20
19    CONTINUE
      GO TO 22
20    CONTINUE
      WRITE(*,24)
      DO 21 I=1,NANS
21    WRITE(*,25) Q1(I,INX),Q2(I,INX)
22    DO 23 I=1,NANS
23    SUM(I)=.5*(Q1(I,INX)+Q2(I,INX))
      RETURN
C
24    FORMAT (46H **** NO CONVERGENCE IN SUBROUTINE GSHANK ****)
25    FORMAT (1X,1P10E12.5)
      END
