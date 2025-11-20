C     REFLC.F - Structure reflection and rotation routines
C     This file contains SUBROUTINE REFLC which reflects partial structure
C     along X, Y, or Z axes or rotates structure to complete a symmetric structure.
C
      SUBROUTINE REFLC (IX,IY,IZ,ITX,NOP)
      USE NEC2_COMMON
C ***
C     DOUBLE PRECISION 6/4/85
C
C     INCLUDE/PARAMETER now from USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     REFLC REFLECTS PARTIAL STRUCTURE ALONG X,Y, OR Z AXES OR ROTATES
C     STRUCTURE TO COMPLETE A SYMMETRIC STRUCTURE.
C
      COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG),
     1ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG),
     2ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
      COMMON /ANGL/ SALP(MAXSEG)
      DIMENSION T1X(1), T1Y(1), T1Z(1), T2X(1), T2Y(1), T2Z(1), X2(1), Y
     12(1), Z2(1)
      EQUIVALENCE (T1X,SI), (T1Y,ALP), (T1Z,BET), (T2X,ICON1), (T2Y,ICON
     12), (T2Z,ITAG), (X2,SI), (Y2,ALP), (Z2,BET)
      NP=N
      MP=M
      IPSYM=0
      ITI=ITX
      IF (IX.LT.0) GO TO 19
      IF (NOP.EQ.0) RETURN
      IPSYM=1
      IF (IZ.EQ.0) GO TO 6
C
C     REFLECT ALONG Z AXIS
C
      IPSYM=2
      IF (N.LT.N2) GO TO 3
      DO 2 I=N2,N
      NX=I+N-N1
      E1=Z(I)
      E2=Z2(I)
      IF (ABS(E1)+ABS(E2).GT.1.D-5.AND.E1*E2.GE.-1.D-6) GO TO 1
      WRITE(*,24)  I
      STOP
1     X(NX)=X(I)
      Y(NX)=Y(I)
      Z(NX)=-E1
      X2(NX)=X2(I)
      Y2(NX)=Y2(I)
      Z2(NX)=-E2
      ITAGI=ITAG(I)
      IF (ITAGI.EQ.0) ITAG(NX)=0
      IF (ITAGI.NE.0) ITAG(NX)=ITAGI+ITI
2     BI(NX)=BI(I)
      N=N*2-N1
      ITI=ITI*2
3     IF (M.LT.M2) GO TO 6
      NXX=LD+1-M1
      DO 5 I=M2,M
      NXX=NXX-1
      NX=NXX-M+M1
      IF (ABS(Z(NXX)).GT.1.D-10) GO TO 4
      WRITE(*,25)  I
      STOP
4     X(NX)=X(NXX)
      Y(NX)=Y(NXX)
      Z(NX)=-Z(NXX)
      T1X(NX)=T1X(NXX)
      T1Y(NX)=T1Y(NXX)
      T1Z(NX)=-T1Z(NXX)
      T2X(NX)=T2X(NXX)
      T2Y(NX)=T2Y(NXX)
      T2Z(NX)=-T2Z(NXX)
      SALP(NX)=-SALP(NXX)
5     BI(NX)=BI(NXX)
      M=M*2-M1
6     IF (IY.EQ.0) GO TO 12
C
C     REFLECT ALONG Y AXIS
C
      IF (N.LT.N2) GO TO 9
      DO 8 I=N2,N
      NX=I+N-N1
      E1=Y(I)
      E2=Y2(I)
      IF (ABS(E1)+ABS(E2).GT.1.D-5.AND.E1*E2.GE.-1.D-6) GO TO 7
      WRITE(*,24)  I
      STOP
7     X(NX)=X(I)
      Y(NX)=-E1
      Z(NX)=Z(I)
      X2(NX)=X2(I)
      Y2(NX)=-E2
      Z2(NX)=Z2(I)
      ITAGI=ITAG(I)
      IF (ITAGI.EQ.0) ITAG(NX)=0
      IF (ITAGI.NE.0) ITAG(NX)=ITAGI+ITI
8     BI(NX)=BI(I)
      N=N*2-N1
      ITI=ITI*2
9     IF (M.LT.M2) GO TO 12
      NXX=LD+1-M1
      DO 11 I=M2,M
      NXX=NXX-1
      NX=NXX-M+M1
      IF (ABS(Y(NXX)).GT.1.D-10) GO TO 10
      WRITE(*,25)  I
      STOP
10    X(NX)=X(NXX)
      Y(NX)=-Y(NXX)
      Z(NX)=Z(NXX)
      T1X(NX)=T1X(NXX)
      T1Y(NX)=-T1Y(NXX)
      T1Z(NX)=T1Z(NXX)
      T2X(NX)=T2X(NXX)
      T2Y(NX)=-T2Y(NXX)
      T2Z(NX)=T2Z(NXX)
      SALP(NX)=-SALP(NXX)
11    BI(NX)=BI(NXX)
      M=M*2-M1
12    IF (IX.EQ.0) GO TO 18
C
C     REFLECT ALONG X AXIS
C
      IF (N.LT.N2) GO TO 15
      DO 14 I=N2,N
      NX=I+N-N1
      E1=X(I)
      E2=X2(I)
      IF (ABS(E1)+ABS(E2).GT.1.D-5.AND.E1*E2.GE.-1.D-6) GO TO 13
      WRITE(*,24)  I
      STOP
13    X(NX)=-E1
      Y(NX)=Y(I)
      Z(NX)=Z(I)
      X2(NX)=-E2
      Y2(NX)=Y2(I)
      Z2(NX)=Z2(I)
      ITAGI=ITAG(I)
      IF (ITAGI.EQ.0) ITAG(NX)=0
      IF (ITAGI.NE.0) ITAG(NX)=ITAGI+ITI
14    BI(NX)=BI(I)
      N=N*2-N1
15    IF (M.LT.M2) GO TO 18
      NXX=LD+1-M1
      DO 17 I=M2,M
      NXX=NXX-1
      NX=NXX-M+M1
      IF (ABS(X(NXX)).GT.1.D-10) GO TO 16
      WRITE(*,25)  I
      STOP
16    X(NX)=-X(NXX)
      Y(NX)=Y(NXX)
      Z(NX)=Z(NXX)
      T1X(NX)=-T1X(NXX)
      T1Y(NX)=T1Y(NXX)
      T1Z(NX)=T1Z(NXX)
      T2X(NX)=-T2X(NXX)
      T2Y(NX)=T2Y(NXX)
      T2Z(NX)=T2Z(NXX)
      SALP(NX)=-SALP(NXX)
17    BI(NX)=BI(NXX)
      M=M*2-M1
18    RETURN
C
C     REPRODUCE STRUCTURE WITH ROTATION TO FORM CYLINDRICAL STRUCTURE
C
19    FNOP=NOP
      IPSYM=-1
      SAM=6.283185308D+0/FNOP
      CS=COS(SAM)
      SS=SIN(SAM)
      IF (N.LT.N2) GO TO 21
      N=N1+(N-N1)*NOP
      NX=NP+1
      DO 20 I=NX,N
      K=I-NP+N1
      XK=X(K)
      YK=Y(K)
      X(I)=XK*CS-YK*SS
      Y(I)=XK*SS+YK*CS
      Z(I)=Z(K)
      XK=X2(K)
      YK=Y2(K)
      X2(I)=XK*CS-YK*SS
      Y2(I)=XK*SS+YK*CS
      Z2(I)=Z2(K)
      ITAGI=ITAG(K)
      IF (ITAGI.EQ.0) ITAG(I)=0
      IF (ITAGI.NE.0) ITAG(I)=ITAGI+ITI
20    BI(I)=BI(K)
21    IF (M.LT.M2) GO TO 23
      M=M1+(M-M1)*NOP
      NX=MP+1
      K=LD+1-M1
      DO 22 I=NX,M
      K=K-1
      J=K-MP+M1
      XK=X(K)
      YK=Y(K)
      X(J)=XK*CS-YK*SS
      Y(J)=XK*SS+YK*CS
      Z(J)=Z(K)
      XK=T1X(K)
      YK=T1Y(K)
      T1X(J)=XK*CS-YK*SS
      T1Y(J)=XK*SS+YK*CS
      T1Z(J)=T1Z(K)
      XK=T2X(K)
      YK=T2Y(K)
      T2X(J)=XK*CS-YK*SS
      T2Y(J)=XK*SS+YK*CS
      T2Z(J)=T2Z(K)
      SALP(J)=SALP(K)
22    BI(J)=BI(K)
23    RETURN
C
24    FORMAT (29H GEOMETRY DATA ERROR--SEGMENT,I5,26H LIES IN PLANE OF S
     1YMMETRY)
25    FORMAT (27H GEOMETRY DATA ERROR--PATCH,I4,26H LIES IN PLANE OF SYM
     1METRY)
      END
