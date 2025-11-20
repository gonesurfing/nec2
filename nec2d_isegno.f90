! =============================================================================
! nec2d_isegno - Segment Number Lookup
! =============================================================================
! Purpose: Find segment number from tag and index
! Contains: ISEGNO
! =============================================================================
module nec2d_isegno
  use nec2d_params
  use nec2d_commons
  implicit NONE

  contains

!***********************************************************************
      function ISEGNO (ITAGI,MX)
!***********************************************************************
!     ISEGNO RETURNS THE SEGMENT NUMBER OF THE MTH SEGMENT HAVING THE
!     TAG NUMBER ITAGI.  IF ITAGI=0 SEGMENT NUMBER M IS RETURNED.
!***********************************************************************
      implicit real*8(A-H,O-Z)
      integer :: ISEGNO, ITAGI, MX, ICNT, I

      if (MX.gt.0) GO TO 1
      write(*,6)
      stop
1     ICNT=0
      if (ITAGI.ne.0) GO TO 2
      ISEGNO=MX
      return
2     if (N.lt.1) GO TO 4
      do 3 I=1,N
      if (ITAG(I).NE.ITAGI) GO TO 3
      ICNT=ICNT+1
      if (ICNT.eq.MX) GO TO 5
3     continue
4     write(*,7)  ITAGI
      stop
5     ISEGNO=I
      return

6     format (4X,'CHECK DATA, PARAMETER SPECIFYING SEGMENT POSITION IN',&
     &' A GROUP OF EQUAL TAGS MUST NOT BE ZERO')
7     format (///,10X,'NO SEGMENT HAS AN ITAG OF ',I5)
      end function ISEGNO

end module nec2d_isegno
