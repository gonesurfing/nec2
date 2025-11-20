! =============================================================================
! nec2d_segment - Segment Lookup
! =============================================================================
! Purpose: Find segment number from tag number
! Contains: ISEGNO
! =============================================================================
function isegno(itagi, mx)
  use nec2d_params
  use nec2d_commons, only: &
    ! /DATA/ - Only variables actually used: ITAG, N
    itag, n
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  ! ISEGNO returns the segment number of the Mth segment having the
  ! tag number ITAGI. If ITAGI=0, segment number M is returned.
  !
  ! Modernized: Eliminated 5 GOTOs using structured control flow
  ! COMMON blocks: Converted to USE...ONLY (2025-11-19)
  !
  implicit real*8(a-h,o-z)

  ! Validate MX parameter (GOTO 1 eliminated)
  if (mx .le. 0) then
    write(*,6)
    stop
  end if

  icnt = 0

  ! Handle ITAGI=0 case (GOTO 2 eliminated)
  if (itagi .eq. 0) then
    isegno = mx
    return
  end if

  ! Validate N parameter (GOTO 4 eliminated)
  if (n .lt. 1) then
    write(*,7) itagi
    stop
  end if

  ! Search for Mth segment with tag ITAGI
  do i = 1, n
    ! GOTO 3 eliminated with CYCLE
    if (itag(i) .ne. itagi) cycle

    icnt = icnt + 1

    ! GOTO 5 eliminated - return when found
    if (icnt .eq. mx) then
      isegno = i
      return
    end if
  end do

  ! If we reach here, tag not found (GOTO 4 path)
  write(*,7) itagi
  stop

6 format(4x, 'CHECK DATA, PARAMETER SPECIFYING SEGMENT POSITION IN ', &
           'A GROUP OF EQUAL TAGS MUST NOT BE ZERO')
7 format(///, 10x, 'NO SEGMENT HAS AN ITAG OF ', i5)

end function isegno
