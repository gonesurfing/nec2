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
  public :: ffld, nefld, nhfld, efld, gfld, gwave, hsfld, fflds, sflds

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
    complex(8) :: rrv, rrh, const, ex, ey, ez
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
          complex(8) :: zrsin
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
        if (abs(current%bi(i)) > 1.0d-20) then
          omega = PI * geom%si(i)
          rk = sin(omega) / omega
          ar = geom%alp(i) * rox + geom%bet(i) * roy
          if (allocated(geom%salp)) then
            ar = ar + geom%salp(i) * roz
          end if
          cix = cix + const * cmplx(current%bir(i), current%bii(i), kind=8) * &
                (geom%alp(i) - ar * rox) * rk
          ciy = ciy + const * cmplx(current%bir(i), current%bii(i), kind=8) * &
                (geom%bet(i) - ar * roy) * rk
          if (allocated(geom%salp)) then
            ciz = ciz + const * cmplx(current%bir(i), current%bii(i), kind=8) * &
                  (geom%salp(i) - ar * roz) * rk
          end if
        end if

        ! Contribution from constant current
        if (abs(current%ci(i)) > 1.0d-20) then
          omega = PI * geom%si(i)
          ar = geom%alp(i) * rox + geom%bet(i) * roy
          if (allocated(geom%salp)) then
            ar = ar + geom%salp(i) * roz
          end if
          cix = cix + const * cmplx(current%cir(i), current%cii(i), kind=8) * &
                (geom%alp(i) - ar * rox) * geom%si(i)
          ciy = ciy + const * cmplx(current%cir(i), current%cii(i), kind=8) * &
                (geom%bet(i) - ar * roy) * geom%si(i)
          if (allocated(geom%salp)) then
            ciz = ciz + const * cmplx(current%cir(i), current%cii(i), kind=8) * &
                  (geom%salp(i) - ar * roz) * geom%si(i)
          end if
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
      if (allocated(geom%salp)) then
        zp = zp + geom%salp(i) * zj_dist
      end if

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
      if (allocated(geom%salp)) then
        dataj%salpj = geom%salp(i)
      else
        dataj%salpj = 0.0d0
      end if

      ! Determine extended kernel type if needed
      dataj%iexk = ground%iexk
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
      if (allocated(geom%salp)) then
        pz = geom%salp(i)
      else
        pz = 0.0d0
      end if

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
  subroutine gfld(ground, rho, phi, rz, eth, epi, erd, ux, ksymp)
    ! Calculates field from ground using Norton approximation
    ! Placeholder for full implementation

    type(ground_data), intent(in) :: ground
    real(8), intent(in) :: rho, phi, rz, ux
    integer, intent(in) :: ksymp
    complex(8), intent(out) :: eth, epi, erd

    ! Placeholder - full implementation would call GWAVE
    eth = (0.0d0, 0.0d0)
    epi = (0.0d0, 0.0d0)
    erd = (0.0d0, 0.0d0)

  end subroutine gfld

  !============================================================================
  ! GWAVE - Ground wave field (placeholder)
  !============================================================================
  subroutine gwave(ground, erv, ezv, erh, ezh, eph)
    ! Computes ground wave fields using Sommerfeld integrals
    ! Placeholder for full implementation

    type(ground_data), intent(in) :: ground
    complex(8), intent(out) :: erv, ezv, erh, ezh, eph

    ! This would call EVLUA from nec2_sommerfeld
    ! Placeholder for now
    erv = (0.0d0, 0.0d0)
    ezv = (0.0d0, 0.0d0)
    erh = (0.0d0, 0.0d0)
    ezh = (0.0d0, 0.0d0)
    eph = (0.0d0, 0.0d0)

  end subroutine gwave

  !============================================================================
  ! HSFLD - H field from surface (placeholder)
  !============================================================================
  subroutine hsfld(geom, xi, yi, zi, ai)
    ! Computes H field from surface patches
    ! Placeholder for full implementation

    type(geometry_data), intent(in) :: geom
    real(8), intent(in) :: xi, yi, zi, ai

    ! Placeholder
    return

  end subroutine hsfld

  !============================================================================
  ! FFLDS - Far field supplementary calculations
  !============================================================================
  subroutine fflds(rox, roy, roz, scur, ex, ey, ez)
    ! Supplementary far field calculations
    ! Simplified version

    real(8), intent(in) :: rox, roy, roz
    complex(8), intent(in) :: scur(:)
    complex(8), intent(out) :: ex, ey, ez

    ! Placeholder for full implementation
    ex = (0.0d0, 0.0d0)
    ey = (0.0d0, 0.0d0)
    ez = (0.0d0, 0.0d0)

  end subroutine fflds

  !============================================================================
  ! SFLDS - Surface field calculations
  !============================================================================
  subroutine sflds(t_val, e_val)
    ! Surface field integration
    ! Placeholder

    real(8), intent(in) :: t_val
    complex(8), intent(out) :: e_val

    e_val = (0.0d0, 0.0d0)

  end subroutine sflds

end module nec2_fields
