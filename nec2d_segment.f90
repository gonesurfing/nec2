! =============================================================================
! nec2d_segment - Segment Lookup
! =============================================================================
! Purpose: Find segment number from tag number
! Contains: ISEGNO
! =============================================================================
function ISEGNO(ITAGI, MX)
  use nec2d_params
  use nec2d_commons, only: &
    ! /DATA/ - Only variables actually used: ITAG, N
    ITAG, N
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  ! ISEGNO returns the segment number of the Mth segment having the
  ! tag number ITAGI. If ITAGI=0, segment number M is returned.
  !
  ! Modernized: Eliminated 5 GOTOs using structured control flow
  ! COMMON blocks: Converted to USE...ONLY (2025-11-19)
  !
  implicit real*8(A-H,O-Z)

  ! Validate MX parameter (GOTO 1 eliminated)
  if (MX .LE. 0) then
    write(*,6)
    stop
  end if

  ICNT = 0

  ! Handle ITAGI=0 case (GOTO 2 eliminated)
  if (ITAGI .EQ. 0) then
    ISEGNO = MX
    return
  end if

  ! Validate N parameter (GOTO 4 eliminated)
  if (N .LT. 1) then
    write(*,7) ITAGI
    stop
  end if

  ! Search for Mth segment with tag ITAGI
  do I = 1, N
    ! GOTO 3 eliminated with CYCLE
    if (ITAG(I) .NE. ITAGI) cycle

    ICNT = ICNT + 1

    ! GOTO 5 eliminated - return when found
    if (ICNT .EQ. MX) then
      ISEGNO = I
      return
    end if
  end do

  ! If we reach here, tag not found (GOTO 4 path)
  write(*,7) ITAGI
  stop

6 format(4X, 'CHECK DATA, PARAMETER SPECIFYING SEGMENT POSITION IN ', &
           'A GROUP OF EQUAL TAGS MUST NOT BE ZERO')
7 format(///, 10X, 'NO SEGMENT HAS AN ITAG OF ', I5)

end function ISEGNO
