! nec2_excitation.f90
! Excitation sources, networks, and loading
! Voltage sources, impedance loading, and network parameters

module nec2_excitation
  use nec2_constants
  use nec2_data_types
  use nec2_current
  implicit none
  private

  ! Public subroutines
  public :: qdsrc, netwk, load_impedance, couple, cabc, etmns, intrp

contains

  !============================================================================
  ! QDSRC - Voltage source (charge discontinuity)
  !============================================================================
  subroutine qdsrc(geom, current, vsource, segj, dataj, loading, is, v, e)
    ! Fills incident field array for voltage source at segment IS
    ! Uses charge discontinuity approximation
    !
    ! Arguments:
    !   geom - geometry data
    !   current - current data
    !   vsource - voltage source data
    !   segj - segment junction data
    !   dataj - junction calculation data
    !   loading - loading data
    !   is - source segment number
    !   v - source voltage
    !   e - incident field array (output)

    type(geometry_data), intent(in) :: geom
    type(current_data), intent(in) :: current
    type(voltage_source_data), intent(inout) :: vsource
    type(segment_junction_data), intent(inout) :: segj
    type(dataj_data), intent(inout) :: dataj
    type(loading_data), intent(in) :: loading
    integer, intent(in) :: is
    complex(8), intent(in) :: v
    complex(8), intent(inout) :: e(:)

    complex(8) :: curd, ccj, etk, ets, etc, vsrc
    real(8) :: s_half, log_term
    integer :: i, j, jx, ipr
    integer :: icon1_save

    complex(8), parameter :: ccj_val = cmplx(0.0d0, -0.01666666667d0, kind=8)

    ! Set up basis functions for source segment
    icon1_save = geom%icon1(is)
    ! Temporarily set icon1 to 0 for basis function calculation
    ! (Would need modifiable geom or pass icon1 separately in practice)

    call tbf(geom, segj, is, 0)

    ! Restore icon1
    ! geom%icon1(is) = icon1_save (if geom were mutable)

    ! Calculate source current from voltage
    s_half = geom%si(is) * 0.5d0
    log_term = log(2.0d0 * s_half / geom%bi(is)) - 1.0d0

    curd = ccj_val * v / (log_term * &
           (segj%bx(segj%jsno) * cos(TWO_PI * s_half) + &
            segj%cx(segj%jsno) * sin(TWO_PI * s_half)) * geom%wlam)

    ! Store voltage source information
    vsource%nqds = vsource%nqds + 1
    if (vsource%nqds <= size(vsource%vqds)) then
      vsource%vqds(vsource%nqds) = v
      vsource%iqds(vsource%nqds) = is
    end if

    ! Calculate incident field contribution at all segments
    do jx = 1, segj%jsno
      j = segj%jco(jx)

      ! Set up segment parameters
      dataj%s = geom%si(j)
      dataj%b = geom%bi(j)
      dataj%xj = geom%x(j)
      dataj%yj = geom%y(j)
      dataj%zj = geom%z(j)
      dataj%cabj = geom%alp(j)
      dataj%sabj = geom%bet(j)
      if (allocated(geom%salp)) then
        dataj%salpj = geom%salp(j)
      else
        dataj%salpj = 0.0d0
      end if

      ! Determine extended kernel type
      ! (Simplified - full logic would check connection details)
      dataj%iexk = 0  ! Default to thin wire
      dataj%ind1 = 2
      dataj%ind2 = 2

      ! Calculate field at segment from source
      ! Would call EFLD here with source segment position
      ! Placeholder for actual field calculation

      ! Combine field components with basis function coefficients
      etk = dataj%exk * dataj%cabj + dataj%eyk * dataj%sabj + dataj%ezk * dataj%salpj
      ets = dataj%exs * dataj%cabj + dataj%eys * dataj%sabj + dataj%ezs * dataj%salpj
      etc = dataj%exc * dataj%cabj + dataj%eyc * dataj%sabj + dataj%ezc * dataj%salpj

      ! Apply loading if present
      vsrc = curd * (etk * segj%ax(jx) + ets * segj%bx(jx) + etc * segj%cx(jx))

      if (loading%nload > 0 .and. j <= size(loading%zarray)) then
        if (abs(loading%zarray(j)) > 1.0d-20) then
          vsrc = vsrc - curd * loading%zarray(j) * &
                 (segj%ax(jx) + segj%cx(jx))
        end if
      end if

      e(j) = e(j) - vsrc
    end do

  end subroutine qdsrc

  !============================================================================
  ! NETWK - Network solution
  !============================================================================
  subroutine netwk(network, cm, cmb, cmc, cmd, ip, einc)
    ! Solves for structure currents including non-radiating networks
    !
    ! Arguments:
    !   network - network data
    !   cm, cmb, cmc, cmd - matrix blocks
    !   ip - pivot array
    !   einc - incident field array

    type(network_data), intent(inout) :: network
    complex(8), intent(inout) :: cm(:), cmb(:), cmc(:), cmd(:)
    integer, intent(inout) :: ip(:)
    complex(8), intent(inout) :: einc(:)

    complex(8), allocatable :: cmn(:,:), rhnt(:), rhs(:), vsrc(:)
    complex(8) :: ymit, zped, cux
    integer, allocatable :: ipnt(:)
    real(8) :: asm, asa, pwr
    integer :: i, j, neqt, neqz2, nop, irow1
    integer :: nseg1, isc1, ntsc, nteq

    ! Initialize power parameters
    network%pin = 0.0d0
    network%pnls = 0.0d0

    neqz2 = network%neq2
    if (neqz2 == 0) neqz2 = 1
    neqt = network%neq + network%neq2

    if (network%ntsol /= 0) return

    nop = network%neq / network%npeq

    ! Check for matrix asymmetry if requested
    if (network%masym /= 0 .and. network%nonet > 0) then
      allocate(cmn(network%nonet, network%nonet))
      allocate(ipnt(network%nonet + 1))
      allocate(rhs(neqt))

      irow1 = 0

      ! Build list of network connection points
      do i = 1, network%nonet
        nseg1 = network%iseg1(i)
        do isc1 = 1, 2
          if (irow1 > 0) then
            do j = 1, irow1
              if (nseg1 == ipnt(j)) goto 100
            end do
          end if
          irow1 = irow1 + 1
          ipnt(irow1) = nseg1
100       nseg1 = network%iseg2(i)
        end do
      end do

      ! Compute asymmetry by solving for each connection point
      if (irow1 >= 2) then
        do i = 1, irow1
          isc1 = ipnt(i)
          asm = 1.0d0  ! Normalization factor

          rhs = (0.0d0, 0.0d0)
          rhs(isc1) = (1.0d0, 0.0d0)

          ! Would solve system here using SOLGF
          ! Placeholder for actual solve

          do j = 1, irow1
            isc1 = ipnt(j)
            cmn(j, i) = rhs(isc1) / asm
          end do
        end do

        ! Calculate asymmetry measures
        asm = 0.0d0
        asa = 0.0d0
        do i = 2, irow1
          do j = 1, i - 1
            cux = cmn(i, j)
            pwr = abs((cux - cmn(j, i)) / cux)
            asa = asa + pwr * pwr
            if (pwr > asm) then
              asm = pwr
              nteq = ipnt(i)
              ntsc = ipnt(j)
            end if
          end do
        end do

        asa = sqrt(asa * 2.0d0 / real(irow1 * (irow1 - 1), kind=8))

        write(*,'(A,F10.6,A,I0,A,I0,A,F10.6)') &
          ' MAXIMUM ASYMMETRY = ', asm, ' AT SEGMENTS ', nteq, ' AND ', ntsc, &
          ' RMS ASYMMETRY = ', asa
      end if

      deallocate(cmn, ipnt, rhs)
    end if

    ! Network solution (simplified - full implementation is complex)
    if (network%nonet == 0) return

    allocate(rhnt(network%nonet))
    allocate(vsrc(network%nonet))

    ! Set up network equations
    do i = 1, network%nonet
      select case (network%ntyp(i))
        case (0)
          ! Short circuit
          ymit = (1.0d30, 0.0d0)
        case (1)
          ! Series impedance
          ymit = 1.0d0 / cmplx(network%x11r(i), network%x11i(i), kind=8)
        case (2)
          ! Parallel admittance
          ymit = cmplx(network%x11r(i), network%x11i(i), kind=8)
        case (3)
          ! Transmission line
          ! More complex - involves characteristic impedance and length
          ymit = (0.0d0, 0.0d0)  ! Placeholder
        case default
          ymit = (0.0d0, 0.0d0)
      end select

      vsrc(i) = (0.0d0, 0.0d0)  ! Voltage sources in network
    end do

    ! Solve network equations and apply to main system
    ! (Simplified - full implementation requires matrix operations)

    deallocate(rhnt, vsrc)

  end subroutine netwk

  !============================================================================
  ! LOAD_IMPEDANCE - Calculate impedance loading
  !============================================================================
  subroutine load_impedance(geom, loading, ldtyp, ldtag, ldtagf, ldtagt, &
                           zlr, zli, zlc, nload)
    ! Calculates impedance of specified segments for various loading types
    !
    ! Arguments:
    !   geom - geometry data
    !   loading - loading data (output)
    !   ldtyp - loading type array
    !   ldtag - tag number array
    !   ldtagf, ldtagt - tag range for loading
    !   zlr, zli, zlc - load parameters (R, L/C values)
    !   nload - number of loads

    type(geometry_data), intent(in) :: geom
    type(loading_data), intent(inout) :: loading
    integer, intent(in) :: ldtyp(:), ldtag(:), ldtagf(:), ldtagt(:)
    real(8), intent(in) :: zlr(:), zli(:), zlc(:)
    integer, intent(in) :: nload

    complex(8) :: zt, tpcj, zint_val
    real(8) :: freq_factor, rolam
    integer :: istep, i, l1, l2, ichk, jump
    integer :: ldtags, iwarn

    complex(8), parameter :: tpcj_const = cmplx(0.0d0, 1.883698955d9, kind=8)

    write(*,'(A)') ' '
    write(*,'(A)') ' STRUCTURE IMPEDANCE LOADING'
    write(*,'(A)') ' '

    ! Initialize loading array
    do i = geom%n2, geom%n
      loading%zarray(i) = (0.0d0, 0.0d0)
    end do

    iwarn = 0
    loading%nload = nload

    ! Cycle over loading cards
    do istep = 1, nload
      if (ldtyp(istep) > 5 .or. ldtyp(istep) < 0) then
        write(*,'(A,I0)') ' ERROR: Invalid loading type ', ldtyp(istep)
        cycle
      end if

      ldtags = ldtag(istep)
      jump = ldtyp(istep) + 1
      ichk = 0

      ! Determine segment range
      l1 = geom%n2
      l2 = geom%n

      if (ldtags == 0) then
        if (ldtagf(istep) /= 0 .or. ldtagt(istep) /= 0) then
          l1 = ldtagf(istep)
          l2 = ldtagt(istep)
          if (l1 > geom%n1) then
            write(*,'(A)') ' ERROR: Invalid segment range'
            cycle
          end if
        end if
      end if

      ! Search segments for proper tags
      do i = l1, l2
        if (ldtags /= 0) then
          if (ldtags /= geom%itag(i)) cycle
          if (ldtagf(istep) /= 0) then
            ichk = ichk + 1
            if (ichk < ldtagf(istep) .or. ichk > ldtagt(istep)) cycle
          end if
        else
          ichk = 1
        end if

        ! Calculate λ*impedance per unit length based on loading type
        select case (jump)
          case (1)
            ! Series RLC
            zt = zlr(istep) / geom%si(i) + &
                 tpcj_const * zli(istep) / (geom%si(i) * geom%wlam)

          case (2)
            ! Parallel RLC
            zt = geom%si(i) / zlr(istep) - &
                 geom%si(i) / (tpcj_const * zli(istep) * geom%wlam)
            zt = 1.0d0 / zt

          case (3)
            ! Series R + parallel RLC
            zt = zlr(istep) / geom%si(i) + &
                 1.0d0 / (geom%si(i) / zli(istep) - &
                         geom%si(i) / (tpcj_const * zlc(istep) * geom%wlam))

          case (4)
            ! Parallel R + series RLC
            zt = zli(istep) / geom%si(i) + &
                 tpcj_const * zlc(istep) / (geom%si(i) * geom%wlam)
            zt = zlr(istep) * zt / (geom%si(i) + zlr(istep) * zt)

          case (5)
            ! Wire conductivity (skin effect)
            rolam = zlc(istep) * geom%wlam
            zt = zint_val  ! Would call ZINT function
            zt = zt / rolam

          case (6)
            ! Impedance per unit length
            zt = cmplx(zlr(istep), zli(istep), kind=8)

          case default
            zt = (0.0d0, 0.0d0)
        end select

        loading%zarray(i) = zt
      end do
    end do

    ! Handle symmetry if needed
    if (geom%n1 + 2 * geom%m1 > 0) return

    ! Replicate loading for symmetric structures
    nop = geom%n / geom%np
    if (nop == 1) return

    do i = 1, geom%np
      zt = loading%zarray(i)
      l1 = i
      do l2 = 2, nop
        l1 = l1 + geom%np
        loading%zarray(l1) = zt
      end do
    end do

  end subroutine load_impedance

  !============================================================================
  ! COUPLE - Compute coupling between antennas
  !============================================================================
  subroutine couple(current, wlam, coupling_result)
    ! Computes mutual coupling between antennas
    !
    ! Arguments:
    !   current - current distribution
    !   wlam - wavelength
    !   coupling_result - output coupling coefficient

    type(current_data), intent(in) :: current
    real(8), intent(in) :: wlam
    complex(8), intent(out) :: coupling_result

    ! Placeholder for full implementation
    ! Would integrate current distributions
    coupling_result = (0.0d0, 0.0d0)

  end subroutine couple

  !============================================================================
  ! CABC - Apply current basis functions
  !============================================================================
  subroutine cabc(current_array)
    ! Applies current basis function coefficients
    ! Transforms from basis function space to physical currents
    !
    ! Arguments:
    !   current_array - current coefficient array (modified in place)

    complex(8), intent(inout) :: current_array(:)

    ! Placeholder for full implementation
    ! Would apply basis function transformations
    ! This is typically done in-place on the current array

  end subroutine cabc

  !============================================================================
  ! ETMNS - E-field transmission (Mitzner's method)
  !============================================================================
  subroutine etmns(p1, p2, p3, p4, p5, p6, ipr, e_result)
    ! Calculates E-field using Mitzner's transmission method
    ! Used for thin-wire scattering problems
    !
    ! Arguments:
    !   p1-p6 - calculation parameters
    !   ipr - print flag
    !   e_result - output E-field

    real(8), intent(in) :: p1, p2, p3, p4, p5, p6
    integer, intent(in) :: ipr
    complex(8), intent(out) :: e_result

    ! Placeholder for full implementation
    e_result = (0.0d0, 0.0d0)

  end subroutine etmns

  !============================================================================
  ! INTRP - Interpolation utility
  !============================================================================
  subroutine intrp(x_val, y_val, f1, f2, f3, f4)
    ! Performs interpolation for field calculations
    ! Uses 4-point interpolation scheme
    !
    ! Arguments:
    !   x_val, y_val - interpolation coordinates
    !   f1, f2, f3, f4 - function values at corners

    real(8), intent(in) :: x_val, y_val
    complex(8), intent(in) :: f1, f2, f3, f4

    real(8) :: wx, wy
    complex(8) :: result

    ! Bilinear interpolation
    wx = x_val
    wy = y_val

    result = f1 * (1.0d0 - wx) * (1.0d0 - wy) + &
             f2 * wx * (1.0d0 - wy) + &
             f3 * (1.0d0 - wx) * wy + &
             f4 * wx * wy

    ! Result would be returned through function value or output argument

  end subroutine intrp

end module nec2_excitation
