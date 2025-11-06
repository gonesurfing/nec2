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
  public :: eksc, ekscx, pcint

  ! Module-level variables for kernel calculations (replaces COMMON /TMI/)
  real(8), save :: zpk_mod, rkb2_mod
  integer, save :: ijx_mod

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
    ! Romberg integration of exp(jkr)/r
    ! Variable interval width integration using GF() for integrand values
    !
    ! NOTE: This is still a PLACEHOLDER - needs full implementation
    !       from nec2dxs.f lines 6065-6172 plus GF() helper (lines 6173-6220)
    !
    ! Arguments:
    !   el1, el2 - integration limits
    !   b   - parameter for integration
    !   ij  - integration type flag
    !   sgr, sgi - REAL output values (NOT complex!)
    !
    ! Original: nec2dxs.f lines 6065-6172

    real(8), intent(in) :: el1, el2, b
    integer, intent(in) :: ij
    real(8), intent(out) :: sgr, sgi  ! NOTE: These are REAL, not COMPLEX!

    ! Placeholder - needs full implementation with GF() helper
    sgr = 0.0d0
    sgi = 0.0d0
  end subroutine intx

end module nec2_kernel
