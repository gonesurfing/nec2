! =============================================================================
! nec2d_utils - General Utilities
! =============================================================================
! Purpose: Move and test functions using module variables
! Contains: ATGN2, CANG, DB10, CPUSEC, STOPWTCH
! =============================================================================
module nec2d_utils
  use nec2d_params
  use nec2d_commons
  implicit none

  contains

!***********************************************************************
      function atgn2 (x,y)
!***********************************************************************
!     ATGN2 IS ARCTANGENT FUNCTION MODIFIED TO RETURN 0. WHEN X=Y=0.
!***********************************************************************
      implicit real*8(a-h,o-z)
      real*8 :: atgn2, x, y

      if (x) 3,1,3
1     if (y) 3,2,3
2     atgn2=0.
      return
3     atgn2=atan2(x,y)
      return
      end function atgn2

!***********************************************************************
      function cang (z)
!***********************************************************************
!     CANG RETURNS THE PHASE ANGLE OF A COMPLEX NUMBER IN DEGREES.
!***********************************************************************
      implicit real*8(a-h,o-z)
      complex*16 :: z
      real*8 :: cang

      cang=atgn2(dimag(z),dreal(z))*57.29577951d+0
      return
      end function cang

!***********************************************************************
      function db10 (x)
!***********************************************************************
!     FUNCTION DB-- RETURNS DB FOR MAGNITUDE (FIELD) OR MAG**2 (POWER)
!***********************************************************************
      implicit real*8(a-h,o-z)
      real*8 :: db10, db20, x, f

      f=10.
      go to 1
      entry db20(x)
      f=20.
1     if (x.lt.1.d-20) go to 2
      db10=f*log10(x)
      return
2     db10=-999.99
      return
      end function db10

!***********************************************************************
      subroutine cpusec (cpusecd)
!***********************************************************************
!     CPUSEC returns cpu time in seconds.
!***********************************************************************
      real*8 :: cpusecd
      real :: cpusecs, walltot, cpusplt, wallsplt

      call stopwtch(cpusecs,walltot,cpusplt,wallsplt)
      cpusecd=60.*cpusecs
      return
      end subroutine cpusec

!***********************************************************************
      subroutine stopwtch(cputot,walltot,cpusplt,wallsplt)
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
      end subroutine stopwtch

end module nec2d_utils
