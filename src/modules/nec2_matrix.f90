! nec2_matrix.f90
! Matrix assembly and operations for NEC2
! Builds impedance matrix from interaction kernels

module nec2_matrix
  use nec2_constants
  use nec2_data_types
  use nec2_utilities
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

    type(geometry_data), intent(in) :: geom
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
          ! Set up basis functions for segment j (would call TRIO)
          ! For now, placeholder - full implementation needs trio() from nec2_current

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

    ! Set source segment parameters in dataj
    dataj%s = geom%si(j)
    dataj%b = geom%bi(j)
    dataj%xj = geom%x(j)
    dataj%yj = geom%y(j)
    dataj%zj = geom%z(j)
    dataj%cabj = geom%alp(j)  ! Direction cosines stored in alp/bet
    dataj%sabj = geom%bet(j)
    if (allocated(geom%salp)) then
      dataj%salpj = geom%salp(j)
    else
      dataj%salpj = 0.0d0
    end if

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
      if (allocated(geom%salp)) then
        salpi = geom%salp(i)
      else
        salpi = 0.0d0
      end if

      ! Calculate electric field (would call EFLD)
      ! For now, placeholder - full implementation needs efld()
      ! This computes EXK, EYK, EZK, EXS, EYS, EZS, EXC, EYC, EZC in dataj

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
    ! Computes matrix elements for wire-to-surface interactions
    !
    ! Arguments: same as cmww but for wire source, patch observation

    type(geometry_data), intent(in) :: geom
    type(segment_junction_data), intent(in) :: segj
    type(dataj_data), intent(inout) :: dataj
    integer, intent(in) :: j, i1, i2, nr, nw, itrp
    complex(8), intent(inout) :: cm(:,:), cw(:,:)

    integer :: i, ipr, ix, ij, jx
    real(8) :: xi, yi, zi, cabi, sabi, salpi
    complex(8) :: etk, ets, etc

    ! Set source segment parameters
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

    ! Determine kernel type
    call determine_kernel_type(geom, j, dataj)

    ! Observation loop over patches
    ipr = 0
    do i = i1, i2
      ipr = ipr + 1

      ! Get patch center coordinates and compute field
      ! Would call HINTG for patch integration
      ! Placeholder for now

      ! Fill matrix elements for each patch corner
      do ix = 1, 4
        ! Similar structure to cmww but for patch observations
        ! Implementation needs HINTG from nec2_current module
      end do
    end do

  end subroutine cmws

  !============================================================================
  ! CMSW - Compute surface-wire interaction matrix elements
  !============================================================================
  subroutine cmsw(geom, segj, dataj, j1, j2, i1, i2, cm, cw, ncw, nrow, itrp)
    ! Computes matrix elements for surface-to-wire interactions
    !
    ! Arguments: patch sources to wire observations

    type(geometry_data), intent(in) :: geom
    type(segment_junction_data), intent(in) :: segj
    type(dataj_data), intent(inout) :: dataj
    integer, intent(in) :: j1, j2, i1, i2, ncw, nrow, itrp
    complex(8), intent(inout) :: cm(:,:), cw(:,:)

    integer :: i, j, ix, ipr, ij, jx
    real(8) :: xi, yi, zi, ai, cabi, sabi, salpi
    complex(8) :: etk, ets, etc

    ! Loop over patch sources
    do j = j1, j2
      ! Set patch source parameters
      ! Would extract patch geometry

      ! Loop over wire observations
      ipr = 0
      do i = i1, i2
        ipr = ipr + 1

        ! Get wire segment parameters
        xi = geom%x(i)
        yi = geom%y(i)
        zi = geom%z(i)
        ai = geom%bi(i)
        cabi = geom%alp(i)
        sabi = geom%bet(i)
        if (allocated(geom%salp)) then
          salpi = geom%salp(i)
        else
          salpi = 0.0d0
        end if

        ! Calculate fields from patch
        ! Would call HSFLD for patch fields
        ! Placeholder

        ! Fill matrix elements
        ! Similar structure to wire-wire
      end do
    end do

  end subroutine cmsw

  !============================================================================
  ! CMSS - Compute surface-surface interaction matrix elements
  !============================================================================
  subroutine cmss(geom, segj, dataj, j1, j2, im1, im2, cm, nrow, itrp)
    ! Computes matrix elements for surface-to-surface (patch-patch) interactions
    !
    ! Arguments:
    !   j1, j2 - range of source patches
    !   im1, im2 - range of observation patches

    type(geometry_data), intent(in) :: geom
    type(segment_junction_data), intent(in) :: segj
    type(dataj_data), intent(inout) :: dataj
    integer, intent(in) :: j1, j2, im1, im2, nrow, itrp
    complex(8), intent(inout) :: cm(:,:)

    integer :: i, j, ipr
    complex(8) :: e_array(9)

    ! Loop over patch sources
    do j = j1, j2
      ! Set patch source parameters

      ! Loop over patch observations
      ipr = 0
      do i = im1, im2
        ipr = ipr + 1

        ! Compute patch-patch interaction
        ! Would call HSFLX or similar
        ! Placeholder

        ! Fill matrix for 4 corners of each patch
        ! More complex than wire-wire due to patch structure
      end do
    end do

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

    type(geometry_data), intent(in) :: geom
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
        ! Would call TRIO

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
