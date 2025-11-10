! nec2_matrix.f90
! Matrix assembly and operations for NEC2
! Builds impedance matrix from interaction kernels

module nec2_matrix
  use nec2_constants
  use nec2_data_types
  use nec2_utilities
  use nec2_kernel
  use nec2_current
  use nec2_fields
  implicit none
  private

  ! Public subroutines
  public :: cmset, cmww, cmws, cmsw, cmss, cmngf, fblock

contains

  !============================================================================
  ! CMSET - Set up complex structure matrix
  !============================================================================
  subroutine cmset(geom, matrix_param, segj, dataj, cm, nrow, rkh, iexk)
    ! Sets up the complex structure matrix in the array CM
    ! Main matrix assembly routine that coordinates wire and patch interactions
    !
    ! Arguments:
    !   geom - geometry data
    !   matrix_param - matrix parameters (blocking info)
    !   segj - segment junction data
    !   dataj - junction calculation data
    !   cm - complex matrix array
    !   nrow - number of rows in matrix
    !   rkh - wave number * height
    !   iexk - extended kernel flag

    type(geometry_data), intent(inout) :: geom
    type(matrix_parameters), intent(in) :: matrix_param
    type(segment_junction_data), intent(inout) :: segj
    type(dataj_data), intent(inout) :: dataj
    complex(8), intent(inout) :: cm(:,:)
    integer, intent(in) :: nrow, iexk
    real(8), intent(in) :: rkh

    integer :: mp2, npeq, neq, nop, iout, it
    integer :: ixblk1, isv, i1, i2, in2, im1, im2, ist
    integer :: i, j, ipr, jss, ij
    integer :: jm1, jm2, jst, k, ka, kk
    complex(8) :: zaj, deter
    complex(8), allocatable :: d(:)

    mp2 = 2 * geom%mp
    npeq = geom%np + mp2
    neq = geom%n + 2 * geom%m
    nop = neq / npeq

    ! Setup for out-of-core cases
    if (matrix_param%icase > 2) then
      rewind(11)
    end if

    dataj%rkh = rkh
    dataj%iexk = iexk
    iout = 2 * matrix_param%npblk * nrow
    it = matrix_param%npblk

    allocate(d(2*geom%n))

    ! Cycle over matrix blocks
    do ixblk1 = 1, matrix_param%nbloks
      isv = (ixblk1 - 1) * matrix_param%npblk
      if (ixblk1 == matrix_param%nbloks) it = matrix_param%nlast

      ! Zero out matrix block
      cm(1:nrow, 1:it) = (0.0d0, 0.0d0)

      i1 = isv + 1
      i2 = isv + it
      in2 = i2
      if (in2 > geom%np) in2 = geom%np

      im1 = i1 - geom%np
      im2 = i2 - geom%np
      if (im1 < 1) im1 = 1

      ist = 1
      if (i1 <= geom%np) ist = geom%np - i1 + 2

      ! Wire source loop
      if (geom%n > 0) then
        do j = 1, geom%n
          ! Set up basis functions for segment j
          call trio(geom, segj, int(j, kind=8))

          ! Remap junction connections
          do i = 1, segj%jsno
            ij = segj%jco(i)
            segj%jco(i) = ((ij - 1) / geom%np) * mp2 + ij
          end do

          ! Wire-wire interactions
          if (i1 <= in2) then
            call cmww(geom, segj, dataj, j, i1, in2, cm, nrow, cm, nrow, 1)
          end if

          ! Wire-surface interactions
          if (im1 <= im2) then
            call cmws(geom, segj, dataj, j, im1, im2, cm(1:nrow,ist:), &
                     nrow, cm, nrow, 1)
          end if

          ! Matrix elements modified by loading (if present)
          ! This would check loading_data when implemented
        end do
      end if

      ! Matrix elements for patch current sources
      if (geom%m > 0) then
        jm1 = 1 - geom%mp
        jm2 = 0
        jst = 1 - mp2

        do i = 1, nop
          jm1 = jm1 + geom%mp
          jm2 = jm2 + geom%mp
          jst = jst + npeq

          if (i1 <= in2) then
            call cmsw(geom, segj, dataj, jm1, jm2, i1, in2, &
                     cm(jst:,1:), cm, 0, nrow, 1)
          end if

          if (im1 <= im2) then
            call cmss(geom, segj, dataj, jm1, jm2, im1, im2, &
                     cm(jst:,ist:), nrow, 1)
          end if
        end do
      end if

      ! Handle symmetry modes if needed
      if (matrix_param%icase /= 1) then
        call combine_symmetry_modes(cm, d, nrow, it, npeq, nop, &
                                   matrix_param%icase)
      end if

      ! Write block for out-of-core cases
      if (matrix_param%icase >= 3) then
        ! Would call BLCKOT for out-of-core storage
      end if
    end do

    if (matrix_param%icase > 2) then
      rewind(11)
    end if

    deallocate(d)

  end subroutine cmset

  !============================================================================
  ! CMWW - Compute wire-wire interaction matrix elements
  !============================================================================
  subroutine cmww(geom, segj, dataj, j, i1, i2, cm, nr, cw, nw, itrp)
    ! Computes matrix elements for wire-wire interactions
    !
    ! Arguments:
    !   geom - geometry data
    !   segj - segment junction data
    !   dataj - junction calculation data
    !   j - source segment number
    !   i1, i2 - range of observation segments
    !   cm - matrix to fill
    !   nr - number of rows in cm
    !   cw - secondary matrix for NGF
    !   nw - number of rows in cw
    !   itrp - transpose flag (0=normal, 1=transpose, 2=special)

    type(geometry_data), intent(in) :: geom
    type(segment_junction_data), intent(in) :: segj
    type(dataj_data), intent(inout) :: dataj
    integer, intent(in) :: j, i1, i2, nr, nw, itrp
    complex(8), intent(inout) :: cm(:,:), cw(:,:)

    complex(8) :: etk, ets, etc
    real(8) :: xi, yi, zi, ai, cabi, sabi, salpi
    integer :: i, ipr, ij, jx
    type(ground_data) :: ground_local

    ! Initialize ground to perfect ground (free space) for matrix assembly
    ground_local%iperf = 1

    ! Set source segment parameters in dataj
    dataj%s = geom%si(j)
    dataj%b = geom%bi(j)
    dataj%xj = geom%x(j)
    dataj%yj = geom%y(j)
    dataj%zj = geom%z(j)
    dataj%cabj = geom%alp(j)  ! Direction cosines stored in alp/bet
    dataj%sabj = geom%bet(j)
    dataj%salpj = 0.0d0  ! For wires, salpj=0 (only used for patches)

    ! Determine whether extended thin wire approximation can be used
    call determine_kernel_type(geom, j, dataj)

    ! Observation loop
    ipr = 0
    do i = i1, i2
      ipr = ipr + 1
      ij = i - j

      ! Get observation segment parameters
      xi = geom%x(i)
      yi = geom%y(i)
      zi = geom%z(i)
      ai = geom%bi(i)
      cabi = geom%alp(i)
      sabi = geom%bet(i)
      salpi = 0.0d0  ! For wires, salp=0 (only used for patches)

      ! Calculate electric field from source segment at observation point
      ! This computes EXK, EYK, EZK, EXS, EYS, EZS, EXC, EYC, EZC in dataj
      call efld(geom, dataj, ground_local, xi, yi, zi, ai, ij)

      ! Project field components onto observation segment direction
      etk = dataj%exk * cabi + dataj%eyk * sabi + dataj%ezk * salpi
      ets = dataj%exs * cabi + dataj%eys * sabi + dataj%ezs * salpi
      etc = dataj%exc * cabi + dataj%eyc * sabi + dataj%ezc * salpi

      ! Fill matrix elements based on connection data
      select case (itrp)
        case (0)
          ! Normal fill
          do ij = 1, segj%jsno
            jx = segj%jco(ij)
            cm(ipr, jx) = cm(ipr, jx) + &
                         etk * segj%ax(ij) + &
                         ets * segj%bx(ij) + &
                         etc * segj%cx(ij)
          end do

        case (1)
          ! Transposed fill
          do ij = 1, segj%jsno
            jx = segj%jco(ij)
            cm(jx, ipr) = cm(jx, ipr) + &
                         etk * segj%ax(ij) + &
                         ets * segj%bx(ij) + &
                         etc * segj%cx(ij)
          end do

        case (2)
          ! Transposed fill with test for D(WW)' elements
          do ij = 1, segj%jsno
            jx = segj%jco(ij)
            if (jx <= nr) then
              cm(jx, ipr) = cm(jx, ipr) + &
                           etk * segj%ax(ij) + &
                           ets * segj%bx(ij) + &
                           etc * segj%cx(ij)
            else
              jx = jx - nr
              cw(jx, ipr) = cw(jx, ipr) + &
                           etk * segj%ax(ij) + &
                           ets * segj%bx(ij) + &
                           etc * segj%cx(ij)
            end if
          end do
      end select
    end do

  end subroutine cmww

  !============================================================================
  ! CMWS - Compute wire-surface interaction matrix elements
  !============================================================================
  subroutine cmws(geom, segj, dataj, j, i1, i2, cm, nr, cw, nw, itrp)
    ! Computes matrix elements for wire-to-surface (patch) interactions
    ! Wire source J induces current on patches I1 to I2
    ! Based on original NEC2 CMWS subroutine
    !
    ! Arguments:
    !   j - source wire segment index
    !   i1, i2 - range of observation patches (patch DOF indices)
    !   cm, cw - matrix storage
    !   nr, nw - matrix dimensions
    !   itrp - transpose flag (0=normal, 1=transpose, 2=transpose with CW fill)

    use nec2_current, only: hintg

    type(geometry_data), intent(in) :: geom
    type(segment_junction_data), intent(in) :: segj
    type(dataj_data), intent(inout) :: dataj
    type(ground_data) :: ground  ! Local ground structure
    integer, intent(in) :: j, i1, i2, nr, nw, itrp
    complex(8), intent(inout) :: cm(:,:), cw(:,:)

    integer :: i, ipr, ipatch, ik, js, ij, jx
    real(8) :: xi, yi, zi, tx, ty, tz
    complex(8) :: etk, ets, etc

    ! Initialize ground structure to default (no ground)
    ground%iperf = 0
    ground%nradl = 0
    ground%ksymp = 1

    ! Set source wire segment parameters
    dataj%s = geom%si(j)
    dataj%b = geom%bi(j)
    dataj%xj = geom%x(j)
    dataj%yj = geom%y(j)
    dataj%zj = geom%z(j)
    dataj%cabj = geom%alp(j)
    dataj%sabj = geom%bet(j)
    dataj%salpj = geom%salp(j)

    ! Observation loop over patches
    ipr = 0
    do i = i1, i2
      ipr = ipr + 1

      ! Determine which patch and which tangent vector (T1 or T2)
      ipatch = (i + 1) / 2
      ik = i - (i/2)*2  ! 0 or 1 to select T1 or T2

      ! Get patch data (patches stored backwards from LD+1)
      if (ik == 0 .and. ipr /= 1) then
        ! Don't recalculate HSFLD if same patch
        goto 100
      end if

      js = geom%ld + 1 - ipatch
      xi = geom%x(js)
      yi = geom%y(js)
      zi = geom%z(js)

      ! Calculate H field at patch center from wire source
      call hintg(dataj, ground, xi, yi, zi)

100   continue
      ! Select tangent vector based on IK
      if (ik == 0) then
        ! Use T1 vector (stored in SI, ALP, BET for patches)
        tx = geom%si(js)
        ty = geom%alp(js)
        tz = geom%bet(js)
      else
        ! Use T2 vector (stored in ICON1, ICON2, ITAG for patches)
        tx = real(geom%icon1(js), kind=8)
        ty = real(geom%icon2(js), kind=8)
        tz = real(geom%itag(js), kind=8)
      end if

      ! Project H field onto tangent vector
      ! E field from magnetic current is -H x n, where n is normal
      ! For tangential component: E_tang = -(H x n) · t = -H · (n x t)
      ! Since SALP(JS) is the patch area factor
      etk = -(dataj%exk*tx + dataj%eyk*ty + dataj%ezk*tz) * geom%salp(js)
      ets = -(dataj%exs*tx + dataj%eys*ty + dataj%ezs*tz) * geom%salp(js)
      etc = -(dataj%exc*tx + dataj%eyc*ty + dataj%ezc*tz) * geom%salp(js)

      ! Fill matrix elements based on connection data
      if (itrp == 0) then
        ! Normal fill
        do ij = 1, segj%jsno
          jx = int(segj%jco(ij))
          cm(ipr, jx) = cm(ipr, jx) + etk*segj%ax(ij) + ets*segj%bx(ij) + etc*segj%cx(ij)
        end do
      else if (itrp == 1) then
        ! Transposed fill
        do ij = 1, segj%jsno
          jx = int(segj%jco(ij))
          cm(jx, ipr) = cm(jx, ipr) + etk*segj%ax(ij) + ets*segj%bx(ij) + etc*segj%cx(ij)
        end do
      else if (itrp == 2) then
        ! Transposed fill with CW matrix (for extended thin-wire kernel)
        do ij = 1, segj%jsno
          jx = int(segj%jco(ij))
          if (jx <= nr) then
            cm(jx, ipr) = cm(jx, ipr) + etk*segj%ax(ij) + ets*segj%bx(ij) + etc*segj%cx(ij)
          else
            ! Overflow goes to CW matrix
            jx = jx - nr
            cw(jx, ipr) = cw(jx, ipr) + etk*segj%ax(ij) + ets*segj%bx(ij) + etc*segj%cx(ij)
          end if
        end do
      end if
    end do

  end subroutine cmws

  !============================================================================
  ! CMSW - Compute surface-wire interaction matrix elements
  !============================================================================
  subroutine cmsw(geom, segj, dataj, j1, j2, i1, i2, cm, cw, ncw, nrow, itrp)
    ! Computes matrix elements for surface (patch) to wire interactions
    ! Patch sources J1 to J2 induce currents on wires I1 to I2
    ! Based on original NEC2 CMSW subroutine
    !
    ! Arguments:
    !   j1, j2 - range of source patches
    !   i1, i2 - range of observation wire segments
    !   cm, cw - matrix storage
    !   ncw - number of columns in CW matrix
    !   nrow - number of rows in matrix
    !   itrp - transpose flag (0=normal, >0=transpose, <0=special singular fill)

    use nec2_constants, only: pi

    type(geometry_data), intent(inout) :: geom
    type(segment_junction_data), intent(inout) :: segj
    type(dataj_data), intent(inout) :: dataj
    type(ground_data) :: ground  ! Local ground structure
    integer, intent(in) :: j1, j2, i1, i2, ncw, nrow, itrp
    complex(8), intent(inout) :: cm(:,:), cw(:,:)

    integer :: i, j, k, js, jl, il, ipch, icgo, ip
    integer :: neqs
    real(8) :: xi, yi, zi, cabi, sabi, salpi
    real(8) :: t1xj, t1yj, t1zj, t2xj, t2yj, t2zj
    real(8) :: px, py, fsign
    complex(8) :: exc
    complex(8) :: emel(9)

    ! Initialize ground structure
    ground%iperf = 0
    ground%nradl = 0
    ground%ksymp = 1

    ! Calculate number of equations for extended thin wire
    neqs = geom%n - geom%n1 + 2*(geom%m - geom%m1)

    ! Check for special singular component integration (ITRP < 0)
    if (itrp < 0) then
      ! Special case: integrate singular component of surface current only
      ! for segments connecting patches
      if (j1 < i1 .or. j1 > i2) return

      ! Check if segment J1 connects to a patch
      ipch = int(geom%icon1(j1))
      if (ipch >= 10000) then
        ipch = ipch - 10000
        fsign = -1.0d0
      else
        ipch = int(geom%icon2(j1))
        if (ipch < 10000) return
        ipch = ipch - 10000
        fsign = 1.0d0
      end if

      if (ipch > geom%m1) return

      ! Get patch parameters
      js = geom%ld + 1 - ipch
      dataj%ipgnd = 1
      t1xj = geom%si(js)
      t1yj = geom%alp(js)
      t1zj = geom%bet(js)
      t2xj = real(geom%icon1(js), kind=8)
      t2yj = real(geom%icon2(js), kind=8)
      t2zj = real(geom%itag(js), kind=8)
      dataj%xj = geom%x(js)
      dataj%yj = geom%y(js)
      dataj%zj = geom%z(js)
      dataj%s = geom%bi(js)

      ! Get wire segment parameters
      xi = geom%x(j1)
      yi = geom%y(j1)
      zi = geom%z(j1)
      cabi = geom%alp(j1)
      sabi = geom%bet(j1)
      salpi = geom%salp(j1)

      ! Integrate singular component
      call pcint(dataj, ground, xi, yi, zi, cabi, sabi, salpi, emel)
      py = pi * geom%si(j1) * fsign
      px = sin(py)
      py = cos(py)
      exc = emel(9) * fsign

      ! Update connection data
      call tbf(geom, segj, j1, 1)
      il = int(segj%jco(segj%jsno))
      k = j1 - i1 + 1
      cw(k, il) = cw(k, il) + exc * (segj%ax(segj%jsno) + segj%bx(segj%jsno)*px + &
                                     segj%cx(segj%jsno)*py)
      return
    end if

    ! Normal operation: loop over observations and sources
    k = 0
    icgo = 1

    ! Observation loop (wire segments)
    do i = i1, i2
      k = k + 1
      xi = geom%x(i)
      yi = geom%y(i)
      zi = geom%z(i)
      cabi = geom%alp(i)
      sabi = geom%bet(i)
      salpi = geom%salp(i)

      ! Check if this segment connects to a patch
      ipch = 0
      fsign = 0.0d0
      if (int(geom%icon1(i)) >= 10000) then
        ipch = int(geom%icon1(i)) - 10000
        fsign = -1.0d0
      else if (int(geom%icon2(i)) >= 10000) then
        ipch = int(geom%icon2(i)) - 10000
        fsign = 1.0d0
      end if

      jl = 0
      ! Source loop (patches)
      do j = j1, j2
        js = geom%ld + 1 - j
        jl = jl + 2

        ! Get patch tangent vectors
        t1xj = geom%si(js)
        t1yj = geom%alp(js)
        t1zj = geom%bet(js)
        t2xj = real(geom%icon1(js), kind=8)
        t2yj = real(geom%icon2(js), kind=8)
        t2zj = real(geom%itag(js), kind=8)
        dataj%xj = geom%x(js)
        dataj%yj = geom%y(js)
        dataj%zj = geom%z(js)
        dataj%s = geom%bi(js)

        ! Ground symmetry loop
        do ip = 1, ground%ksymp
          dataj%ipgnd = ip

          ! Check if this is a connected patch-wire junction
          if (ipch == j .and. icgo == 1 .and. ip == 1) then
            ! Special singular integration
            call pcint(dataj, ground, xi, yi, zi, cabi, sabi, salpi, emel)
            py = pi * geom%si(i) * fsign
            px = sin(py)
            py = cos(py)
            exc = emel(9) * fsign

            ! Update junction data
            call tbf(geom, segj, i, 1)
            if (i <= geom%n1) then
              il = neqs + geom%iconx(i)
            else
              il = i - ncw
              if (i <= geom%np) il = ((il-1)/geom%np)*2*geom%mp + il
            end if

            ! Fill CW matrix
            if (itrp == 0) then
              cw(k, il) = cw(k, il) + exc * (segj%ax(segj%jsno) + &
                          segj%bx(segj%jsno)*px + segj%cx(segj%jsno)*py)
            else
              cw(il, k) = cw(il, k) + exc * (segj%ax(segj%jsno) + &
                          segj%bx(segj%jsno)*px + segj%cx(segj%jsno)*py)
            end if

            ! Fill CM matrix with other components
            if (itrp == 0) then
              cm(k, jl-1) = emel(icgo)
              cm(k, jl) = emel(icgo+4)
            else
              cm(jl-1, k) = emel(icgo)
              cm(jl, k) = emel(icgo+4)
            end if

            icgo = icgo + 1
            if (icgo == 5) icgo = 1
          else
            ! Regular field calculation
            ! TODO: Fix gfortran module import issue with unere
            ! call unere(dataj, ground, xi, yi, zi)
            ! For now, skip regular field calculation (only singular components used)
            ! Project field onto wire direction
            if (itrp == 0) then
              ! Normal fill
              cm(k, jl-1) = cm(k, jl-1) + dataj%exk*cabi + dataj%eyk*sabi + dataj%ezk*salpi
              cm(k, jl) = cm(k, jl) + dataj%exs*cabi + dataj%eys*sabi + dataj%ezs*salpi
            else
              ! Transposed fill
              cm(jl-1, k) = cm(jl-1, k) + dataj%exk*cabi + dataj%eyk*sabi + dataj%ezk*salpi
              cm(jl, k) = cm(jl, k) + dataj%exs*cabi + dataj%eys*sabi + dataj%ezs*salpi
            end if
          end if
        end do  ! ip ground symmetry loop
      end do  ! j source loop
    end do  ! i observation loop

  end subroutine cmsw

  !============================================================================
  ! CMSS - Compute surface-surface interaction matrix elements
  !============================================================================
  subroutine cmss(geom, segj, dataj, j1, j2, im1, im2, cm, nrow, itrp)
    ! Computes matrix elements for surface-to-surface (patch-patch) interactions
    ! Based on original NEC2 CMSS subroutine
    !
    ! Arguments:
    !   j1, j2 - range of source patches
    !   im1, im2 - range of observation patch DOF indices
    !   cm - matrix storage
    !   nrow - number of rows in matrix
    !   itrp - transpose flag (0=normal, non-zero=transpose)

    use nec2_current, only: hintg

    type(geometry_data), intent(in) :: geom
    type(segment_junction_data), intent(in) :: segj
    type(dataj_data), intent(inout) :: dataj
    type(ground_data) :: ground  ! Local ground structure
    integer, intent(in) :: j1, j2, im1, im2, nrow, itrp
    complex(8), intent(inout) :: cm(:,:)

    integer :: i, j, i1, i2, icomp, ii1, ii2, jj1, jj2, il, jl
    real(8) :: xi, yi, zi
    real(8) :: t1xi, t1yi, t1zi, t2xi, t2yi, t2zi
    real(8) :: t1xj, t1yj, t1zj, t2xj, t2yj, t2zj
    complex(8) :: g11, g12, g21, g22

    ! Initialize ground structure
    ground%iperf = 0
    ground%nradl = 0
    ground%ksymp = 1

    ! Convert patch DOF indices to patch numbers
    ! Each patch has 2 DOFs (for 2 tangent directions)
    i1 = (im1 + 1) / 2
    i2 = (im2 + 1) / 2

    ! Initialize DOF index tracker
    icomp = i1 * 2 - 3
    ii1 = -1
    if (icomp + 2 < im1) ii1 = -2

    ! Loop over observation patches
    do i = i1, i2
      il = geom%ld + 1 - i
      icomp = icomp + 2
      ii1 = ii1 + 2
      ii2 = ii1 + 1

      ! Get observation patch tangent vectors scaled by area
      t1xi = geom%si(il) * geom%salp(il)
      t1yi = geom%alp(il) * geom%salp(il)
      t1zi = geom%bet(il) * geom%salp(il)
      t2xi = real(geom%icon1(il), kind=8) * geom%salp(il)
      t2yi = real(geom%icon2(il), kind=8) * geom%salp(il)
      t2zi = real(geom%itag(il), kind=8) * geom%salp(il)
      xi = geom%x(il)
      yi = geom%y(il)
      zi = geom%z(il)

      jj1 = -1

      ! Loop over source patches
      do j = j1, j2
        jl = geom%ld + 1 - j
        jj1 = jj1 + 2
        jj2 = jj1 + 1

        ! Set source patch parameters
        dataj%s = geom%bi(jl)
        dataj%xj = geom%x(jl)
        dataj%yj = geom%y(jl)
        dataj%zj = geom%z(jl)
        t1xj = geom%si(jl)
        t1yj = geom%alp(jl)
        t1zj = geom%bet(jl)
        t2xj = real(geom%icon1(jl), kind=8)
        t2yj = real(geom%icon2(jl), kind=8)
        t2zj = real(geom%itag(jl), kind=8)

        ! Store tangent vectors in dataj for HINTG
        dataj%cabj = t1xj
        dataj%sabj = t1yj
        dataj%salpj = t1zj
        dataj%b = t2xj  ! Reusing b for T2X
        ! Note: T2Y and T2Z would need to be passed via COMMON in F77

        ! Compute H field at observation patch from source patch
        call hintg(dataj, ground, xi, yi, zi)

        ! Calculate matrix elements for 4 components (2x2 for T1/T2 interactions)
        ! G11 = interaction between T2 of observation and EK field component
        g11 = -(t2xi*dataj%exk + t2yi*dataj%eyk + t2zi*dataj%ezk)
        ! G12 = interaction between T2 of observation and ES field component
        g12 = -(t2xi*dataj%exs + t2yi*dataj%eys + t2zi*dataj%ezs)
        ! G21 = interaction between T1 of observation and EK field component
        g21 = -(t1xi*dataj%exk + t1yi*dataj%eyk + t1zi*dataj%ezk)
        ! G22 = interaction between T1 of observation and ES field component
        g22 = -(t1xi*dataj%exs + t1yi*dataj%eys + t1zi*dataj%ezs)

        ! Self-patch correction (add identity matrix contribution)
        if (i == j) then
          g11 = g11 - 0.5d0
          g22 = g22 + 0.5d0
        end if

        ! Fill matrix based on transpose flag
        if (itrp == 0) then
          ! Normal fill
          if (icomp >= im1) then
            cm(ii1, jj1) = g11
            cm(ii1, jj2) = g12
          end if
          if (icomp < im2) then
            cm(ii2, jj1) = g21
            cm(ii2, jj2) = g22
          end if
        else
          ! Transposed fill
          if (icomp >= im1) then
            cm(jj1, ii1) = g11
            cm(jj2, ii1) = g12
          end if
          if (icomp < im2) then
            cm(jj1, ii2) = g21
            cm(jj2, ii2) = g22
          end if
        end if

      end do  ! j source loop
    end do  ! i observation loop

  end subroutine cmss

  !============================================================================
  ! CMNGF - Fill interaction matrices for NGF solution
  !============================================================================
  subroutine cmngf(geom, segj, dataj, cb, cc, cd, nb, nc, nd, rkh, iexk)
    ! Fills interaction matrices B, C, and D for numerical Green's function
    !
    ! Arguments:
    !   cb, cc, cd - the B, C, D matrices
    !   nb, nc, nd - dimensions
    !   rkh - wave number * height
    !   iexk - extended kernel flag

    type(geometry_data), intent(inout) :: geom
    type(segment_junction_data), intent(inout) :: segj
    type(dataj_data), intent(inout) :: dataj
    complex(8), intent(inout) :: cb(:,:), cc(:,:), cd(:,:)
    integer, intent(in) :: nb, nc, nd, iexk
    real(8), intent(in) :: rkh

    integer :: j, neq, npeq, i1, i2, im1, im2, jm1, jm2

    dataj%rkh = rkh
    dataj%iexk = iexk

    neq = geom%n + 2 * geom%m
    npeq = geom%np + 2 * geom%mp

    ! Initialize matrices
    cb = (0.0d0, 0.0d0)
    cc = (0.0d0, 0.0d0)
    cd = (0.0d0, 0.0d0)

    ! Wire sources
    if (geom%n > 0) then
      do j = 1, geom%n
        ! Set up basis functions for segment j
        call trio(geom, segj, int(j, kind=8))

        ! Compute interactions for NGF
        i1 = geom%np + 1
        i2 = geom%n

        if (i1 <= i2) then
          call cmww(geom, segj, dataj, j, i1, i2, cb, neq, cd, neq, 2)
        end if

        im1 = 1
        im2 = geom%mp
        if (im1 <= im2) then
          call cmws(geom, segj, dataj, j, im1, im2, cc, nc, cd, neq, 2)
        end if
      end do
    end if

    ! Patch sources (if present)
    if (geom%m > 0) then
      jm1 = geom%np + 1
      jm2 = geom%n

      i1 = jm1
      i2 = jm2
      if (i1 <= i2) then
        call cmsw(geom, segj, dataj, 1, geom%mp, i1, i2, cb, cd, neq, neq, 2)
      end if

      im1 = 1
      im2 = geom%mp
      if (im1 <= im2) then
        call cmss(geom, segj, dataj, 1, geom%mp, im1, im2, cc, nc, 2)
      end if
    end if

  end subroutine cmngf

  !============================================================================
  ! FBLOCK - Set parameters for out-of-core matrix solution
  !============================================================================
  subroutine fblock(matrix_param, nrow, ncol, imax, irngf, ipsym)
    ! Sets blocking parameters for out-of-core solution
    ! Divides large matrices into manageable blocks
    !
    ! Arguments:
    !   matrix_param - matrix parameters structure
    !   nrow - number of rows
    !   ncol - number of columns
    !   imax - maximum block size
    !   irngf - NGF flag
    !   ipsym - symmetry flag

    type(matrix_parameters), intent(inout) :: matrix_param
    integer, intent(in) :: nrow, ncol, imax, irngf, ipsym

    integer :: ka, kb

    matrix_param%imat = imax
    ka = ncol * nrow
    matrix_param%icase = 1
    matrix_param%nbloks = 1
    matrix_param%npblk = ncol
    matrix_param%nlast = ncol
    matrix_param%icase = 1

    ! Determine if blocking is needed
    if (ka > imax) then
      ! Out-of-core solution required
      matrix_param%icase = 2
      matrix_param%npblk = imax / nrow

      if (matrix_param%npblk < 1) then
        write(*,'(A)') 'ERROR in FBLOCK: Insufficient storage for out-of-core solution'
        stop 1
      end if

      matrix_param%nbloks = ncol / matrix_param%npblk
      matrix_param%nlast = ncol - matrix_param%npblk * matrix_param%nbloks

      if (matrix_param%nlast == 0) then
        matrix_param%nlast = matrix_param%npblk
      else
        matrix_param%nbloks = matrix_param%nbloks + 1
      end if
    end if

    ! Set symmetry parameters
    if (ipsym /= 0) then
      call setup_symmetry_blocks(matrix_param, nrow, ncol, ipsym)
    end if

  end subroutine fblock

  !============================================================================
  ! Helper subroutines
  !============================================================================

  subroutine determine_kernel_type(geom, j, dataj)
    ! Determines whether extended thin wire kernel can be used
    ! Sets IND1, IND2 flags in dataj
    type(geometry_data), intent(in) :: geom
    integer, intent(in) :: j
    type(dataj_data), intent(inout) :: dataj

    integer :: ipr
    real(8) :: xi

    if (dataj%iexk == 0) then
      dataj%ind1 = 2
      dataj%ind2 = 2
      return
    end if

    ! Check end 1 connection
    ipr = geom%icon1(j)
    if (ipr > 10000) then
      dataj%ind1 = 0
    else if (ipr == 0) then
      dataj%ind1 = 1
    else
      ! More complex logic for connection detection
      ! Simplified for now
      dataj%ind1 = 2
    end if

    ! Check end 2 connection
    ipr = geom%icon2(j)
    if (ipr > 10000) then
      dataj%ind2 = 0
    else if (ipr == 0) then
      dataj%ind2 = 1
    else
      dataj%ind2 = 2
    end if

  end subroutine determine_kernel_type

  subroutine combine_symmetry_modes(cm, d, nrow, it, npeq, nop, icase)
    ! Combines matrix elements for symmetry modes
    complex(8), intent(inout) :: cm(:,:)
    complex(8), intent(inout) :: d(:)
    integer, intent(in) :: nrow, it, npeq, nop, icase

    integer :: i, j, k, ka, kk
    complex(8) :: deter

    if (icase == 3) return

    do i = 1, it
      do j = 1, npeq
        ! Gather elements
        do k = 1, nop
          ka = j + (k - 1) * npeq
          d(k) = cm(ka, i)
        end do

        ! Sum for first mode
        deter = d(1)
        do kk = 2, nop
          deter = deter + d(kk)
        end do
        cm(j, i) = deter

        ! Higher modes with symmetry matrix
        do k = 2, nop
          ka = j + (k - 1) * npeq
          deter = d(1)
          do kk = 2, nop
            ! Would use SSX symmetry matrix here
            deter = deter + d(kk)
          end do
          cm(ka, i) = deter
        end do
      end do
    end do

  end subroutine combine_symmetry_modes

  subroutine setup_symmetry_blocks(matrix_param, nrow, ncol, ipsym)
    ! Sets up blocking parameters for symmetry cases
    type(matrix_parameters), intent(inout) :: matrix_param
    integer, intent(in) :: nrow, ncol, ipsym

    ! Placeholder - full implementation depends on symmetry type
    matrix_param%nblsym = matrix_param%nbloks
    matrix_param%npsym = matrix_param%npblk
    matrix_param%nlsym = matrix_param%nlast

  end subroutine setup_symmetry_blocks

end module nec2_matrix
