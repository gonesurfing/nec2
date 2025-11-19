FUNCTION ISEGNO(ITAGI, MX)
  USE nec2d_params
  USE nec2d_commons, ONLY: &
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
  IMPLICIT REAL*8(A-H,O-Z)

  ! Validate MX parameter (GOTO 1 eliminated)
  IF (MX .LE. 0) THEN
    WRITE(*,6)
    STOP
  END IF

  ICNT = 0

  ! Handle ITAGI=0 case (GOTO 2 eliminated)
  IF (ITAGI .EQ. 0) THEN
    ISEGNO = MX
    RETURN
  END IF

  ! Validate N parameter (GOTO 4 eliminated)
  IF (N .LT. 1) THEN
    WRITE(*,7) ITAGI
    STOP
  END IF

  ! Search for Mth segment with tag ITAGI
  DO I = 1, N
    ! GOTO 3 eliminated with CYCLE
    IF (ITAG(I) .NE. ITAGI) CYCLE

    ICNT = ICNT + 1

    ! GOTO 5 eliminated - return when found
    IF (ICNT .EQ. MX) THEN
      ISEGNO = I
      RETURN
    END IF
  END DO

  ! If we reach here, tag not found (GOTO 4 path)
  WRITE(*,7) ITAGI
  STOP

6 FORMAT(4X, 'CHECK DATA, PARAMETER SPECIFYING SEGMENT POSITION IN ', &
           'A GROUP OF EQUAL TAGS MUST NOT BE ZERO')
7 FORMAT(///, 10X, 'NO SEGMENT HAS AN ITAG OF ', I5)

END FUNCTION ISEGNO
