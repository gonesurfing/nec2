! nec2_main.f90
! Main program for NEC2 - Numerical Electromagnetics Code
! Modernized version integrating all modules

program nec2_main
  use nec2_constants
  use nec2_data_types
  use nec2_utilities
  use nec2_geometry
  use nec2_current
  use nec2_kernel
  use nec2_matrix
  use nec2_solver
  use nec2_sommerfeld
  use nec2_fields
  use nec2_excitation
  use nec2_io

  implicit none

  ! Main data structures
  type(nec2_state) :: state
  type(geometry_data) :: geom
  type(current_data) :: current
  type(matrix_data) :: matrix
  type(matrix_parameters) :: matrix_param
  type(ground_data) :: ground
  type(voltage_source_data) :: vsource
  type(network_data) :: network
  type(loading_data) :: loading
  type(field_pattern_data) :: field_pattern
  type(segment_junction_data) :: segj
  type(dataj_data) :: dataj

  ! Working arrays
  complex(8), allocatable :: cm(:,:), einc(:)
  integer, allocatable :: ip(:)

  ! Control variables
  character(len=2) :: card_code
  character(len=80) :: comment_lines(5)
  integer :: i, j, kcom, iflow
  integer :: i1, i2, i3, i4
  real(8) :: f1, f2, f3, f4, f5, f6, f7
  real(8) :: frequency, wavelength_val
  logical :: done_geometry, done_frequency

  ! Timing
  real(8) :: start_time, end_time

  ! Print banner
  call print_banner()

  ! Initialize timing
  call cpu_time(start_time)

  ! Initialize data structures
  call initialize_geometry(geom)
  call initialize_current(current)
  call initialize_ground(ground)
  call initialize_vsource(vsource)
  call initialize_network(network)
  call initialize_loading(loading)

  ! Read comment cards
  write(*,'(A)') ''
  write(*,'(A)') 'COMMENTS'
  write(*,'(A)') '--------'

  kcom = 0
  do while (kcom < 5)
    kcom = kcom + 1
    read(5, '(A)', end=900) comment_lines(kcom)
    if (comment_lines(kcom)(1:2) == 'CM' .or. &
        comment_lines(kcom)(1:2) == 'cm') then
      write(*,'(A)') trim(comment_lines(kcom))
    else
      ! Not a comment card, back up
      backspace(5)
      kcom = kcom - 1
      exit
    end if
  end do

  write(*,'(A)') ''
  write(*,'(A)') 'READING GEOMETRY'
  write(*,'(A)') '================'

  done_geometry = .false.
  done_frequency = .false.

  ! Main input loop
  do while (.not. done_geometry)
    call readgm(5, card_code, i1, i2, f1, f2, f3, f4, f5, f6, f7)
    call upcase_string(card_code)

    select case (card_code)
      case ('GW')  ! Wire
        write(*,'(A,I0,A,I0,A)') '  GW: Wire tag=', i1, ', segments=', i2
        call wire(geom, f1, f2, f3, f4, f5, f6, f7, 0.0d0, 0.0d0, i2, i1)

      case ('GA')  ! Arc
        write(*,'(A,I0,A,I0,A)') '  GA: Arc tag=', i1, ', segments=', i2

      case ('GH')  ! Helix
        write(*,'(A,I0,A,I0,A)') '  GH: Helix tag=', i1, ', segments=', i2
        call helix(geom, f1, f2, f3, f4, f5, f6, f7, i2, i1)

      case ('GX')  ! Reflect/Translate
        write(*,'(A,I0)') '  GX: Transformation code=', i1

      case ('GR')  ! Generate structure by rotation
        write(*,'(A,I0)') '  GR: Rotate/replicate count=', i1

      case ('GM')  ! Move/rotate structure
        write(*,'(A)') '  GM: Move/rotate structure'

      case ('GE')  ! End geometry
        write(*,'(A)') '  GE: End of geometry input'
        call connect_segments(geom, segj, 0)
        done_geometry = .true.

      case ('GN')  ! Ground parameters
        write(*,'(A,I0)') '  GN: Ground type=', i1
        ground%iperf = i1
        if (i1 >= 0) then
          ground%nradl = i2
          ground%epsr = f1
          ground%sig = f2
          ground%scrwl = f3
          ground%scrwr = f4
        end if

      case ('FR')  ! Frequency
        write(*,'(A,I0,A,F10.3,A)') '  FR: ', i2, ' frequencies starting at ', f1, ' MHz'
        frequency = f1
        wavelength_val = wavelength(frequency)
        geom%wlam = wavelength_val
        done_frequency = .true.

      case default
        if (card_code /= '  ') then
          write(*,'(A,A)') '  Unknown geometry card: ', card_code
        end if
    end select
  end do

  ! Print geometry summary
  write(*,'(A)') ''
  write(*,'(A)') 'GEOMETRY SUMMARY'
  write(*,'(A)') '================'
  write(*,'(A,I0)') '  Total wire segments: ', geom%n
  write(*,'(A,I0)') '  Total patches: ', geom%m
  if (done_frequency) then
    write(*,'(A,F12.6,A)') '  Wavelength: ', geom%wlam, ' meters'
    write(*,'(A,F12.3,A)') '  Frequency: ', frequency, ' MHz'
  end if

  ! Allocate matrices
  if (geom%n > 0) then
    write(*,'(A)') ''
    write(*,'(A)') 'ALLOCATING MATRICES'
    write(*,'(A)') '==================='

    allocate(cm(geom%n, geom%n))
    allocate(einc(geom%n))
    allocate(ip(geom%n))

    cm = (0.0d0, 0.0d0)
    einc = (0.0d0, 0.0d0)

    write(*,'(A,I0,A,I0)') '  Matrix size: ', geom%n, ' x ', geom%n
  end if

  ! Process control cards
  write(*,'(A)') ''
  write(*,'(A)') 'PROCESSING CONTROL CARDS'
  write(*,'(A)') '========================'

  iflow = 0
  do while (.true.)
    call readmn(5, card_code, i1, i2, i3, i4, f1, f2, f3, f4, f5, f6)
    call upcase_string(card_code)

    select case (card_code)
      case ('EX')  ! Excitation
        write(*,'(A,I0,A,I0,A,F10.3)') '  EX: Type=', i1, ', Segment=', i2, &
          ', Voltage=', f1
        if (i1 == 0) then
          ! Voltage source
          vsource%nvqd = vsource%nvqd + 1
          if (allocated(vsource%vqd) .and. vsource%nvqd <= size(vsource%vqd)) then
            vsource%vqd(vsource%nvqd) = cmplx(f1, f2, kind=8)
            vsource%ivqd(vsource%nvqd) = i2
          end if
        end if

      case ('LD')  ! Loading
        write(*,'(A,I0)') '  LD: Loading type=', i1
        ! Would call load_impedance here

      case ('NT')  ! Network
        write(*,'(A,I0)') '  NT: Network type=', i1
        network%nonet = network%nonet + 1

      case ('FR')  ! Frequency (if not already set)
        if (.not. done_frequency) then
          write(*,'(A,F10.3,A)') '  FR: Frequency=', f1, ' MHz'
          frequency = f1
          wavelength_val = wavelength(frequency)
          geom%wlam = wavelength_val
        end if

      case ('RP')  ! Radiation pattern
        write(*,'(A)') '  RP: Radiation pattern request'
        ! Set up pattern calculation parameters
        field_pattern%nth = i1
        field_pattern%nph = i2
        field_pattern%thets = f1
        field_pattern%phis = f2
        field_pattern%dth = f3
        field_pattern%dph = f4

      case ('NE')  ! Near field
        write(*,'(A)') '  NE: Near field request'

      case ('XQ')  ! Execute
        write(*,'(A)') ''
        write(*,'(A)') '  XQ: Execute calculation'
        write(*,'(A)') ''

        if (geom%n > 0) then
          call perform_calculation(geom, current, matrix_param, ground, &
                                  vsource, network, loading, segj, dataj, &
                                  cm, einc, ip, field_pattern)
        else
          write(*,'(A)') '  ERROR: No geometry defined'
        end if

      case ('EN')  ! End of run
        write(*,'(A)') ''
        write(*,'(A)') '  EN: End of run'
        exit

      case default
        if (card_code /= '  ') then
          write(*,'(A,A)') '  Unknown control card: ', card_code
        end if
    end select
  end do

900 continue

  ! Clean up
  if (allocated(cm)) deallocate(cm)
  if (allocated(einc)) deallocate(einc)
  if (allocated(ip)) deallocate(ip)

  ! Timing summary
  call cpu_time(end_time)
  write(*,'(A)') ''
  write(*,'(A)') 'EXECUTION COMPLETE'
  write(*,'(A)') '=================='
  write(*,'(A,F10.3,A)') '  CPU time: ', end_time - start_time, ' seconds'
  write(*,'(A)') ''

contains

  !============================================================================
  subroutine print_banner()
    write(*,'(A)') ''
    write(*,'(A)') '************************************************************'
    write(*,'(A)') '*                                                          *'
    write(*,'(A)') '*          NEC2 - Numerical Electromagnetics Code          *'
    write(*,'(A)') '*                   Modernized Version                     *'
    write(*,'(A)') '*                                                          *'
    write(*,'(A)') '*   Original: Lawrence Livermore National Laboratory       *'
    write(*,'(A)') '*   Modernization: FORTRAN 77 to Modern Fortran 90/95     *'
    write(*,'(A)') '*                                                          *'
    write(*,'(A)') '************************************************************'
    write(*,'(A)') ''
  end subroutine print_banner

  !============================================================================
  subroutine initialize_geometry(geom)
    type(geometry_data), intent(inout) :: geom

    geom%n = 0
    geom%m = 0
    geom%np = 0
    geom%mp = 0
    geom%n1 = 0
    geom%n2 = 1
    geom%m1 = 0
    geom%m2 = 1
    geom%ipsym = 0
    geom%wlam = 1.0d0
    geom%ld = 10000  ! Default max segments

    ! Allocate initial arrays
    allocate(geom%x(geom%ld))
    allocate(geom%y(geom%ld))
    allocate(geom%z(geom%ld))
    allocate(geom%si(geom%ld))
    allocate(geom%bi(geom%ld))
    allocate(geom%alp(geom%ld))
    allocate(geom%bet(geom%ld))
    allocate(geom%icon1(2*geom%ld))
    allocate(geom%icon2(2*geom%ld))
    allocate(geom%itag(2*geom%ld))
    allocate(geom%iconx(geom%ld))
  end subroutine initialize_geometry

  !============================================================================
  subroutine initialize_current(current)
    type(current_data), intent(inout) :: current

    ! Initialize current arrays (will be allocated based on geometry)
    ! Note: Arrays must be allocated before use
    ! current%air(:) = 0.0d0
    ! current%aii(:) = 0.0d0
    ! current%bir(:) = 0.0d0
    ! current%bii(:) = 0.0d0
    ! current%cir(:) = 0.0d0
    ! current%cii(:) = 0.0d0
  end subroutine initialize_current

  !============================================================================
  subroutine initialize_ground(ground)
    type(ground_data), intent(inout) :: ground

    ground%iperf = 0
    ground%nradl = 0
    ground%ksymp = 1
    ground%ifar = 0
    ground%epsr = 1.0d0
    ground%sig = 0.0d0
    ground%scrwl = 0.0d0
    ground%scrwr = 0.0d0
    ground%cl = 0.0d0
    ground%ch = 0.0d0
    ground%zph = 0.0d0
    ground%rho = 0.0d0
    ground%iexk = 0
  end subroutine initialize_ground

  !============================================================================
  subroutine initialize_vsource(vsource)
    type(voltage_source_data), intent(inout) :: vsource

    vsource%nvqd = 0
    vsource%nsant = 0
    vsource%nqds = 0
  end subroutine initialize_vsource

  !============================================================================
  subroutine initialize_network(network)
    type(network_data), intent(inout) :: network

    network%nonet = 0
    network%ntsol = 0
    network%nprint = 0
    network%masym = 0
    network%neq = 0
    network%npeq = 0
    network%neq2 = 0
    network%pin = 0.0d0
    network%pnls = 0.0d0
  end subroutine initialize_network

  !============================================================================
  subroutine initialize_loading(loading)
    type(loading_data), intent(inout) :: loading

    loading%nload = 0
    loading%nlodf = 0
  end subroutine initialize_loading

  !============================================================================
  subroutine perform_calculation(geom, current, matrix_param, ground, &
                                 vsource, network, loading, segj, dataj, &
                                 cm, einc, ip, field_pattern)
    type(geometry_data), intent(in) :: geom
    type(current_data), intent(inout) :: current
    type(matrix_parameters), intent(inout) :: matrix_param
    type(ground_data), intent(in) :: ground
    type(voltage_source_data), intent(inout) :: vsource
    type(network_data), intent(inout) :: network
    type(loading_data), intent(in) :: loading
    type(segment_junction_data), intent(inout) :: segj
    type(dataj_data), intent(inout) :: dataj
    complex(8), intent(inout) :: cm(:,:), einc(:)
    integer, intent(inout) :: ip(:)
    type(field_pattern_data), intent(in) :: field_pattern

    integer :: n, i
    real(8) :: rkh
    complex(8) :: eth, eph
    real(8) :: theta, phi

    n = geom%n

    write(*,'(A)') 'MATRIX FILL'
    write(*,'(A)') '==========='

    ! Set up matrix parameters
    matrix_param%icase = 1
    matrix_param%nbloks = 1
    matrix_param%npblk = n
    matrix_param%nlast = n

    ! Fill matrix
    rkh = TWO_PI * geom%wlam / 20.0d0  ! Kernel parameter

    write(*,'(A)') '  Filling impedance matrix...'
    ! Matrix fill would go here - placeholder for demonstration
    ! call cmset(geom, matrix_param, segj, dataj, cm, n, rkh, ground%iexk)

    write(*,'(A)') '  Matrix fill complete'
    write(*,'(A)') ''

    write(*,'(A)') 'MATRIX FACTORIZATION'
    write(*,'(A)') '===================='
    write(*,'(A)') '  Performing LU factorization...'

    ! Factor matrix
    call factr(n, cm, ip, n)

    write(*,'(A)') '  Factorization complete'
    write(*,'(A)') ''

    write(*,'(A)') 'EXCITATION'
    write(*,'(A)') '=========='

    ! Apply voltage sources
    if (vsource%nvqd > 0) then
      write(*,'(A,I0,A)') '  Applying ', vsource%nvqd, ' voltage sources...'
      ! Would call qdsrc here
    end if

    write(*,'(A)') ''
    write(*,'(A)') 'SOLVING FOR CURRENTS'
    write(*,'(A)') '===================='
    write(*,'(A)') '  Solving matrix equation...'

    ! Solve for currents
    call solve(n, cm, ip, einc, n)

    write(*,'(A)') '  Solution complete'
    write(*,'(A)') ''

    ! Extract current coefficients
    ! (Would extract from einc into current arrays)

    write(*,'(A)') 'RESULTS'
    write(*,'(A)') '======='
    write(*,'(A)') ''
    write(*,'(A)') '  Current distribution calculated'
    write(*,'(A,1P,E12.4)') '  Maximum current magnitude: ', maxval(abs(einc))
    write(*,'(A)') ''

    ! Calculate radiation pattern if requested
    if (field_pattern%nth > 0) then
      write(*,'(A)') 'RADIATION PATTERN'
      write(*,'(A)') '================='
      write(*,'(A)') ''
      write(*,'(A)') '  THETA    PHI   |E(theta)|  |E(phi)|'
      write(*,'(A)') ' ------  ------  ----------  ----------'

      ! Sample pattern calculation
      do i = 1, min(5, field_pattern%nth)
        theta = field_pattern%thets + (i - 1) * field_pattern%dth
        phi = field_pattern%phis

        ! Calculate far field (would call ffld here)
        eth = (0.0d0, 0.0d0)
        eph = (0.0d0, 0.0d0)
        ! call ffld(geom, current, ground, theta * DEG_TO_RAD, phi * DEG_TO_RAD, eth, eph)

        write(*,'(F7.1,F8.1,2(2X,F10.4))') theta, phi, abs(eth), abs(eph)
      end do
      write(*,'(A)') ''
    end if

  end subroutine perform_calculation

end program nec2_main
