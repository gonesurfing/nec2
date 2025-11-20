! =============================================================================
! nec2d_sommerfeld - Sommerfeld Integration
! =============================================================================
! Purpose: Ground wave and Sommerfeld integral evaluations
! Contains: EVLUA, GSHANK, SAOA
! GOTOs eliminated: 33
! =============================================================================
subroutine evlua(erv, ezv, erh, eph)
!
! evlua controls the integration contour in the complex lambda
! plane for evaluation of the sommerfeld integrals
!
  implicit real*8(a-h,o-z)
  save
  complex*16 erv, ezv, erh, eph, a, b, ck1, ck1sq, bk, sum, delta, ans, delta2, &
             cp1, cp2, cp3, cksm, ct1, ct2, ct3
  common /cntour/ a, b
  common /evlcom/ cksm, ct1, ct2, ct3, ck1, ck1sq, ck2, ck2sq, tkmag, tsmag, &
                  ck1r, zph, rho, jh
  dimension sum(6), ans(6)
  data ptp/0.6283185308d0/

  del = zph
  if (rho > del) del = rho

  ! Choose between Bessel and Hankel function forms
  if (zph < 2.d0*rho) then
    ! Hankel function form of sommerfeld integrals
    jh = 1
    cp1 = dcmplx(0.d0, 0.4d0*ck2)
    cp2 = dcmplx(0.6d0*ck2, -0.2d0*ck2)
    cp3 = dcmplx(1.02d0*ck2, -0.2d0*ck2)
    a = cp1
    b = cp2
    call rom1(6, sum, 2)
    a = cp2
    b = cp3
    call rom1(6, ans, 2)

    do i = 1, 6
      sum(i) = -(sum(i) + ans(i))
    end do

    ! Path from imaginary axis to -infinity
    slope = 1000.d0
    if (zph > 0.001d0*rho) slope = rho / zph
    del = ptp / del
    delta = dcmplx(-1.d0, slope) * del / sqrt(1.d0 + slope*slope)
    delta2 = -dconjg(delta)
    call gshank(cp1, delta, ans, 6, sum, 0, bk, bk)
    rmis = rho * (dreal(ck1) - ck2)

    ! Determine integration path based on geometry
    if (rmis < 2.d0*ck2 .or. rho < 1.d-10) then
      ! Integrate below branch points, then to + infinity
      do i = 1, 6
        sum(i) = -ans(i)
      end do
      rmis = dreal(ck1) * 1.01d0
      if (ck2 + 1.d0 > rmis) rmis = ck2 + 1.d0
      bk = dcmplx(rmis, 0.99d0*dimag(ck1))
      delta = bk - cp3
      delta = delta * del / abs(delta)
      call gshank(cp3, delta, ans, 6, sum, 1, bk, delta2)

    else if (zph < 1.d-10) then
      ! Integrate up between branch cuts, then to + infinity
      cp1 = ck1 - (0.1d0, 0.2d0)
      cp2 = cp1 + 0.2d0
      bk = dcmplx(0.d0, del)
      call gshank(cp1, bk, sum, 6, ans, 0, bk, bk)
      a = cp1
      b = cp2
      call rom1(6, ans, 1)

      do i = 1, 6
        ans(i) = ans(i) - sum(i)
      end do

      call gshank(cp3, bk, sum, 6, ans, 0, bk, bk)
      call gshank(cp2, delta2, ans, 6, sum, 0, bk, bk)

    else
      ! Check secondary condition for path selection
      bk = dcmplx(-zph, rho) * (ck1 - cp3)
      rmis = -dreal(bk) / abs(dimag(bk))

      if (rmis > 4.d0*rho/zph) then
        ! Integrate below branch points, then to + infinity
        do i = 1, 6
          sum(i) = -ans(i)
        end do
        rmis = dreal(ck1) * 1.01d0
        if (ck2 + 1.d0 > rmis) rmis = ck2 + 1.d0
        bk = dcmplx(rmis, 0.99d0*dimag(ck1))
        delta = bk - cp3
        delta = delta * del / abs(delta)
        call gshank(cp3, delta, ans, 6, sum, 1, bk, delta2)
      else
        ! Integrate up between branch cuts, then to + infinity
        cp1 = ck1 - (0.1d0, 0.2d0)
        cp2 = cp1 + 0.2d0
        bk = dcmplx(0.d0, del)
        call gshank(cp1, bk, sum, 6, ans, 0, bk, bk)
        a = cp1
        b = cp2
        call rom1(6, ans, 1)

        do i = 1, 6
          ans(i) = ans(i) - sum(i)
        end do

        call gshank(cp3, bk, sum, 6, ans, 0, bk, bk)
        call gshank(cp2, delta2, ans, 6, sum, 0, bk, bk)
      end if
    end if

  else
    ! Bessel function form of sommerfeld integrals
    jh = 0
    a = (0.d0, 0.d0)
    del = 1.d0 / del

    ! Determine integration path based on wavelength
    if (del <= tkmag) then
      ! Direct integration path
      b = dcmplx(del, -del)
      call rom1(6, sum, 2)
    else
      ! Two-stage integration path
      b = dcmplx(0.1d0*tkmag, -0.1d0*tkmag)
      call rom1(6, sum, 2)
      a = b
      b = dcmplx(del, -del)
      call rom1(6, ans, 2)

      do i = 1, 6
        sum(i) = sum(i) + ans(i)
      end do
    end if

    ! Common path for Bessel form
    delta = ptp * del
    call gshank(b, delta, ans, 6, sum, 0, b, b)
  end if

  ! Final assembly of field components
  ans(6) = ans(6) * ck1

  ! Conjugate since nec uses exp(+jwt)
  erv = dconjg(ck1sq * ans(3))
  ezv = dconjg(ck1sq * (ans(2) + ck2sq*ans(5)))
  erh = dconjg(ck2sq * (ans(1) + ans(6)))
  eph = -dconjg(ck2sq * (ans(4) + ans(6)))

end subroutine evlua

subroutine gshank(start, dela, sum, nans, seed, ibk, bk, delb)
!
! gshank integrates the 6 sommerfeld integrals from start to
! infinity (until convergence) in lambda. at the break point, bk,
! the step increment may be changed from dela to delb. shank's
! algorithm to accelerate convergence of a slowly converging series
! is used
!
  implicit real*8(a-h,o-z)
  save
  complex*16 start, dela, sum, seed, bk, delb, a, b, q1, q2, ans1, ans2, a1, a2, &
             as1, as2, del, aa
  common /cntour/ a, b
  dimension q1(6,20), q2(6,20), ans1(6), ans2(6), sum(6), seed(6)
  data crit/1.d-4/, maxh/20/
  logical :: converged, hit_breakpoint

  rbk = dreal(bk)
  del = dela
  ibx = 0
  if (ibk == 0) ibx = 1

  ! Initialize ans2 with seed values
  do i = 1, nans
    ans2(i) = seed(i)
  end do

  b = start

  ! Main integration loop - continues until convergence or max iterations
  main_integration: do int = 1, maxh
    inx = int

    ! First integration step
    a = b
    b = b + del

    ! Check if we hit the break point during first step
    hit_breakpoint = .false.
    if (ibx == 0 .and. dreal(b) >= rbk) then
      ! Hit break point - need to integrate to bk and reset parameters
      ibx = 1
      hit_breakpoint = .true.
      b = bk
      del = delb
      call rom1(nans, sum, 2)
      do i = 1, nans
        ans2(i) = ans2(i) + sum(i)
      end do
      cycle main_integration  ! Restart loop with new parameters
    end if

    ! Normal first step integration
    call rom1(nans, sum, 2)
    do i = 1, nans
      ans1(i) = ans2(i) + sum(i)
    end do

    ! Second integration step
    a = b
    b = b + del

    ! Check if we hit the break point during second step
    if (ibx == 0 .and. dreal(b) >= rbk) then
      ! Hit break point - need to integrate to bk and reset parameters
      ibx = 2
      b = bk
      del = delb
      call rom1(nans, sum, 2)
      do i = 1, nans
        ans2(i) = ans1(i) + sum(i)
      end do
      cycle main_integration  ! Restart loop with new parameters
    end if

    ! Normal second step integration
    call rom1(nans, sum, 2)
    do i = 1, nans
      ans2(i) = ans1(i) + sum(i)
    end do

    ! Apply Shanks transformation to accelerate convergence
    den = 0.0d0
    do i = 1, nans
      as1 = ans1(i)
      as2 = ans2(i)

      ! Apply successive transformations if we have enough history
      if (int >= 2) then
        do j = 2, int
          jm = j - 1
          aa = q2(i, jm)
          a1 = q1(i, jm) + as1 - 2.0d0 * aa

          ! Check for zero denominator in first transformation
          if (dreal(a1) == 0.0d0 .and. dimag(a1) == 0.0d0) then
            a1 = q1(i, jm)
          else
            a2 = aa - q1(i, jm)
            a1 = q1(i, jm) - a2 * a2 / a1
          end if

          a2 = aa + as2 - 2.0d0 * as1

          ! Check for zero denominator in second transformation
          if (dreal(a2) == 0.0d0 .and. dimag(a2) == 0.0d0) then
            a2 = aa
          else
            a2 = aa - (as1 - aa) * (as1 - aa) / a2
          end if

          q1(i, jm) = as1
          q2(i, jm) = as2
          as1 = a1
          as2 = a2
        end do
      end if

      q1(i, int) = as1
      q2(i, int) = as2
      amg = abs(dreal(as2)) + abs(dimag(as2))
      if (amg > den) den = amg
    end do

    ! Check for convergence
    denm = 1.0d-3 * den * crit
    jm = int - 3
    if (jm < 1) jm = 1

    converged = .true.
    convergence_check: do j = jm, int
      do i = 1, nans
        a1 = q2(i, j)
        den = (abs(dreal(a1)) + abs(dimag(a1))) * crit
        if (den < denm) den = denm
        a1 = q1(i, j) - a1
        amg = abs(dreal(a1)) + abs(dimag(a1))
        if (amg > den) then
          ! Not converged yet - exit convergence check
          converged = .false.
          exit convergence_check
        end if
      end do
    end do convergence_check

    ! If converged, exit main loop
    if (converged) exit main_integration

  end do main_integration

  ! Check if we failed to converge within maxh iterations
  if (.not. converged) then
    write(*, 24)
    do i = 1, nans
      write(*, 25) q1(i, inx), q2(i, inx)
    end do
  end if

  ! Compute final result as average of last two estimates
  do i = 1, nans
    sum(i) = 0.5d0 * (q1(i, inx) + q2(i, inx))
  end do

24 format(46h **** no convergence in subroutine gshank ****)
25 format(1x, 1p10e12.5)
end subroutine gshank

subroutine saoa(t, ans)
!
! saoa computes the integrand for each of the 6
! sommerfeld integrals for source and observer above ground
!
  implicit real*8(a-h, o-z)
  save
  complex*16 ans, xl, dxl, cgam1, cgam2, b0, b0p, com, ck1, ck1sq, cksm, ct1, &
             ct2, ct3, dgam, den1, den2
  common /evlcom/ cksm, ct1, ct2, ct3, ck1, ck1sq, ck2, ck2sq, tkmag, tsmag, &
                  ck1r, zph, rho, jh
  dimension ans(6)

  call lambda(t, xl, dxl)

  ! Select between Bessel and Hankel function forms
  if (jh > 0) then
    ! Hankel function form
    call hankel(xl*rho, b0, b0p)
    com = xl - ck1
    cgam1 = sqrt(xl + ck1) * sqrt(com)
    if (dreal(com) < 0.d0 .and. dimag(com) >= 0.d0) cgam1 = -cgam1
    com = xl - ck2
    cgam2 = sqrt(xl + ck2) * sqrt(com)
    if (dreal(com) < 0.d0 .and. dimag(com) >= 0.d0) cgam2 = -cgam2
  else
    ! Bessel function form
    call bessel(xl*rho, b0, b0p)
    b0 = 2.d0 * b0
    b0p = 2.d0 * b0p
    cgam1 = sqrt(xl*xl - ck1sq)
    cgam2 = sqrt(xl*xl - ck2sq)
    if (dreal(cgam1) == 0.d0) cgam1 = dcmplx(0.d0, -abs(dimag(cgam1)))
    if (dreal(cgam2) == 0.d0) cgam2 = dcmplx(0.d0, -abs(dimag(cgam2)))
  end if

  ! Compute dgam based on conditions
  xlr = xl * dconjg(xl)
  if (xlr < tsmag) then
    ! Direct computation
    dgam = cgam2 - cgam1
  else if (dimag(xl) < 0.d0) then
    ! Use polynomial approximation with positive sign
    dgam = 1.d0 / (xl * xl)
    dgam = ((ct3 * dgam + ct2) * dgam + ct1) / xl
  else
    xlr = dreal(xl)
    if (xlr < ck2) then
      ! Use polynomial approximation with negative sign
      dgam = 1.d0 / (xl * xl)
      dgam = -(((ct3 * dgam + ct2) * dgam + ct1) / xl)
    else if (xlr > ck1r) then
      ! Use polynomial approximation with positive sign
      dgam = 1.d0 / (xl * xl)
      dgam = ((ct3 * dgam + ct2) * dgam + ct1) / xl
    else
      ! Direct computation
      dgam = cgam2 - cgam1
    end if
  end if

  ! Common computation for all paths
  den2 = cksm * dgam / (cgam2 * (ck1sq * cgam2 + ck2sq * cgam1))
  den1 = 1.d0 / (cgam1 + cgam2) - cksm / cgam2
  com = dxl * xl * exp(-cgam2 * zph)
  ans(6) = com * b0 * den1 / ck1
  com = com * den2

  ! Handle rho == 0 special case
  if (rho == 0.d0) then
    ! Simplified formulas for rho = 0
    ans(1) = -com * xl * xl * 0.5d0
    ans(4) = ans(1)
  else
    ! Normal case
    b0p = b0p / rho
    ans(1) = -com * xl * (b0p + b0 * xl)
    ans(4) = com * xl * b0p
  end if

  ! Common computation for all paths
  ans(2) = com * cgam2 * cgam2 * b0
  ans(3) = -ans(4) * cgam2 * rho
  ans(5) = com * b0

end subroutine saoa

! -----------------------------------------------------------------------------
! somset - extracted from nec2dxs_integrated.f
! -----------------------------------------------------------------------------
  block data somset
  implicit real*8(a-h,o-z)
  complex*16 ar1,ar2,ar3,epscf
  common /ggrid/ ar1(11,10,4),ar2(17,5,4),ar3(9,8,4),epscf,dxa(3),dya(3),xsa(3),ysa(3),nxa(3),nya(3)
  data nxa/11,17,9/,nya/10,5,8/,xsa/0.,.2,.2/,ysa/0.,0.,.3490658504/
  data dxa/.02,.05,.1/,dya/.1745329252,.0872664626,.1745329252/
  end