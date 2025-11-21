C     GWAVE.F - Ground wave electric field computation
C     Computes the electric field, including ground wave, of a
C     current element over a ground plane using formulas of K.A. Norton
C     (Proc. IRE, Sept., 1937, pp.1203,1236.)
C
      SUBROUTINE GWAVE (ERV,EZV,ERH,EZH,EPH)
C ***
C     DOUBLE PRECISION 6/4/85
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     GWAVE COMPUTES THE ELECTRIC FIELD, INCLUDING GROUND WAVE, OF A
C     CURRENT ELEMENT OVER A GROUND PLANE USING FORMULAS OF K.A. NORTON
C     (PROC. IRE, SEPT., 1937, PP.1203,1236.)
C
      COMPLEX*16 FJ,TPJ,U2,U,RK1,RK2,T1,T2,T3,T4,P1,RV,OMR,W,F,Q1,RH,V,G
     1,XR1,XR2,X1,X2,X3,X4,X5,X6,X7,EZV,ERV,EZH,ERH,EPH,XX1,XX2,ECON,
     2FBAR
      COMMON /GWAV/ U,U2,XX1,XX2,R1,R2,ZMH,ZPH
      DIMENSION FJX(2), TPJX(2), ECONX(2)
      EQUIVALENCE (FJ,FJX), (TPJ,TPJX), (ECON,ECONX)
      DATA FJX/0.,1./,TPJX/0.,6.283185308D+0/
      DATA ECONX/0.,-188.367/
      SPPP=ZMH/R1
      SPPP2=SPPP*SPPP
      CPPP2=1.-SPPP2
      IF (CPPP2.LT.1.D-20) CPPP2=1.D-20
      CPPP=SQRT(CPPP2)
      SPP=ZPH/R2
      SPP2=SPP*SPP
      CPP2=1.-SPP2
      IF (CPP2.LT.1.D-20) CPP2=1.D-20
      CPP=SQRT(CPP2)
      RK1=-TPJ*R1
      RK2=-TPJ*R2
      T1=1.-U2*CPP2
      T2=SQRT(T1)
      T3=(1.-1./RK1)/RK1
      T4=(1.-1./RK2)/RK2
      P1=RK2*U2*T1/(2.*CPP2)
      RV=(SPP-U*T2)/(SPP+U*T2)
      OMR=1.-RV
      W=1./OMR
      W=(4.,0.)*P1*W*W
      F=FBAR(W)
      Q1=RK2*T1/(2.*U2*CPP2)
      RH=(T2-U*SPP)/(T2+U*SPP)
      V=1./(1.+RH)
      V=(4.,0.)*Q1*V*V
      G=FBAR(V)
      XR1=XX1/R1
      XR2=XX2/R2
      X1=CPPP2*XR1
      X2=RV*CPP2*XR2
      X3=OMR*CPP2*F*XR2
      X4=U*T2*SPP*2.*XR2/RK2
      X5=XR1*T3*(1.-3.*SPPP2)
      X6=XR2*T4*(1.-3.*SPP2)
      EZV=(X1+X2+X3-X4-X5-X6)*ECON
      X1=SPPP*CPPP*XR1
      X2=RV*SPP*CPP*XR2
      X3=CPP*OMR*U*T2*F*XR2
      X4=SPP*CPP*OMR*XR2/RK2
      X5=3.*SPPP*CPPP*T3*XR1
      X6=CPP*U*T2*OMR*XR2/RK2*.5
      X7=3.*SPP*CPP*T4*XR2
      ERV=-(X1+X2-X3+X4-X5+X6-X7)*ECON
      EZH=-(X1-X2+X3-X4-X5-X6+X7)*ECON
      X1=SPPP2*XR1
      X2=RV*SPP2*XR2
      X4=U2*T1*OMR*F*XR2
      X5=T3*(1.-3.*CPPP2)*XR1
      X6=T4*(1.-3.*CPP2)*(1.-U2*(1.+RV)-U2*OMR*F)*XR2
      X7=U2*CPP2*OMR*(1.-1./RK2)*(F*(U2*T1-SPP2-1./RK2)+1./RK2)*XR2
      ERH=(X1-X2-X4-X5+X6+X7)*ECON
      X1=XR1
      X2=RH*XR2
      X3=(RH+1.)*G*XR2
      X4=T3*XR1
      X5=T4*(1.-U2*(1.+RV)-U2*OMR*F)*XR2
      X6=.5*U2*OMR*(F*(U2*T1-SPP2-1./RK2)+1./RK2)*XR2/RK2
      EPH=-(X1-X2+X3-X4+X5+X6)*ECON
      RETURN
      END
