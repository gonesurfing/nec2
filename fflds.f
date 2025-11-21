C     FFLDS.F - Far field calculation from surface currents
C     Calculates the XYZ components of the electric field due to
C     surface currents for radiation pattern computation.
C
      SUBROUTINE FFLDS (ROX,ROY,ROZ,SCUR,EX,EY,EZ)
C ***
C     DOUBLE PRECISION 6/4/85
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C     CALCULATES THE XYZ COMPONENTS OF THE ELECTRIC FIELD DUE TO
C     SURFACE CURRENTS
      COMPLEX*16 CT,CONS,SCUR,EX,EY,EZ
      COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG),
     1ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG),
     2ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
      DIMENSION XS(1), YS(1), ZS(1), S(1), SCUR(1), CONSX(2)
      EQUIVALENCE (XS,X), (YS,Y), (ZS,Z), (S,BI), (CONS,CONSX)
      DATA TPI/6.283185308D+0/,CONSX/0.,188.365/
      EX=(0.,0.)
      EY=(0.,0.)
      EZ=(0.,0.)
      I=LD+1
      DO 1 J=1,M
      I=I-1
      ARG=TPI*(ROX*XS(I)+ROY*YS(I)+ROZ*ZS(I))
      CT=DCMPLX(COS(ARG)*S(I),SIN(ARG)*S(I))
      K=3*J
      EX=EX+SCUR(K-2)*CT
      EY=EY+SCUR(K-1)*CT
      EZ=EZ+SCUR(K)*CT
1     CONTINUE
      CT=ROX*EX+ROY*EY+ROZ*EZ
      EX=CONS*(CT*ROX-EX)
      EY=CONS*(CT*ROY-EY)
      EZ=CONS*(CT*ROZ-EZ)
      RETURN
      END
