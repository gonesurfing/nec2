!***********************************************************************
!     NEC2D Utility Functions Module
!***********************************************************************
!     Contains small, standalone utility functions
!     - ATGN2: Arc tangent with special handling for 0,0
!     - CANG: Complex angle in degrees
!     - DB10/DB20: Decibel conversion
!     - CPUSEC/STOPWTCH: CPU timing utilities
!***********************************************************************

MODULE nec2d_utils
  USE nec2d_params
  USE nec2d_commons
  IMPLICIT NONE

  CONTAINS

!***********************************************************************
      FUNCTION ATGN2 (X,Y)
!***********************************************************************
!     ATGN2 IS ARCTANGENT FUNCTION MODIFIED TO RETURN 0. WHEN X=Y=0.
!***********************************************************************
      IMPLICIT REAL*8(A-H,O-Z)
      REAL*8 :: ATGN2, X, Y

      IF (X) 3,1,3
1     IF (Y) 3,2,3
2     ATGN2=0.
      RETURN
3     ATGN2=ATAN2(X,Y)
      RETURN
      END FUNCTION ATGN2

!***********************************************************************
      FUNCTION CANG (Z)
!***********************************************************************
!     CANG RETURNS THE PHASE ANGLE OF A COMPLEX NUMBER IN DEGREES.
!***********************************************************************
      IMPLICIT REAL*8(A-H,O-Z)
      COMPLEX*16 :: Z
      REAL*8 :: CANG

      CANG=ATGN2(DIMAG(Z),DREAL(Z))*57.29577951D+0
      RETURN
      END FUNCTION CANG

!***********************************************************************
      FUNCTION DB10 (X)
!***********************************************************************
!     FUNCTION DB-- RETURNS DB FOR MAGNITUDE (FIELD) OR MAG**2 (POWER)
!***********************************************************************
      IMPLICIT REAL*8(A-H,O-Z)
      REAL*8 :: DB10, DB20, X, F

      F=10.
      GO TO 1
      ENTRY DB20(X)
      F=20.
1     IF (X.LT.1.D-20) GO TO 2
      DB10=F*LOG10(X)
      RETURN
2     DB10=-999.99
      RETURN
      END FUNCTION DB10

!***********************************************************************
      SUBROUTINE CPUSEC (CPUSECD)
!***********************************************************************
!     CPUSEC returns cpu time in seconds.
!***********************************************************************
      REAL*8 :: CPUSECD
      REAL :: CPUSECS, WALLTOT, CPUSPLT, WALLSPLT

      CALL STOPWTCH(CPUSECS,WALLTOT,CPUSPLT,WALLSPLT)
      CPUSECD=60.*CPUSECS
      RETURN
      END SUBROUTINE CPUSEC

!***********************************************************************
      SUBROUTINE STOPWTCH(cputot,walltot,cpusplt,wallsplt)
!***********************************************************************
!     This routine operates as a stopwatch.
!     When first called, the routine initializes the clock.
!     On subsequent calls, the routine returns:
!
!     Outputs: cputot   -- elapsed CPU time since initialization
!              walltot  -- elapsed wallclock time since initialization
!              cpusplt  -- split (delta) CPU time since previous call
!              wallsplt -- split wallclock time since previous call
!***********************************************************************
      REAL :: cputot,walltot,cpusplt,wallsplt
      LOGICAL :: initiz
      INTEGER :: wallinit,walllast,wallnow,time
      REAL :: cpuinit,cpulast,cpunow
      REAL :: tarray(2)
      SAVE initiz,cpuinit,cpulast,wallinit,walllast
      DATA initiz/.false./

      if (.not. initiz) then
         initiz = .true.
         cpuinit  = 0.0
         wallinit = 0
         cpuinit  = etime(tarray)
         wallinit = time()
         cpulast  =  cpuinit
         walllast = wallinit
      end if

      cpunow  = etime(tarray)
      wallnow = time()

      cputot   = (cpunow  - cpuinit)  / 60.0
      walltot  = float(wallnow - wallinit) / 60.0
      cpusplt  = (cpunow  - cpulast)  / 60.0
      wallsplt = float(wallnow - walllast) / 60.0

      cpulast  = cpunow
      walllast = wallnow

      return
      END SUBROUTINE STOPWTCH

END MODULE nec2d_utils
