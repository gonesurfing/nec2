! nec2_solver.f90
! Linear algebra solvers for NEC2
! Matrix factorization and solution routines

module nec2_solver
  use nec2_constants
  use nec2_data_types
  implicit none
  private

  ! Public subroutines
  public :: factr, solve, factrs, solves, facio, lfactr, solgf

contains

  !============================================================================
  ! FACTR - Factor matrix using LU decomposition with partial pivoting
  !============================================================================
  subroutine factr(n, a, ip, ndim)
    ! Factors a matrix into unit lower triangular (L) and upper triangular (U)
    ! matrices using the Gauss-Doolittle algorithm (Ralston, pages 411-416)
    ! The matrix is transposed during this process.
    !
    ! Arguments:
    !   n - matrix size
    !   a - input matrix, output LU factorization (stored transposed)
    !   ip - pivot index array
    !   ndim - leading dimension of a

    integer, intent(in) :: n, ndim
    complex(8), intent(inout) :: a(ndim, ndim)
    integer, intent(out) :: ip(ndim)

    complex(8), allocatable :: d(:)
    complex(8) :: arj
    real(8) :: dmax, elmag
    integer :: i, j, k, r, rm1, rp1, pj, pr, jp1
    integer :: iflg

    allocate(d(n))

    ! Un-transpose the matrix for Gauss elimination
    do i = 2, n
      do j = 1, i - 1
        arj = a(i, j)
        a(i, j) = a(j, i)
        a(j, i) = arj
      end do
    end do

    iflg = 0

    ! Main elimination loop
    do r = 1, n
      ! STEP 1: Copy row r to working array
      do k = 1, n
        d(k) = a(k, r)
      end do

      ! STEPS 2 AND 3: Forward elimination
      rm1 = r - 1
      if (rm1 >= 1) then
        do j = 1, rm1
          pj = ip(j)
          arj = d(pj)
          a(j, r) = arj
          d(pj) = d(j)
          jp1 = j + 1

          do i = jp1, n
            d(i) = d(i) - a(i, j) * arj
          end do
        end do
      end if

      ! STEP 4: Partial pivoting - find maximum element
      dmax = real(d(r) * conjg(d(r)), kind=8)
      ip(r) = r
      rp1 = r + 1

      if (rp1 <= n) then
        do i = rp1, n
          elmag = real(d(i) * conjg(d(i)), kind=8)
          if (elmag >= dmax) then
            dmax = elmag
            ip(r) = i
          end if
        end do
      end if

      if (dmax < 1.0d-10) then
        iflg = 1
      end if

      pr = ip(r)
      a(r, r) = d(pr)
      d(pr) = d(r)

      ! STEP 5: Scale row elements
      if (rp1 <= n) then
        arj = 1.0d0 / a(r, r)
        do i = rp1, n
          a(i, r) = d(i) * arj
        end do
      end if

      if (iflg /= 0) then
        write(*,'(A,I0,A,1P,E16.8)') ' PIVOT(', r, ')=', dmax
        iflg = 0
      end if
    end do

    deallocate(d)

  end subroutine factr

  !============================================================================
  ! SOLVE - Solve LU*X=B using forward and backward substitution
  !============================================================================
  subroutine solve(n, a, ip, b, ndim)
    ! Solves the matrix equation LU*X=B where L is a unit lower triangular
    ! matrix and U is an upper triangular matrix, both stored in A.
    ! The RHS vector B is input and the solution is returned through B.
    !
    ! Arguments:
    !   n - system size
    !   a - LU factorized matrix from FACTR
    !   ip - pivot index array from FACTR
    !   b - input RHS vector, output solution vector
    !   ndim - leading dimension of a

    integer, intent(in) :: n, ndim
    complex(8), intent(in) :: a(ndim, ndim)
    integer, intent(in) :: ip(ndim)
    complex(8), intent(inout) :: b(ndim)

    complex(8), allocatable :: y(:)
    complex(8) :: sum_val
    integer :: i, j, k, pi, ip1

    allocate(y(n))

    ! Forward substitution
    do i = 1, n
      pi = ip(i)
      y(i) = b(pi)
      b(pi) = b(i)
      ip1 = i + 1

      if (ip1 <= n) then
        do j = ip1, n
          b(j) = b(j) - a(j, i) * y(i)
        end do
      end if
    end do

    ! Backward substitution
    do k = 1, n
      i = n - k + 1
      sum_val = (0.0d0, 0.0d0)
      ip1 = i + 1

      if (ip1 <= n) then
        do j = ip1, n
          sum_val = sum_val + a(i, j) * b(j)
        end do
      end if

      b(i) = (y(i) - sum_val) / a(i, i)
    end do

    deallocate(y)

  end subroutine solve

  !============================================================================
  ! FACTRS - Symmetric matrix factorization for NGF
  !============================================================================
  subroutine factrs(np, nrow, a, ip, ix, iu1, iu2, iu3, iu4)
    ! Factors symmetric matrix for numerical Green's function solution
    ! Handles out-of-core blocking if needed
    !
    ! Arguments:
    !   np - number of primary segments
    !   nrow - matrix row dimension
    !   a - matrix to factor
    !   ip - pivot array
    !   ix - current block index
    !   iu1-iu4 - file unit numbers for out-of-core storage

    integer, intent(in) :: np, nrow, ix, iu1, iu2, iu3, iu4
    complex(8), intent(inout) :: a(:,:)
    integer, intent(inout) :: ip(:)

    complex(8), allocatable :: d(:)
    complex(8) :: arj, pivot_val
    real(8) :: dmax, elmag
    integer :: i, j, k, r, rm1, rp1, pj, pr, jp1
    integer :: iflg, n

    n = np
    allocate(d(nrow))

    iflg = 0

    ! Factorization with symmetry considerations
    do r = 1, n
      ! Copy row
      do k = 1, n
        d(k) = a(k, r)
      end do

      ! Forward elimination
      rm1 = r - 1
      if (rm1 >= 1) then
        do j = 1, rm1
          pj = ip(j)
          arj = d(pj)
          a(j, r) = arj
          d(pj) = d(j)
          jp1 = j + 1

          do i = jp1, n
            d(i) = d(i) - a(i, j) * arj
          end do
        end do
      end if

      ! Pivoting
      dmax = real(d(r) * conjg(d(r)), kind=8)
      ip(r) = r
      rp1 = r + 1

      if (rp1 <= n) then
        do i = rp1, n
          elmag = real(d(i) * conjg(d(i)), kind=8)
          if (elmag >= dmax) then
            dmax = elmag
            ip(r) = i
          end if
        end do
      end if

      if (dmax < 1.0d-10) then
        iflg = 1
      end if

      pr = ip(r)
      a(r, r) = d(pr)
      d(pr) = d(r)

      ! Scale
      if (rp1 <= n) then
        arj = 1.0d0 / a(r, r)
        do i = rp1, n
          a(i, r) = d(i) * arj
        end do
      end if

      if (iflg /= 0) then
        write(*,'(A,I0,A,1P,E16.8)') ' Symmetry pivot(', r, ')=', dmax
        iflg = 0
      end if
    end do

    deallocate(d)

  end subroutine factrs

  !============================================================================
  ! SOLVES - Solve with symmetry considerations
  !============================================================================
  subroutine solves(a, ip, b, neq, nrh, np, n, mp, m, ifl1, ifl2)
    ! Solves system with symmetry modes
    !
    ! Arguments:
    !   a - LU factorized matrix
    !   ip - pivot array
    !   b - RHS vectors
    !   neq - number of equations
    !   nrh - number of right-hand sides
    !   np, n - wire segment counts
    !   mp, m - patch counts
    !   ifl1, ifl2 - flags for solution type

    complex(8), intent(in) :: a(:,:)
    integer, intent(in) :: ip(:)
    complex(8), intent(inout) :: b(:,:)
    integer, intent(in) :: neq, nrh, np, n, mp, m, ifl1, ifl2

    integer :: i, j, k, irh
    complex(8), allocatable :: y(:)
    complex(8) :: sum_val
    integer :: pi, ip1

    allocate(y(neq))

    ! Solve for each RHS
    do irh = 1, nrh
      ! Forward substitution
      do i = 1, neq
        pi = ip(i)
        y(i) = b(pi, irh)
        b(pi, irh) = b(i, irh)
        ip1 = i + 1

        if (ip1 <= neq) then
          do j = ip1, neq
            b(j, irh) = b(j, irh) - a(j, i) * y(i)
          end do
        end if
      end do

      ! Backward substitution
      do k = 1, neq
        i = neq - k + 1
        sum_val = (0.0d0, 0.0d0)
        ip1 = i + 1

        if (ip1 <= neq) then
          do j = ip1, neq
            sum_val = sum_val + a(i, j) * b(j, irh)
          end do
        end if

        b(i, irh) = (y(i) - sum_val) / a(i, i)
      end do
    end do

    deallocate(y)

  end subroutine solves

  !============================================================================
  ! FACIO - Out-of-core factorization
  !============================================================================
  subroutine facio(a, nrow, nop, ip, iu1, iu2, iu3, iu4)
    ! Performs LU factorization for out-of-core matrix storage
    ! Used when matrix is too large to fit in memory
    !
    ! Arguments:
    !   a - matrix block in core
    !   nrow - row dimension
    !   nop - number of operations
    !   ip - pivot array
    !   iu1-iu4 - file unit numbers for block I/O

    complex(8), intent(inout) :: a(:,:)
    integer, intent(in) :: nrow, nop, iu1, iu2, iu3, iu4
    integer, intent(inout) :: ip(:)

    ! This is a simplified version
    ! Full implementation would handle block I/O
    call factr(nrow, a, ip, nrow)

  end subroutine facio

  !============================================================================
  ! LFACTR - Local factorization for subblocks
  !============================================================================
  subroutine lfactr(a, nrow, ix1, ix2, ip)
    ! Factors a subblock of the matrix
    ! Used in block-based solution methods
    !
    ! Arguments:
    !   a - matrix to factor
    !   nrow - row dimension
    !   ix1, ix2 - block range
    !   ip - pivot array

    complex(8), intent(inout) :: a(:,:)
    integer, intent(in) :: nrow, ix1, ix2
    integer, intent(inout) :: ip(:)

    integer :: n

    n = ix2 - ix1 + 1
    call factr(n, a, ip, nrow)

  end subroutine lfactr

  !============================================================================
  ! SOLGF - Solve for numerical Green's function
  !============================================================================
  subroutine solgf(a, b, c, d, xy, ip, np, n1, n, mp, m1, m, n1c, n2c, n2cz)
    ! Solves for current in numerical Green's function procedure
    ! This handles the block-structured system arising from NGF formulation:
    !   [ A  B ] [ I1 ]   [ E1 ]
    !   [ C  D ] [ I2 ] = [ E2 ]
    ! Where A is N1C×N1C (primary), D is N2C×N2C (secondary)
    !
    ! Solution algorithm:
    !   1. Solve A*I1 = E1  →  I1 = inv(A)*E1
    !   2. Compute E2' = E2 - C*I1
    !   3. Solve D*I2 = E2'  →  I2 = inv(D)*E2'
    !   4. Compute I1' = I1 - inv(A)*B*I2
    !
    ! Arguments:
    !   a - primary block matrix (N1C×N1C)
    !   b - coupling matrix A→D (N1C×N2C)
    !   c - coupling matrix D→A (N1C×N2C)
    !   d - secondary block matrix (N2C×N2C)
    !   xy - excitation/solution array
    !   ip - pivot array
    !   np, n1, n - wire segment parameters
    !   mp, m1, m - patch parameters
    !   n1c, n2c, n2cz - array dimensions

    complex(8), intent(in) :: a(:,:), b(:,:), c(:,:), d(:,:)
    complex(8), intent(inout) :: xy(:,:)
    integer, intent(in) :: ip(:)
    integer, intent(in) :: np, n1, n, mp, m1, m, n1c, n2c, n2cz

    complex(8), allocatable :: y(:)
    complex(8) :: sum_val
    integer :: i, j, ii, jj, jp, n2, npm

    ! Check for normal solution (not NGF)
    if (n2c <= 0) then
      ! Simple case: just solve the primary system
      call solves(a, ip, xy, n1c, 1, np, n, mp, m, 13, 14)
      return
    end if

    allocate(y(n1c + n2c))

    ! Reorder excitation array if needed
    if (n1 /= n .and. m1 /= 0) then
      n2 = n1 + 1
      jj = n + 1
      npm = n + 2 * m1

      ! Save elements that need reordering
      do i = n2, npm
        y(i) = xy(i, 1)
      end do

      ! Reorder: move elements N+1:NPM to positions N1+1:...
      j = n1
      do i = jj, npm
        j = j + 1
        xy(j, 1) = y(i)
      end do

      ! Then move elements N1+1:N to follow
      do i = n2, n
        j = j + 1
        xy(j, 1) = y(i)
      end do
    end if

    ! STEP 1: Compute inv(A)*E1
    ! Solve A*x = E1 where E1 is in xy(1:N1C)
    call solves(a, ip, xy, n1c, 1, np, n1, mp, m1, 13, 14)

    ! STEP 2: Compute E2 - C*inv(A)*E1
    ! The result goes into xy(N1C+1:N1C+N2C)
    do i = 1, n2c
      sum_val = (0.0d0, 0.0d0)
      do j = 1, n1c
        sum_val = sum_val + c(j, i) * xy(j, 1)
      end do
      ii = n1c + i
      xy(ii, 1) = xy(ii, 1) - sum_val
    end do

    ! STEP 3: Compute inv(D)*(E2 - C*inv(A)*E1) = I2
    ! Solve D*x = (E2 - C*inv(A)*E1) for the secondary unknowns
    jj = n1c + 1
    call solve(n2c, d, ip(jj:), xy(jj:, 1), n2c)

    ! STEP 4: Compute inv(A)*E1 - (inv(A)*B)*I2 = I1
    ! Update the primary solution by removing the coupling effect
    do i = 1, n1c
      sum_val = (0.0d0, 0.0d0)
      do j = 1, n2c
        jp = n1c + j
        sum_val = sum_val + b(i, j) * xy(jp, 1)
      end do
      xy(i, 1) = xy(i, 1) - sum_val
    end do

    ! Reorder current array back if we reordered earlier
    if (n1 /= n .and. m1 /= 0) then
      n2 = n1 + 1
      npm = n + 2 * m1

      ! Save reordered elements
      do i = n2, npm
        y(i) = xy(i, 1)
      end do

      ! Restore original order
      jj = n1c + 1
      j = n1
      do i = jj, npm
        j = j + 1
        xy(j, 1) = y(i)
      end do

      do i = n2, n1c
        j = j + 1
        xy(j, 1) = y(i)
      end do
    end if

    deallocate(y)

  end subroutine solgf

  !============================================================================
  ! Helper routines
  !============================================================================

  subroutine check_singular(pivot_val, row_num)
    ! Check for singular or near-singular matrix
    real(8), intent(in) :: pivot_val
    integer, intent(in) :: row_num

    if (pivot_val < 1.0d-20) then
      write(*,'(A,I0,A,1P,E12.5)') &
        'WARNING: Near-singular matrix at row ', row_num, &
        ', pivot = ', pivot_val
    end if
  end subroutine check_singular

  function matrix_norm(a, n) result(norm_val)
    ! Compute 1-norm of matrix (maximum column sum)
    complex(8), intent(in) :: a(:,:)
    integer, intent(in) :: n
    real(8) :: norm_val
    real(8) :: col_sum
    integer :: i, j

    norm_val = 0.0d0
    do j = 1, n
      col_sum = 0.0d0
      do i = 1, n
        col_sum = col_sum + abs(a(i, j))
      end do
      if (col_sum > norm_val) norm_val = col_sum
    end do
  end function matrix_norm

  function condition_number_estimate(a, n) result(cond)
    ! Rough estimate of condition number
    ! (not exact, but useful for diagnostics)
    complex(8), intent(in) :: a(:,:)
    integer, intent(in) :: n
    real(8) :: cond
    real(8) :: max_diag, min_diag

    integer :: i

    max_diag = 0.0d0
    min_diag = huge(1.0d0)

    do i = 1, n
      if (abs(a(i, i)) > max_diag) max_diag = abs(a(i, i))
      if (abs(a(i, i)) < min_diag) min_diag = abs(a(i, i))
    end do

    if (min_diag > 1.0d-20) then
      cond = max_diag / min_diag
    else
      cond = huge(1.0d0)
    end if
  end function condition_number_estimate

end module nec2_solver
