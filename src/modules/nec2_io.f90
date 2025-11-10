! nec2_io.f90
! Input/output operations for NEC2
! Card reading, parsing, and output formatting

module nec2_io
  use nec2_constants
  use nec2_data_types
  implicit none
  private

  ! Public subroutines
  public :: readgm, readmn, parsit, prnt
  public :: gfout, rdpat, nfpat, datagn
  public :: upcase_string

contains

  !============================================================================
  ! READGM - Read geometry card
  !============================================================================
  subroutine readgm(inunit, code, i1, i2, r1, r2, r3, r4, r5, r6, r7)
    ! Reads a geometry record and parses it
    !
    ! Arguments:
    !   inunit - input file unit
    !   code - two letter mnemonic code (output)
    !   i1, i2 - integer values from record
    !   r1-r7 - real values from record

    integer, intent(in) :: inunit
    character(len=*), intent(out) :: code
    integer, intent(out) :: i1, i2
    real(8), intent(out) :: r1, r2, r3, r4, r5, r6, r7

    integer :: intval(2), ieof
    real(8) :: reaval(7)

    ! Call parser to read and parse record
    call parsit(inunit, 2, 7, code, intval, reaval, ieof)

    ! Set return variables from parsed arrays
    if (ieof < 0) code = 'GE'  ! End of file marker

    i1 = intval(1)
    i2 = intval(2)

    r1 = reaval(1)
    r2 = reaval(2)
    r3 = reaval(3)
    r4 = reaval(4)
    r5 = reaval(5)
    r6 = reaval(6)
    r7 = reaval(7)

  end subroutine readgm

  !============================================================================
  ! READMN - Read control card
  !============================================================================
  subroutine readmn(inunit, code, i1, i2, i3, i4, f1, f2, f3, f4, f5, f6)
    ! Reads a control record and parses it
    !
    ! Arguments:
    !   inunit - input file unit
    !   code - two letter mnemonic code (output)
    !   i1-i4 - integer values from record
    !   f1-f6 - real values from record

    integer, intent(in) :: inunit
    character(len=*), intent(out) :: code
    integer, intent(out) :: i1, i2, i3, i4
    real(8), intent(out) :: f1, f2, f3, f4, f5, f6

    integer :: intval(4), ieof
    real(8) :: reaval(6)

    ! Call parser to read and parse record
    call parsit(inunit, 4, 6, code, intval, reaval, ieof)

    ! Set return variables from parsed arrays
    if (ieof < 0) code = 'EN'  ! End marker

    i1 = intval(1)
    i2 = intval(2)
    i3 = intval(3)
    i4 = intval(4)

    f1 = reaval(1)
    f2 = reaval(2)
    f3 = reaval(3)
    f4 = reaval(4)
    f5 = reaval(5)
    f6 = reaval(6)

  end subroutine readmn

  !============================================================================
  ! PARSIT - Parse input line
  !============================================================================
  subroutine parsit(inunit, maxint, maxrea, cmnd, intfld, reafld, ieof)
    ! Parses a NEC2 input card into command, integers, and reals
    !
    ! Arguments:
    !   inunit - input file unit
    !   maxint - maximum number of integers to parse
    !   maxrea - maximum number of reals to parse
    !   cmnd - command code (output)
    !   intfld - integer field array (output)
    !   reafld - real field array (output)
    !   ieof - end-of-file flag (output)

    integer, intent(in) :: inunit, maxint, maxrea
    character(len=*), intent(out) :: cmnd
    integer, intent(out) :: intfld(:), ieof
    real(8), intent(out) :: reafld(:)

    character(len=132) :: line
    integer :: ios, istart, iend, i
    real(8) :: rval

    ! Read line from input
    read(inunit, '(A)', iostat=ios) line
    if (ios /= 0) then
      ieof = -1
      return
    end if

    ieof = 0

    ! Initialize output arrays
    intfld(1:maxint) = 0
    reafld(1:maxrea) = 0.0d0

    ! Extract command code (first 2 characters)
    cmnd = line(1:2)
    call upcase_string(cmnd)

    ! Parse integer fields (columns 3-10, 2x I5 format)
    if (maxint >= 1 .and. len_trim(line) >= 7) then
      read(line(3:7), '(I5)', iostat=ios) intfld(1)
    end if
    if (maxint >= 2 .and. len_trim(line) >= 12) then
      read(line(8:12), '(I5)', iostat=ios) intfld(2)
    end if
    if (maxint >= 3 .and. len_trim(line) >= 17) then
      read(line(13:17), '(I5)', iostat=ios) intfld(3)
    end if
    if (maxint >= 4 .and. len_trim(line) >= 22) then
      read(line(18:22), '(I5)', iostat=ios) intfld(4)
    end if

    ! Parse real fields (F10.5 format, starting at column 11 or 21)
    istart = 11
    if (maxint >= 3) istart = 21

    do i = 1, maxrea
      iend = istart + 9
      if (len_trim(line) >= iend) then
        read(line(istart:iend), '(F10.5)', iostat=ios) rval
        if (ios == 0) reafld(i) = rval
      end if
      istart = iend + 1
    end do

  end subroutine parsit

  !============================================================================
  ! PRNT - Print input data (formatted output)
  !============================================================================
  subroutine prnt(in1, in2, in3, fl1, fl2, fl3, fl4, fl5, fl6, ctype)
    ! Prints input data for loading, inserting blanks for zeros
    !
    ! Arguments:
    !   in1-3 - integer values to print
    !   fl1-6 - real values to print
    !   ctype - character string description

    integer, intent(in) :: in1, in2, in3
    real(8), intent(in) :: fl1, fl2, fl3, fl4, fl5, fl6
    character(len=*), intent(in) :: ctype

    character(len=5) :: cint(3)
    character(len=13) :: cflt(6)
    integer :: i

    ! Initialize strings
    do i = 1, 3
      cint(i) = '     '
    end do

    ! Format integer fields (blank if zero, "ALL" if all zero)
    if (in1 == 0 .and. in2 == 0 .and. in3 == 0) then
      cint(1) = '  ALL'
    else
      if (in1 /= 0) write(cint(1), '(I5)') in1
      if (in2 /= 0) write(cint(2), '(I5)') in2
      if (in3 /= 0) write(cint(3), '(I5)') in3
    end if

    ! Format real fields (blank if near zero)
    do i = 1, 6
      cflt(i) = '             '
    end do

    if (abs(fl1) > 1.0d-30) write(cflt(1), '(1P,E13.4)') fl1
    if (abs(fl2) > 1.0d-30) write(cflt(2), '(1P,E13.4)') fl2
    if (abs(fl3) > 1.0d-30) write(cflt(3), '(1P,E13.4)') fl3
    if (abs(fl4) > 1.0d-30) write(cflt(4), '(1P,E13.4)') fl4
    if (abs(fl5) > 1.0d-30) write(cflt(5), '(1P,E13.4)') fl5
    if (abs(fl6) > 1.0d-30) write(cflt(6), '(1P,E13.4)') fl6

    ! Print formatted output
    write(*, '(/,3X,3A5,3X,6A13,3X,A)') (cint(i), i=1,3), (cflt(i), i=1,6), trim(ctype)

  end subroutine prnt

  !============================================================================
  ! GFOUT - Green's function output
  !============================================================================
  subroutine gfout(field_pattern)
    ! Outputs numerical Green's function data
    ! Placeholder for full implementation

    type(field_pattern_data), intent(in) :: field_pattern

    write(*,'(A)') ' '
    write(*,'(A)') ' GREEN''S FUNCTION OUTPUT'
    write(*,'(A)') ' (Full implementation pending)'
    write(*,'(A)') ' '

  end subroutine gfout

  !============================================================================
  ! RDPAT - Read radiation pattern request
  !============================================================================
  subroutine rdpat()
    ! Reads radiation pattern calculation request
    ! Placeholder for full implementation

    write(*,'(A)') ' Reading radiation pattern request...'

  end subroutine rdpat

  !============================================================================
  ! NFPAT - Near-field pattern output
  !============================================================================
  subroutine nfpat(field_pattern)
    ! Outputs near-field pattern data
    ! Placeholder for full implementation

    type(field_pattern_data), intent(in) :: field_pattern

    write(*,'(A)') ' '
    write(*,'(A)') ' NEAR-FIELD PATTERN OUTPUT'
    write(*,'(A)') ' (Full implementation pending)'
    write(*,'(A)') ' '

  end subroutine nfpat

  !============================================================================
  ! DATAGN - Data generation control
  !============================================================================
  subroutine datagn()
    ! Controls data generation and output
    ! Placeholder for full implementation

    ! This would handle various data output requests
    ! including impedance, admittance, current distribution, etc.

  end subroutine datagn

  !============================================================================
  ! Helper subroutines
  !============================================================================

  subroutine upcase_string(str)
    ! Converts string to uppercase
    character(len=*), intent(inout) :: str
    integer :: i, ic

    do i = 1, len(str)
      ic = iachar(str(i:i))
      if (ic >= iachar('a') .and. ic <= iachar('z')) then
        str(i:i) = achar(ic - 32)
      end if
    end do
  end subroutine upcase_string

  subroutine print_geometry_summary(geom)
    ! Prints summary of geometry
    type(geometry_data), intent(in) :: geom

    write(*,'(A)') ' '
    write(*,'(A)') ' GEOMETRY SUMMARY'
    write(*,'(A,I0)') '   Number of wire segments: ', geom%n
    write(*,'(A,I0)') '   Number of patches: ', geom%m
    write(*,'(A,F10.5,A)') '   Wavelength: ', geom%wlam, ' units'
    write(*,'(A)') ' '

  end subroutine print_geometry_summary

  subroutine print_current_summary(current, geom)
    ! Prints summary of current distribution
    type(current_data), intent(in) :: current
    type(geometry_data), intent(in) :: geom

    real(8) :: max_current, total_power, curr_mag
    integer :: i, max_loc

    write(*,'(A)') ' '
    write(*,'(A)') ' CURRENT DISTRIBUTION SUMMARY'

    ! Find maximum current
    max_current = 0.0d0
    max_loc = 1
    do i = 1, geom%n
      curr_mag = sqrt(current%air(i)**2 + current%aii(i)**2)
      if (curr_mag > max_current) then
        max_current = curr_mag
        max_loc = i
      end if
    end do

    write(*,'(A,1P,E12.4,A,I0)') '   Maximum current: ', max_current, ' A at segment ', max_loc
    write(*,'(A)') ' '

  end subroutine print_current_summary

  subroutine print_pattern_header(theta_start, theta_end, theta_inc, &
                                   phi_start, phi_end, phi_inc)
    ! Prints header for radiation pattern output
    real(8), intent(in) :: theta_start, theta_end, theta_inc
    real(8), intent(in) :: phi_start, phi_end, phi_inc

    write(*,'(A)') ' '
    write(*,'(A)') ' RADIATION PATTERN'
    write(*,'(A)') ' ================='
    write(*,'(A,F7.2,A,F7.2,A,F7.2)') '   Theta range: ', theta_start, &
      ' to ', theta_end, ' deg, step ', theta_inc
    write(*,'(A,F7.2,A,F7.2,A,F7.2)') '   Phi range:   ', phi_start, &
      ' to ', phi_end, ' deg, step ', phi_inc
    write(*,'(A)') ' '
    write(*,'(A)') '  THETA   PHI   |E(theta)|  |E(phi)|   GAIN(dBi)  PHASE(deg)'
    write(*,'(A)') ' ------- ------- ---------- ---------- ---------- ----------'

  end subroutine print_pattern_header

  subroutine print_impedance_data(segment, voltage, current, impedance)
    ! Prints impedance data for a segment
    integer, intent(in) :: segment
    complex(8), intent(in) :: voltage, current, impedance

    real(8) :: r_part, x_part, v_mag, i_mag

    r_part = real(impedance, kind=8)
    x_part = aimag(impedance)
    v_mag = abs(voltage)
    i_mag = abs(current)

    write(*,'(I6,2X,4(F12.4,2X))') segment, v_mag, i_mag, r_part, x_part

  end subroutine print_impedance_data

end module nec2_io
