C     MOVE.F - Structure movement and reproduction
C     Moves the structure with respect to its coordinate system or
C     reproduces structure in new positions. Structure is rotated
C     about X,Y,Z axes then shifted.
C
      SUBROUTINE MOVE (ROX,ROY,ROZ,XS,YS,ZS,ITS,NRPT,ITGI)
      USE NEC2_COMMON
C ***
C     DOUBLE PRECISION 6/4/85
C
C     INCLUDE/PARAMETER now from USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     SUBROUTINE MOVE MOVES THE STRUCTURE WITH RESPECT TO ITS
C     COORDINATE SYSTEM OR REPRODUCES STRUCTURE IN NEW POSITIONS.
C     STRUCTURE IS ROTATED ABOUT X,Y,Z AXES BY ROX,ROY,ROZ
C     RESPECTIVELY, THEN SHIFTED BY XS,YS,ZS
C
      COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG),
     1ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG),
     2ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
      COMMON /ANGL/ SALP(MAXSEG)
      DIMENSION T1X(1), T1Y(1), T1Z(1), T2X(1), T2Y(1), T2Z(1), X2(1), Y
     12(1), Z2(1)
      EQUIVALENCE (X2(1),SI(1)), (Y2(1),ALP(1)), (Z2(1),BET(1))
      EQUIVALENCE (T1X,SI), (T1Y,ALP), (T1Z,BET), (T2X,ICON1), (T2Y,ICON
     12), (T2Z,ITAG)
      IF (ABS(ROX)+ABS(ROY).GT.1.D-10) IPSYM=IPSYM*3
      SPS=SIN(ROX)
      CPS=COS(ROX)
      STH=SIN(ROY)
      CTH=COS(ROY)
      SPH=SIN(ROZ)
      CPH=COS(ROZ)
      XX=CPH*CTH
      XY=CPH*STH*SPS-SPH*CPS
      XZ=CPH*STH*CPS+SPH*SPS
      YX=SPH*CTH
      YY=SPH*STH*SPS+CPH*CPS
      YZ=SPH*STH*CPS-CPH*SPS
      ZX=-STH
      ZY=CTH*SPS
      ZZ=CTH*CPS
      NRP=NRPT
      IF (NRPT.EQ.0) NRP=1
      IX=1
      IF (N.LT.N2) GO TO 3
      I1=ISEGNO(ITS,1)
      IF (I1.LT.N2) I1=N2
      IX=I1
      K=N
      IF (NRPT.EQ.0) K=I1-1
      DO 2 IR=1,NRP
      DO 1 I=I1,N
      K=K+1
      XI=X(I)
      YI=Y(I)
      ZI=Z(I)
      X(K)=XI*XX+YI*XY+ZI*XZ+XS
      Y(K)=XI*YX+YI*YY+ZI*YZ+YS
      Z(K)=XI*ZX+YI*ZY+ZI*ZZ+ZS
      XI=X2(I)
      YI=Y2(I)
      ZI=Z2(I)
      X2(K)=XI*XX+YI*XY+ZI*XZ+XS
      Y2(K)=XI*YX+YI*YY+ZI*YZ+YS
      Z2(K)=XI*ZX+YI*ZY+ZI*ZZ+ZS
      BI(K)=BI(I)
      ITAG(K)=ITAG(I)
      IF(ITAG(I).NE.0)ITAG(K)=ITAG(I)+ITGI
1     CONTINUE
      I1=N+1
      N=K
2     CONTINUE
3     IF (M.LT.M2) GO TO 6
      I1=M2
      K=M
      LDI=LD+1
      IF (NRPT.EQ.0) K=M1
      DO 5 II=1,NRP
      DO 4 I=I1,M
      K=K+1
      IR=LDI-I
      KR=LDI-K
      XI=X(IR)
      YI=Y(IR)
      ZI=Z(IR)
      X(KR)=XI*XX+YI*XY+ZI*XZ+XS
      Y(KR)=XI*YX+YI*YY+ZI*YZ+YS
      Z(KR)=XI*ZX+YI*ZY+ZI*ZZ+ZS
      XI=T1X(IR)
      YI=T1Y(IR)
      ZI=T1Z(IR)
      T1X(KR)=XI*XX+YI*XY+ZI*XZ
      T1Y(KR)=XI*YX+YI*YY+ZI*YZ
      T1Z(KR)=XI*ZX+YI*ZY+ZI*ZZ
      XI=T2X(IR)
      YI=T2Y(IR)
      ZI=T2Z(IR)
      T2X(KR)=XI*XX+YI*XY+ZI*XZ
      T2Y(KR)=XI*YX+YI*YY+ZI*YZ
      T2Z(KR)=XI*ZX+YI*ZY+ZI*ZZ
      SALP(KR)=SALP(IR)
4     BI(KR)=BI(IR)
      I1=M+1
5     M=K
6     IF ((NRPT.EQ.0).AND.(IX.EQ.1)) RETURN
      NP=N
      MP=M
      IPSYM=0
      RETURN
      END
