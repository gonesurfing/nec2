! Template for testing a modernized module against original implementation
! This shows how to test modules incrementally during modernization

program test_module_example
  ! This template shows testing of the geometry module as an example
  use nec2_geometry  ! The new modernized module
  implicit none

  ! Test control
  integer :: total_tests, passed_tests
  real(8), parameter :: TOLERANCE = 1.0d-10

  total_tests = 0
  passed_tests = 0

  write(*,'(A)') "========================================"
  write(*,'(A)') "Testing nec2_geometry Module"
  write(*,'(A)') "========================================"
  write(*,*)

  ! Run tests
  call test_wire_generation(total_tests, passed_tests)
  call test_helix_generation(total_tests, passed_tests)
  call test_patch_generation(total_tests, passed_tests)

  ! Summary
  write(*,*)
  write(*,'(A)') "========================================"
  write(*,'(A,I0,A,I0)') "Results: ", passed_tests, " / ", total_tests
  if (passed_tests == total_tests) then
    write(*,'(A)') "Status: PASS"
  else
    write(*,'(A)') "Status: FAIL"
    stop 1
  end if
  write(*,'(A)') "========================================"

contains

  subroutine test_wire_generation(total, passed)
    ! Test WIRE subroutine against original implementation
    integer, intent(inout) :: total, passed

    ! Variables for original implementation
    real(8) :: x_old(100), y_old(100), z_old(100)
    real(8) :: si_old(100), bi_old(100)

    ! Variables for new implementation
    real(8) :: x_new(100), y_new(100), z_new(100)
    real(8) :: si_new(100), bi_new(100)

    ! Test parameters
    real(8) :: xw1, yw1, zw1, xw2, yw2, zw2, rad
    integer :: ns, i
    logical :: test_passed

    write(*,'(A)') "Testing WIRE generation..."

    ! Test case 1: Simple straight wire
    xw1 = 0.0d0
    yw1 = 0.0d0
    zw1 = -0.25d0
    xw2 = 0.0d0
    yw2 = 0.0d0
    zw2 = 0.25d0
    rad = 0.001d0
    ns = 11

    ! Call original implementation
    call wire_original(xw1, yw1, zw1, xw2, yw2, zw2, rad, &
                       1.0d0, 1.0d0, ns, 1, &
                       x_old, y_old, z_old, si_old, bi_old)

    ! Call new implementation (from module)
    call wire_new(xw1, yw1, zw1, xw2, yw2, zw2, rad, &
                  1.0d0, 1.0d0, ns, 1, &
                  x_new, y_new, z_new, si_new, bi_new)

    ! Compare results
    test_passed = .true.
    do i = 1, ns
      if (abs(x_old(i) - x_new(i)) > TOLERANCE) test_passed = .false.
      if (abs(y_old(i) - y_new(i)) > TOLERANCE) test_passed = .false.
      if (abs(z_old(i) - z_new(i)) > TOLERANCE) test_passed = .false.
      if (abs(si_old(i) - si_new(i)) > TOLERANCE) test_passed = .false.
      if (abs(bi_old(i) - bi_new(i)) > TOLERANCE) test_passed = .false.
    end do

    total = total + 1
    if (test_passed) then
      passed = passed + 1
      write(*,'(A)') "  PASS: Straight wire generation"
    else
      write(*,'(A)') "  FAIL: Straight wire generation"
      ! Print first difference found
      do i = 1, ns
        if (abs(z_old(i) - z_new(i)) > TOLERANCE) then
          write(*,'(A,I3,A,ES12.4,A,ES12.4)') &
            "    Segment ", i, ": old z=", z_old(i), " new z=", z_new(i)
          exit
        end if
      end do
    end if

  end subroutine test_wire_generation

  subroutine test_helix_generation(total, passed)
    integer, intent(inout) :: total, passed
    write(*,'(A)') "Testing HELIX generation..."
    ! Similar structure to test_wire_generation
    ! Compare old vs new HELIX implementation
    write(*,'(A)') "  (Not implemented in template)"
  end subroutine

  subroutine test_patch_generation(total, passed)
    integer, intent(inout) :: total, passed
    write(*,'(A)') "Testing PATCH generation..."
    ! Similar structure to test_wire_generation
    ! Compare old vs new PATCH implementation
    write(*,'(A)') "  (Not implemented in template)"
  end subroutine

  ! Wrapper for original implementation (links to original .o file)
  subroutine wire_original(xw1, yw1, zw1, xw2, yw2, zw2, rad, &
                          rdel, rrad, ns, itg, &
                          x, y, z, si, bi)
    real(8), intent(in) :: xw1, yw1, zw1, xw2, yw2, zw2
    real(8), intent(in) :: rad, rdel, rrad
    integer, intent(in) :: ns, itg
    real(8), intent(out) :: x(*), y(*), z(*), si(*), bi(*)

    ! This would call the original WIRE subroutine
    ! Compile original code separately and link
    external wire
    call wire(xw1, yw1, zw1, xw2, yw2, zw2, rad, rdel, rrad, ns, itg)
    ! Then extract results from COMMON blocks

  end subroutine

  subroutine wire_new(xw1, yw1, zw1, xw2, yw2, zw2, rad, &
                     rdel, rrad, ns, itg, &
                     x, y, z, si, bi)
    ! New implementation from modernized module
    real(8), intent(in) :: xw1, yw1, zw1, xw2, yw2, zw2
    real(8), intent(in) :: rad, rdel, rrad
    integer, intent(in) :: ns, itg
    real(8), intent(out) :: x(*), y(*), z(*), si(*), bi(*)

    ! Call the new module version
    ! use nec2_geometry, only: generate_wire
    ! call generate_wire(...)

  end subroutine

end program test_module_example
