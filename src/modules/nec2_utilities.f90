! nec2_utilities.f90
! Utility functions used throughout NEC2
! Simple mathematical and helper functions with no/minimal dependencies

module nec2_utilities
  use nec2_constants
  use nec2_data_types
  implicit none
  public

contains

  !============================================================================
  ! DB10 - Convert magnitude to decibels (10*log10)
  !============================================================================
  !RETURNS DB FOR MAGNITUDE (FIELD) OR MAG**2 (POWER) I
  pure function db10(x) result(db_value)
    ! Returns dB for magnitude (field)
    ! If x < 1e-20, returns -999.99 to indicate very small value
    real(8), intent(in) :: x
    real(8) :: db_value

    if (x < 1.0d-20) then
      db_value = -999.99d0
    else
      db_value = 10.0d0 * log10(x)
    end if
  end function db10

  !============================================================================
  ! DB20 - Convert magnitude to decibels (20*log10)
  !============================================================================
  pure function db20(x) result(db_value)
    ! Returns dB for power (20*log10)
    ! If x < 1e-20, returns -999.99 to indicate very small value
    real(8), intent(in) :: x
    real(8) :: db_value

    if (x < 1.0d-20) then
      db_value = -999.99d0
    else
      db_value = 20.0d0 * log10(x)
    end if
  end function db20

  !============================================================================
  ! ATGN2 - Modified arctangent function
  !============================================================================
  pure function atgn2(x, y) result(angle)
    ! Arctangent function modified to return 0 when x=y=0
    ! This avoids undefined behavior in atan2(0,0)
    !
    ! Arguments:
    !   x - numerator (opposite side)
    !   y - denominator (adjacent side)
    !
    ! Returns:
    !   angle in radians, or 0 if both x and y are zero
    real(8), intent(in) :: x, y
    real(8) :: angle

    ! Exact zero check (matches original behavior)
    if (x == 0.0d0 .and. y == 0.0d0) then
      angle = 0.0d0
    else
      angle = atan2(x, y)
    end if
  end function atgn2

  !============================================================================
  ! CANG - Phase angle of complex number in degrees
  !============================================================================
  pure function cang(z) result(phase_deg)
    ! Returns the phase angle of a complex number in degrees
    !
    ! Arguments:
    !   z - complex number
    !
    ! Returns:
    !   phase angle in degrees
    complex(8), intent(in) :: z
    real(8) :: phase_deg

    phase_deg = atgn2(aimag(z), real(z)) * RAD_TO_DEG
  end function cang

  !============================================================================
  ! ISEGNO - Find segment number by tag
  !============================================================================
  function isegno(geom, itagi, mx) result(segment_number)
    ! Returns the segment number of the MXth segment having tag number ITAGI
    ! If ITAGI=0, returns segment number MX directly
    !
    ! Arguments:
    !   geom - geometry data structure
    !   itagi - tag number to search for (0 = return mx directly)
    !   mx - which occurrence of the tag (1st, 2nd, etc.)
    !
    ! Returns:
    !   segment_number - the found segment number
    !
    ! Errors:
    !   Stops execution if mx <= 0 or if tag not found
    type(geometry_data), intent(in) :: geom
    integer, intent(in) :: itagi, mx
    integer :: segment_number
    integer :: i, icnt

    ! Check for valid mx
    if (mx <= 0) then
      write(*,'(A)') 'ERROR in ISEGNO: Parameter specifying segment ' // &
                     'position in a group of equal tags must not be zero'
      stop 1
    end if

    ! If itagi=0, return mx directly
    if (itagi == 0) then
      segment_number = mx
      return
    end if

    ! Search for the tag
    icnt = 0
    if (geom%n >= 1) then
      do i = 1, geom%n
        if (geom%itag(i) == itagi) then
          icnt = icnt + 1
          if (icnt == mx) then
            segment_number = i
            return
          end if
        end if
      end do
    end if

    ! Tag not found
    write(*,'(A,I0)') 'ERROR in ISEGNO: No segment has an ITAG of ', itagi
    stop 1
  end function isegno

  !============================================================================
  ! Additional utility functions
  !============================================================================

  ! pure function cmplx_magnitude(z) result(mag)
  !   ! Calculate magnitude of complex number
  !   complex(8), intent(in) :: z
  !   real(8) :: mag
  !   mag = abs(z)
  ! end function cmplx_magnitude

  ! pure function cmplx_phase_rad(z) result(phase)
  !   ! Phase angle in radians
  !   complex(8), intent(in) :: z
  !   real(8) :: phase
  !   phase = atgn2(aimag(z), real(z, kind=8))
  ! end function cmplx_phase_rad

  pure function distance_3d(x1, y1, z1, x2, y2, z2) result(dist)
    ! Calculate 3D distance between two points
    real(8), intent(in) :: x1, y1, z1, x2, y2, z2
    real(8) :: dist
    real(8) :: dx, dy, dz

    dx = x2 - x1
    dy = y2 - y1
    dz = z2 - z1
    dist = sqrt(dx*dx + dy*dy + dz*dz)
  end function distance_3d

  ! pure function normalize_vector(x, y, z) result(mag)
  !   ! Return magnitude and normalize vector components in place
  !   ! Note: This version returns magnitude; caller must divide by it
  !   real(8), intent(in) :: x, y, z
  !   real(8) :: mag
  !   mag = sqrt(x*x + y*y + z*z)
  ! end function normalize_vector

  !============================================================================
  ! String utilities
  !============================================================================

  subroutine upcase(intext, outtxt, length)
    ! Convert string to uppercase
    ! Original UPCASE routine from nec2dxs.f
    character(*), intent(in) :: intext
    character(*), intent(out) :: outtxt
    integer, intent(out) :: length
    integer :: i, ic

    length = len_trim(intext)
    outtxt = intext

    do i = 1, length
      ic = ichar(outtxt(i:i))
      if (ic >= ichar('a') .and. ic <= ichar('z')) then
        outtxt(i:i) = char(ic - 32)
      end if
    end do
  end subroutine upcase

  !============================================================================
  ! Timing utility
  !============================================================================

  subroutine cpusec(cpusecd)
    ! Get CPU time in seconds
    ! Modern replacement for original CPUSEC
    real(8), intent(out) :: cpusecd
    real :: cpu_time_val

    call cpu_time(cpu_time_val)
    cpusecd = real(cpu_time_val, kind=8)
  end subroutine cpusec

  !============================================================================
  ! Error checking utilities
  !============================================================================

  ! pure function is_near_zero(x, tolerance) result(is_zero)
  !   ! Check if value is effectively zero within tolerance
  !   real(8), intent(in) :: x
  !   real(8), intent(in), optional :: tolerance
  !   logical :: is_zero
  !   real(8) :: tol

  !   tol = 1.0d-20
  !   if (present(tolerance)) tol = tolerance

  !   is_zero = abs(x) < tol
  ! end function is_near_zero

  ! pure function safe_divide(numerator, denominator, default_val) result(quotient)
  !   ! Safe division that returns default value if denominator is near zero
  !   real(8), intent(in) :: numerator, denominator
  !   real(8), intent(in), optional :: default_val
  !   real(8) :: quotient
  !   real(8) :: def_value

  !   def_value = 0.0d0
  !   if (present(default_val)) def_value = default_val

  !   if (abs(denominator) < 1.0d-20) then
  !     quotient = def_value
  !   else
  !     quotient = numerator / denominator
  !   end if
  ! end function safe_divide

end module nec2_utilities
