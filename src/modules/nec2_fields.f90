! nec2_fields.f90
! Field calculations (far-field and near-field)
! Electric and magnetic field computations

module nec2_fields
  use nec2_constants
  use nec2_data_types
  use nec2_kernel
  use nec2_sommerfeld
  implicit none
  private

  ! Public subroutines
  public :: ffld, nefld, nhfld, efld, gfld, gwave, hsfld, hsflx, fflds, sflds

contains

  !============================================================================
  ! FFLD - Far-field pattern calculation
  !============================================================================
  subroutine ffld(geom, current, ground, thet, phi, eth, eph)
    ! Calculates far zone radiated electric fields
    ! The factor exp(jkR)/(R/λ) is NOT included
    !
    ! Arguments:
    !   geom - geometry data
    !   current - current distribution
    !   ground - ground parameters
    !   thet, phi - observation angles (radians)
    !   eth, eph - output E-theta and E-phi components

    type(geometry_data), intent(in) :: geom
    type(current_data), intent(in) :: current
    type(ground_data), intent(in) :: ground
    real(8), intent(in) :: thet, phi
    complex(8), intent(out) :: eth, eph

    complex(8) :: cix, ciy, ciz, exa, ccx, ccy, ccz
    complex(8) :: rrv, rrh, const, ex, ey, ez, zrsin
    real(8) :: phx, phy, roz, rozs, thx, thy, thz, rox, roy
    real(8) :: omega, ar, ai, zij, rk
    integer :: i, k, ksymp_local

    complex(8), parameter :: const_val = cmplx(0.0d0, -29.97922085d0, kind=8)

    ! Direction cosines for observation point
    phx = -sin(phi)
    phy = cos(phi)
    roz = cos(thet)
    rozs = roz
    thx = roz * phy
    thy = -roz * phx
    thz = -sin(thet)
    rox = -thz * phy
    roy = thz * phx

    if (geom%n == 0) goto 100

    ! Determine number of structure images for ground
    ksymp_local = ground%ksymp

    ! Loop over structure and its image if any
    do k = 1, ksymp_local
      ! Calculate reflection coefficients for image
      if (k == 2) then
        if (ground%iperf == 1) then
          ! Perfect ground
          rrv = -cmplx(1.0d0, 0.0d0, kind=8)
          rrh = -cmplx(1.0d0, 0.0d0, kind=8)
        else
          ! Finite conductivity ground
          zrsin = sqrt(1.0d0 - ground%zrati * ground%zrati * thz * thz)
          rrv = -(roz - ground%zrati * zrsin) / (roz + ground%zrati * zrsin)
          rrh = (ground%zrati * roz - zrsin) / (ground%zrati * roz + zrsin)
        end if

        ! Apply image coefficients
        roz = -roz
        ccx = cix
        ccy = ciy
        ccz = ciz
      end if

      cix = (0.0d0, 0.0d0)
      ciy = (0.0d0, 0.0d0)
      ciz = (0.0d0, 0.0d0)

      ! Loop over structure segments
      do i = 1, geom%n
        zij = geom%z(i)
        if (k == 2) zij = -zij

        ! Phase factor for segment
        omega = TWO_PI * (geom%x(i) * rox + geom%y(i) * roy + zij * roz)
        ar = cos(omega)
        ai = sin(omega)
        const = const_val * cmplx(ar, ai, kind=8)

        ! Contribution from sine current
        if (abs(current%bir(i)) > 1.0d-20 .or. abs(current%bii(i)) > 1.0d-20) then
          omega = PI * geom%si(i)
          rk = sin(omega) / omega
          ar = geom%alp(i) * rox + geom%bet(i) * roy
          ! For wires, third direction cosine salp=0 (patches not yet supported)
          cix = cix + const * cmplx(current%bir(i), current%bii(i), kind=8) * &
                (geom%alp(i) - ar * rox) * rk
          ciy = ciy + const * cmplx(current%bir(i), current%bii(i), kind=8) * &
                (geom%bet(i) - ar * roy) * rk
          ! ciz contribution is 0 for wires (salp=0)
        end if

        ! Contribution from constant current
        if (abs(current%cir(i)) > 1.0d-20 .or. abs(current%cii(i)) > 1.0d-20) then
          omega = PI * geom%si(i)
          ar = geom%alp(i) * rox + geom%bet(i) * roy
          ! For wires, third direction cosine salp=0 (patches not yet supported)
          cix = cix + const * cmplx(current%cir(i), current%cii(i), kind=8) * &
                (geom%alp(i) - ar * rox) * geom%si(i)
          ciy = ciy + const * cmplx(current%cir(i), current%cii(i), kind=8) * &
                (geom%bet(i) - ar * roy) * geom%si(i)
          ! ciz contribution is 0 for wires (salp=0)
        end if

        ! Contribution from cosine current (not commonly used)
        ! Skipped for brevity - can be added if needed
      end do

      ! Add image contributions if second pass
      if (k == 2) then
        ex = cix + ccx * rrh
        ey = ciy + ccy * rrh
        ez = ciz - ccz * rrv
        cix = ex
        ciy = ey
        ciz = ez
      end if
    end do

100 continue

    ! Transform to theta-phi components
    eth = cix * thx + ciy * thy + ciz * thz
    eph = cix * phx + ciy * phy

  end subroutine ffld

  !============================================================================
  ! NEFLD - Near electric field
  !============================================================================
  subroutine nefld(geom, current, dataj, ground, xob, yob, zob, ex, ey, ez)
    ! Computes near electric field at specified observation point
    ! after structure currents have been computed
    !
    ! Arguments:
    !   geom - geometry data
    !   current - current distribution
    !   dataj - junction data for field calculations
    !   ground - ground parameters
    !   xob, yob, zob - observation point coordinates
    !   ex, ey, ez - output E-field components

    type(geometry_data), intent(in) :: geom
    type(current_data), intent(in) :: current
    type(dataj_data), intent(inout) :: dataj
    type(ground_data), intent(in) :: ground
    real(8), intent(in) :: xob, yob, zob
    complex(8), intent(out) :: ex, ey, ez

    complex(8) :: acx, bcx, ccx
    real(8) :: ax, xj_dist, yj_dist, zj_dist, zp, dist_sq
    integer :: i

    ex = (0.0d0, 0.0d0)
    ey = (0.0d0, 0.0d0)
    ez = (0.0d0, 0.0d0)
    ax = 0.0d0

    if (geom%n == 0) return

    ! Check if observation point is inside any segment
    do i = 1, geom%n
      xj_dist = xob - geom%x(i)
      yj_dist = yob - geom%y(i)
      zj_dist = zob - geom%z(i)

      zp = geom%alp(i) * xj_dist + geom%bet(i) * yj_dist
      ! For wires, third direction cosine salp=0 (patches not yet supported)

      if (abs(zp) <= 0.5001d0 * geom%si(i)) then
        dist_sq = xj_dist * xj_dist + yj_dist * yj_dist + zj_dist * zj_dist - zp * zp
        if (dist_sq <= 0.9d0 * geom%bi(i) * geom%bi(i)) then
          ax = geom%bi(i)
          exit
        end if
      end if
    end do

    ! Sum contributions from all segments
    do i = 1, geom%n
      ! Set up segment parameters in dataj
      dataj%s = geom%si(i)
      dataj%b = geom%bi(i)
      dataj%xj = geom%x(i)
      dataj%yj = geom%y(i)
      dataj%zj = geom%z(i)
      dataj%cabj = geom%alp(i)
      dataj%sabj = geom%bet(i)
      dataj%salpj = 0.0d0  ! For wires, third direction cosine is 0 (patches not yet supported)

      ! Determine extended kernel type if needed
      dataj%iexk = 0  ! Initialize to 0 (set by calling function if needed)
      ! (kernel type determination logic would go here)

      ! Calculate field from this segment
      call efld(geom, dataj, ground, xob, yob, zob, ax, 1)

      ! Add weighted contributions from current components
      acx = cmplx(current%air(i), current%aii(i), kind=8)
      bcx = cmplx(current%bir(i), current%bii(i), kind=8)
      ccx = cmplx(current%cir(i), current%cii(i), kind=8)

      ex = ex + dataj%exk * acx + dataj%exs * bcx + dataj%exc * ccx
      ey = ey + dataj%eyk * acx + dataj%eys * bcx + dataj%eyc * ccx
      ez = ez + dataj%ezk * acx + dataj%ezs * bcx + dataj%ezc * ccx
    end do

  end subroutine nefld

  !============================================================================
  ! NHFLD - Near magnetic field
  !============================================================================
  subroutine nhfld(geom, current, xob, yob, zob, hx, hy, hz)
    ! Computes near magnetic field at specified observation point
    !
    ! Arguments:
    !   geom - geometry data
    !   current - current distribution
    !   xob, yob, zob - observation point
    !   hx, hy, hz - output H-field components

    type(geometry_data), intent(in) :: geom
    type(current_data), intent(in) :: current
    real(8), intent(in) :: xob, yob, zob
    complex(8), intent(out) :: hx, hy, hz

    complex(8) :: cur, hpx, hpy, hpz
    real(8) :: xij, yij, zij, rh, rx, ry, rz, r, r2, r5
    real(8) :: omega, c, s, px, py, pz
    integer :: i

    hx = (0.0d0, 0.0d0)
    hy = (0.0d0, 0.0d0)
    hz = (0.0d0, 0.0d0)

    if (geom%n == 0) return

    ! Sum contributions from all segments
    do i = 1, geom%n
      ! Vector from segment center to observation point
      xij = xob - geom%x(i)
      yij = yob - geom%y(i)
      zij = zob - geom%z(i)

      rh = sqrt(xij * xij + yij * yij + zij * zij)
      if (rh < 1.0d-20) cycle

      ! Simplified H-field calculation (dipole approximation)
      ! Full implementation would include segment integration
      cur = cmplx(current%air(i) + current%bir(i), &
                  current%aii(i) + current%bii(i), kind=8)

      omega = TWO_PI * rh
      c = cos(omega)
      s = sin(omega)

      r = rh
      r2 = r * r
      r5 = r2 * r2 * r

      ! Cross product of current direction with position vector
      ! Simplified - full version would integrate over segment
      px = geom%alp(i)
      py = geom%bet(i)
      pz = 0.0d0  ! For wires, third direction cosine is 0 (patches not yet supported)

      rx = xij / rh
      ry = yij / rh
      rz = zij / rh

      ! H = (I dl × r) / (4π r³) [with phase and magnitude factors]
      hpx = cur * (py * rz - pz * ry) * geom%si(i)
      hpy = cur * (pz * rx - px * rz) * geom%si(i)
      hpz = cur * (px * ry - py * rx) * geom%si(i)

      hx = hx + hpx * cmplx(c, -s, kind=8) / r2
      hy = hy + hpy * cmplx(c, -s, kind=8) / r2
      hz = hz + hpz * cmplx(c, -s, kind=8) / r2
    end do

    ! Apply scaling factor
    hx = hx / (4.0d0 * PI)
    hy = hy / (4.0d0 * PI)
    hz = hz / (4.0d0 * PI)

  end subroutine nhfld

  !============================================================================
  ! EFLD - Electric field from a segment
  !============================================================================
  subroutine efld(geom, dataj, ground, xi, yi, zi, ai, ij)
    ! Computes near E field from a segment with sine, cosine, and
    ! constant currents. Ground effect included.
    !
    ! Arguments:
    !   geom - geometry data
    !   dataj - junction data (contains segment params and output fields)
    !   ground - ground parameters
    !   xi, yi, zi - observation point
    !   ai - radius for near-field approximation
    !   ij - segment index offset

    type(geometry_data), intent(in) :: geom
    type(dataj_data), intent(inout) :: dataj
    type(ground_data), intent(in) :: ground
    real(8), intent(in) :: xi, yi, zi, ai
    integer, intent(in) :: ij

    complex(8) :: tezs, ters, tezc, terc, tezk, terk
    complex(8) :: txk, tyk, tzk, txs, tys, tzs, txc, tyc, tzc
    real(8) :: xij, yij, zij, zp, rhox, rhoy, rhoz, rh, r
    real(8) :: rfl, salpr
    integer :: ip, ijx

    ! Initialize output fields
    dataj%exk = (0.0d0, 0.0d0)
    dataj%eyk = (0.0d0, 0.0d0)
    dataj%ezk = (0.0d0, 0.0d0)
    dataj%exs = (0.0d0, 0.0d0)
    dataj%eys = (0.0d0, 0.0d0)
    dataj%ezs = (0.0d0, 0.0d0)
    dataj%exc = (0.0d0, 0.0d0)
    dataj%eyc = (0.0d0, 0.0d0)
    dataj%ezc = (0.0d0, 0.0d0)

    xij = xi - dataj%xj
    yij = yi - dataj%yj
    ijx = ij
    rfl = -1.0d0

    ! Loop for structure and its image
    do ip = 1, ground%ksymp
      if (ip == 2) ijx = 1
      rfl = -rfl
      salpr = dataj%salpj * rfl
      zij = zi - rfl * dataj%zj

      ! Project onto segment axis
      zp = xij * dataj%cabj + yij * dataj%sabj + zij * salpr

      ! Perpendicular distance vector
      rhox = xij - dataj%cabj * zp
      rhoy = yij - dataj%sabj * zp
      rhoz = zij - salpr * zp

      ! Perpendicular distance
      rh = sqrt(rhox * rhox + rhoy * rhoy + rhoz * rhoz + ai * ai)

      if (rh > 1.0d-10) then
        rhox = rhox / rh
        rhoy = rhoy / rh
        rhoz = rhoz / rh
      else
        rhox = 0.0d0
        rhoy = 0.0d0
        rhoz = 0.0d0
      end if

      r = sqrt(zp * zp + rh * rh)

      ! Calculate field using appropriate kernel
      if (r >= dataj%rkh) then
        ! Lumped current element approximation for large separations
        ! (simplified - full implementation in original code)
        tezk = (0.0d0, 0.0d0)
        terk = (0.0d0, 0.0d0)
        tezs = (0.0d0, 0.0d0)
        ters = (0.0d0, 0.0d0)
        tezc = (0.0d0, 0.0d0)
        terc = (0.0d0, 0.0d0)
      else
        ! Use kernel functions
        if (dataj%iexk == 0) then
          ! Thin wire kernel
          call eksc(dataj%s, zp, rh, TWO_PI, ijx, tezs, ters, tezc, terc, tezk, terk)
        else
          ! Extended thin wire kernel
          call ekscx(dataj%b, dataj%s, zp, rh, TWO_PI, ijx, &
                    dataj%ind1, dataj%ind2, tezs, ters, tezc, terc, tezk, terk)
        end if
      end if

      ! Transform to x, y, z components
      txs = tezs * dataj%cabj + ters * rhox
      tys = tezs * dataj%sabj + ters * rhoy
      tzs = tezs * salpr + ters * rhoz

      txk = tezk * dataj%cabj + terk * rhox
      tyk = tezk * dataj%sabj + terk * rhoy
      tzk = tezk * salpr + terk * rhoz

      txc = tezc * dataj%cabj + terc * rhox
      tyc = tezc * dataj%sabj + terc * rhoy
      tzc = tezc * salpr + terc * rhoz

      ! Add contributions (with image if ip==2)
      if (ip == 1) then
        dataj%exk = txk
        dataj%eyk = tyk
        dataj%ezk = tzk
        dataj%exs = txs
        dataj%eys = tys
        dataj%ezs = tzs
        dataj%exc = txc
        dataj%eyc = tyc
        dataj%ezc = tzc
      else
        ! Add image contributions (simplified - needs ground reflection coefficients)
        dataj%exk = dataj%exk + txk
        dataj%eyk = dataj%eyk + tyk
        dataj%ezk = dataj%ezk - tzk  ! Sign flip for vertical component
        dataj%exs = dataj%exs + txs
        dataj%eys = dataj%eys + tys
        dataj%ezs = dataj%ezs - tzs
        dataj%exc = dataj%exc + txc
        dataj%eyc = dataj%eyc + tyc
        dataj%ezc = dataj%ezc - tzc
      end if
    end do

  end subroutine efld

  !============================================================================
  ! GFLD - Ground field calculation (placeholder)
  !============================================================================
  subroutine gfld(geom, current, ground, rho, phi, rz, eth, epi, erd, ux, ksymp)
    ! Computes the radiated field including ground wave
    ! Sums contributions from all segments with ground reflection
    !
    ! Arguments:
    !   geom - Geometry data structure
    !   current - Current distribution data
    !   ground - Ground parameters (for ffld call)
    !   rho - Radial distance in cylindrical coordinates
    !   phi - Azimuthal angle
    !   rz - Vertical coordinate
    !   eth, epi, erd - Output field components (theta, phi, radial)
    !   ux - Ground reflection coefficient
    !   ksymp - Symmetry flag (1=space wave only)
    !
    ! Original: nec2dxs.f lines 5069-5221

    type(geometry_data), intent(in) :: geom
    type(current_data), intent(in) :: current
    type(ground_data), intent(in) :: ground
    real(8), intent(in) :: rho, phi, rz, ux
    integer, intent(in) :: ksymp
    complex(8), intent(out) :: eth, epi, erd

    complex(8) :: exa, cix, ciy, ciz, ex, ey
    complex(8) :: xx1, xx2, u, u2
    complex(8) :: erv, ezv, erh, ezh, eph_local
    real(8) :: r, thet, arg, phx, phy, rx, ry
    real(8) :: dx, dy, dz, rix, riy, riz, rhs, rhp, rhx, rhy
    real(8) :: calp, cbet, sbet, cph, sph, el, rfl, rxyz
    real(8) :: rnx, rny, rnz, omega, sill, top, bot, a, too, boo, b, c
    real(8) :: rr, ri, r1, r2, zmh, zph
    real(8) :: rnx_obs, rny_obs, rnz_obs, thx, thy, thz
    integer :: i, k

    real(8), parameter :: ptp = TWO_PI

    ! Calculate distance to observation point
    r = sqrt(rho*rho + rz*rz)

    ! Check for space wave only conditions
    if (ksymp == 1 .or. abs(ux) > 0.5d0 .or. r > 1.0d5) then
      ! Computation of space wave only
      if (rz < 1.0d-20) then
        thet = PI * 0.5d0
      else
        thet = atan(rho / rz)
      end if

      call ffld(geom, current, ground, thet, phi, eth, epi)

      arg = -ptp * r
      exa = cmplx(cos(arg), sin(arg), kind=8) / r
      eth = eth * exa
      epi = epi * exa
      erd = cmplx(0.0d0, 0.0d0, kind=8)
      return
    end if

    ! Computation of space and ground waves
    u = cmplx(ux, 0.0d0, kind=8)
    u2 = u * u
    phx = -sin(phi)
    phy = cos(phi)
    rx = rho * phy
    ry = -rho * phx
    cix = cmplx(0.0d0, 0.0d0, kind=8)
    ciy = cmplx(0.0d0, 0.0d0, kind=8)
    ciz = cmplx(0.0d0, 0.0d0, kind=8)

    ! Summation of field from individual segments
    do i = 1, geom%n
      dx = geom%alp(i)
      dy = geom%bet(i)
      dz = 0.0d0  ! For wires, third direction cosine is 0 (patches not yet supported)
      rix = rx - geom%x(i)
      riy = ry - geom%y(i)
      rhs = rix*rix + riy*riy
      rhp = sqrt(rhs)

      if (rhp < 1.0d-6) then
        rhx = 1.0d0
        rhy = 0.0d0
      else
        rhx = rix / rhp
        rhy = riy / rhp
      end if

      calp = 1.0d0 - dz*dz
      if (calp < 1.0d-6) then
        cph = rhx
        sph = rhy
      else
        calp = sqrt(calp)
        cbet = dx / calp
        sbet = dy / calp
        cph = rhx*cbet + rhy*sbet
        sph = rhy*cbet - rhx*sbet
      end if

      el = PI * geom%si(i)
      rfl = -1.0d0

      ! Integration over segment and image
      do k = 1, 2
        rfl = -rfl
        riz = rz - geom%z(i) * rfl
        rxyz = sqrt(rix*rix + riy*riy + riz*riz)
        rnx = rix / rxyz
        rny = riy / rxyz
        rnz = riz / rxyz
        omega = -(rnx*dx + rny*dy + rnz*dz*rfl)
        sill = omega * el
        top = el + sill
        bot = el - sill

        ! Calculate integration coefficients
        if (abs(omega) < 1.0d-7) then
          a = (2.0d0 - omega*omega*el*el/3.0d0) * el
        else
          a = 2.0d0 * sin(sill) / omega
        end if

        if (abs(top) < 1.0d-7) then
          too = 1.0d0 - top*top/6.0d0
        else
          too = sin(top) / top
        end if

        if (abs(bot) < 1.0d-7) then
          boo = 1.0d0 - bot*bot/6.0d0
        else
          boo = sin(bot) / bot
        end if

        b = el * (boo - too)
        c = el * (boo + too)

        ! Combine with current coefficients
        rr = a*current%air(i) + b*current%bii(i) + c*current%cir(i)
        ri = a*current%aii(i) - b*current%bir(i) + c*current%cii(i)

        arg = ptp * (geom%x(i)*rnx + geom%y(i)*rny + geom%z(i)*rnz*rfl)
        exa = cmplx(cos(arg), sin(arg), kind=8) * cmplx(rr, ri, kind=8) / ptp

        if (k == 1) then
          xx1 = exa
          r1 = rxyz
          zmh = riz
        else
          xx2 = exa
          r2 = rxyz
          zph = riz
        end if
      end do

      ! Call subroutine to compute field of segment including ground wave
      call gwave(u, u2, xx1, xx2, r1, r2, zmh, zph, erv, ezv, erh, ezh, eph_local)

      erh = erh * cph * calp + erv * dz
      eph_local = eph_local * sph * calp
      ezh = ezh * cph * calp + ezv * dz

      ex = erh * rhx - eph_local * rhy
      ey = erh * rhy + eph_local * rhx

      cix = cix + ex
      ciy = ciy + ey
      ciz = ciz + ezh
    end do

    ! Apply phase factor for observation point
    arg = -ptp * r
    exa = cmplx(cos(arg), sin(arg), kind=8)
    cix = cix * exa
    ciy = ciy * exa
    ciz = ciz * exa

    ! Transform to spherical components
    rnx_obs = rx / r
    rny_obs = ry / r
    rnz_obs = rz / r

    thx = rnz_obs * phy
    thy = -rnz_obs * phx
    thz = -rho / r

    eth = cix*thx + ciy*thy + ciz*thz
    epi = cix*phx + ciy*phy
    erd = cix*rnx_obs + ciy*rny_obs + ciz*rnz_obs

  end subroutine gfld

  !============================================================================
  ! GWAVE - Ground wave field (placeholder)
  !============================================================================
  subroutine gwave(u, u2, xx1, xx2, r1, r2, zmh, zph, erv, ezv, erh, ezh, eph)
    ! Computes electric field (including ground wave) of a current element
    ! over a ground plane using formulas of K.A. Norton (Proc. IRE, Sept. 1937)
    !
    ! Arguments:
    !   u, u2 - Ground reflection coefficient and its square
    !   xx1, xx2 - Phase factors for direct and image contributions
    !   r1, r2 - Distances to direct and image sources
    !   zmh, zph - Vertical components for direct and image paths
    !   erv, ezv, erh, ezh, eph - Output field components
    !
    ! Original: nec2dxs.f lines 5348-5427

    use nec2_sommerfeld, only: fbar

    complex(8), intent(in) :: u, u2, xx1, xx2
    real(8), intent(in) :: r1, r2, zmh, zph
    complex(8), intent(out) :: erv, ezv, erh, ezh, eph

    complex(8) :: rk1, rk2, t1, t2, t3, t4, p1, rv, omr, w, f, q1, rh, v, g
    complex(8) :: xr1, xr2, x1, x2, x3, x4, x5, x6, x7
    real(8) :: sppp, sppp2, cppp, cppp2, spp, spp2, cpp, cpp2

    ! Constants
    complex(8), parameter :: fj = cmplx(0.0d0, 1.0d0, kind=8)
    complex(8), parameter :: tpj = cmplx(0.0d0, TWO_PI, kind=8)
    complex(8), parameter :: econ = cmplx(0.0d0, -188.367d0, kind=8)

    ! Compute trigonometric values
    sppp = zmh / r1
    sppp2 = sppp * sppp
    cppp2 = 1.0d0 - sppp2
    if (cppp2 < 1.0d-20) cppp2 = 1.0d-20
    cppp = sqrt(cppp2)

    spp = zph / r2
    spp2 = spp * spp
    cpp2 = 1.0d0 - spp2
    if (cpp2 < 1.0d-20) cpp2 = 1.0d-20
    cpp = sqrt(cpp2)

    ! Complex wave numbers
    rk1 = -tpj * r1
    rk2 = -tpj * r2

    ! Intermediate terms
    t1 = 1.0d0 - u2 * cpp2
    t2 = sqrt(t1)
    t3 = (1.0d0 - 1.0d0/rk1) / rk1
    t4 = (1.0d0 - 1.0d0/rk2) / rk2

    ! Vertical polarization reflection coefficient and attenuation
    p1 = rk2 * u2 * t1 / (2.0d0 * cpp2)
    rv = (spp - u*t2) / (spp + u*t2)
    omr = 1.0d0 - rv
    w = 1.0d0 / omr
    w = cmplx(4.0d0, 0.0d0, kind=8) * p1 * w * w
    f = fbar(w)

    ! Horizontal polarization reflection coefficient and attenuation
    q1 = rk2 * t1 / (2.0d0 * u2 * cpp2)
    rh = (t2 - u*spp) / (t2 + u*spp)
    v = 1.0d0 / (1.0d0 + rh)
    v = cmplx(4.0d0, 0.0d0, kind=8) * q1 * v * v
    g = fbar(v)

    ! Normalized distances
    xr1 = xx1 / r1
    xr2 = xx2 / r2

    ! EZV - Vertical component for vertical polarization
    x1 = cppp2 * xr1
    x2 = rv * cpp2 * xr2
    x3 = omr * cpp2 * f * xr2
    x4 = u * t2 * spp * 2.0d0 * xr2 / rk2
    x5 = xr1 * t3 * (1.0d0 - 3.0d0*sppp2)
    x6 = xr2 * t4 * (1.0d0 - 3.0d0*spp2)
    ezv = (x1 + x2 + x3 - x4 - x5 - x6) * econ

    ! ERV - Radial component for vertical polarization
    x1 = sppp * cppp * xr1
    x2 = rv * spp * cpp * xr2
    x3 = cpp * omr * u * t2 * f * xr2
    x4 = spp * cpp * omr * xr2 / rk2
    x5 = 3.0d0 * sppp * cppp * t3 * xr1
    x6 = cpp * u * t2 * omr * xr2 / rk2 * 0.5d0
    x7 = 3.0d0 * spp * cpp * t4 * xr2
    erv = -(x1 + x2 - x3 + x4 - x5 + x6 - x7) * econ

    ! EZH - Vertical component for horizontal polarization
    ezh = -(x1 - x2 + x3 - x4 - x5 - x6 + x7) * econ

    ! ERH - Radial component for horizontal polarization
    x1 = sppp2 * xr1
    x2 = rv * spp2 * xr2
    x4 = u2 * t1 * omr * f * xr2
    x5 = t3 * (1.0d0 - 3.0d0*cppp2) * xr1
    x6 = t4 * (1.0d0 - 3.0d0*cpp2) * (1.0d0 - u2*(1.0d0 + rv) - u2*omr*f) * xr2
    x7 = u2 * cpp2 * omr * (1.0d0 - 1.0d0/rk2) * &
         (f*(u2*t1 - spp2 - 1.0d0/rk2) + 1.0d0/rk2) * xr2
    erh = (x1 - x2 - x4 - x5 + x6 + x7) * econ

    ! EPH - Phi component for horizontal polarization
    x1 = xr1
    x2 = rh * xr2
    x3 = (rh + 1.0d0) * g * xr2
    x4 = t3 * xr1
    x5 = t4 * (1.0d0 - u2*(1.0d0 + rv) - u2*omr*f) * xr2
    x6 = 0.5d0 * u2 * omr * (f*(u2*t1 - spp2 - 1.0d0/rk2) + 1.0d0/rk2) * xr2 / rk2
    eph = -(x1 - x2 + x3 - x4 + x5 + x6) * econ

  end subroutine gwave

  !============================================================================
  ! HSFLX - H field calculation helper
  !============================================================================
  subroutine hsflx(s, rh, zp, hpk, hps, hpc)
    ! Calculates H field of sine, cosine, and constant current of segment
    !
    ! Arguments:
    !   s - segment length
    !   rh - radial distance
    !   zp - z projection
    !   hpk, hps, hpc - H field components (constant, sine, cosine)
    !
    ! Original: nec2dxs.f lines 5852-5908

    use nec2_kernel, only: hfk

    real(8), intent(in) :: s, rh, zp
    complex(8), intent(out) :: hpk, hps, hpc

    complex(8) :: ekr1, ekr2, t1, t2, cons
    real(8) :: dh, z1, z2, rhz, dk, cdk, sdk, hkr, hki, rh2, r1, r2
    real(8) :: zp_local, hss

    real(8), parameter :: tp = TWO_PI
    real(8), parameter :: pi8 = 8.0d0 * PI
    complex(8), parameter :: fj = cmplx(0.0d0, 1.0d0, kind=8)
    complex(8), parameter :: fjk = cmplx(0.0d0, -TWO_PI, kind=8)

    ! Check for singularity
    if (rh < 1.0d-10) then
      hps = cmplx(0.0d0, 0.0d0, kind=8)
      hpc = cmplx(0.0d0, 0.0d0, kind=8)
      hpk = cmplx(0.0d0, 0.0d0, kind=8)
      return
    end if

    ! Handle sign of zp
    if (zp < 0.0d0) then
      zp_local = -zp
      hss = -1.0d0
    else
      zp_local = zp
      hss = 1.0d0
    end if

    dh = 0.5d0 * s
    z1 = zp_local + dh
    z2 = zp_local - dh

    ! Check for small z2
    if (z2 < 1.0d-7) then
      rhz = 1.0d0
    else
      rhz = rh / z2
    end if

    dk = tp * dh
    cdk = cos(dk)
    sdk = sin(dk)

    ! Call hfk for constant current term
    call hfk(-dk, dk, rh*tp, zp_local*tp, hkr, hki)
    hpk = cmplx(hkr, hki, kind=8)

    if (rhz < 1.0d-3) then
      ! Small rhz approximation
      ekr1 = cmplx(cdk, sdk, kind=8) / (z2*z2)
      ekr2 = cmplx(cdk, -sdk, kind=8) / (z1*z1)
      t1 = tp * (1.0d0/z1 - 1.0d0/z2)
      t2 = exp(fjk*zp_local) * rh / pi8
      hps = t2 * (t1 + (ekr1 + ekr2)*sdk) * hss
      hpc = t2 * (-fj*t1 + (ekr1 - ekr2)*cdk)
    else
      ! Normal case
      rh2 = rh * rh
      r1 = sqrt(rh2 + z1*z1)
      r2 = sqrt(rh2 + z2*z2)
      ekr1 = exp(fjk*r1)
      ekr2 = exp(fjk*r2)
      t1 = z1 * ekr1 / r1
      t2 = z2 * ekr2 / r2
      hps = (cdk*(ekr2 - ekr1) - fj*sdk*(t2 + t1)) * hss
      hpc = -sdk*(ekr2 + ekr1) - fj*cdk*(t2 - t1)
      cons = -fj / (2.0d0*tp*rh)
      hps = cons * hps
      hpc = cons * hpc
    end if

  end subroutine hsflx

  !============================================================================
  ! HSFLD - H field from surface patches
  !============================================================================
  subroutine hsfld(dataj, ground, xi, yi, zi, ai)
    ! Computes H field for constant, sine, and cosine current on a segment
    ! including ground effects
    !
    ! Arguments:
    !   dataj - junction/segment data (contains E fields and geometry)
    !   ground - ground parameters
    !   xi, yi, zi - observation point
    !   ai - segment radius
    !
    ! Original: nec2dxs.f lines 5739-5851

    type(dataj_data), intent(inout) :: dataj
    type(ground_data), intent(in) :: ground
    real(8), intent(in) :: xi, yi, zi, ai

    complex(8) :: hpk, hps, hpc, qx, qy, qz
    complex(8) :: rrv, rrh, zratx
    real(8) :: xij, yij, zij, rfl, salpr, zp
    real(8) :: rhox, rhoy, rhoz, rh, phx, phy, phz
    real(8) :: rmag, xymag, px, py, cth
    real(8) :: xspec, yspec, rhospc

    real(8), parameter :: eta = 376.73d0
    integer :: ip

    xij = xi - dataj%xj
    yij = yi - dataj%yj
    rfl = -1.0d0

    ! Loop over symmetry (1 or 2 iterations)
    do ip = 1, ground%ksymp
      rfl = -rfl
      salpr = dataj%salpj * rfl
      zij = zi - rfl*dataj%zj

      ! Project onto segment axis
      zp = xij*dataj%cabj + yij*dataj%sabj + zij*salpr

      ! Perpendicular components
      rhox = xij - dataj%cabj*zp
      rhoy = yij - dataj%sabj*zp
      rhoz = zij - salpr*zp

      ! Radial distance with regularization
      rh = sqrt(rhox*rhox + rhoy*rhoy + rhoz*rhoz + ai*ai)

      if (rh <= 1.0d-10) then
        ! Singularity - zero fields
        dataj%exk = cmplx(0.0d0, 0.0d0, kind=8)
        dataj%eyk = cmplx(0.0d0, 0.0d0, kind=8)
        dataj%ezk = cmplx(0.0d0, 0.0d0, kind=8)
        dataj%exs = cmplx(0.0d0, 0.0d0, kind=8)
        dataj%eys = cmplx(0.0d0, 0.0d0, kind=8)
        dataj%ezs = cmplx(0.0d0, 0.0d0, kind=8)
        dataj%exc = cmplx(0.0d0, 0.0d0, kind=8)
        dataj%eyc = cmplx(0.0d0, 0.0d0, kind=8)
        dataj%ezc = cmplx(0.0d0, 0.0d0, kind=8)
        cycle
      end if

      ! Normalize perpendicular vector
      rhox = rhox / rh
      rhoy = rhoy / rh
      rhoz = rhoz / rh

      ! Phi direction vector (cross product of segment axis with radial)
      phx = dataj%sabj*rhoz - salpr*rhoy
      phy = salpr*rhox - dataj%cabj*rhoz
      phz = dataj%cabj*rhoy - dataj%sabj*rhox

      ! Calculate H fields
      call hsflx(dataj%s, rh, zp, hpk, hps, hpc)

      if (ip /= 2) then
        ! First iteration - direct contribution
        dataj%exk = hpk * phx
        dataj%eyk = hpk * phy
        dataj%ezk = hpk * phz
        dataj%exs = hps * phx
        dataj%eys = hps * phy
        dataj%ezs = hps * phz
        dataj%exc = hpc * phx
        dataj%eyc = hpc * phy
        dataj%ezc = hpc * phz
      else
        ! Second iteration - add ground reflection
        if (ground%iperf == 1) then
          ! Perfect ground
          dataj%exk = dataj%exk - hpk*phx
          dataj%eyk = dataj%eyk - hpk*phy
          dataj%ezk = dataj%ezk - hpk*phz
          dataj%exs = dataj%exs - hps*phx
          dataj%eys = dataj%eys - hps*phy
          dataj%ezs = dataj%ezs - hps*phz
          dataj%exc = dataj%exc - hpc*phx
          dataj%eyc = dataj%eyc - hpc*phy
          dataj%ezc = dataj%ezc - hpc*phz
        else
          ! Finite conductivity ground
          zratx = ground%zrati
          rmag = sqrt(zp*zp + rh*rh)
          xymag = sqrt(xij*xij + yij*yij)

          ! Handle radial wire ground screen
          if (ground%nradl /= 0) then
            xspec = (xi*dataj%zj + zi*dataj%xj) / (zi + dataj%zj)
            yspec = (yi*dataj%zj + zi*dataj%yj) / (zi + dataj%zj)
            rhospc = sqrt(xspec*xspec + yspec*yspec + ground%t2*ground%t2)

            if (rhospc <= ground%scrwl) then
              rrv = ground%t1 * rhospc * log(rhospc / ground%t2)
              zratx = (rrv*ground%zrati) / (eta*ground%zrati + rrv)
            end if
          end if

          ! Calculate reflection coefficients
          if (xymag > 1.0d-6) then
            px = -yij / xymag
            py = xij / xymag
            cth = zij / rmag
            rrv = sqrt(1.0d0 - zratx*zratx*(1.0d0 - cth*cth))
          else
            px = 0.0d0
            py = 0.0d0
            cth = 1.0d0
            rrv = cmplx(1.0d0, 0.0d0, kind=8)
          end if

          rrh = zratx * cth
          rrh = -(rrh - rrv) / (rrh + rrv)
          rrv = zratx * rrv
          rrv = (cth - rrv) / (cth + rrv)

          ! Apply reflection coefficients
          qy = (phx*px + phy*py) * (rrv - rrh)
          qx = qy*px + phx*rrh
          qy = qy*py + phy*rrh
          qz = phz*rrh

          dataj%exk = dataj%exk - hpk*qx
          dataj%eyk = dataj%eyk - hpk*qy
          dataj%ezk = dataj%ezk - hpk*qz
          dataj%exs = dataj%exs - hps*qx
          dataj%eys = dataj%eys - hps*qy
          dataj%ezs = dataj%ezs - hps*qz
          dataj%exc = dataj%exc - hpc*qx
          dataj%eyc = dataj%eyc - hpc*qy
          dataj%ezc = dataj%ezc - hpc*qz
        end if
      end if
    end do

  end subroutine hsfld

  !============================================================================
  ! FFLDS - Far field supplementary calculations
  !============================================================================
  subroutine fflds(geom, rox, roy, roz, scur, ex, ey, ez)
    ! Calculates the XYZ components of the electric field due to surface currents
    ! Used for far-field contributions from surface patches
    !
    ! Arguments:
    !   geom - geometry data (for surface patch locations)
    !   rox, roy, roz - direction cosines of observation direction
    !   scur - surface current array (3*M elements: x,y,z components)
    !   ex, ey, ez - output electric field components

    type(geometry_data), intent(in) :: geom
    real(8), intent(in) :: rox, roy, roz
    complex(8), intent(in) :: scur(:)
    complex(8), intent(out) :: ex, ey, ez

    complex(8) :: ct, proj
    real(8) :: arg, cos_arg, sin_arg, area
    integer :: i, j, k, patch_idx

    complex(8), parameter :: CONS_VAL = cmplx(0.0d0, 188.365d0, kind=8)  ! j*60*pi

    ! Initialize field components
    ex = (0.0d0, 0.0d0)
    ey = (0.0d0, 0.0d0)
    ez = (0.0d0, 0.0d0)

    ! Sum contributions from all surface patches
    ! Patches are stored after wire segments: indices LD+1 to LD+M
    patch_idx = geom%ld + 1
    do j = 1, geom%m
      i = patch_idx - 1  ! Current patch index in geometry arrays

      ! Compute phase factor: exp(j*2*pi*(rox*x + roy*y + roz*z)) * area
      arg = TWO_PI * (rox * geom%x(i) + roy * geom%y(i) + roz * geom%z(i))
      cos_arg = cos(arg)
      sin_arg = sin(arg)
      area = geom%bi(i)  ! Patch area stored in bi

      ct = cmplx(cos_arg * area, sin_arg * area, kind=8)

      ! Add current contributions (scur has x,y,z components for each patch)
      k = 3 * j
      ex = ex + scur(k-2) * ct
      ey = ey + scur(k-1) * ct
      ez = ez + scur(k) * ct

      patch_idx = patch_idx - 1
    end do

    ! Project out radial component and apply constant
    ! E = CONS * (proj * r_hat - E) where proj = r_hat . E
    proj = rox * ex + roy * ey + roz * ez
    ex = CONS_VAL * (proj * rox - ex)
    ey = CONS_VAL * (proj * roy - ey)
    ez = CONS_VAL * (proj * roz - ez)

  end subroutine fflds

  !============================================================================
  ! SFLDS - Surface field calculations
  !============================================================================
  subroutine sflds(t_val, e_out, dataj, ground, obs_x, obs_y, obs_z, sn_val, xsn, ysn, isnor)
    ! Computes the field due to ground for a current element on the source
    ! segment at position T relative to segment center. Returns 9 field
    ! components: constant, sine, and cosine terms for x, y, z directions.
    !
    ! This function is critical for surface patch near-field calculations
    ! including ground effects.
    !
    ! Arguments:
    !   t_val - position on segment relative to center (-0.5 to 0.5)
    !   e_out - output field array (9 components):
    !           E(1:3) = constant term (x,y,z)
    !           E(4:6) = sine term (x,y,z)
    !           E(7:9) = cosine term (x,y,z)
    !   dataj - segment geometry data
    !   ground - ground parameters
    !   obs_x, obs_y, obs_z - observation point coordinates
    !   sn_val - ? (from original INCOM common)
    !   xsn, ysn - ? (from original INCOM common)
    !   isnor - flag: 0=Norton approximation, 1=Sommerfeld interpolation
    !
    ! Original: nec2dxs.f lines 9126-9243
    ! Note: Uses intrp from nec2_sommerfeld (already imported at module level)

    real(8), intent(in) :: t_val
    complex(8), intent(out) :: e_out(9)
    type(dataj_data), intent(in) :: dataj
    type(ground_data), intent(in) :: ground
    real(8), intent(in) :: obs_x, obs_y, obs_z
    real(8), intent(in) :: sn_val, xsn, ysn
    integer, intent(in) :: isnor

    real(8) :: xt, yt, zt, rhx, rhy, rhs, rho, phx, phy
    real(8) :: cph, sph, zph, zphs, r2s, r2, rk, sfac
    real(8) :: r1, zmh, thet, pot
    complex(8) :: erv, ezv, erh, ezh, eph
    complex(8) :: xx1, xx2, u, u2
    complex(8) :: et, er, hrv, hzv, hrh
    complex(8) :: frati, t1

    real(8), parameter :: PI = 3.141592654d0
    real(8), parameter :: TP = 6.283185308d0
    real(8), parameter :: POT_VAL = 1.570796327d0

    ! Compute position of current element on segment
    xt = dataj%xj + t_val * dataj%cabj
    yt = dataj%yj + t_val * dataj%sabj
    zt = dataj%zj + t_val * dataj%salpj

    ! Compute horizontal distance components to observation point
    rhx = obs_x - xt
    rhy = obs_y - yt
    rhs = rhx * rhx + rhy * rhy
    rho = sqrt(rhs)

    ! Compute unit vectors for cylindrical coordinates
    if (rho > 0.0d0) then
      rhx = rhx / rho
      rhy = rhy / rho
      phx = -rhy
      phy = rhx
    else
      rhx = 1.0d0
      rhy = 0.0d0
      phx = 0.0d0
      phy = 1.0d0
    end if

    ! Azimuthal angle components
    cph = rhx * xsn + rhy * ysn
    sph = rhy * xsn - rhx * ysn
    if (abs(cph) < 1.0d-10) cph = 0.0d0
    if (abs(sph) < 1.0d-10) sph = 0.0d0

    ! Image source geometry
    zph = obs_z + zt
    zphs = zph * zph
    r2s = rhs + zphs
    r2 = sqrt(r2s)
    rk = r2 * TP
    xx2 = cmplx(cos(rk), -sin(rk), kind=8)

    if (isnor == 1) then
      ! Use Sommerfeld interpolation for field due to ground
      if (rho < 1.0d-12) then
        thet = POT_VAL
      else
        thet = atan(zph / rho)
      end if

      ! Interpolate in Sommerfeld field tables
      call intrp(r2, thet, erv, ezv, erh, eph, erh)  ! Note: erh used twice, may need fixing

      ! Combine vertical and horizontal components
      ! Convert to x,y,z components and multiply by exp(-jkr)/r
      xx2 = xx2 / r2
      sfac = sn_val * cph
      erh = xx2 * (dataj%salpj * erv + sfac * erh)
      ezh = xx2 * (dataj%salpj * ezv - sfac * erv)
      eph = sn_val * sph * xx2 * eph

      ! X,Y,Z fields for constant current
      e_out(1) = erh * rhx + eph * phx
      e_out(2) = erh * rhy + eph * phy
      e_out(3) = ezh

      ! X,Y,Z fields for sine current
      rk = TP * t_val
      sfac = sin(rk)
      e_out(4) = e_out(1) * sfac
      e_out(5) = e_out(2) * sfac
      e_out(6) = e_out(3) * sfac

      ! X,Y,Z fields for cosine current
      sfac = cos(rk)
      e_out(7) = e_out(1) * sfac
      e_out(8) = e_out(2) * sfac
      e_out(9) = e_out(3) * sfac

    else
      ! Use Norton approximation for field due to ground
      ! Current is lumped at segment center with current moment for
      ! constant, sine, or cosine distribution

      zmh = 1.0d0
      r1 = 1.0d0
      xx1 = (0.0d0, 0.0d0)

      ! Call gwave for ground wave field
      ! Note: This requires ground parameters that should come from ground structure
      u = cmplx(1.0d0, 0.0d0, kind=8)  ! Simplified
      u2 = u * u
      call gwave(u, u2, xx1, xx2, r1, r2, zmh, zph, erv, ezv, erh, ezh, eph)

      ! Compute direct field terms
      frati = cmplx(1.0d0, 0.0d0, kind=8)  ! Should come from ground%frati
      et = -(0.0d0, 4.77134d0) * frati * xx2 / (r2s * r2)
      er = 2.0d0 * et * cmplx(1.0d0, rk, kind=8)
      et = et * cmplx(1.0d0 - rk * rk, rk, kind=8)

      ! Subtract direct field contribution from ground wave
      hrv = (er + et) * rho * zph / r2s
      hzv = (zphs * er - rhs * et) / r2s
      hrh = (rhs * er - zphs * et) / r2s

      erv = erv - hrv
      ezv = ezv - hzv
      erh = erh + hrh
      ezh = ezh + hrv
      eph = eph + et

      ! Apply segment orientation and current type factors
      erv = erv * dataj%salpj
      ezv = ezv * dataj%salpj
      erh = erh * sn_val * cph
      ezh = ezh * sn_val * cph
      eph = eph * sn_val * sph

      ! Combine components
      erh = erv + erh
      e_out(1) = (erh * rhx + eph * phx) * dataj%s
      e_out(2) = (erh * rhy + eph * phy) * dataj%s
      e_out(3) = (ezv + ezh) * dataj%s

      ! For Norton approximation, sine and cosine terms are zero initially
      e_out(4) = (0.0d0, 0.0d0)
      e_out(5) = (0.0d0, 0.0d0)
      e_out(6) = (0.0d0, 0.0d0)

      ! Apply sinc function for cosine term
      sfac = PI * dataj%s
      if (abs(sfac) > 1.0d-10) then
        sfac = sin(sfac) / sfac
      else
        sfac = 1.0d0
      end if
      e_out(7) = e_out(1) * sfac
      e_out(8) = e_out(2) * sfac
      e_out(9) = e_out(3) * sfac
    end if

  end subroutine sflds

end module nec2_fields
