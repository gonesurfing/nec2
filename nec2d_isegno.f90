! =============================================================================
! nec2d_isegno - Segment Number Lookup
! =============================================================================
! Purpose: Find segment number from tag and index
! Contains: ISEGNO
! =============================================================================
module nec2d_isegno
  use nec2d_params
  use nec2d_commons
  implicit none

  contains

!***********************************************************************
      function isegno (itagi,mx)
!***********************************************************************
!     ISEGNO RETURNS THE SEGMENT NUMBER OF THE MTH SEGMENT HAVING THE
!     TAG NUMBER ITAGI.  IF ITAGI=0 SEGMENT NUMBER M IS RETURNED.
!***********************************************************************
      implicit real*8(a-h,o-z)
      integer :: isegno, itagi, mx, icnt, i

      if (mx.gt.0) go to 1
      write(*,6)
      stop
1     icnt=0
      if (itagi.ne.0) go to 2
      isegno=mx
      return
2     if (n.lt.1) go to 4
      do 3 i=1,n
      if (itag(i).ne.itagi) go to 3
      icnt=icnt+1
      if (icnt.eq.mx) go to 5
3     continue
4     write(*,7)  itagi
      stop
5     isegno=i
      return

6     format (4x,'CHECK DATA, PARAMETER SPECIFYING SEGMENT POSITION IN',&
     &' A GROUP OF EQUAL TAGS MUST NOT BE ZERO')
7     format (///,10x,'NO SEGMENT HAS AN ITAG OF ',i5)
      end function isegno

end module nec2d_isegno
