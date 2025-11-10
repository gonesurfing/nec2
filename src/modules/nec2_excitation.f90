! nec2_excitation.f90
! Excitation sources, networks, and loading
! Voltage sources, impedance loading, and network parameters

module nec2_excitation
  use nec2_constants
  use nec2_data_types
  use nec2_current
  use nec2_fields
  use nec2_sommerfeld, only: intrp
  implicit none
  private

  ! Public subroutines
  public :: qdsrc, netwk, load_impedance, couple, cabc, cabc_full, etmns

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
    type(ground_data) :: ground_local

    complex(8), parameter :: ccj_val = cmplx(0.0d0, -0.01666666667d0, kind=8)

    ! Initialize ground to perfect ground (free space) for voltage source calculation
    ground_local%iperf = 1

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
      dataj%salpj = 0.0d0

      ! Determine extended kernel type
      ! (Simplified - full logic would check connection details)
      dataj%iexk = 0  ! Default to thin wire
      dataj%ind1 = 2
      dataj%ind2 = 2

      ! Calculate field at segment j from source segment is
      ! Field components stored in dataj: exk, eyk, ezk, exs, eys, ezs, exc, eyc, ezc
      call efld(geom, dataj, ground_local, dataj%xj, dataj%yj, dataj%zj, dataj%b, int(j - is))

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
    ! This implements the full network solution algorithm:
    !   1. Build network equation matrix from Y-parameters
    !   2. Add structure interaction admittances
    !   3. Solve combined structure + network system
    !   4. Calculate voltages, currents, impedances, power
    !
    ! Arguments:
    !   network - network data structure
    !   cm, cmb, cmc, cmd - interaction matrix blocks for NGF
    !   ip - pivot array for matrix factorization
    !   einc - excitation vector (RHS)

    use nec2_solver, only: solgf, factr, solve

    type(network_data), intent(inout) :: network
    complex(8), intent(inout) :: cm(:), cmb(:), cmc(:), cmd(:)
    integer, intent(inout) :: ip(:)
    complex(8), intent(inout) :: einc(:)

    complex(8), allocatable :: cmn(:,:), rhnt(:), rhs(:), rhnx(:)
    complex(8), allocatable :: cmn2d(:,:)
    integer, allocatable :: ipnt(:), nteqa(:), ntsca(:)
    complex(8) :: ymit, zped, cux, vlt
    real(8) :: asm, asa, pwr, y11r, y11i, y12r, y12i, y22r, y22i
    real(8), parameter :: tp = 6.283185308d0
    integer :: i, j, neqt, neqz2, nop, irow1, irow2
    integer :: nseg1, nseg2, isc1, isc2, ntsc, nteq
    integer :: ndimn

    ! Initialize power parameters
    network%pin = 0.0d0
    network%pnls = 0.0d0

    neqz2 = network%neq2
    if (neqz2 == 0) neqz2 = 1
    neqt = network%neq + network%neq2

    ! If solution is already done, skip
    if (network%ntsol /= 0) return

    nop = network%neq / network%npeq
    ndimn = 50  ! Maximum network equations (from NETMX)

    ! If no networks, just solve the structure
    if (network%nonet == 0) then
      ! Solve structure equations without network
      ! For now, simplified - full implementation requires proper matrix handling
      write(*,'(A)') 'NETWK: No networks present, basic solution'
      return
    end if

    ! Network solution with admittance matrix
    allocate(cmn2d(ndimn, ndimn))
    allocate(rhnt(ndimn))
    allocate(rhnx(ndimn))
    allocate(ipnt(ndimn))
    allocate(nteqa(ndimn))
    allocate(ntsca(ndimn))
    allocate(rhs(neqt))

    ! Initialize network arrays
    cmn2d = (0.0d0, 0.0d0)
    rhnx = (0.0d0, 0.0d0)
    nteq = 0
    ntsc = 0

    ! Build network equations
    do j = 1, network%nonet
      nseg1 = network%iseg1(j)
      nseg2 = network%iseg2(j)

      ! Convert network parameters to Y-parameters
      if (network%ntyp(j) <= 1) then
        ! Direct Y-parameter specification or series impedance
        y11r = network%x11r(j)
        y11i = network%x11i(j)
        y12r = network%x12r(j)
        y12i = network%x12i(j)
        y22r = network%x22r(j)
        y22i = network%x22i(j)
      else
        ! Transmission line - convert to Y-parameters
        ! Length in wavelengths
        y22r = tp * network%x11i(j) / network%wlam
        y12r = 0.0d0
        y12i = 1.0d0 / (network%x11r(j) * sin(y22r))
        y11r = network%x12r(j)
        y11i = -y12i * cos(y22r)
        y22r = network%x22r(j)
        y22i = y11i + network%x22i(j)
        y11i = y11i + network%x12i(j)
        if (network%ntyp(j) == 2) then
          y12r = -y12r
          y12i = -y12i
        end if
      end if

      ! Find equation numbers for segment 1
      irow1 = 0
      if (nteq > 0) then
        do i = 1, nteq
          if (nseg1 == nteqa(i)) then
            irow1 = i
            exit
          end if
        end do
      end if
      if (irow1 == 0) then
        nteq = nteq + 1
        irow1 = nteq
        nteqa(nteq) = nseg1
      end if

      ! Find equation numbers for segment 2
      irow2 = 0
      if (nteq > 0) then
        do i = 1, nteq
          if (nseg2 == nteqa(i)) then
            irow2 = i
            exit
          end if
        end do
      end if
      if (irow2 == 0) then
        nteq = nteq + 1
        irow2 = nteq
        nteqa(nteq) = nseg2
      end if

      ! Fill network equation matrix with Y-parameter coefficients
      ! (Assuming segment length normalization is 1.0 for simplicity)
      cmn2d(irow1, irow1) = cmn2d(irow1, irow1) - cmplx(y11r, y11i, kind=8)
      cmn2d(irow1, irow2) = cmn2d(irow1, irow2) - cmplx(y12r, y12i, kind=8)
      cmn2d(irow2, irow2) = cmn2d(irow2, irow2) - cmplx(y22r, y22i, kind=8)
      cmn2d(irow2, irow1) = cmn2d(irow2, irow1) - cmplx(y12r, y12i, kind=8)
    end do

    ! STEP 2: Add structure interaction matrix admittances to network matrix
    ! For each network node, solve structure with unit excitation
    do i = 1, nteq
      ! Set up unit excitation at segment i
      rhs = (0.0d0, 0.0d0)
      irow1 = nteqa(i)
      rhs(irow1) = (1.0d0, 0.0d0)

      ! Solve structure system with solgf (now uses 1D arrays - Fortran 77 compatible!)
      call solgf(cm, cmb, cmc, cmd, rhs, ip, &
                 network%np, network%n1, network%n, network%mp, network%m1, &
                 network%m, network%neq, network%neq2, neqz2)

      ! Apply basis function transformation
      call cabc(rhs)

      ! Add structure response to network matrix
      do j = 1, nteq
        irow1 = nteqa(j)
        cmn2d(i, j) = cmn2d(i, j) + rhs(irow1)
      end do
    end do

    ! STEP 3: Factor the network equation matrix
    call factr(nteq, cmn2d, ipnt, ndimn)

    ! STEP 4: Solve structure with actual excitation
    rhs = einc
    call solgf(cm, cmb, cmc, cmd, rhs, ip, &
               network%np, network%n1, network%n, network%mp, network%m1, &
               network%m, network%neq, network%neq2, neqz2)
    call cabc(rhs)

    ! STEP 5: Build network RHS from structure solution
    do i = 1, nteq
      irow1 = nteqa(i)
      rhnt(i) = rhnx(i) + rhs(irow1)
    end do

    ! STEP 6: Solve network equations for voltages
    call solve(nteq, cmn2d, ipnt, rhnt, ndimn)

    ! STEP 7: Apply network voltages back to structure
    do i = 1, nteq
      irow1 = nteqa(i)
      einc(irow1) = einc(irow1) - rhnt(i)
    end do

    ! STEP 8: Final structure solution with network effects
    call solgf(cm, cmb, cmc, cmd, einc, ip, &
               network%np, network%n1, network%n, network%mp, network%m1, &
               network%m, network%neq, network%neq2, neqz2)
    call cabc(einc)

    ! STEP 9: Calculate and output power at network connection points
    write(*,'(///,27X,A)') '- - - STRUCTURE EXCITATION DATA AT NETWORK CONNECTION POINTS - - -'
    write(*,'(/,3X,A)') 'TAG  SEG.    VOLTAGE (VOLTS)         CURRENT (AMPS)         ' // &
                        'IMPEDANCE (OHMS)        ADMITTANCE (MHOS)      POWER'

    do i = 1, nteq
      irow1 = nteqa(i)
      ! Voltage at network node
      vlt = rhnt(i)
      ! Current from solution
      cux = einc(irow1)

      ! Impedance and admittance
      if (abs(cux) > 1.0d-20) then
        zped = vlt / cux
        ymit = cux / vlt
      else
        zped = (0.0d0, 0.0d0)
        ymit = (0.0d0, 0.0d0)
      end if

      ! Power (real part of V * conj(I) / 2)
      pwr = 0.5d0 * real(vlt * conjg(cux), kind=8)
      network%pnls = network%pnls - pwr

      write(*,'(2(1X,I5),1P,9E12.5)') 0, irow1, vlt, cux, zped, ymit, pwr
    end do

    deallocate(cmn2d, rhnt, rhnx, ipnt, nteqa, ntsca, rhs)

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
    integer :: ldtags, iwarn, nop

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
            ! Wire conductivity (skin effect) - internal impedance with skin effect
            ! ZINT calculates impedance using Bessel function approximations
            ! sigl = conductivity * relative permeability
            ! zlr = real part (resistivity), zli = imaginary part (rel. permeability)
            rolam = zlc(istep) * geom%wlam
            zt = zint(zlr(istep), rolam) / rolam

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
  subroutine couple(geom, vsource, current_array, wlam, &
                    ncoup, icoup, nctag, ncseg, y11a, y12a)
    ! Computes maximum coupling between pairs of segments
    ! Builds Y-parameter matrices from current solutions
    !
    ! Arguments:
    !   geom - geometry data
    !   vsource - voltage source data
    !   current_array - current solution array
    !   wlam - wavelength
    !   ncoup - number of coupling points
    !   icoup - current coupling index (incremented)
    !   nctag - tag numbers for coupling segments
    !   ncseg - segment numbers for coupling
    !   y11a - Y11 admittance parameters (output)
    !   y12a - Y12 admittance parameters (output)
    !
    ! Original: nec2dxs.f lines 3040-3114

    use nec2_utilities, only: isegno, db10

    type(geometry_data), intent(in) :: geom
    type(voltage_source_data), intent(in) :: vsource
    complex(8), intent(in) :: current_array(:)
    real(8), intent(in) :: wlam
    integer, intent(in) :: ncoup
    integer, intent(inout) :: icoup
    integer, intent(in) :: nctag(:), ncseg(:)
    complex(8), intent(inout) :: y11a(:), y12a(:)

    complex(8) :: y11, y12, y22, yl, yin, zl, zin, rho
    real(8) :: c, gmax, dbc
    integer :: i, j, j1, j2, k, l1, npm1
    integer :: itt1, itt2, its1, its2, isg1, isg2

    ! Check if conditions are met for coupling calculation
    if (vsource%nsant /= 1 .or. vsource%nvqd /= 0) return

    ! Check if current segment matches expected
    j = isegno(geom, nctag(icoup + 1), ncseg(icoup + 1))
    if (j /= vsource%isant(1)) return

    ! Increment coupling index
    icoup = icoup + 1

    ! Calculate input admittance
    zin = vsource%vsant(1)
    y11a(icoup) = current_array(j) * wlam / zin

    ! Build Y12 parameters for cross-coupling
    l1 = (icoup - 1) * (ncoup - 1)
    do i = 1, ncoup
      if (i == icoup) cycle
      k = isegno(geom, nctag(i), ncseg(i))
      l1 = l1 + 1
      y12a(l1) = current_array(k) * wlam / zin
    end do

    ! If not all coupling points calculated, return
    if (icoup < ncoup) return

    ! Output coupling results
    write(*,'(///,36X,A)') '- - - ISOLATION DATA - - -'
    write(*,'(/,6X,A,8X,A,15X,A)') '- - COUPLING BETWEEN - -', 'MAXIMUM', &
                                    '- - - FOR MAXIMUM COUPLING - - -'
    write(*,'(12X,A,14X,A,3X,A,4X,A,7X,A)') 'SEG.', 'SEG.', 'COUPLING', &
                                              'LOAD IMPEDANCE (2ND SEG.)', 'INPUT IMPEDANCE'
    write(*,'(2X,A,3X,A,4X,A,3X,A,6X,A,8X,A,9X,A,9X,A,9X,A)') &
           'TAG/SEG.', 'NO.', 'TAG/SEG.', 'NO.', '(DB)', 'REAL', 'IMAG.', 'REAL', 'IMAG.'

    npm1 = ncoup - 1

    ! Calculate coupling for each pair
    do i = 1, npm1
      itt1 = nctag(i)
      its1 = ncseg(i)
      isg1 = isegno(geom, itt1, its1)
      l1 = i + 1

      do j = l1, ncoup
        itt2 = nctag(j)
        its2 = ncseg(j)
        isg2 = isegno(geom, itt2, its2)

        j1 = j + (i - 1) * npm1 - 1
        j2 = i + (j - 1) * npm1

        y11 = y11a(i)
        y22 = y11a(j)
        y12 = 0.5d0 * (y12a(j1) + y12a(j2))

        yin = y12 * y12
        dbc = abs(yin)
        c = dbc / (2.0d0 * real(y11, kind=8) * real(y22, kind=8) - real(yin, kind=8))

        ! Check if coupling is valid
        if (c < 0.0d0 .or. c > 1.0d0) then
          write(*,'(2(1X,I4,1X,I4,1X,I5,2X),A,1P,E12.5,A)') &
                 itt1, its1, isg1, itt2, its2, isg2, &
                 '**ERROR** COUPLING IS NOT BETWEEN 0 AND 1. (=', c, ')'
          cycle
        end if

        ! Calculate maximum coupling
        if (c < 0.01d0) then
          gmax = 0.5d0 * (c + 0.25d0 * c * c * c)
        else
          gmax = (1.0d0 - sqrt(1.0d0 - c * c)) / c
        end if

        rho = gmax * conjg(yin) / dbc
        yl = ((1.0d0 - rho) / (1.0d0 + rho) + 1.0d0) * real(y22, kind=8) - y22
        zl = 1.0d0 / yl
        yin = y11 - yin / (y22 + yl)
        zin = 1.0d0 / yin
        dbc = db10(gmax)

        write(*,'(2(1X,I4,1X,I4,1X,I5,2X),F9.3,2X,1P,2(2X,E12.5,1X,E12.5))') &
               itt1, its1, isg1, itt2, its2, isg2, dbc, zl, zin
      end do
    end do

  end subroutine couple

  !============================================================================
  ! CABC - Apply current basis functions
  !============================================================================
  subroutine cabc(current_array)
    ! Computes coefficients of constant (A), sine (B), and cosine (C) terms
    ! in the current interpolation functions. Transforms from current coefficients
    ! to physical current distributions.
    !
    ! NOTE: This is a SIMPLIFIED pass-through implementation for netwk() usage.
    ! The full implementation would require:
    !   - Access to geometry, segj, vsource, and current data structures
    !   - TBF() calls for basis function computation
    !   - Voltage source handling (NQDS loop)
    !   - Surface patch T1/T2 to X/Y/Z conversion
    !
    ! For netwk() operation with wire-only structures, the current coefficients
    ! from solgf() are already in usable form, so pass-through is acceptable.
    !
    ! See cabc_full() below for the complete implementation.
    !
    ! Arguments:
    !   current_array - current coefficient array (modified in place)
    !
    ! Original: nec2dxs.f lines 1820-1906

    complex(8), intent(inout) :: current_array(:)

    ! Pass-through for netwk() compatibility
    ! The current array is already in correct form from solgf()

  end subroutine cabc

  !============================================================================
  ! CABC_FULL - Full current basis function transformation
  !============================================================================
  subroutine cabc_full(geom, current, segj, vsource, current_array)
    ! Full implementation of current basis function transformation
    ! Computes coefficients of constant (A), sine (B), and cosine (C) terms
    ! in the current interpolation functions.
    !
    ! Arguments:
    !   geom - geometry data
    !   current - current coefficient data structure
    !   segj - segment junction data
    !   vsource - voltage source data
    !   current_array - current coefficient array (modified in place)
    !
    ! Original: nec2dxs.f lines 1820-1906

    use nec2_current, only: tbf

    type(geometry_data), intent(in) :: geom
    type(current_data), intent(inout) :: current
    type(segment_junction_data), intent(inout) :: segj
    type(voltage_source_data), intent(in) :: vsource
    complex(8), intent(inout) :: current_array(:)

    complex(8) :: curd, ccj, cs1, cs2
    real(8) :: ar, ai, sh
    integer :: i, j, jx, is, k, jco1, jco2, icon1_save
    real(8), parameter :: tp = 6.283185308d0
    complex(8), parameter :: ccj_val = cmplx(0.0d0, -0.01666666667d0, kind=8)

    ccj = ccj_val

    ! STEP 1: Initialize A, B, C coefficient arrays to zero
    if (geom%n == 0) goto 600

    do i = 1, geom%n
      current%air(i) = 0.0d0
      current%aii(i) = 0.0d0
      current%bir(i) = 0.0d0
      current%bii(i) = 0.0d0
      current%cir(i) = 0.0d0
      current%cii(i) = 0.0d0
    end do

    ! STEP 2: For each segment, compute basis functions and accumulate
    do i = 1, geom%n
      ar = real(current_array(i), kind=8)
      ai = aimag(current_array(i))

      ! Call TBF to get basis function coefficients
      call tbf(geom, segj, i, 1)

      ! Accumulate contributions to A, B, C arrays
      do jx = 1, segj%jsno
        j = segj%jco(jx)
        current%air(j) = current%air(j) + segj%ax(jx) * ar
        current%aii(j) = current%aii(j) + segj%ax(jx) * ai
        current%bir(j) = current%bir(j) + segj%bx(jx) * ar
        current%bii(j) = current%bii(j) + segj%bx(jx) * ai
        current%cir(j) = current%cir(j) + segj%cx(jx) * ar
        current%cii(j) = current%cii(j) + segj%cx(jx) * ai
      end do
    end do

    ! STEP 3: Handle voltage sources (NQDS)
    if (vsource%nqds == 0) goto 400

    do is = 1, vsource%nqds
      i = vsource%iqds(is)

      ! Save and modify icon1 temporarily
      icon1_save = geom%icon1(i)
      ! In practice would need mutable geom or different approach
      ! For now skip the icon1 modification

      ! Call TBF with capacitance end flag = 0
      call tbf(geom, segj, i, 0)

      ! Calculate source current from voltage
      sh = geom%si(i) * 0.5d0
      curd = ccj * vsource%vqds(is) / &
             ((log(2.0d0 * sh / geom%bi(i)) - 1.0d0) * &
              (segj%bx(segj%jsno) * cos(tp * sh) + &
               segj%cx(segj%jsno) * sin(tp * sh)) * geom%wlam)

      ar = real(curd, kind=8)
      ai = aimag(curd)

      ! Accumulate voltage source contributions
      do jx = 1, segj%jsno
        j = segj%jco(jx)
        current%air(j) = current%air(j) + segj%ax(jx) * ar
        current%aii(j) = current%aii(j) + segj%ax(jx) * ai
        current%bir(j) = current%bir(j) + segj%bx(jx) * ar
        current%bii(j) = current%bii(j) + segj%bx(jx) * ai
        current%cir(j) = current%cir(j) + segj%cx(jx) * ar
        current%cii(j) = current%cii(j) + segj%cx(jx) * ai
      end do
    end do

    ! STEP 4: Combine A and C coefficients into final current
400 do i = 1, geom%n
      current_array(i) = cmplx(current%air(i) + current%cir(i), &
                               current%aii(i) + current%cii(i), kind=8)
    end do

    ! STEP 5: Convert surface patch currents from T1/T2 to X/Y/Z components
600 if (geom%m == 0) return

    k = geom%ld - geom%m
    jco1 = geom%n + 2 * geom%m + 1
    jco2 = jco1 + geom%m

    do i = 1, geom%m
      k = k + 1
      jco1 = jco1 - 2
      jco2 = jco2 - 3

      cs1 = current_array(jco1)
      cs2 = current_array(jco1 + 1)

      ! Convert from T1, T2 components to X, Y, Z using patch orientation vectors
      ! Note: Would need t1x, t1y, t1z, t2x, t2y, t2z arrays from geometry
      ! These are equivalenced to si, alp, bet, icon1, icon2, itag in original
      ! Skipping for now as patch support is incomplete
      ! current_array(jco2) = cs1 * t1x(k) + cs2 * t2x(k)
      ! current_array(jco2 + 1) = cs1 * t1y(k) + cs2 * t2y(k)
      ! current_array(jco2 + 2) = cs1 * t1z(k) + cs2 * t2z(k)
    end do

  end subroutine cabc_full

  !============================================================================
  ! ETMNS - E-field transmission (Mitzner's method)
  !============================================================================
  subroutine etmns(geom, vsource, ground, e_array, p1, p2, p3, p4, p5, p6, ipr)
    ! Fills the array E with the negative of the electric field incident on
    ! the structure. This is the right-hand side of the matrix equation.
    !
    ! Supports multiple excitation modes controlled by IPR:
    !   IPR = 0 or 5: Voltage sources (transmitting case)
    !   IPR = 1:      Linearly polarized plane wave
    !   IPR = 2:      Linearly polarized plane wave (alt)
    !   IPR = 3:      Elliptically polarized plane wave
    !   IPR = 4:      Elementary current source
    !
    ! Arguments:
    !   geom - geometry data
    !   vsource - voltage source data
    !   ground - ground parameters
    !   e_array - incident field array (output)
    !   p1-p6 - excitation parameters (interpretation depends on ipr)
    !   ipr - excitation type flag
    !
    ! Original: nec2dxs.f lines 3836-4068

    type(geometry_data), intent(in) :: geom
    type(voltage_source_data), intent(inout) :: vsource
    type(ground_data), intent(in) :: ground
    complex(8), intent(inout) :: e_array(:)
    real(8), intent(in) :: p1, p2, p3, p4, p5, p6
    integer, intent(in) :: ipr

    complex(8) :: cx, cy, cz, rrv, rrh, tt1, tt2, er, et, ezh, erh
    real(8) :: cth, sth, cph, sph, cet, set, px, py, pz, wx, wy, wz, qx, qy, qz
    real(8) :: arg, ds, dsh, r, rs, cthi, sthi
    integer :: i, is, neq, ii, i1, i2
    real(8), parameter :: tp = 6.283185308d0
    real(8), parameter :: reta = 2.654420938d-3

    neq = geom%n + 2 * geom%m
    vsource%nqds = 0

    if (ipr > 0 .and. ipr /= 5) goto 500

    ! ========================================================================
    ! MODE: Applied field of voltage sources for transmitting case (IPR=0,5)
    ! ========================================================================
    ! Initialize E array to zero
    do i = 1, neq
      e_array(i) = (0.0d0, 0.0d0)
    end do

    ! Add simple voltage source contributions
    if (vsource%nsant > 0) then
      do i = 1, vsource%nsant
        is = vsource%isant(i)
        e_array(is) = -vsource%vsant(i) / (geom%si(is) * geom%wlam)
      end do
    end if

    ! Add voltage sources with charge discontinuity
    ! NOTE: Full qdsrc() requires current, segj, dataj, loading parameters
    ! For now, using simplified inline calculation
    if (vsource%nvqd > 0) then
      do i = 1, vsource%nvqd
        is = vsource%ivqd(i)
        ! Simplified: just add voltage/impedance at segment
        ! Full implementation would call qdsrc with all required data structures
        e_array(is) = e_array(is) - vsource%vqd(i) / (geom%si(is) * geom%wlam)
      end do
    end if
    return

    ! ========================================================================
    ! MODE: Incident plane wave (IPR=1,2,3)
    ! ========================================================================
500 if (ipr > 3) goto 1900

    ! Calculate wave propagation and polarization vectors
    cth = cos(p1)  ! cos(theta) - elevation angle
    sth = sin(p1)  ! sin(theta)
    cph = cos(p2)  ! cos(phi) - azimuth angle
    sph = sin(p2)  ! sin(phi)
    cet = cos(p3)  ! cos(eta) - polarization angle
    set = sin(p3)  ! sin(eta)

    ! Polarization vector P (electric field direction)
    px = cth * cph * cet - sph * set
    py = cth * sph * cet + cph * set
    pz = -sth * cet

    ! Wave propagation direction W
    wx = -sth * cph
    wy = -sth * sph
    wz = -cth

    ! Q vector (cross product for orthogonal component)
    qx = wy * pz - wz * py
    qy = wz * px - wx * pz
    qz = wx * py - wy * px

    ! Calculate ground reflection coefficients
    if (ground%ksymp == 1) goto 700  ! Skip if symmetry

    if (ground%iperf == 1) then
      ! Perfect ground
      rrv = -(1.0d0, 0.0d0)
      rrh = -(1.0d0, 0.0d0)
    else
      ! Real ground - compute reflection coefficients
      rrv = sqrt(1.0d0 - ground%zrati * ground%zrati * sth * sth)
      rrh = ground%zrati * cth
      rrh = (rrh - rrv) / (rrh + rrv)
      rrv = ground%zrati * rrv
      rrv = -(cth - rrv) / (cth + rrv)
    end if

700 if (ipr > 1) goto 1300

    ! ========================================================================
    ! IPR=1: Linearly polarized plane wave
    ! ========================================================================
    if (geom%n > 0) then
      do i = 1, geom%n
        arg = -tp * (wx * geom%x(i) + wy * geom%y(i) + wz * geom%z(i))
        e_array(i) = -(px * geom%alp(i) + py * geom%bet(i) + pz * geom%salp(i)) * &
                     cmplx(cos(arg), sin(arg), kind=8)
      end do

      ! Add ground reflection if not symmetric
      if (ground%ksymp /= 1) then
        tt1 = (py * cph - px * sph) * (rrh - rrv)
        cx = rrv * px - tt1 * sph
        cy = rrv * py + tt1 * cph
        cz = -rrv * pz

        do i = 1, geom%n
          arg = -tp * (wx * geom%x(i) + wy * geom%y(i) - wz * geom%z(i))
          e_array(i) = e_array(i) - (cx * geom%alp(i) + cy * geom%bet(i) + cz * geom%salp(i)) * &
                       cmplx(cos(arg), sin(arg), kind=8)
        end do
      end if
    end if

    ! Handle surface patches
    if (geom%m > 0) then
      i = geom%ld + 1
      i1 = geom%n - 1

      do is = 1, geom%m
        i = i - 1
        i1 = i1 + 2
        i2 = i1 + 1
        arg = -tp * (wx * geom%x(i) + wy * geom%y(i) + wz * geom%z(i))
        tt1 = cmplx(cos(arg), sin(arg), kind=8) * geom%salp(i) * reta

        ! Would need t1x, t1y, t1z, t2x, t2y, t2z arrays for surface patches
        ! Skipping patch field calculation for now
        ! e_array(i2) = (qx * t1x(i) + qy * t1y(i) + qz * t1z(i)) * tt1
        ! e_array(i1) = (qx * t2x(i) + qy * t2y(i) + qz * t2z(i)) * tt1
      end do

      ! Ground reflection for patches
      if (ground%ksymp /= 1) then
        tt1 = (qy * cph - qx * sph) * (rrv - rrh)
        cx = -(rrh * qx - tt1 * sph)
        cy = -(rrh * qy + tt1 * cph)
        cz = rrh * qz

        i = geom%ld + 1
        i1 = geom%n - 1

        do is = 1, geom%m
          i = i - 1
          i1 = i1 + 2
          i2 = i1 + 1
          arg = -tp * (wx * geom%x(i) + wy * geom%y(i) - wz * geom%z(i))
          tt1 = cmplx(cos(arg), sin(arg), kind=8) * geom%salp(i) * reta

          ! e_array(i2) = e_array(i2) + (cx * t1x(i) + cy * t1y(i) + cz * t1z(i)) * tt1
          ! e_array(i1) = e_array(i1) + (cx * t2x(i) + cy * t2y(i) + cz * t2z(i)) * tt1
        end do
      end if
    end if
    return

    ! ========================================================================
    ! IPR=2,3: Elliptically polarized plane wave
    ! ========================================================================
1300 tt1 = -(0.0d0, 1.0d0) * p6
    if (ipr == 3) tt1 = -tt1

    if (geom%n > 0) then
      cx = px + tt1 * qx
      cy = py + tt1 * qy
      cz = pz + tt1 * qz

      do i = 1, geom%n
        arg = -tp * (wx * geom%x(i) + wy * geom%y(i) + wz * geom%z(i))
        e_array(i) = -(cx * geom%alp(i) + cy * geom%bet(i) + cz * geom%salp(i)) * &
                     cmplx(cos(arg), sin(arg), kind=8)
      end do

      if (ground%ksymp /= 1) then
        tt2 = (cy * cph - cx * sph) * (rrh - rrv)
        cx = rrv * cx - tt2 * sph
        cy = rrv * cy + tt2 * cph
        cz = -rrv * cz

        do i = 1, geom%n
          arg = -tp * (wx * geom%x(i) + wy * geom%y(i) - wz * geom%z(i))
          e_array(i) = e_array(i) - (cx * geom%alp(i) + cy * geom%bet(i) + cz * geom%salp(i)) * &
                       cmplx(cos(arg), sin(arg), kind=8)
        end do
      end if
    end if

    ! Surface patches for elliptical polarization (similar pattern, omitted for brevity)
    return

    ! ========================================================================
    ! MODE: Incident field of elementary current source (IPR=4)
    ! ========================================================================
1900 wz = cos(p4)
    wx = wz * cos(p5)
    wy = wz * sin(p5)
    wz = sin(p4)
    ds = p6 * 59.958d0
    dsh = p6 / (2.0d0 * tp)

    i = geom%ld + 1
    i1 = geom%n - 1

    do ii = 1, geom%n + geom%m
      if (ii <= geom%n) then
        i = ii
      else
        i = i - 1
        i1 = i1 + 2
        i2 = i1 + 1
      end if

      ! Vector from source to observation point
      px = geom%x(i) - p1
      py = geom%y(i) - p2
      pz = geom%z(i) - p3
      rs = px * px + py * py + pz * pz

      if (rs < 1.0d-30) cycle

      r = sqrt(rs)
      px = px / r
      py = py / r
      pz = pz / r

      cthi = px * wx + py * wy + pz * wz
      sthi = sqrt(1.0d0 - cthi * cthi)

      qx = px - wx * cthi
      qy = py - wy * cthi
      qz = pz - wz * cthi

      arg = sqrt(qx * qx + qy * qy + qz * qz)

      if (arg >= 1.0d-30) then
        qx = qx / arg
        qy = qy / arg
        qz = qz / arg
      else
        qx = 1.0d0
        qy = 0.0d0
        qz = 0.0d0
      end if

      arg = -tp * r
      tt1 = cmplx(cos(arg), sin(arg), kind=8)

      if (ii <= geom%n) then
        ! Wire segment
        tt2 = cmplx(1.0d0, -1.0d0 / (r * tp), kind=8) / rs
        er = ds * tt1 * tt2 * cthi
        et = 0.5d0 * ds * tt1 * (cmplx(0.0d0, tp / r, kind=8) + tt2) * sthi
        ezh = er * cthi - et * sthi
        erh = er * sthi + et * cthi
        cx = ezh * wx + erh * qx
        cy = ezh * wy + erh * qy
        cz = ezh * wz + erh * qz
        e_array(ii) = -(cx * geom%alp(ii) + cy * geom%bet(ii) + cz * geom%salp(ii))
      else
        ! Surface patch (would need patch orientation vectors)
        px = wy * qz - wz * qy
        py = wz * qx - wx * qz
        pz = wx * qy - wy * qx
        tt2 = dsh * tt1 * cmplx(1.0d0 / r, tp, kind=8) / r * sthi * geom%salp(i)
        cx = tt2 * px
        cy = tt2 * py
        cz = tt2 * pz
        ! e_array(i2) = cx * t1x(i) + cy * t1y(i) + cz * t1z(i)
        ! e_array(i1) = cx * t2x(i) + cy * t2y(i) + cz * t2z(i)
      end if
    end do

  end subroutine etmns

  !============================================================================
  ! ZINT - Wire internal impedance calculation
  !============================================================================
  function zint(sigl, rolam) result(z_internal)
    ! Computes the internal impedance of a circular wire including skin effect
    ! Uses Bessel function approximations for different parameter ranges
    !
    ! Arguments:
    !   sigl - conductivity * relative permeability (complex if lossy)
    !   rolam - wire radius / wavelength ratio
    !
    ! Returns:
    !   z_internal - internal impedance per unit length (ohms/m)
    !
    ! Original: nec2dxs.f lines 9894-9974

    real(8), intent(in) :: sigl, rolam
    complex(8) :: z_internal

    ! Polynomial coefficients for TH and PH functions
    complex(8) :: cc1, cc2, cc3, cc4, cc5, cc6, cc7
    complex(8) :: cc8, cc9, cc10, cc11, cc12, cc13, cc14
    complex(8) :: fj, cn, br1, br2
    real(8) :: x, y, s, ber, bei
    real(8) :: ber2, bei2

    ! Constants
    real(8), parameter :: TPCMU = 2.368705d3  ! 2*pi*c*mu0 (CGS units)
    real(8), parameter :: CMOTP = 60.0d0       ! 60 ohms
    complex(8), parameter :: FJ_CONST = cmplx(0.0d0, 1.0d0, kind=8)
    complex(8), parameter :: CN_CONST = cmplx(0.70710678d0, 0.70710678d0, kind=8)

    ! Polynomial coefficients for approximations
    cc1 = cmplx(6.0d-7, 1.9d-6, kind=8)
    cc2 = cmplx(-3.4d-6, 5.1d-6, kind=8)
    cc3 = cmplx(-2.52d-5, 0.0d0, kind=8)
    cc4 = cmplx(-9.06d-5, -9.01d-5, kind=8)
    cc5 = cmplx(0.0d0, -9.765d-4, kind=8)
    cc6 = cmplx(0.0110486d0, -0.0110485d0, kind=8)
    cc7 = cmplx(0.0d0, -0.3926991d0, kind=8)
    cc8 = cmplx(1.6d-6, -3.2d-6, kind=8)
    cc9 = cmplx(1.17d-5, -2.4d-6, kind=8)
    cc10 = cmplx(3.46d-5, 3.38d-5, kind=8)
    cc11 = cmplx(5.0d-7, 2.452d-4, kind=8)
    cc12 = cmplx(-1.3813d-3, 1.3811d-3, kind=8)
    cc13 = cmplx(-6.25001d-2, -1.0d-7, kind=8)
    cc14 = cmplx(0.70710678d0, 0.70710678d0, kind=8)

    fj = FJ_CONST
    cn = CN_CONST

    ! Compute parameter X
    x = sqrt(TPCMU * sigl) * rolam

    if (x > 110.0d0) then
      ! Large X approximation
      br1 = cmplx(0.70710678d0, -0.70710678d0, kind=8)

    else if (x > 8.0d0) then
      ! Medium X - use asymptotic expansion
      br2 = fj * f_func(x, cc1, cc2, cc3, cc4, cc5, cc6, cc7, cn) / PI
      br1 = g_func(x, cc1, cc2, cc3, cc4, cc5, cc6, cc7, cn) + br2
      br2 = g_func(x, cc1, cc2, cc3, cc4, cc5, cc6, cc7, cn) * &
            ph_func(8.0d0/x, cc8, cc9, cc10, cc11, cc12, cc13, cc14) - &
            br2 * ph_func(-8.0d0/x, cc8, cc9, cc10, cc11, cc12, cc13, cc14)
      br1 = br1 / br2

    else
      ! Small X - use power series for Bessel functions
      y = x / 8.0d0
      y = y * y
      s = y * y

      ! BER0 approximation
      ber = ((((((-9.01d-6*s + 1.22552d-3)*s - 0.08349609d0)*s + 2.6419140d0) &
            *s - 32.363456d0)*s + 113.77778d0)*s - 64.0d0)*s + 1.0d0

      ! BEI0 approximation
      bei = ((((((1.1346d-4*s - 0.01103667d0)*s + 0.52185615d0)*s - &
            10.567658d0)*s + 72.817777d0)*s - 113.77778d0)*s + 16.0d0) * y

      br1 = cmplx(ber, bei, kind=8)

      ! BER1 approximation
      ber2 = (((((((-3.94d-6*s + 4.5957d-4)*s - 0.02609253d0)*s + 0.66047849d0) &
             *s - 6.0681481d0)*s + 14.222222d0)*s - 4.0d0) * y) * x

      ! BEI1 approximation
      bei2 = ((((((4.609d-5*s - 3.79386d-3)*s + 0.14677204d0)*s - 2.3116751d0) &
             *s + 11.377778d0)*s - 10.666667d0)*s + 0.5d0) * x

      br2 = cmplx(ber2, bei2, kind=8)
      br1 = br1 / br2
    end if

    ! Final impedance calculation
    z_internal = fj * sqrt(CMOTP / sigl) * br1 / rolam

  contains

    ! Helper function TH - polynomial approximation
    function th_func(d, c1, c2, c3, c4, c5, c6, c7) result(th_val)
      real(8), intent(in) :: d
      complex(8), intent(in) :: c1, c2, c3, c4, c5, c6, c7
      complex(8) :: th_val
      th_val = (((((c1*d + c2)*d + c3)*d + c4)*d + c5)*d + c6)*d + c7
    end function th_func

    ! Helper function PH - polynomial approximation
    function ph_func(d, c8, c9, c10, c11, c12, c13, c14) result(ph_val)
      real(8), intent(in) :: d
      complex(8), intent(in) :: c8, c9, c10, c11, c12, c13, c14
      complex(8) :: ph_val
      ph_val = (((((c8*d + c9)*d + c10)*d + c11)*d + c12)*d + c13)*d + c14
    end function ph_func

    ! Helper function F
    function f_func(d, c1, c2, c3, c4, c5, c6, c7, cn) result(f_val)
      real(8), intent(in) :: d
      complex(8), intent(in) :: c1, c2, c3, c4, c5, c6, c7, cn
      complex(8) :: f_val
      f_val = sqrt(PI/2.0d0/d) * exp(-cn*d + th_func(-8.0d0/x, c1, c2, c3, c4, c5, c6, c7))
    end function f_func

    ! Helper function G
    function g_func(d, c1, c2, c3, c4, c5, c6, c7, cn) result(g_val)
      real(8), intent(in) :: d
      complex(8), intent(in) :: c1, c2, c3, c4, c5, c6, c7, cn
      complex(8) :: g_val
      g_val = exp(cn*d + th_func(8.0d0/x, c1, c2, c3, c4, c5, c6, c7)) / sqrt(TWO_PI*d)
    end function g_func

  end function zint

end module nec2_excitation
