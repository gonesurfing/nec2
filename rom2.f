C     ROM2.F - Sommerfeld ground integration over source segment
C     For the Sommerfeld ground option, ROM2 integrates over the source
C     segment to obtain the total field due to ground. The method of
C     variable interval width Romberg integration is used. There are 9
C     field components - the X, Y, and Z components due to constant,
C     sine, and cosine current distributions.
C
      SUBROUTINE ROM2 (A,B,SUM,DMIN)
C ***
C     DOUBLE PRECISION 6/4/85
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     FOR THE SOMMERFELD GROUND OPTION, ROM2 INTEGRATES OVER THE SOURCE
C     SEGMENT TO OBTAIN THE TOTAL FIELD DUE TO GROUND.  THE METHOD OF
C     VARIABLE INTERVAL WIDTH ROMBERG INTEGRATION IS USED.  THERE ARE 9
C     FIELD COMPONENTS - THE X, Y, AND Z COMPONENTS DUE TO CONSTANT,
C     SINE, AND COSINE CURRENT DISTRIBUTIONS.
C
      COMPLEX*16 SUM,G1,G2,G3,G4,G5,T00,T01,T10,T02,T11,T20
      DIMENSION SUM(9), G1(9), G2(9), G3(9), G4(9), G5(9), T01(9), T10(9
     1), T20(9)
      DATA NM,NTS,NX,N/65536,4,1,9/,RX/1.D-4/
      Z=A
      ZE=B
      S=B-A
      IF (S.GE.0.) GO TO 1
      WRITE(*,18)
      STOP
1     EP=S/(1.E4*NM)
      ZEND=ZE-EP
      DO 2 I=1,N
2     SUM(I)=(0.,0.)
      NS=NX
      NT=0
      CALL SFLDS (Z,G1)
3     DZ=S/NS
      IF (Z+DZ.LE.ZE) GO TO 4
      DZ=ZE-Z
      IF (DZ.LE.EP) GO TO 17
4     DZOT=DZ*.5
      CALL SFLDS (Z+DZOT,G3)
      CALL SFLDS (Z+DZ,G5)
5     TMAG1=0.
      TMAG2=0.
C
C     EVALUATE 3 POINT ROMBERG RESULT AND TEST CONVERGENCE.
C
      DO 6 I=1,N
      T00=(G1(I)+G5(I))*DZOT
      T01(I)=(T00+DZ*G3(I))*.5
      T10(I)=(4.*T01(I)-T00)/3.
      IF (I.GT.3) GO TO 6
      TR=DREAL(T01(I))
      TI=DIMAG(T01(I))
      TMAG1=TMAG1+TR*TR+TI*TI
      TR=DREAL(T10(I))
      TI=DIMAG(T10(I))
      TMAG2=TMAG2+TR*TR+TI*TI
6     CONTINUE
      TMAG1=SQRT(TMAG1)
      TMAG2=SQRT(TMAG2)
      CALL TEST(TMAG1,TMAG2,TR,0.D0,0.D0,TI,DMIN)
      IF(TR.GT.RX)GO TO 8
      DO 7 I=1,N
7     SUM(I)=SUM(I)+T10(I)
      NT=NT+2
      GO TO 12
8     CALL SFLDS (Z+DZ*.25,G2)
      CALL SFLDS (Z+DZ*.75,G4)
      TMAG1=0.
      TMAG2=0.
C
C     EVALUATE 5 POINT ROMBERG RESULT AND TEST CONVERGENCE.
C
      DO 9 I=1,N
      T02=(T01(I)+DZOT*(G2(I)+G4(I)))*.5
      T11=(4.*T02-T01(I))/3.
      T20(I)=(16.*T11-T10(I))/15.
      IF (I.GT.3) GO TO 9
      TR=DREAL(T11)
      TI=DIMAG(T11)
      TMAG1=TMAG1+TR*TR+TI*TI
      TR=DREAL(T20(I))
      TI=DIMAG(T20(I))
      TMAG2=TMAG2+TR*TR+TI*TI
9     CONTINUE
      TMAG1=SQRT(TMAG1)
      TMAG2=SQRT(TMAG2)
      CALL TEST(TMAG1,TMAG2,TR,0.D0,0.D0,TI,DMIN)
      IF(TR.GT.RX)GO TO 14
10    DO 11 I=1,N
11    SUM(I)=SUM(I)+T20(I)
      NT=NT+1
12    Z=Z+DZ
      IF (Z.GT.ZEND) GO TO 17
      DO 13 I=1,N
13    G1(I)=G5(I)
      IF (NT.LT.NTS.OR.NS.LE.NX) GO TO 3
      NS=NS/2
      NT=1
      GO TO 3
14    NT=0
      IF (NS.LT.NM) GO TO 15
      WRITE(*,19)  Z
      GO TO 10
15    NS=NS*2
      DZ=S/NS
      DZOT=DZ*.5
      DO 16 I=1,N
      G5(I)=G3(I)
16    G3(I)=G2(I)
      GO TO 5
17    CONTINUE
      RETURN
C
18    FORMAT (30H ERROR - B LESS THAN A IN ROM2)
19    FORMAT (33H ROM2 -- STEP SIZE LIMITED AT Z =,1P,E12.5)
      END
