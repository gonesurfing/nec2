! Unit tests for individual NEC2 functions
! Tests mathematical and utility functions against known values

program test_unit_functions
  implicit none

  integer :: total_tests, passed_tests

  total_tests = 0
  passed_tests = 0

  write(*,'(A)') "========================================"
  write(*,'(A)') "NEC2 Unit Function Tests"
  write(*,'(A)') "========================================"
  write(*,*)

  ! Test mathematical functions
  call test_db10(total_tests, passed_tests)
  call test_atgn2(total_tests, passed_tests)
  call test_cang(total_tests, passed_tests)
  call test_zint(total_tests, passed_tests)

  ! Test utility functions
  call test_isegno(total_tests, passed_tests)

  ! Summary
  write(*,*)
  write(*,'(A)') "========================================"
  write(*,'(A,I0,A,I0)') "Results: ", passed_tests, " / ", total_tests, " passed"
  write(*,'(A)') "========================================"

  if (passed_tests .ne. total_tests) then
    stop 1
  end if

contains

  subroutine assert_real_equal(actual, expected, tolerance, test_name, &
                                total, passed)
    real(8), intent(in) :: actual, expected, tolerance
    character(*), intent(in) :: test_name
    integer, intent(inout) :: total, passed
    real(8) :: rel_error

    total = total + 1
    rel_error = abs(actual - expected) / max(abs(expected), 1.0d-20)

    if (rel_error < tolerance) then
      passed = passed + 1
      write(*,'(A,A)') "PASS: ", test_name
    else
      write(*,'(A,A)') "FAIL: ", test_name
      write(*,'(A,ES12.4,A,ES12.4,A,ES12.4)') &
        "  Expected: ", expected, ", Got: ", actual, &
        ", Error: ", rel_error
    end if
  end subroutine

  subroutine assert_complex_equal(actual, expected, tolerance, test_name, &
                                   total, passed)
    complex(8), intent(in) :: actual, expected
    real(8), intent(in) :: tolerance
    character(*), intent(in) :: test_name
    integer, intent(inout) :: total, passed
    real(8) :: rel_error

    total = total + 1
    rel_error = abs(actual - expected) / max(abs(expected), 1.0d-20)

    if (rel_error < tolerance) then
      passed = passed + 1
      write(*,'(A,A)') "PASS: ", test_name
    else
      write(*,'(A,A)') "FAIL: ", test_name
      write(*,'(A,2ES12.4,A,2ES12.4,A,ES12.4)') &
        "  Expected: ", expected, ", Got: ", actual, &
        ", Error: ", rel_error
    end if
  end subroutine

  subroutine test_db10(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result
    real(8), external :: db10

    write(*,'(A)') "Testing DB10 (dB conversion)..."

    ! Test positive values
    result = db10(1.0d0)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "db10(1.0) = 0 dB", total, passed)

    result = db10(10.0d0)
    call assert_real_equal(result, 10.0d0, 1.0d-10, &
                          "db10(10.0) = 10 dB", total, passed)

    result = db10(100.0d0)
    call assert_real_equal(result, 20.0d0, 1.0d-10, &
                          "db10(100.0) = 20 dB", total, passed)

    result = db10(0.1d0)
    call assert_real_equal(result, -10.0d0, 1.0d-10, &
                          "db10(0.1) = -10 dB", total, passed)
  end subroutine

  subroutine test_atgn2(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result, pi
    real(8), external :: atgn2

    pi = 3.141592653589793d0

    write(*,'(A)') "Testing ATGN2 (arctangent)..."

    ! Test quadrants
    result = atgn2(1.0d0, 0.0d0)
    call assert_real_equal(result, pi/2.0d0, 1.0d-10, &
                          "atgn2(1,0) = π/2", total, passed)

    result = atgn2(0.0d0, 1.0d0)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "atgn2(0,1) = 0", total, passed)

    result = atgn2(-1.0d0, 0.0d0)
    call assert_real_equal(result, -pi/2.0d0, 1.0d-10, &
                          "atgn2(-1,0) = -π/2", total, passed)

    result = atgn2(1.0d0, 1.0d0)
    call assert_real_equal(result, pi/4.0d0, 1.0d-10, &
                          "atgn2(1,1) = π/4", total, passed)
  end subroutine

  subroutine test_cang(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result
    complex(8) :: z
    real(8), external :: cang

    write(*,'(A)') "Testing CANG (complex angle)..."

    ! Test real positive
    z = cmplx(1.0d0, 0.0d0, kind=8)
    result = cang(z)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "cang(1+0i) = 0", total, passed)

    ! Test imaginary
    z = cmplx(0.0d0, 1.0d0, kind=8)
    result = cang(z)
    call assert_real_equal(result, 90.0d0, 1.0d-10, &
                          "cang(0+1i) = 90°", total, passed)

    ! Test negative real
    z = cmplx(-1.0d0, 0.0d0, kind=8)
    result = cang(z)
    call assert_real_equal(result, 180.0d0, 1.0d-10, &
                          "cang(-1+0i) = 180°", total, passed)
  end subroutine

  subroutine test_zint(total, passed)
    integer, intent(inout) :: total, passed
    complex(8) :: result, expected
    complex(8) :: zint
    real(8) :: sigl, rolam

    write(*,'(A)') "Testing ZINT (internal impedance)..."

    ! Test for copper wire at various frequencies
    ! σ = 5.8e7 S/m for copper, radius = 0.001 wavelengths
    sigl = 5.8d7
    rolam = 0.001d0

    result = zint(sigl, rolam)

    ! For high conductivity, should get small positive real part
    ! and small negative imaginary part (skin effect)
    ! Just check that it's in reasonable range
    if (real(result) > 0.0d0 .and. real(result) < 1.0d0 .and. &
        aimag(result) < 0.0d0 .and. aimag(result) > -1.0d0) then
      passed = passed + 1
      write(*,'(A,A)') "PASS: ", "zint returns reasonable values"
    else
      write(*,'(A,A)') "FAIL: ", "zint out of expected range"
      write(*,'(A,2ES12.4)') "  Got: ", result
    end if
    total = total + 1
  end subroutine

  subroutine test_isegno(total, passed)
    integer, intent(inout) :: total, passed
    integer :: result, expected
    integer, external :: isegno

    ! This would need the geometry data to be set up
    ! Placeholder for demonstration
    write(*,'(A)') "Testing ISEGNO (segment number lookup)..."
    write(*,'(A)') "  (requires geometry setup - skipped)"
  end subroutine

end program test_unit_functions
