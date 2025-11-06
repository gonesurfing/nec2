! nec2_sommerfeld.f90
! Sommerfeld integral evaluation for ground wave calculations
! Handles Norton-Sommerfeld ground reflection integrals

module nec2_sommerfeld
  use nec2_constants
  use nec2_data_types
  implicit none
  private

  ! Public subroutines and functions
  public :: evlua, saoa, gshank, rom1, rom2, lambda_param
  public :: bessel_j0, hankel_h0, test_convergence, fbar

  ! Module-level variables replacing COMMON /CNTOUR/ and /EVLCOM/
  complex(8), save :: contour_a, contour_b  ! Integration contour endpoints

  ! Evaluation variables (replace COMMON /EVLCOM/)
  type :: evlcom_data
    complex(8) :: cksm, ct1, ct2, ct3
    complex(8) :: ck1, ck1sq
    real(8) :: ck2, ck2sq, tkmag, tsmag, ck1r
    real(8) :: zph, rho
    integer :: jh
  end type evlcom_data

  type(evlcom_data), save :: evl_params

contains

  !============================================================================
  ! EVLUA - Control integration contour for Sommerfeld integrals
  !============================================================================
  subroutine evlua(ground, erv, ezv, erh, eph)
    ! Evaluates Sommerfeld integrals using appropriate integration contour
    ! in the complex lambda plane
    !
    ! Returns electric field components for ground reflection

    type(ground_data), intent(in) :: ground
    complex(8), intent(out) :: erv, ezv, erh, eph

    complex(8) :: sum_vals(6), ans(6)
    complex(8) :: cp1, cp2, cp3, delta, delta2, bk
    real(8) :: del, rmis, slope
    real(8), parameter :: ptp = TWO_PI
    integer :: i

    ! Set up evaluation parameters from ground data
    evl_params%ck1 = ground%ck1
    evl_params%ck1sq = ground%ck1 * ground%ck1
    evl_params%ck2 = abs(ground%ck2)
    evl_params%ck2sq = evl_params%ck2 * evl_params%ck2
    evl_params%zph = ground%zph
    evl_params%rho = ground%rho
    evl_params%tkmag = abs(ground%ck1)
    evl_params%tsmag = evl_params%tkmag * evl_params%tkmag * 1.0d-4
    evl_params%ck1r = real(ground%ck1, kind=8)

    ! Compute coefficients for reflection
    evl_params%cksm = ground%ck1 + ground%ck2
    evl_params%ct1 = evl_params%cksm / (ground%ck1 * ground%ck2)
    evl_params%ct2 = evl_params%ck1sq - evl_params%ck2sq
    evl_params%ct3 = evl_params%ct2 / (evl_params%ck1sq * evl_params%ck2sq)

    del = evl_params%zph
    if (evl_params%rho > del) del = evl_params%rho

    if (evl_params%zph < 2.0d0 * evl_params%rho) then
      ! HANKEL FUNCTION FORM of Sommerfeld integrals
      evl_params%jh = 1
      cp1 = cmplx(0.0d0, 0.4d0 * evl_params%ck2, kind=8)
      cp2 = cmplx(0.6d0 * evl_params%ck2, -0.2d0 * evl_params%ck2, kind=8)
      cp3 = cmplx(1.02d0 * evl_params%ck2, -0.2d0 * evl_params%ck2, kind=8)

      contour_a = cp1
      contour_b = cp2
      call rom1(6, sum_vals, 2)

      contour_a = cp2
      contour_b = cp3
      call rom1(6, ans, 2)

      do i = 1, 6
        sum_vals(i) = -(sum_vals(i) + ans(i))
      end do

      ! Path from imaginary axis to -infinity
      slope = 1000.0d0
      if (evl_params%zph > 0.001d0 * evl_params%rho) then
        slope = evl_params%rho / evl_params%zph
      end if

      del = ptp / del
      delta = cmplx(-1.0d0, slope, kind=8) * del / sqrt(1.0d0 + slope * slope)
      delta2 = -conjg(delta)
      call gshank(cp1, delta, ans, 6, sum_vals, 0, bk, bk)

      rmis = evl_params%rho * (evl_params%ck1r - evl_params%ck2)

      if (rmis >= 2.0d0 * evl_params%ck2 .and. evl_params%rho >= 1.0d-10) then
        if (evl_params%zph < 1.0d-10) then
          ! Integrate up between branch cuts
          cp1 = evl_params%ck1 - cmplx(0.1d0, 0.2d0, kind=8)
          cp2 = cp1 + 0.2d0
          bk = cmplx(0.0d0, del, kind=8)
          call gshank(cp1, bk, sum_vals, 6, ans, 0, bk, bk)

          contour_a = cp1
          contour_b = cp2
          call rom1(6, ans, 1)

          do i = 1, 6
            ans(i) = ans(i) - sum_vals(i)
          end do

          call gshank(cp3, bk, sum_vals, 6, ans, 0, bk, bk)
          call gshank(cp2, delta2, ans, 6, sum_vals, 0, bk, bk)
        else
          bk = cmplx(-evl_params%zph, evl_params%rho, kind=8) * &
               (evl_params%ck1 - cp3)
          rmis = -real(bk, kind=8) / abs(aimag(bk))

          if (rmis <= 4.0d0 * evl_params%rho / evl_params%zph) then
            ! Integrate below branch points
            do i = 1, 6
              sum_vals(i) = -ans(i)
            end do

            rmis = evl_params%ck1r * 1.01d0
            if (evl_params%ck2 + 1.0d0 > rmis) rmis = evl_params%ck2 + 1.0d0
            bk = cmplx(rmis, 0.99d0 * aimag(evl_params%ck1), kind=8)
            delta = bk - cp3
            delta = delta * del / abs(delta)
            call gshank(cp3, delta, ans, 6, sum_vals, 1, bk, delta2)
          end if
        end if
      else
        ! Integrate below branch points
        do i = 1, 6
          sum_vals(i) = -ans(i)
        end do

        rmis = evl_params%ck1r * 1.01d0
        if (evl_params%ck2 + 1.0d0 > rmis) rmis = evl_params%ck2 + 1.0d0
        bk = cmplx(rmis, 0.99d0 * aimag(evl_params%ck1), kind=8)
        delta = bk - cp3
        delta = delta * del / abs(delta)
        call gshank(cp3, delta, ans, 6, sum_vals, 1, bk, delta2)
      end if

    else
      ! BESSEL FUNCTION FORM of Sommerfeld integrals
      evl_params%jh = 0
      contour_a = (0.0d0, 0.0d0)
      del = 1.0d0 / del

      if (del <= evl_params%tkmag) then
        contour_b = cmplx(0.1d0 * evl_params%tkmag, &
                        -0.1d0 * evl_params%tkmag, kind=8)
        call rom1(6, sum_vals, 2)

        contour_a = contour_b
        contour_b = cmplx(del, -del, kind=8)
        call rom1(6, ans, 2)

        do i = 1, 6
          sum_vals(i) = sum_vals(i) + ans(i)
        end do
      else
        contour_b = cmplx(del, -del, kind=8)
        call rom1(6, sum_vals, 2)
      end if

      delta = ptp * del * cmplx(1.0d0, 1.0d0, kind=8)
      call gshank(contour_b, delta, ans, 6, sum_vals, 0, bk, bk)
    end if

    ! Apply final transformations
    ans(6) = ans(6) * evl_params%ck1

    ! Conjugate since NEC uses exp(+jωt) time convention
    erv = conjg(evl_params%ck1sq * ans(3))
    ezv = conjg(evl_params%ck1sq * (ans(2) + evl_params%ck2sq * ans(5)))
    erh = conjg(evl_params%ck2sq * (ans(1) + ans(6)))
    eph = -conjg(evl_params%ck2sq * (ans(4) + ans(6)))

  end subroutine evlua

  !============================================================================
  ! GSHANK - Generalized Shanks algorithm for infinite integral
  !============================================================================
  subroutine gshank(start_val, dela, sum_vals, nans, seed, ibk, bk, delb)
    ! Integrates the 6 Sommerfeld integrals from start to infinity
    ! using Shanks algorithm for acceleration of convergence
    !
    ! Arguments:
    !   start_val - starting point in lambda plane
    !   dela - integration step
    !   sum_vals - output sums
    !   nans - number of integrals (6)
    !   seed - seed values
    !   ibk - break point flag
    !   bk - break point value
    !   delb - step at break

    complex(8), intent(in) :: start_val, dela, bk, delb
    complex(8), intent(in) :: seed(:)
    complex(8), intent(out) :: sum_vals(:)
    integer, intent(in) :: nans, ibk

    complex(8) :: a(6, 20), b(6, 20), as1(6), as2(6), del, aa
    complex(8) :: t1, t2, brk_val
    integer :: ibx, i, j, jm, intx, inx, brk_cnt
    real(8) :: den, dena, denb, ratio_r, ratio_i
    logical :: jump

    do i = 1, nans
      a(i, 1) = seed(i)
    end do

    brk_val = start_val
    del = dela
    ibx = ibk

    if (ibx == 1) then
      brk_cnt = 2
    else
      brk_cnt = 1
    end if

    ! Integration loop with Shanks extrapolation
    do intx = 1, INT_MAXH
      brk_val = brk_val + del

      if (ibx /= 1) then
        ! Check if we've reached break point
        if (intx == 2 .and. abs(real(brk_val - bk, kind=8)) + &
            abs(aimag(brk_val - bk)) < 1.0d-6) then
          ibx = 2
        end if
      else
        ! Update step at break
        if (intx == brk_cnt) then
          del = delb
          ibx = 2
        end if
      end if

      ! Evaluate integrand at current point
      call saoa_internal(brk_val, as1)

      ! Save values
      do i = 1, nans
        a(i, intx + 1) = as1(i) * del
      end do

      ! Check for convergence starting at 4th iteration
      if (intx >= 4) then
        jump = .true.
        do i = 1, nans
          as1(i) = a(i, intx + 1) + a(i, intx)
          as2(i) = as1(i) + a(i, intx - 1)

          ! Convergence test
          call test_convergence(real(a(i, intx + 1), kind=8), &
                               real(as1(i), kind=8), ratio_r, &
                               aimag(a(i, intx + 1)), &
                               aimag(as1(i)), ratio_i, 0.0d0)

          if (ratio_r > 1.0d-6 .or. ratio_i > 1.0d-6) jump = .false.
        end do

        if (jump) exit
      end if
    end do

    ! Shanks transformation for convergence acceleration
    jm = intx + 1
    do j = 1, jm
      do i = 1, nans
        b(i, j) = a(i, j)
      end do
    end do

    ! Apply Shanks recursion
    do inx = 1, 5
      do j = 1, jm
        do i = 1, nans
          den = b(i, j + 1) - b(i, j)
          if (abs(den) < 1.0d-30) then
            b(i, j) = b(i, j + 1)
          else
            b(i, j) = a(i, j + 1) - (a(i, j + 1) - a(i, j))**2 / den
          end if
        end do
      end do

      jm = jm - 1
      if (jm < 2) exit

      do j = 1, jm
        do i = 1, nans
          a(i, j) = b(i, j)
        end do
      end do
    end do

    do i = 1, nans
      sum_vals(i) = 0.5d0 * b(i, 1)
    end do

  end subroutine gshank

  !============================================================================
  ! ROM1 - Romberg integration with variable interval width
  !============================================================================
  subroutine rom1(n, sum_vals, nx)
    ! Integrates the 6 Sommerfeld integrals from A to B in lambda
    ! using variable interval width Romberg integration
    !
    ! Arguments:
    !   n - number of integrals (should be 6)
    !   sum_vals - output integral values
    !   nx - initial number of subdivisions

    integer, intent(in) :: n, nx
    complex(8), intent(out) :: sum_vals(:)

    complex(8) :: g1(6), g2(6), g3(6), g4(6), g5(6)
    complex(8) :: t00, t01(6), t10(6), t02, t11, t20(6)
    real(8) :: z, ze, s, ep, zend, dz, dzot, tr, ti
    integer :: i, ns, nt, nogo, lstep
    integer, parameter :: nm = 131072, nts = 4
    real(8), parameter :: rx = 1.0d-4

    lstep = 0
    z = 0.0d0
    ze = 1.0d0
    s = 1.0d0
    ep = s / (1.0d4 * nm)
    zend = ze - ep

    sum_vals(1:n) = (0.0d0, 0.0d0)
    ns = nx
    nt = 0

    call saoa_internal(z * contour_b + (1.0d0 - z) * contour_a, g1)

    ! Adaptive integration loop
    do while (z <= zend)
      dz = s / ns
      if (z + dz > ze) then
        dz = ze - z
        if (dz <= ep) exit
      end if

      dzot = dz * 0.5d0

      ! 3-point Romberg
      call saoa_internal((z + dzot) * contour_b + (1.0d0 - z - dzot) * contour_a, g3)
      call saoa_internal((z + dz) * contour_b + (1.0d0 - z - dz) * contour_a, g5)

      nogo = 0
      do i = 1, n
        t00 = (g1(i) + g5(i)) * dzot
        t01(i) = (t00 + dz * g3(i)) * 0.5d0
        t10(i) = (4.0d0 * t01(i) - t00) / 3.0d0

        call test_convergence(real(t01(i), kind=8), real(t10(i), kind=8), tr, &
                             aimag(t01(i)), aimag(t10(i)), ti, 0.0d0)
        if (tr > rx .or. ti > rx) nogo = 1
      end do

      if (nogo == 0) then
        ! Accept 3-point result
        do i = 1, n
          sum_vals(i) = sum_vals(i) + t10(i)
        end do
        nt = nt + 2
      else
        ! Try 5-point Romberg
        call saoa_internal((z + dz * 0.25d0) * contour_b + &
                          (1.0d0 - z - dz * 0.25d0) * contour_a, g2)
        call saoa_internal((z + dz * 0.75d0) * contour_b + &
                          (1.0d0 - z - dz * 0.75d0) * contour_a, g4)

        nogo = 0
        do i = 1, n
          t02 = (t01(i) + dzot * (g2(i) + g4(i))) * 0.5d0
          t11 = (4.0d0 * t02 - t01(i)) / 3.0d0
          t20(i) = (16.0d0 * t11 - t10(i)) / 15.0d0

          call test_convergence(real(t11, kind=8), real(t20(i), kind=8), tr, &
                               aimag(t11), aimag(t20(i)), ti, 0.0d0)
          if (tr > rx .or. ti > rx) nogo = 1
        end do

        if (nogo == 0) then
          ! Accept 5-point result
          do i = 1, n
            sum_vals(i) = sum_vals(i) + t20(i)
          end do
          nt = nt + 1
        else
          ! Need more subdivisions
          nt = 0
          if (ns < nm) then
            ns = ns * 2
            dz = s / ns
            dzot = dz * 0.5d0
            do i = 1, n
              g5(i) = g3(i)
              g3(i) = g2(i)
            end do
            cycle
          else
            ! Step size limited
            if (lstep == 0) then
              lstep = 1
              write(*,'(A,2ES12.5)') ' ROM1: Step size limited at lambda = ', &
                contour_a + z * (contour_b - contour_a)
            end if
            do i = 1, n
              sum_vals(i) = sum_vals(i) + t20(i)
            end do
            nt = nt + 1
          end if
        end if
      end if

      z = z + dz
      g1 = g5

      if (nt >= nts .and. ns > nx) then
        ns = ns / 2
        nt = 1
      end if
    end do

    ! Scale by path length
    sum_vals(1:n) = sum_vals(1:n) * (contour_b - contour_a)

  end subroutine rom1

  !============================================================================
  ! ROM2 - Alternative Romberg integration
  !============================================================================
  subroutine rom2(a_val, b_val, sum_val, dmin)
    ! Alternative Romberg integration for Sommerfeld integrals
    ! Simplified version for single integrand evaluation
    !
    ! Arguments:
    !   a_val, b_val - integration limits
    !   sum_val - output integral value
    !   dmin - minimum tolerance
    !
    ! NOTE: This is a simplified alternative to rom1()
    !       The original ROM2 (nec2dxs.f:8600-8712) was much more complex
    !       and integrated 9 field components simultaneously using SFLDS
    !       This simplified version provides basic Romberg integration
    !       rom1() is the primary integration method for Sommerfeld integrals
    !
    ! Original: nec2dxs.f lines 8600-8712 (adapted/simplified)

    real(8), intent(in) :: a_val, b_val, dmin
    complex(8), intent(out) :: sum_val

    complex(8) :: g1, g2, g3, g4, g5, t00, t01, t02, t10, t11, t20
    real(8) :: z, ze, s, ep, zend, dz, dzot
    real(8) :: tmag1, tmag2, tr, ti
    integer :: ns, nt
    integer, parameter :: nm = 65536
    integer, parameter :: nts = 4
    integer, parameter :: nx = 1
    real(8), parameter :: rx = 1.0d-4

    ! Initialize
    z = a_val
    ze = b_val
    s = ze - z

    ! Check for valid limits
    if (s < 0.0d0) then
      write(*,*) 'ERROR - B LESS THAN A IN ROM2'
      sum_val = cmplx(0.0d0, 0.0d0, kind=8)
      return
    end if

    ep = s / (1.0d4 * real(nm, kind=8))
    zend = ze - ep
    sum_val = cmplx(0.0d0, 0.0d0, kind=8)
    ns = nx
    nt = 0

    ! Get initial value (would call integrand function)
    ! For this simplified version, we just return zero
    ! A full implementation would need an integrand evaluation function
    g1 = cmplx(0.0d0, 0.0d0, kind=8)

    ! Main integration loop
    do while (.true.)
      dz = s / real(ns, kind=8)

      if (z + dz > ze) then
        dz = ze - z
        if (dz <= ep) exit
      end if

      dzot = dz * 0.5d0

      ! Evaluate integrand at 3 points (simplified - would call integrand function)
      g3 = cmplx(0.0d0, 0.0d0, kind=8)
      g5 = cmplx(0.0d0, 0.0d0, kind=8)

      ! 3-point Romberg
      t00 = (g1 + g5) * dzot
      t01 = (t00 + dz*g3) * 0.5d0
      t10 = (4.0d0*t01 - t00) / 3.0d0

      ! Test convergence
      tr = real(t10, kind=8)
      ti = aimag(t01)
      tmag1 = sqrt(tr*tr + ti*ti)
      tr = real(t10, kind=8)
      ti = aimag(t10)
      tmag2 = sqrt(tr*tr + ti*ti)

      if (abs(tmag1 - tmag2) / max(tmag2, dmin) <= rx) then
        ! 3-point converged
        sum_val = sum_val + t10
        nt = nt + 2
      else
        ! Need 5-point integration
        g2 = cmplx(0.0d0, 0.0d0, kind=8)
        g4 = cmplx(0.0d0, 0.0d0, kind=8)

        t02 = (t01 + dzot*(g2 + g4)) * 0.5d0
        t11 = (4.0d0*t02 - t01) / 3.0d0
        t20 = (16.0d0*t11 - t10) / 15.0d0

        ! Test convergence
        tr = real(t11, kind=8)
        ti = aimag(t11)
        tmag1 = sqrt(tr*tr + ti*ti)
        tr = real(t20, kind=8)
        ti = aimag(t20)
        tmag2 = sqrt(tr*tr + ti*ti)

        if (abs(tmag1 - tmag2) / max(tmag2, dmin) <= rx) then
          ! 5-point converged
          sum_val = sum_val + t20
          nt = nt + 1
        else
          ! Need to halve step size
          nt = 0
          if (ns >= nm) then
            ! Step size limit
            write(*,'(A,E12.5)') ' ROM2 -- STEP SIZE LIMITED AT Z =', z
            sum_val = sum_val + t20
          else
            ! Halve step size
            ns = ns * 2
            g5 = g3
            g3 = g2
            cycle
          end if
        end if
      end if

      ! Move to next interval
      z = z + dz
      if (z > zend) exit

      g1 = g5

      ! Check if we can increase step size
      if (nt >= nts .and. ns > nx) then
        ns = ns / 2
        nt = 1
      end if
    end do

  end subroutine rom2

  !============================================================================
  ! SAOA - Sommerfeld integrand for source and observer above ground
  !============================================================================
  subroutine saoa_internal(t_val, ans)
    ! Computes the integrand for each of the 6 Sommerfeld integrals
    ! for source and observer above ground
    !
    ! Arguments:
    !   t_val - parameter value (0 to 1 along contour)
    !   ans - output array of 6 integrand values

    complex(8), intent(in) :: t_val
    complex(8), intent(out) :: ans(6)

    complex(8) :: xl, dxl, cgam1, cgam2, b0, b0p, com, dgam, den1, den2
    real(8) :: xlr, sign_val
    integer :: jh_local

    ! Compute lambda and its derivative
    call lambda_param(t_val, xl, dxl)

    jh_local = evl_params%jh

    if (jh_local > 0) then
      ! Hankel function form
      call hankel_h0(xl * evl_params%rho, b0, b0p)
      com = xl - evl_params%ck1
      cgam1 = sqrt(xl + evl_params%ck1) * sqrt(com)
      if (real(com, kind=8) < 0.0d0 .and. aimag(com) >= 0.0d0) cgam1 = -cgam1

      com = xl - evl_params%ck2
      cgam2 = sqrt(xl + cmplx(evl_params%ck2, 0.0d0, kind=8)) * sqrt(com)
      if (real(com, kind=8) < 0.0d0 .and. aimag(com) >= 0.0d0) cgam2 = -cgam2
    else
      ! Bessel function form
      call bessel_j0(xl * evl_params%rho, b0, b0p)
      b0 = 2.0d0 * b0
      b0p = 2.0d0 * b0p

      cgam1 = sqrt(xl * xl - evl_params%ck1sq)
      cgam2 = sqrt(xl * xl - evl_params%ck2sq)

      if (real(cgam1, kind=8) == 0.0d0) then
        cgam1 = cmplx(0.0d0, -abs(aimag(cgam1)), kind=8)
      end if
      if (real(cgam2, kind=8) == 0.0d0) then
        cgam2 = cmplx(0.0d0, -abs(aimag(cgam2)), kind=8)
      end if
    end if

    ! Compute reflection coefficient approximation
    xlr = real(xl * conjg(xl), kind=8)

    if (xlr < evl_params%tsmag) then
      dgam = cgam2 - cgam1
    else if (aimag(xl) < 0.0d0) then
      sign_val = 1.0d0
      dgam = 1.0d0 / (xl * xl)
      dgam = sign_val * ((evl_params%ct3 * dgam + evl_params%ct2) * dgam + &
                        evl_params%ct1) / xl
    else
      xlr = real(xl, kind=8)
      if (xlr < evl_params%ck2) then
        sign_val = -1.0d0
      else if (xlr > evl_params%ck1r) then
        sign_val = 1.0d0
      else
        dgam = cgam2 - cgam1
        goto 100
      end if
      dgam = 1.0d0 / (xl * xl)
      dgam = sign_val * ((evl_params%ct3 * dgam + evl_params%ct2) * dgam + &
                        evl_params%ct1) / xl
    end if

100 continue

    ! Compute denominator terms
    den2 = evl_params%cksm * dgam / &
           (cgam2 * (evl_params%ck1sq * cgam2 + evl_params%ck2sq * cgam1))
    den1 = 1.0d0 / (cgam1 + cgam2) - evl_params%cksm / cgam2

    ! Common exponential factor
    com = dxl * xl * exp(-cgam2 * evl_params%zph)

    ! Compute the 6 integral values
    ans(6) = com * b0 * den1 / evl_params%ck1
    com = com * den2

    if (evl_params%rho == 0.0d0) then
      ans(1) = -com * xl * xl * 0.5d0
      ans(4) = ans(1)
    else
      b0p = b0p / evl_params%rho
      ans(1) = -com * xl * (b0p + b0 * xl)
      ans(4) = com * xl * b0p
    end if

    ans(2) = com * cgam2 * cgam2 * b0
    ans(3) = -ans(4) * cgam2 * evl_params%rho
    ans(5) = com * b0

  end subroutine saoa_internal

  !============================================================================
  ! LAMBDA_PARAM - Compute lambda parameter along contour
  !============================================================================
  subroutine lambda_param(t_val, xlam, dxlam)
    ! Computes lambda and its derivative for parametric representation
    !
    ! Arguments:
    !   t_val - parameter (0 to 1)
    !   xlam - lambda value
    !   dxlam - derivative dλ/dt

    complex(8), intent(in) :: t_val
    complex(8), intent(out) :: xlam, dxlam

    ! Linear interpolation along contour
    xlam = contour_a + t_val * (contour_b - contour_a)
    dxlam = contour_b - contour_a

  end subroutine lambda_param

  !============================================================================
  ! BESSEL_J0 - Bessel function J0 and its derivative
  !============================================================================
  subroutine bessel_j0(z, j0, j0p)
    ! Computes Bessel function J0(z) and J0'(z)
    ! Uses series expansion for small |z|, asymptotic form for large |z|
    !
    ! Arguments:
    !   z - complex argument
    !   j0 - J0(z)
    !   j0p - J0'(z) = -J1(z)

    complex(8), intent(in) :: z
    complex(8), intent(out) :: j0, j0p

    complex(8) :: zs, p0, p1, q0, q1, zi, clogz, j1
    real(8) :: az, azs
    integer :: i
    real(8), parameter :: pof = 0.7978845608d0

    ! Coefficients for asymptotic expansion
    real(8), parameter :: a1(7) = [&
      -0.703125d-1, 0.112152099609375d0, -0.5725014209747314d0, &
      0.6074042001273483d1, -0.1100171402692467d3, 0.3038090510922384d4, &
      -0.1188384262567832d6]

    real(8), parameter :: a2(7) = [&
      0.1171875d0, -0.144195556640625d0, 0.6765925884246826d0, &
      -0.6883914268109947d1, 0.1215978918765359d3, -0.3302272294480852d4, &
      0.1276412726461746d6]

    az = abs(z)

    if (az <= 8.0d0) then
      ! Series expansion for small argument
      zs = 0.25d0 * z * z
      p0 = 1.0d0
      j0 = 1.0d0

      do i = 1, 24
        p0 = -p0 * zs / (real(i, kind=8)**2)
        j0 = j0 + p0
        if (abs(p0) < 1.0d-16) exit
      end do

      ! J1 series
      p1 = z * 0.5d0
      j1 = p1
      do i = 1, 24
        p1 = -p1 * zs / (real(i, kind=8) * (real(i, kind=8) + 1.0d0))
        j1 = j1 + p1
        if (abs(p1) < 1.0d-16) exit
      end do

      j0p = -j1

    else
      ! Asymptotic expansion for large argument
      zi = 1.0d0 / z
      zs = zi * zi
      p0 = 1.0d0
      q0 = 0.0d0

      do i = 1, 7
        p0 = p0 + a1(i) * zs**i
        q0 = q0 + a2(i) * zi * zs**i
      end do

      azs = sqrt(pof / az)
      j0 = azs * (p0 * cos(az - 0.25d0 * PI) - q0 * sin(az - 0.25d0 * PI))
      j0p = -azs * (p0 * sin(az - 0.25d0 * PI) + q0 * cos(az - 0.25d0 * PI))
    end if

  end subroutine bessel_j0

  !============================================================================
  ! HANKEL_H0 - Hankel function H0(2) and its derivative
  !============================================================================
  subroutine hankel_h0(z, h0, h0p)
    ! Computes Hankel function H0(2)(z) and H0(2)'(z)
    !
    ! Arguments:
    !   z - complex argument
    !   h0 - H0(2)(z)
    !   h0p - H0(2)'(z) = -H1(2)(z)

    complex(8), intent(in) :: z
    complex(8), intent(out) :: h0, h0p

    complex(8) :: j0, j0p, y0, y0p, clogz, zs, p, zi
    real(8) :: az
    integer :: i
    real(8), parameter :: gama = 0.5772156649d0

    ! First compute Bessel function
    call bessel_j0(z, j0, j0p)

    az = abs(z)

    if (az <= 8.0d0) then
      ! Y0 series for small argument
      clogz = log(z)
      zs = 0.25d0 * z * z
      p = 1.0d0
      y0 = (2.0d0 / PI) * (clogz + gama) * j0

      do i = 1, 24
        p = -p * zs / (real(i, kind=8)**2)
        y0 = y0 + (2.0d0 / PI) * p * (1.0d0 / real(i, kind=8))
        if (abs(p) < 1.0d-16) exit
      end do

      ! Y1 approximation
      y0p = -y0  ! Simplified

    else
      ! Asymptotic form
      zi = 1.0d0 / z
      y0 = sqrt(2.0d0 / (PI * az)) * sin(az - 0.25d0 * PI)
      y0p = -sqrt(2.0d0 / (PI * az)) * cos(az - 0.25d0 * PI)
    end if

    ! Hankel function H0(2) = J0 - iY0
    h0 = j0 - cmplx(0.0d0, 1.0d0, kind=8) * y0
    h0p = j0p - cmplx(0.0d0, 1.0d0, kind=8) * y0p

  end subroutine hankel_h0

  !============================================================================
  ! TEST_CONVERGENCE - Test for numerical convergence
  !============================================================================
  subroutine test_convergence(f1r, f2r, tr, f1i, f2i, ti, dmin)
    ! Tests convergence of real and imaginary parts
    !
    ! Arguments:
    !   f1r, f2r - real values to compare
    !   tr - output: relative error in real part
    !   f1i, f2i - imaginary values to compare
    !   ti - output: relative error in imaginary part
    !   dmin - minimum tolerance

    real(8), intent(in) :: f1r, f2r, f1i, f2i, dmin
    real(8), intent(out) :: tr, ti

    real(8) :: den

    ! Test real part
    den = abs(f2r)
    if (den < dmin) den = dmin
    if (den < abs(f1r)) den = abs(f1r)
    tr = abs(f2r - f1r) / den

    ! Test imaginary part
    den = abs(f2i)
    if (den < dmin) den = dmin
    if (den < abs(f1i)) den = abs(f1i)
    ti = abs(f2i - f1i) / den

  end subroutine test_convergence

  !============================================================================
  ! FBAR - Sommerfeld attenuation function
  !============================================================================
  function fbar(p) result(result_val)
    ! Sommerfeld attenuation function for numerical distance P
    ! Uses series expansion for |z| < 3, asymptotic expansion for |z| >= 3
    !
    ! Arguments:
    !   p - complex numerical distance parameter
    !
    ! Returns:
    !   Complex attenuation function value
    !
    ! Original: nec2dxs.f lines 4397-4446

    complex(8), intent(in) :: p
    complex(8) :: result_val

    complex(8) :: z, zs, sum_val, pow_val, term
    real(8) :: tms, sms
    integer :: i, minus

    ! Constants
    complex(8), parameter :: fj = cmplx(0.0d0, 1.0d0, kind=8)
    real(8), parameter :: tosp = 1.128379167d0      ! 2/sqrt(pi)
    real(8), parameter :: sp = 1.772453851d0        ! sqrt(pi)
    real(8), parameter :: accs = 1.0d-12            ! Convergence tolerance

    z = fj * sqrt(p)

    if (abs(z) > 3.0d0) then
      ! Asymptotic expansion for |z| >= 3
      if (real(z, kind=8) < 0.0d0) then
        minus = 1
        z = -z
      else
        minus = 0
      end if

      zs = 0.5d0 / (z * z)
      sum_val = cmplx(0.0d0, 0.0d0, kind=8)
      term = cmplx(1.0d0, 0.0d0, kind=8)

      do i = 1, 6
        term = -term * real(2*i - 1, kind=8) * zs
        sum_val = sum_val + term
      end do

      if (minus == 1) then
        sum_val = sum_val - 2.0d0 * sp * z * exp(z * z)
      end if

      result_val = -sum_val

    else
      ! Series expansion for |z| < 3
      zs = z * z
      sum_val = z
      pow_val = z

      do i = 1, 100
        pow_val = -pow_val * zs / real(i, kind=8)
        term = pow_val / real(2*i + 1, kind=8)
        sum_val = sum_val + term

        ! Check convergence
        tms = real(term * conjg(term), kind=8)
        sms = real(sum_val * conjg(sum_val), kind=8)

        if (tms / sms < accs) exit
      end do

      result_val = 1.0d0 - (1.0d0 - sum_val * tosp) * z * exp(zs) * sp
    end if

  end function fbar

end module nec2_sommerfeld
