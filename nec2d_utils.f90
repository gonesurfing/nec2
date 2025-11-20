! =============================================================================
! nec2d_utils - General Utilities
! =============================================================================
! Purpose: Move and test functions using module variables
! Contains: ATGN2, CANG, DB10, CPUSEC, STOPWTCH
! =============================================================================
module nec2d_utils
  use nec2d_params
  use nec2d_commons
  implicit NONE

  contains

!***********************************************************************
      function ATGN2 (X,Y)
!***********************************************************************
!     ATGN2 IS ARCTANGENT FUNCTION MODIFIED TO RETURN 0. WHEN X=Y=0.
!***********************************************************************
      implicit real*8(A-H,O-Z)
      real*8 :: ATGN2, X, Y

      if (X) 3,1,3
1     if (Y) 3,2,3
2     ATGN2=0.
      return
3     ATGN2=ATAN2(X,Y)
      return
      end function ATGN2

!***********************************************************************
      function CANG (Z)
!***********************************************************************
!     CANG RETURNS THE PHASE ANGLE OF A COMPLEX NUMBER IN DEGREES.
!***********************************************************************
      implicit real*8(A-H,O-Z)
      complex*16 :: Z
      real*8 :: CANG

      CANG=ATGN2(DIMAG(Z),DREAL(Z))*57.29577951D+0
      return
      end function CANG

!***********************************************************************
      function DB10 (X)
!***********************************************************************
!     FUNCTION DB-- RETURNS DB FOR MAGNITUDE (FIELD) OR MAG**2 (POWER)
!***********************************************************************
      implicit real*8(A-H,O-Z)
      real*8 :: DB10, DB20, X, F

      F=10.
      GO TO 1
      ENTRY DB20(X)
      F=20.
1     if (X.lt.1.D-20) GO TO 2
      DB10=F*LOG10(X)
      return
2     DB10=-999.99
      return
      end function DB10

!***********************************************************************
      subroutine CPUSEC (CPUSECD)
!***********************************************************************
!     CPUSEC returns cpu time in seconds.
!***********************************************************************
      real*8 :: CPUSECD
      real :: CPUSECS, WALLTOT, CPUSPLT, WALLSPLT

      call STOPWTCH(CPUSECS,WALLTOT,CPUSPLT,WALLSPLT)
      CPUSECD=60.*CPUSECS
      return
      end subroutine CPUSEC

!***********************************************************************
      subroutine STOPWTCH(cputot,walltot,cpusplt,wallsplt)
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
      real :: cputot,walltot,cpusplt,wallsplt
      logical :: initiz
      integer :: wallinit,walllast,wallnow,time
      real :: cpuinit,cpulast,cpunow
      real :: tarray(2)
      save initiz,cpuinit,cpulast,wallinit,walllast
      data initiz/.false./

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
      end subroutine STOPWTCH

end module nec2d_utils
