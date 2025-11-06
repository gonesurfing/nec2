! nec2_kernel.f90
! Interaction kernel calculations for NEC2
! Electric field kernels for wire-wire and wire-patch interactions

module nec2_kernel
  use nec2_constants
  use nec2_data_types
  use nec2_utilities
  implicit none
  private

  ! Public subroutines
  public :: eksc, ekscx, pcint, hfk, gh

  ! Module-level variables for kernel calculations (replaces COMMON /TMI/)
  real(8), save :: zpk_mod, rkb2_mod
  integer, save :: ijx_mod

  ! Module-level variables for H-field calculations (replaces COMMON /TMH/)
  real(8), save :: zpk_h, rhks_h

contains

  !============================================================================
  ! EKSC - E field from sine/cosine/constant currents (thin wire)
  !============================================================================
  subroutine eksc(s, z, rh, xk, ij, ezs, ers, ezc, erc, ezk, erk)
    ! Computes E field of sine, cosine, and constant current filaments
    ! using thin wire approximation
    !
    ! Arguments:
    !   s   - segment length
    !   z   - z coordinate
    !   rh  - radial distance
    !   xk  - wave number (2*pi/wavelength)
    !   ij  - field type flag
    !   ezs, ers - E field components for sine current
    !   ezc, erc - E field components for cosine current
    !   ezk, erk - E field components for constant current

    real(8), intent(in) :: s, z, rh, xk
    integer, intent(in) :: ij
    complex(8), intent(out) :: ezs, ers, ezc, erc, ezk, erk

    complex(8) :: con, gz1, gz2, gp1, gp2, gzp1, gzp2
    complex(8) :: cint_val
    real(8) :: sh, shk, ss, cs, z1, z2, rhk
    real(8) :: sgr, sgi  ! Real/imaginary parts from intx()
    complex(8), parameter :: con_const = (0.0d0, 4.771341189d0)

    ijx_mod = ij
    zpk_mod = xk * z
    rhk = xk * rh
    rkb2_mod = rhk * rhk

    sh = 0.5d0 * s
    shk = xk * sh
    ss = sin(shk)
    cs = cos(shk)

    z2 = sh - z
    z1 = -(sh + z)

    ! Call GX for Green's function evaluations
    call gx(z1, rh, xk, gz1, gp1)
    call gx(z2, rh, xk, gz2, gp2)

    gzp1 = gp1 * z1
    gzp2 = gp2 * z2

    con = con_const

    ! Calculate field components
    ezs = con * ((gz2 - gz1) * cs * xk - (gzp2 + gzp1) * ss)
    ezc = -con * ((gz2 + gz1) * ss * xk + (gzp2 - gzp1) * cs)
    erk = con * (gp2 - gp1) * rh

    ! Integrate for constant current
    call intx(-shk, shk, rhk, ij, sgr, sgi)
    cint_val = cmplx(sgr, sgi, kind=8)
    ezk = -con * (gzp2 - gzp1 + xk*xk * cint_val)

    gzp1 = gzp1 * z1
    gzp2 = gzp2 * z2

    if (rh < 1.0d-10) then
      ers = (0.0d0, 0.0d0)
      erc = (0.0d0, 0.0d0)
    else
      ers = -con * ((gzp2 + gzp1 + gz2 + gz1) * ss - &
                    (z2*gz2 - z1*gz1) * cs * xk) / rh
      erc = -con * ((gzp2 - gzp1 + gz2 - gz1) * cs + &
                    (z2*gz2 + z1*gz1) * ss * xk) / rh
    end if

  end subroutine eksc

  !============================================================================
  ! EKSCX - E field with extended thin wire kernel
  !============================================================================
  subroutine ekscx(bx, s, z, rhx, xk, ij, inx1, inx2, &
                   ezs, ers, ezc, erc, ezk, erk)
    ! Computes E field using extended thin wire approximation
    ! Accounts for finite wire radius more accurately
    !
    ! Arguments:
    !   bx  - wire radius
    !   s   - segment length
    !   z   - z coordinate
    !   rhx - radial distance
    !   xk  - wave number
    !   ij  - field type flag
    !   inx1, inx2 - kernel type flags
    !   (outputs same as EKSC)

    real(8), intent(in) :: bx, s, z, rhx, xk
    integer, intent(in) :: ij, inx1, inx2
    complex(8), intent(out) :: ezs, ers, ezc, erc, ezk, erk

    complex(8) :: con, gz1, gz2, gzp1, gzp2
    complex(8) :: gr1, gr2, grp1, grp2, grk1, grk2
    complex(8) :: gzz1, gzz2, cint_val
    real(8) :: rh, b, sh, shk, ss, cs, z1, z2, a2, rhk
    real(8) :: bk, bk2
    real(8) :: sgr, sgi  ! Real/imaginary parts from intx()
    integer :: ira
    complex(8), parameter :: con_const = (0.0d0, 4.771341189d0)

    ! Determine radial parameters
    if (rhx < bx) then
      rh = bx
      b = rhx
      ira = 1
    else
      rh = rhx
      b = bx
      ira = 0
    end if

    sh = 0.5d0 * s
    ijx_mod = ij
    zpk_mod = xk * z
    rhk = xk * rh
    rkb2_mod = rhk * rhk

    shk = xk * sh
    ss = sin(shk)
    cs = cos(shk)
    z2 = sh - z
    z1 = -(sh + z)
    a2 = b * b

    ! Evaluate kernels based on approximation type
    if (inx1 == 2) then
      call gx(z1, rhx, xk, gz1, grk1)
      gzp1 = grk1 * z1
      gr1 = gz1 / rhx
      grp1 = gzp1 / rhx
      grk1 = grk1 * rhx
      gzz1 = (0.0d0, 0.0d0)
    else
      call gxx(z1, rh, b, a2, xk, ira, gz1, gzp1, gr1, grp1, grk1, gzz1)
    end if

    if (inx2 == 2) then
      call gx(z2, rhx, xk, gz2, grk2)
      gzp2 = grk2 * z2
      gr2 = gz2 / rhx
      grp2 = gzp2 / rhx
      grk2 = grk2 * rhx
      gzz2 = (0.0d0, 0.0d0)
    else
      call gxx(z2, rh, b, a2, xk, ira, gz2, gzp2, gr2, grp2, grk2, gzz2)
    end if

    con = con_const

    ! Calculate field components
    ezs = con * ((gz2 - gz1) * cs * xk - (gzp2 + gzp1) * ss)
    ezc = -con * ((gz2 + gz1) * ss * xk + (gzp2 - gzp1) * cs)
    ers = -con * ((z2*grp2 + z1*grp1 + gr2 + gr1) * ss - &
                  (z2*gr2 - z1*gr1) * cs * xk)
    erc = -con * ((z2*grp2 - z1*grp1 + gr2 - gr1) * cs + &
                  (z2*gr2 + z1*gr1) * ss * xk)
    erk = con * (grk2 - grk1)

    call intx(-shk, shk, rhk, ij, sgr, sgi)
    cint_val = cmplx(sgr, sgi, kind=8)

    bk = b * xk
    bk2 = bk * bk * 0.25d0
    ezk = -con * (gzp2 - gzp1 + xk*xk * (1.0d0 - bk2) * cint_val - &
                  bk2 * (gzz2 - gzz1))

  end subroutine ekscx

  !============================================================================
  ! PCINT - Patch integration at wire connection
  !============================================================================
  subroutine pcint(dataj, xi, yi, zi, cabi, sabi, salpi, e_array)
    ! Integrates over patches at wire connection point
    ! Computes interaction between wire and connected patch
    !
    ! Arguments:
    !   dataj  - junction data
    !   xi, yi, zi - observation point
    !   cabi, sabi, salpi - direction cosines
    !   e_array - output field components (9 values)

    type(dataj_data), intent(inout) :: dataj
    real(8), intent(in) :: xi, yi, zi, cabi, sabi, salpi
    complex(8), intent(out) :: e_array(9)

    complex(8) :: e1, e2, e3, e4, e5, e6, e7, e8, e9
    complex(8) :: exk_local, exs_local
    real(8) :: d, ds, da, gcon, fcon
    real(8) :: xxj, xyj, xzj, xs, s1, s2, s2x
    real(8) :: xss, yss, zss, g1, g2, g3, g4, f1, f2
    real(8) :: t1xj, t1yj, t1zj, t2xj, t2yj, t2zj
    integer :: i1, i2
    integer, parameter :: nint = 10

    ! Save original values
    xxj = dataj%xj
    xyj = dataj%yj
    xzj = dataj%zj
    xs = dataj%s

    ! Extract tangent vectors from dataj
    t1xj = dataj%cabj
    t1yj = dataj%sabj
    t1zj = dataj%salpj
    t2xj = dataj%b
    t2yj = real(dataj%ind1, kind=8)
    t2zj = real(dataj%ind2, kind=8)

    ! Setup integration parameters
    d = sqrt(dataj%s) * 0.5d0
    ds = 4.0d0 * d / real(nint, kind=8)
    da = ds * ds
    gcon = 1.0d0 / dataj%s
    fcon = 1.0d0 / (TWO_PI * d)

    dataj%s = da
    s1 = d + ds * 0.5d0
    xss = dataj%xj + s1 * (t1xj + t2xj)
    yss = dataj%yj + s1 * (t1yj + t2yj)
    zss = dataj%zj + s1 * (t1zj + t2zj)
    s1 = s1 + d
    s2x = s1

    ! Initialize field components
    e1 = (0.0d0, 0.0d0)
    e2 = (0.0d0, 0.0d0)
    e3 = (0.0d0, 0.0d0)
    e4 = (0.0d0, 0.0d0)
    e5 = (0.0d0, 0.0d0)
    e6 = (0.0d0, 0.0d0)
    e7 = (0.0d0, 0.0d0)
    e8 = (0.0d0, 0.0d0)
    e9 = (0.0d0, 0.0d0)

    ! Double integration over patch
    do i1 = 1, nint
      s1 = s1 - ds
      s2 = s2x
      xss = xss - ds * t1xj
      yss = yss - ds * t1yj
      zss = zss - ds * t1zj
      dataj%xj = xss
      dataj%yj = yss
      dataj%zj = zss

      do i2 = 1, nint
        s2 = s2 - ds
        dataj%xj = dataj%xj - ds * t2xj
        dataj%yj = dataj%yj - ds * t2yj
        dataj%zj = dataj%zj - ds * t2zj

        ! Call near field routine (would need UNERE)
        ! For now, using placeholder - full implementation needs UNERE
        exk_local = dataj%exk * cabi + dataj%eyk * sabi + dataj%ezk * salpi
        exs_local = dataj%exs * cabi + dataj%eys * sabi + dataj%ezs * salpi

        ! Calculate weighting functions
        g1 = (d + s1) * (d + s2) * gcon
        g2 = (d - s1) * (d + s2) * gcon
        g3 = (d - s1) * (d - s2) * gcon
        g4 = (d + s1) * (d - s2) * gcon

        f2 = (s1*s1 + s2*s2) * TWO_PI
        f1 = s1 / f2 - (g1 - g2 - g3 + g4) * fcon
        f2 = s2 / f2 - (g1 + g2 - g3 - g4) * fcon

        ! Accumulate contributions
        e1 = e1 + exk_local * g1
        e2 = e2 + exk_local * g2
        e3 = e3 + exk_local * g3
        e4 = e4 + exk_local * g4
        e5 = e5 + exs_local * g1
        e6 = e6 + exs_local * g2
        e7 = e7 + exs_local * g3
        e8 = e8 + exs_local * g4
        e9 = e9 + exk_local * f1 + exs_local * f2
      end do
    end do

    ! Store results
    e_array(1) = e1
    e_array(2) = e2
    e_array(3) = e3
    e_array(4) = e4
    e_array(5) = e5
    e_array(6) = e6
    e_array(7) = e7
    e_array(8) = e8
    e_array(9) = e9

    ! Restore original values
    dataj%xj = xxj
    dataj%yj = xyj
    dataj%zj = xzj
    dataj%s = xs

  end subroutine pcint

  !============================================================================
  ! GX - Green's function for thin wire approximation
  !============================================================================
  subroutine gx(zz, rh, xk, gz, gzp)
    ! Segment end contributions for thin wire approximation
    ! Computes Green's function and its derivative
    !
    ! Arguments:
    !   zz  - z coordinate distance
    !   rh  - radial distance
    !   xk  - wave number (2*pi/wavelength)
    !   gz  - Green's function value
    !   gzp - Derivative of Green's function
    !
    ! Original: nec2dxs.f lines 5428-5442

    real(8), intent(in) :: zz, rh, xk
    complex(8), intent(out) :: gz, gzp

    real(8) :: r2, r, rk

    ! Calculate distance
    r2 = zz*zz + rh*rh
    r = sqrt(r2)
    rk = xk * r

    ! Green's function: exp(ikr)/r
    gz = cmplx(cos(rk), -sin(rk), kind=8) / r

    ! Derivative: -(1 + ikr) * exp(ikr) / r^2
    gzp = -cmplx(1.0d0, rk, kind=8) * gz / r2

  end subroutine gx

  subroutine gxx(zz, rh, a, a2, xk, ira, g1, g1p, g2, g2p, g3, gzp)
    ! Segment end contributions for extended thin wire approximation
    ! Computes Green's function and derivatives with finite radius correction
    !
    ! Arguments:
    !   zz  - z coordinate distance
    !   rh  - radial distance
    !   a   - wire radius
    !   a2  - wire radius squared (a^2)
    !   xk  - wave number (2*pi/wavelength)
    !   ira - flag: 0=normal, 1=special radial case
    !   g1, g1p, g2, g2p, g3, gzp - Green's function components
    !
    ! Original: nec2dxs.f lines 5443-5487

    real(8), intent(in) :: zz, rh, a, a2, xk
    integer, intent(in) :: ira
    complex(8), intent(out) :: g1, g1p, g2, g2p, g3, gzp

    real(8) :: r2, r, r4, rk, rk2, rh2, t1, t2
    complex(8) :: gz, c1, c2, c3

    ! Calculate distance parameters
    r2 = zz*zz + rh*rh
    r = sqrt(r2)
    r4 = r2 * r2
    rk = xk * r
    rk2 = rk * rk
    rh2 = rh * rh

    ! Radius correction terms
    t1 = 0.25d0 * a2 * rh2 / r4
    t2 = 0.5d0 * a2 / r2

    ! Complex expansion terms
    c1 = cmplx(1.0d0, rk, kind=8)
    c2 = 3.0d0*c1 - rk2
    c3 = cmplx(6.0d0, rk, kind=8)*rk2 - 15.0d0*c1

    ! Base Green's function
    gz = cmplx(cos(rk), -sin(rk), kind=8) / r

    ! Compute G2 and G1
    g2 = gz * (1.0d0 + t1*c2)
    g1 = g2 - t2*c1*gz

    ! Scale gz for derivatives
    gz = gz / r2

    ! Compute derivatives
    g2p = gz * (t1*c3 - c1)
    gzp = t2 * c2 * gz
    g3 = g2p + gzp
    g1p = g3 * zz

    ! Branch based on IRA flag
    if (ira == 1) then
      ! Special radial case (IRA=1)
      t2 = 0.5d0 * a
      g2 = -t2 * c1 * gz
      g2p = t2 * gz * c2 / r2
      g3 = rh2*g2p - a*gz*c1
      g2p = g2p * zz
      gzp = -zz * c1 * gz
    else
      ! Normal case (IRA=0)
      g3 = (g3 + gzp) * rh
      gzp = -zz * c1 * gz

      if (rh > 1.0d-10) then
        g2 = g2 / rh
        g2p = g2p * zz / rh
      else
        ! Singularity handling for rh → 0
        g2 = (0.0d0, 0.0d0)
        g2p = (0.0d0, 0.0d0)
      end if
    end if

  end subroutine gxx

  subroutine intx(el1, el2, b, ij, sgr, sgi)
    ! Romberg integration of exp(jkr)/r with variable interval width
    ! Uses GF() to compute integrand values
    !
    ! Arguments:
    !   el1, el2 - integration limits
    !   b   - radial distance parameter (for singularity handling)
    !   ij  - integration type flag (0=diagonal term, nonzero=off-diagonal)
    !   sgr, sgi - Real and imaginary parts of integral result
    !
    ! Original: nec2dxs.f lines 6065-6174

    real(8), intent(in) :: el1, el2, b
    integer, intent(in) :: ij
    real(8), intent(out) :: sgr, sgi

    ! Integration parameters
    integer, parameter :: nx = 1        ! Initial step count
    integer, parameter :: nm = 65536    ! Maximum step count
    integer, parameter :: nts = 4       ! Threshold for step size increase
    real(8), parameter :: rx = 1.0d-4   ! Convergence tolerance

    ! Local variables
    real(8) :: z, ze, s, ep, zend, dz, dzot, zp, fnm, fns
    real(8) :: g1r, g1i, g2r, g2i, g3r, g3i, g4r, g4i, g5r, g5i
    real(8) :: t00r, t00i, t01r, t01i, t02r, t02i
    real(8) :: t10r, t10i, t11r, t11i, t20r, t20i
    real(8) :: te1r, te1i, te2r, te2i
    integer :: ns, nt

    ! Initialize integration bounds
    z = el1
    ze = el2
    if (ij == 0) ze = 0.0d0

    s = ze - z
    fnm = real(nm, kind=8)
    ep = s / (10.0d0 * fnm)
    zend = ze - ep

    ! Initialize result
    sgr = 0.0d0
    sgi = 0.0d0

    ns = nx
    nt = 0

    ! Get initial integrand value
    call gf_integrand(z, g1r, g1i)

    ! Main integration loop
    do while (.true.)
      fns = real(ns, kind=8)
      dz = s / fns
      zp = z + dz

      ! Check if we've reached the end
      if (zp >= ze) then
        dz = ze - z
        if (abs(dz) < ep) exit
      end if

      ! Compute interval values
      dzot = dz * 0.5d0
      zp = z + dzot
      call gf_integrand(zp, g3r, g3i)
      zp = z + dz
      call gf_integrand(zp, g5r, g5i)

      ! 3-point Romberg integration
      t00r = (g1r + g5r) * dzot
      t00i = (g1i + g5i) * dzot
      t01r = (t00r + dz * g3r) * 0.5d0
      t01i = (t00i + dz * g3i) * 0.5d0
      t10r = (4.0d0 * t01r - t00r) / 3.0d0
      t10i = (4.0d0 * t01i - t00i) / 3.0d0

      ! Test convergence of 3-point result
      call test_convergence(t01r, t10r, te1r, t01i, t10i, te1i, 0.0d0)

      if (te1i <= rx .and. te1r <= rx) then
        ! 3-point converged
        sgr = sgr + t10r
        sgi = sgi + t10i
        nt = nt + 2
      else
        ! Need 5-point integration
        zp = z + dz * 0.25d0
        call gf_integrand(zp, g2r, g2i)
        zp = z + dz * 0.75d0
        call gf_integrand(zp, g4r, g4i)

        t02r = (t01r + dzot * (g2r + g4r)) * 0.5d0
        t02i = (t01i + dzot * (g2i + g4i)) * 0.5d0
        t11r = (4.0d0 * t02r - t01r) / 3.0d0
        t11i = (4.0d0 * t02i - t01i) / 3.0d0
        t20r = (16.0d0 * t11r - t10r) / 15.0d0
        t20i = (16.0d0 * t11i - t10i) / 15.0d0

        ! Test convergence of 5-point result
        call test_convergence(t11r, t20r, te2r, t11i, t20i, te2i, 0.0d0)

        if (te2i <= rx .and. te2r <= rx) then
          ! 5-point converged
          sgr = sgr + t20r
          sgi = sgi + t20i
          nt = nt + 1
        else
          ! Need to halve step size
          nt = 0
          if (ns >= nm) then
            ! Step size limit reached - use best estimate
            write(*,'(A,F10.5)') ' STEP SIZE LIMITED AT Z=', z
            sgr = sgr + t20r
            sgi = sgi + t20i
          else
            ! Halve step size and retry
            ns = ns * 2
            fns = real(ns, kind=8)
            dz = s / fns
            dzot = dz * 0.5d0
            g5r = g3r
            g5i = g3i
            g3r = g2r
            g3i = g2i
            cycle
          end if
        end if
      end if

      ! Move to next interval
      z = z + dz
      if (z >= zend) exit

      g1r = g5r
      g1i = g5i

      ! Check if we can increase step size
      if (nt >= nts .and. ns > nx) then
        ns = ns / 2
        nt = 1
      end if
    end do

    ! Add contribution of near singularity for diagonal term
    if (ij == 0) then
      sgr = 2.0d0 * (sgr + log((sqrt(b*b + s*s) + s) / b))
      sgi = 2.0d0 * sgi
    end if

  end subroutine intx

  !============================================================================
  ! GF_INTEGRAND - Integrand function for INTX
  !============================================================================
  subroutine gf_integrand(zk, co, si)
    ! Computes the integrand exp(jkr)/(kr) for numerical integration
    ! Uses module variables zpk_mod, rkb2_mod, ijx_mod from COMMON /TMI/
    !
    ! Arguments:
    !   zk - integration point
    !   co - cosine part (real component)
    !   si - sine part (imaginary component)
    !
    ! Original: nec2dxs.f lines 4879-4901

    real(8), intent(in) :: zk
    real(8), intent(out) :: co, si

    real(8) :: zdk, rk, rks

    zdk = zk - zpk_mod
    rk = sqrt(rkb2_mod + zdk*zdk)
    si = sin(rk) / rk

    if (ijx_mod /= 0) then
      ! Off-diagonal term
      co = cos(rk) / rk
    else
      ! Diagonal term - need special handling near rk=0
      if (rk >= 0.2d0) then
        co = (cos(rk) - 1.0d0) / rk
      else
        ! Taylor series for small rk: (cos(rk)-1)/rk ≈ -rk/2 + rk³/24 - ...
        rks = rk * rk
        co = ((-1.38888889d-3 * rks + 4.16666667d-2) * rks - 0.5d0) * rk
      end if
    end if

  end subroutine gf_integrand

  !============================================================================
  ! TEST_CONVERGENCE - Test for convergence in numerical integration
  !============================================================================
  subroutine test_convergence(f1r, f2r, tr, f1i, f2i, ti, dmin)
    ! Tests relative error between two integration estimates
    !
    ! Arguments:
    !   f1r, f1i - first estimate (real and imaginary)
    !   f2r, f2i - second estimate (real and imaginary)
    !   tr, ti - relative errors (output)
    !   dmin - minimum denominator for relative error
    !
    ! Original: nec2dxs.f lines 9674-9694

    real(8), intent(in) :: f1r, f2r, f1i, f2i, dmin
    real(8), intent(out) :: tr, ti

    real(8) :: den

    ! Find maximum absolute value for denominator
    den = abs(f2r)
    tr = abs(f2i)
    if (den < tr) den = tr
    if (den < dmin) den = dmin

    if (den >= 1.0d-37) then
      ! Compute relative errors
      tr = abs((f1r - f2r) / den)
      ti = abs((f1i - f2i) / den)
    else
      ! Denominator too small - consider converged
      tr = 0.0d0
      ti = 0.0d0
    end if

  end subroutine test_convergence

  !============================================================================
  ! GH - Integrand for H field of a wire
  !============================================================================
  subroutine gh(zk, hr, hi)
    ! Computes integrand for H-field of a wire segment
    ! Uses module variables zpk_h, rhks_h from COMMON /TMH/
    !
    ! Arguments:
    !   zk - integration point
    !   hr - real part of integrand
    !   hi - imaginary part of integrand
    !
    ! Original: nec2dxs.f lines 5329-5347

    real(8), intent(in) :: zk
    real(8), intent(out) :: hr, hi

    real(8) :: rs, r, ckr, skr, rr2, rr3

    ! Compute distance
    rs = zk - zpk_h
    rs = rhks_h + rs*rs
    r = sqrt(rs)

    ! Trig functions
    ckr = cos(r)
    skr = sin(r)

    ! Powers of 1/r
    rr2 = 1.0d0 / rs
    rr3 = rr2 / r

    ! H-field integrand components
    hr = skr*rr2 + ckr*rr3
    hi = ckr*rr2 - skr*rr3

  end subroutine gh

  !============================================================================
  ! HFK - H field integration for uniform current filament
  !============================================================================
  subroutine hfk(el1, el2, rhk, zpkx, sgr, sgi)
    ! Computes H field of uniform current filament by numerical integration
    ! Uses variable interval width Romberg integration
    !
    ! Arguments:
    !   el1, el2 - integration limits
    !   rhk - radial distance * k
    !   zpkx - z coordinate * k
    !   sgr, sgi - real and imaginary parts of result
    !
    ! Original: nec2dxs.f lines 5563-5651

    real(8), intent(in) :: el1, el2, rhk, zpkx
    real(8), intent(out) :: sgr, sgi

    ! Integration parameters
    integer, parameter :: nx = 1
    integer, parameter :: nm = 65536
    integer, parameter :: nts = 4
    real(8), parameter :: rx = 1.0d-4

    ! Local variables
    real(8) :: z, ze, s, ep, zend, dz, dzot, zp
    real(8) :: g1r, g1i, g2r, g2i, g3r, g3i, g4r, g4i, g5r, g5i
    real(8) :: t00r, t00i, t01r, t01i, t02r, t02i
    real(8) :: t10r, t10i, t11r, t11i, t20r, t20i
    real(8) :: te1r, te1i, te2r, te2i
    integer :: ns, nt

    ! Set module variables for gh()
    zpk_h = zpkx
    rhks_h = rhk * rhk

    ! Initialize
    z = el1
    ze = el2
    s = ze - z
    ep = s / (10.0d0 * real(nm, kind=8))
    zend = ze - ep
    sgr = 0.0d0
    sgi = 0.0d0
    ns = nx
    nt = 0

    ! Get initial integrand value
    call gh(z, g1r, g1i)

    ! Main integration loop (same structure as intx)
    do while (.true.)
      dz = s / real(ns, kind=8)
      zp = z + dz

      if (zp >= ze) then
        dz = ze - z
        if (abs(dz) < ep) exit
      end if

      ! Compute interval values
      dzot = dz * 0.5d0
      zp = z + dzot
      call gh(zp, g3r, g3i)
      zp = z + dz
      call gh(zp, g5r, g5i)

      ! 3-point Romberg
      t00r = (g1r + g5r) * dzot
      t00i = (g1i + g5i) * dzot
      t01r = (t00r + dz*g3r) * 0.5d0
      t01i = (t00i + dz*g3i) * 0.5d0
      t10r = (4.0d0*t01r - t00r) / 3.0d0
      t10i = (4.0d0*t01i - t00i) / 3.0d0

      ! Test convergence
      call test_convergence(t01r, t10r, te1r, t01i, t10i, te1i, 0.0d0)

      if (te1i <= rx .and. te1r <= rx) then
        ! 3-point converged
        sgr = sgr + t10r
        sgi = sgi + t10i
        nt = nt + 2
      else
        ! Need 5-point integration
        zp = z + dz * 0.25d0
        call gh(zp, g2r, g2i)
        zp = z + dz * 0.75d0
        call gh(zp, g4r, g4i)

        t02r = (t01r + dzot*(g2r + g4r)) * 0.5d0
        t02i = (t01i + dzot*(g2i + g4i)) * 0.5d0
        t11r = (4.0d0*t02r - t01r) / 3.0d0
        t11i = (4.0d0*t02i - t01i) / 3.0d0
        t20r = (16.0d0*t11r - t10r) / 15.0d0
        t20i = (16.0d0*t11i - t10i) / 15.0d0

        ! Test convergence
        call test_convergence(t11r, t20r, te2r, t11i, t20i, te2i, 0.0d0)

        if (te2i <= rx .and. te2r <= rx) then
          ! 5-point converged
          sgr = sgr + t20r
          sgi = sgi + t20i
          nt = nt + 1
        else
          ! Need to halve step size
          nt = 0
          if (ns >= nm) then
            ! Step size limit
            write(*,'(A,F10.5)') ' STEP SIZE LIMITED AT Z=', z
            sgr = sgr + t20r
            sgi = sgi + t20i
          else
            ! Halve step size
            ns = ns * 2
            dz = s / real(ns, kind=8)
            dzot = dz * 0.5d0
            g5r = g3r
            g5i = g3i
            g3r = g2r
            g3i = g2i
            cycle
          end if
        end if
      end if

      ! Move to next interval
      z = z + dz
      if (z >= zend) exit

      g1r = g5r
      g1i = g5i

      ! Check if we can increase step size
      if (nt >= nts .and. ns > nx) then
        ns = ns / 2
        nt = 1
      end if
    end do

    ! Scale result
    sgr = sgr * rhk * 0.5d0
    sgi = sgi * rhk * 0.5d0

  end subroutine hfk

end module nec2_kernel
