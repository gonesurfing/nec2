C     PATCH.F - Patch geometry generation and subdivision
C     Generates and modifies patch geometry data for surface elements.
C     Includes SUBPH entry point for dividing patches at wire connections.
C
      SUBROUTINE PATCH (NX,NY,X1,Y1,Z1,X2,Y2,Z2,X3,Y3,Z3,X4,Y4,Z4)
      USE NEC2_COMMON
C ***
C     DOUBLE PRECISION 6/4/85
C
C     INCLUDE/PARAMETER now from USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C     PATCH GENERATES AND MODIFIES PATCH GEOMETRY DATA
      COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG),
     1ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG),
     2ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
      COMMON /ANGL/ SALP(MAXSEG)
      DIMENSION T1X(1), T1Y(1), T1Z(1), T2X(1), T2Y(1), T2Z(1)
      EQUIVALENCE (T1X,SI), (T1Y,ALP), (T1Z,BET), (T2X,ICON1), (T2Y,ICON
     12), (T2Z,ITAG)
C     NEW PATCHES.  FOR NX=0, NY=1,2,3,4 PATCH IS (RESPECTIVELY)
C     ARBITRARY, RECTAGULAR, TRIANGULAR, OR QUADRILATERAL.
C     FOR NX AND NY .GT. 0 A RECTANGULAR SURFACE IS PRODUCED WITH
C     NX BY NY RECTANGULAR PATCHES.
      M=M+1
      MI=LD+1-M
      NTP=NY
      IF (NX.GT.0) NTP=2
      IF (NTP.GT.1) GO TO 2
      X(MI)=X1
      Y(MI)=Y1
      Z(MI)=Z1
      BI(MI)=Z2
      ZNV=COS(X2)
      XNV=ZNV*COS(Y2)
      YNV=ZNV*SIN(Y2)
      ZNV=SIN(X2)
      XA=SQRT(XNV*XNV+YNV*YNV)
      IF (XA.LT.1.D-6) GO TO 1
      T1X(MI)=-YNV/XA
      T1Y(MI)=XNV/XA
      T1Z(MI)=0.
      GO TO 6
1     T1X(MI)=1.
      T1Y(MI)=0.
      T1Z(MI)=0.
      GO TO 6
2     S1X=X2-X1
      S1Y=Y2-Y1
      S1Z=Z2-Z1
      S2X=X3-X2
      S2Y=Y3-Y2
      S2Z=Z3-Z2
      IF (NX.EQ.0) GO TO 3
      S1X=S1X/NX
      S1Y=S1Y/NX
      S1Z=S1Z/NX
      S2X=S2X/NY
      S2Y=S2Y/NY
      S2Z=S2Z/NY
3     XNV=S1Y*S2Z-S1Z*S2Y
      YNV=S1Z*S2X-S1X*S2Z
      ZNV=S1X*S2Y-S1Y*S2X
      XA=SQRT(XNV*XNV+YNV*YNV+ZNV*ZNV)
      XNV=XNV/XA
      YNV=YNV/XA
      ZNV=ZNV/XA
      XST=SQRT(S1X*S1X+S1Y*S1Y+S1Z*S1Z)
      T1X(MI)=S1X/XST
      T1Y(MI)=S1Y/XST
      T1Z(MI)=S1Z/XST
      IF (NTP.GT.2) GO TO 4
      X(MI)=X1+.5*(S1X+S2X)
      Y(MI)=Y1+.5*(S1Y+S2Y)
      Z(MI)=Z1+.5*(S1Z+S2Z)
      BI(MI)=XA
      GO TO 6
4     IF (NTP.EQ.4) GO TO 5
      X(MI)=(X1+X2+X3)/3.
      Y(MI)=(Y1+Y2+Y3)/3.
      Z(MI)=(Z1+Z2+Z3)/3.
      BI(MI)=.5*XA
      GO TO 6
5     S1X=X3-X1
      S1Y=Y3-Y1
      S1Z=Z3-Z1
      S2X=X4-X1
      S2Y=Y4-Y1
      S2Z=Z4-Z1
      XN2=S1Y*S2Z-S1Z*S2Y
      YN2=S1Z*S2X-S1X*S2Z
      ZN2=S1X*S2Y-S1Y*S2X
      XST=SQRT(XN2*XN2+YN2*YN2+ZN2*ZN2)
      SALPN=1./(3.*(XA+XST))
      X(MI)=(XA*(X1+X2+X3)+XST*(X1+X3+X4))*SALPN
      Y(MI)=(XA*(Y1+Y2+Y3)+XST*(Y1+Y3+Y4))*SALPN
      Z(MI)=(XA*(Z1+Z2+Z3)+XST*(Z1+Z3+Z4))*SALPN
      BI(MI)=.5*(XA+XST)
      S1X=(XNV*XN2+YNV*YN2+ZNV*ZN2)/XST
      IF (S1X.GT.0.9998) GO TO 6
      WRITE(*,14)
      STOP
6     T2X(MI)=YNV*T1Z(MI)-ZNV*T1Y(MI)
      T2Y(MI)=ZNV*T1X(MI)-XNV*T1Z(MI)
      T2Z(MI)=XNV*T1Y(MI)-YNV*T1X(MI)
      SALP(MI)=1.
      IF (NX.EQ.0) GO TO 8
      M=M+NX*NY-1
      XN2=X(MI)-S1X-S2X
      YN2=Y(MI)-S1Y-S2Y
      ZN2=Z(MI)-S1Z-S2Z
      XS=T1X(MI)
      YS=T1Y(MI)
      ZS=T1Z(MI)
      XT=T2X(MI)
      YT=T2Y(MI)
      ZT=T2Z(MI)
      MI=MI+1
      DO 7 IY=1,NY
      XN2=XN2+S2X
      YN2=YN2+S2Y
      ZN2=ZN2+S2Z
      DO 7 IX=1,NX
      XST=IX
      MI=MI-1
      X(MI)=XN2+XST*S1X
      Y(MI)=YN2+XST*S1Y
      Z(MI)=ZN2+XST*S1Z
      BI(MI)=XA
      SALP(MI)=1.
      T1X(MI)=XS
      T1Y(MI)=YS
      T1Z(MI)=ZS
      T2X(MI)=XT
      T2Y(MI)=YT
7     T2Z(MI)=ZT
8     IPSYM=0
      NP=N
      MP=M
      RETURN
C     DIVIDE PATCH FOR WIRE CONNECTION
      ENTRY SUBPH (NX,NY,X1,Y1,Z1,X2,Y2,Z2,X3,Y3,Z3,X4,Y4,Z4)
      IF (NY.GT.0) GO TO 10
      IF (NX.EQ.M) GO TO 10
      NXP=NX+1
      IX=LD-M
      DO 9 IY=NXP,M
      IX=IX+1
      NYP=IX-3
      X(NYP)=X(IX)
      Y(NYP)=Y(IX)
      Z(NYP)=Z(IX)
      BI(NYP)=BI(IX)
      SALP(NYP)=SALP(IX)
      T1X(NYP)=T1X(IX)
      T1Y(NYP)=T1Y(IX)
      T1Z(NYP)=T1Z(IX)
      T2X(NYP)=T2X(IX)
      T2Y(NYP)=T2Y(IX)
9     T2Z(NYP)=T2Z(IX)
10    MI=LD+1-NX
      XS=X(MI)
      YS=Y(MI)
      ZS=Z(MI)
      XA=BI(MI)*.25
      XST=SQRT(XA)*.5
      S1X=T1X(MI)
      S1Y=T1Y(MI)
      S1Z=T1Z(MI)
      S2X=T2X(MI)
      S2Y=T2Y(MI)
      S2Z=T2Z(MI)
      SALN=SALP(MI)
      XT=XST
      YT=XST
      IF (NY.GT.0) GO TO 11
      MIA=MI
      GO TO 12
11    M=M+1
      MP=MP+1
      MIA=LD+1-M
12    DO 13 IX=1,4
      X(MIA)=XS+XT*S1X+YT*S2X
      Y(MIA)=YS+XT*S1Y+YT*S2Y
      Z(MIA)=ZS+XT*S1Z+YT*S2Z
      BI(MIA)=XA
      T1X(MIA)=S1X
      T1Y(MIA)=S1Y
      T1Z(MIA)=S1Z
      T2X(MIA)=S2X
      T2Y(MIA)=S2Y
      T2Z(MIA)=S2Z
      SALP(MIA)=SALN
      IF (IX.EQ.2) YT=-YT
      IF (IX.EQ.1.OR.IX.EQ.3) XT=-XT
      MIA=MIA-1
13    CONTINUE
      M=M+3
      IF (NX.LE.MP) MP=MP+3
      IF (NY.GT.0) Z(MI)=10000.
      RETURN
C
14    FORMAT (' ERROR -- CORNERS OF QUADRILATERAL PATCH DO NOT LIE IN',
     1' A PLANE')
      END
