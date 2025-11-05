! Unit tests for NEW modernized NEC2 modules
! Tests the modernized utilities against known values

program test_new_modules
  use nec2_constants
  use nec2_utilities
  implicit none

  integer :: total_tests, passed_tests

  total_tests = 0
  passed_tests = 0

  write(*,'(A)') "========================================"
  write(*,'(A)') "NEC2 Modernized Module Tests"
  write(*,'(A)') "========================================"
  write(*,*)

  ! Test modernized utility functions
  call test_db10_new(total_tests, passed_tests)
  call test_db20_new(total_tests, passed_tests)
  call test_atgn2_new(total_tests, passed_tests)
  call test_cang_new(total_tests, passed_tests)
  call test_safe_divide(total_tests, passed_tests)
  call test_distance_3d(total_tests, passed_tests)

  ! Test constants
  call test_constants(total_tests, passed_tests)

  ! Summary
  write(*,*)
  write(*,'(A)') "========================================"
  write(*,'(A,I0,A,I0)') "Results: ", passed_tests, " / ", total_tests, " passed"
  if (passed_tests == total_tests) then
    write(*,'(A)') "✓ ALL TESTS PASSED"
  else
    write(*,'(A,I0,A)') "✗ ", total_tests - passed_tests, " TESTS FAILED"
  end if
  write(*,'(A)') "========================================"

  if (passed_tests /= total_tests) then
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
      write(*,'(A,A)') "  ✓ ", test_name
    else
      write(*,'(A,A)') "  ✗ ", test_name
      write(*,'(A,ES12.4,A,ES12.4,A,ES12.4)') &
        "    Expected: ", expected, ", Got: ", actual, &
        ", Error: ", rel_error
    end if
  end subroutine

  subroutine test_db10_new(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result

    write(*,'(A)') "Testing db10() - dB conversion..."

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

    result = db10(1.0d-30)
    call assert_real_equal(result, -999.99d0, 1.0d-10, &
                          "db10(tiny) = -999.99 dB", total, passed)
  end subroutine

  subroutine test_db20_new(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result

    write(*,'(A)') "Testing db20() - voltage dB conversion..."

    result = db20(1.0d0)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "db20(1.0) = 0 dB", total, passed)

    result = db20(10.0d0)
    call assert_real_equal(result, 20.0d0, 1.0d-10, &
                          "db20(10.0) = 20 dB", total, passed)
  end subroutine

  subroutine test_atgn2_new(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result

    write(*,'(A)') "Testing atgn2() - arctangent..."

    result = atgn2(1.0d0, 0.0d0)
    call assert_real_equal(result, PI/2.0d0, 1.0d-10, &
                          "atgn2(1,0) = π/2", total, passed)

    result = atgn2(0.0d0, 1.0d0)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "atgn2(0,1) = 0", total, passed)

    result = atgn2(-1.0d0, 0.0d0)
    call assert_real_equal(result, -PI/2.0d0, 1.0d-10, &
                          "atgn2(-1,0) = -π/2", total, passed)

    result = atgn2(1.0d0, 1.0d0)
    call assert_real_equal(result, PI/4.0d0, 1.0d-10, &
                          "atgn2(1,1) = π/4", total, passed)

    result = atgn2(0.0d0, 0.0d0)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "atgn2(0,0) = 0 (degenerate)", total, passed)
  end subroutine

  subroutine test_cang_new(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result
    complex(8) :: z

    write(*,'(A)') "Testing cang() - complex angle..."

    z = cmplx(1.0d0, 0.0d0, kind=8)
    result = cang(z)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "cang(1+0i) = 0°", total, passed)

    z = cmplx(0.0d0, 1.0d0, kind=8)
    result = cang(z)
    call assert_real_equal(result, 90.0d0, 1.0d-10, &
                          "cang(0+1i) = 90°", total, passed)

    z = cmplx(-1.0d0, 0.0d0, kind=8)
    result = cang(z)
    call assert_real_equal(result, 180.0d0, 1.0d-10, &
                          "cang(-1+0i) = 180°", total, passed)

    z = cmplx(0.0d0, 0.0d0, kind=8)
    result = cang(z)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "cang(0+0i) = 0° (degenerate)", total, passed)
  end subroutine

  subroutine test_safe_divide(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result

    write(*,'(A)') "Testing safe_divide()..."

    result = safe_divide(10.0d0, 2.0d0, 999.0d0)
    call assert_real_equal(result, 5.0d0, 1.0d-10, &
                          "safe_divide(10/2) = 5", total, passed)

    result = safe_divide(10.0d0, 0.0d0, 999.0d0)
    call assert_real_equal(result, 999.0d0, 1.0d-10, &
                          "safe_divide(10/0) = default", total, passed)
  end subroutine

  subroutine test_distance_3d(total, passed)
    integer, intent(inout) :: total, passed
    real(8) :: result

    write(*,'(A)') "Testing distance_3d()..."

    result = distance_3d(0.0d0, 0.0d0, 0.0d0, 3.0d0, 4.0d0, 0.0d0)
    call assert_real_equal(result, 5.0d0, 1.0d-10, &
                          "distance 3-4-5 triangle", total, passed)

    result = distance_3d(1.0d0, 1.0d0, 1.0d0, 1.0d0, 1.0d0, 1.0d0)
    call assert_real_equal(result, 0.0d0, 1.0d-10, &
                          "distance to same point", total, passed)
  end subroutine

  subroutine test_constants(total, passed)
    integer, intent(inout) :: total, passed

    write(*,'(A)') "Testing constants..."

    call assert_real_equal(PI, 3.141592654d0, 1.0d-9, &
                          "PI value", total, passed)

    call assert_real_equal(TWO_PI, 6.283185307d0, 1.0d-9, &
                          "TWO_PI value", total, passed)

    call assert_real_equal(DEG_TO_RAD * 180.0d0, PI, 1.0d-9, &
                          "DEG_TO_RAD conversion", total, passed)

    call assert_real_equal(wavelength(300.0d0), 1.0d0, 1.0d-9, &
                          "wavelength at 300 MHz", total, passed)
  end subroutine

end program test_new_modules
