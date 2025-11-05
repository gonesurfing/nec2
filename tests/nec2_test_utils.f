C     Extracted utility functions from nec2dxs.f for unit testing
C     This file contains only the functions needed for testing
C     without the main PROGRAM, so it can be linked with test programs
C
C     DB10 - Decibel conversion
      REAL*8 FUNCTION DB10(X)
      IMPLICIT REAL*8(A-H,O-Z)
      DB10=-999.99D0
      IF (X.LT.1.D-20) RETURN
      DB10=10.D0*DLOG10(X)
      RETURN
      END
C
C     ATGN2 - Arctangent with proper quadrant handling
      REAL*8 FUNCTION ATGN2(X,Y)
      IMPLICIT REAL*8(A-H,O-Z)
      DATA PI/3.141592654D0/
      Z=0.0D0
      IF (ABS(X)+ABS(Y).LT.1.D-20) GO TO 1
      Z=DATAN2(X,Y)
1     ATGN2=Z
      RETURN
      END
C
C     CANG - Complex angle in degrees
      REAL*8 FUNCTION CANG(Z)
      IMPLICIT REAL*8(A-H,O-Z)
      COMPLEX*16 Z
      DATA TD/57.295779513D0/
      ZM=ABS(Z)
      IF (ZM.LT.1.D-20) GO TO 1
      CANG=DATAN2(DIMAG(Z),DREAL(Z))*TD
      RETURN
1     CANG=0.0D0
      RETURN
      END
C
C     ZINT - Internal impedance of a wire
      COMPLEX*16 FUNCTION ZINT(SIGL,ROLAM)
      IMPLICIT REAL*8(A-H,O-Z)
      COMPLEX*16 ZJ,P1,P2,P3,R
      DATA PI/3.141592654D0/,ETA/376.73D0/
      ZJ=(0.0D0,1.0D0)
      TPMU=2.0D0*PI*1.0D-7
      F=1.0D0/ROLAM
      OM=2.0D0*PI*F
      RORAD=ROLAM*ROLAM
      ZINT=(0.0D0,0.0D0)
      IF (SIGL.LT.1.0D-20) RETURN
      SKD=DSQRT(OM*TPMU/(SIGL*PI))
      P1=RORAD*SKD
      P2=P1*DSQRT(ZJ)
      P3=P2*P2
      R=DSQRT(1.0D0+P3)
      ZINT=((R+P2)*ZJ*ETA*SKD)/(2.0D0*PI*RORAD*R)
      RETURN
      END
