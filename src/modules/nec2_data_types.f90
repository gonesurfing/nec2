! nec2_data_types.f90
! Derived types to replace all COMMON blocks from nec2dxs.f
! This module defines the core data structures used throughout NEC2

module nec2_data_types
  use nec2_constants
  implicit none
  public

  ! Default array sizes (can be made allocatable for flexibility)
  integer, parameter :: DEFAULT_MAXSEG = 3000
  integer, parameter :: DEFAULT_MAXMAT = 3000
  integer, parameter :: DEFAULT_LOADMX = 300
  integer, parameter :: DEFAULT_NSMAX = 120
  integer, parameter :: DEFAULT_NETMX = 240
  integer, parameter :: DEFAULT_JMAX = 60

  !============================================================================
  ! GEOMETRY DATA (replaces COMMON /DATA/)
  !============================================================================
  type :: geometry_data
    ! Segment coordinates and properties
    real(8), allocatable :: x(:)        ! X coordinates of segment centers
    real(8), allocatable :: y(:)        ! Y coordinates
    real(8), allocatable :: z(:)        ! Z coordinates
    real(8), allocatable :: si(:)       ! Segment lengths
    real(8), allocatable :: bi(:)       ! Segment radii
    real(8), allocatable :: alp(:)      ! Alpha direction cosines
    real(8), allocatable :: bet(:)      ! Beta direction cosines

    ! Connectivity information
    integer, allocatable :: icon1(:)    ! Connection data 1
    integer, allocatable :: icon2(:)    ! Connection data 2
    integer, allocatable :: itag(:)     ! Segment tags
    integer, allocatable :: iconx(:)    ! Connection index

    ! Wavelength and counts
    real(8) :: wlam                     ! Wavelength

    ! Dimensions and indices
    integer :: ld                       ! Leading dimension
    integer :: n1, n2                   ! Wire segment indices
    integer :: n                        ! Total wire segments
    integer :: np                       ! Total segments including patches
    integer :: m1, m2                   ! Patch indices
    integer :: m                        ! Total patches
    integer :: mp                       ! Total patches (alternate)
    integer :: ipsym                    ! Symmetry flag
  end type geometry_data

  !============================================================================
  ! MATRIX DATA (replaces COMMON /CMB/)
  !============================================================================
  type :: matrix_data
    complex(8), allocatable :: cm(:)    ! Matrix storage (IRESRV size)
  end type matrix_data

  !============================================================================
  ! MATRIX PARAMETERS (replaces COMMON /MATPAR/)
  !============================================================================
  type :: matrix_parameters
    integer :: icase                    ! Case number
    integer :: nbloks                   ! Number of blocks
    integer :: npblk                    ! N per block
    integer :: nlast                    ! Last block size
    integer :: nblsym                   ! Symmetric block count
    integer :: npsym                    ! N per symmetric block
    integer :: nlsym                    ! Last symmetric block size
    integer :: imat                     ! Matrix flag
    integer :: icasx                    ! Case X
    integer :: nbbx, npbx, nlbx         ! Block parameters X
    integer :: nbbl, npbl, nlbl         ! Block parameters L
  end type matrix_parameters

  !============================================================================
  ! SAVE DATA (replaces COMMON /SAVE/)
  !============================================================================
  type :: save_data
    real(8) :: epsr                     ! Relative permittivity
    real(8) :: sig                      ! Conductivity
    real(8) :: scrwlt                   ! Screen wire left thickness
    real(8) :: scrwrt                   ! Screen wire right thickness
    real(8) :: fmhz                     ! Frequency in MHz
    integer, allocatable :: ip(:)       ! Integer parameters array
    integer :: kcom                     ! Command counter
  end type save_data

  !============================================================================
  ! COMMAND SAVE (replaces COMMON /CSAVE/)
  !============================================================================
  type :: command_save_data
    real(8) :: com(19,5)                ! Command data storage
  end type command_save_data

  !============================================================================
  ! CURRENT DATA (replaces COMMON /CRNT/)
  !============================================================================
  type :: current_data
    real(8), allocatable :: air(:)      ! Current coefficients - real part A
    real(8), allocatable :: aii(:)      ! Current coefficients - imag part A
    real(8), allocatable :: bir(:)      ! Current coefficients - real part B
    real(8), allocatable :: bii(:)      ! Current coefficients - imag part B
    real(8), allocatable :: cir(:)      ! Current coefficients - real part C
    real(8), allocatable :: cii(:)      ! Current coefficients - imag part C
    complex(8), allocatable :: cur(:)   ! Total current array
  end type current_data

  !============================================================================
  ! GROUND PARAMETERS (replaces COMMON /GND/)
  !============================================================================
  type :: ground_data
    complex(8) :: zrati                 ! Impedance ratio
    complex(8) :: zrati2                ! Impedance ratio 2
    complex(8) :: frati                 ! F ratio
    complex(8) :: t1, t2                ! Ground reflection coefficients
    real(8) :: cl, ch                   ! Cliff/cliff height parameters
    real(8) :: scrwl, scrwr             ! Screen wire parameters
    integer :: nradl                    ! Number of radial wires
    integer :: ksymp                    ! Symmetry parameter
    integer :: ifar                     ! Far field flag
    integer :: iperf                    ! Perfect ground flag (1=perfect, 0=real)
  end type ground_data

  !============================================================================
  ! LOADING DATA (replaces COMMON /ZLOAD/)
  !============================================================================
  type :: loading_data
    complex(8), allocatable :: zarray(:)  ! Loading impedance array
    integer :: nload                      ! Number of loads
    integer :: nlodf                      ! Load flag
  end type loading_data

  !============================================================================
  ! Y-PARAMETER DATA (replaces COMMON /YPARM/)
  !============================================================================
  type :: yparm_data
    complex(8) :: y11a(5)               ! Y11 parameters
    complex(8) :: y12a(20)              ! Y12 parameters
    integer :: ncoup                    ! Number of coupling calculations
    integer :: icoup                    ! Coupling index
    integer :: nctag(5)                 ! Coupling tags
    integer :: ncseg(5)                 ! Coupling segments
  end type yparm_data

  !============================================================================
  ! SEGMENT JUNCTION DATA (replaces COMMON /SEGJ/)
  !============================================================================
  type :: segment_junction_data
    real(8), allocatable :: ax(:)       ! A coefficients X
    real(8), allocatable :: bx(:)       ! B coefficients X
    real(8), allocatable :: cx(:)       ! C coefficients X
    integer, allocatable :: jco(:)      ! Junction connection
    integer :: jsno                     ! Junction segment number
    integer :: iscon(50)                ! Connection indices
    integer :: nscon                    ! Number of segment connections
    integer :: ipcon(10)                ! Patch connections
    integer :: npcon                    ! Number of patch connections
  end type segment_junction_data

  !============================================================================
  ! VOLTAGE SOURCE DATA (replaces COMMON /VSORC/)
  !============================================================================
  type :: voltage_source_data
    complex(8), allocatable :: vqd(:)   ! Voltage applied (general)
    complex(8), allocatable :: vsant(:) ! Voltage source antenna
    complex(8), allocatable :: vqds(:)  ! Voltage applied (special)
    integer, allocatable :: ivqd(:)     ! Voltage segment index
    integer, allocatable :: isant(:)    ! Source antenna index
    integer, allocatable :: iqds(:)     ! Special source index
    integer :: nvqd                     ! Number of general voltages
    integer :: nsant                    ! Number of antenna sources
    integer :: nqds                     ! Number of special sources
  end type voltage_source_data

  !============================================================================
  ! NETWORK CONNECTION DATA (replaces COMMON /NETCX/)
  !============================================================================
  type :: network_data
    complex(8) :: zped                  ! Impedance pedestal
    real(8) :: pin                      ! Input power
    real(8) :: pnls                     ! Power NLS
    real(8), allocatable :: x11r(:)     ! Network parameter X11 real
    real(8), allocatable :: x11i(:)     ! Network parameter X11 imag
    real(8), allocatable :: x12r(:)     ! Network parameter X12 real
    real(8), allocatable :: x12i(:)     ! Network parameter X12 imag
    real(8), allocatable :: x22r(:)     ! Network parameter X22 real
    real(8), allocatable :: x22i(:)     ! Network parameter X22 imag
    integer, allocatable :: ntyp(:)     ! Network type
    integer, allocatable :: iseg1(:)    ! Segment 1
    integer, allocatable :: iseg2(:)    ! Segment 2
    integer :: neq                      ! Number of equations
    integer :: npeq                     ! N per equation
    integer :: neq2                     ! Number of equations 2
    integer :: nonet                    ! Number of networks
    integer :: ntsol                    ! Network solution flag
    integer :: nprint                   ! Print flag
    integer :: masym                    ! Matrix asymmetry flag
  end type network_data

  !============================================================================
  ! FIELD PATTERN DATA (replaces COMMON /FPAT/)
  !============================================================================
  type :: field_pattern_data
    real(8) :: thets                    ! Theta start
    real(8) :: phis                     ! Phi start
    real(8) :: dth                      ! Delta theta
    real(8) :: dph                      ! Delta phi
    real(8) :: rfld                     ! Field distance
    real(8) :: gnor                     ! Gain normalization
    real(8) :: clt, cht                 ! Cliff parameters
    real(8) :: epsr2, sig2              ! Ground parameters
    real(8) :: xpr6                     ! Extra parameter 6
    real(8) :: pinr, pnlr               ! Power parameters
    real(8) :: ploss                    ! Power loss
    real(8) :: xnr, ynr, znr            ! Near field position
    real(8) :: dxnr, dynr, dznr         ! Near field increments
    integer :: nth, nph                 ! Number of theta, phi points
    integer :: ipd                      ! Polarization flag
    integer :: iavp                     ! Average power flag
    integer :: inor                     ! Normalization flag
    integer :: iax                      ! Axis flag
    integer :: ixtyp                    ! Excitation type
    integer :: near                     ! Near field flag
    integer :: nfeh                     ! Near field E/H flag
    integer :: nrx, nry, nrz            ! Near field grid points
  end type field_pattern_data

  !============================================================================
  ! GROUND GRID DATA (replaces COMMON /GGRID/)
  !============================================================================
  type :: ground_grid_data
    complex(8) :: ar1(11,10,4)          ! Array 1
    complex(8) :: ar2(17,5,4)           ! Array 2
    complex(8) :: ar3(9,8,4)            ! Array 3
    complex(8) :: epscf                 ! Epsilon factor
    real(8) :: dxa(3), dya(3)           ! Grid spacing
    real(8) :: xsa(3), ysa(3)           ! Grid start
    integer :: nxa(3), nya(3)           ! Grid dimensions
  end type ground_grid_data

  !============================================================================
  ! GROUND WAVE DATA (replaces COMMON /GWAV/)
  !============================================================================
  type :: ground_wave_data
    complex(8) :: u, u2                 ! U parameters
    complex(8) :: xx1, xx2              ! X parameters
    real(8) :: r1, r2                   ! Distances
    real(8) :: zmh, zph                 ! Heights
  end type ground_wave_data

  !============================================================================
  ! PLOT DATA (replaces COMMON /PLOT/)
  !============================================================================
  type :: plot_data
    integer :: iplp1, iplp2, iplp3, iplp4  ! Plot flags
  end type plot_data

  !============================================================================
  ! EVALUATION COMMON DATA (replaces COMMON /EVLCOM/)
  !============================================================================
  type :: evaluation_data
    complex(8) :: cksm                  ! Checksum
    complex(8) :: ct1, ct2, ct3         ! C parameters
    complex(8) :: ck1, ck2              ! CK parameters
    complex(8) :: ck1sq, ck2sq          ! CK squared
    real(8) :: tkmag, tsmag             ! Magnitudes
    complex(8) :: ct              ! Additional parameter
  end type evaluation_data

  !============================================================================
  ! CONTOUR DATA (replaces COMMON /CNTOUR/)
  !============================================================================
  type :: contour_data
    real(8) :: a, b                     ! Contour parameters
  end type contour_data

  !============================================================================
  ! ANGLE DATA (replaces COMMON /ANGL/)
  !============================================================================
  type :: angle_data
    real(8), allocatable :: salp(:)     ! Sin(alpha) array
  end type angle_data

  !============================================================================
  ! DATA J (replaces COMMON /DATAJ/)
  !============================================================================
  type :: dataj_data
    real(8) :: s, b                     ! Segment length and radius (also b=t2x for patches)
    real(8) :: xj, yj, zj               ! Junction coordinates
    real(8) :: cabj, sabj, salpj        ! Direction cosines (also t1x, t1y, t1z for patches)
    complex(8) :: exk, eyk, ezk         ! E field components (kernel)
    complex(8) :: exs, eys, ezs         ! E field components (source)
    complex(8) :: exc, eyc, ezc         ! E field components (constant)
    real(8) :: rkh                      ! R*k for H field
    real(8) :: t2y, t2z                 ! Second tangent vector for patches (t2x=b)
    integer :: iexk, ipgnd              ! Field type flag, ground plane flag
  end type dataj_data

  !============================================================================
  ! SMALL MATRIX DATA (replaces COMMON /SMAT/)
  !============================================================================
  type :: small_matrix_data
    real(8) :: ssx(16,16)               ! Small matrix storage
  end type small_matrix_data

  !============================================================================
  ! SCRATCH MATRIX (replaces COMMON /SCRATM/)
  !============================================================================
  type :: scratch_matrix_data
    real(8), allocatable :: d(:)        ! Scratch array
  end type scratch_matrix_data

  !============================================================================
  ! MASTER STRUCTURE - Contains all data
  !============================================================================
  type :: nec2_state
    type(geometry_data) :: geom
    type(matrix_data) :: matrix
    type(matrix_parameters) :: matpar
    type(save_data) :: save
    type(command_save_data) :: csave
    type(current_data) :: current
    type(ground_data) :: ground
    type(loading_data) :: loading
    type(yparm_data) :: yparm
    type(segment_junction_data) :: segj
    type(voltage_source_data) :: vsource
    type(network_data) :: network
    type(field_pattern_data) :: fpat
    type(ground_grid_data) :: ggrid
    type(ground_wave_data) :: gwave
    type(plot_data) :: plot
    type(evaluation_data) :: evlcom
    type(contour_data) :: contour
    type(angle_data) :: angle
    type(dataj_data) :: dataj
    type(small_matrix_data) :: smat
    type(scratch_matrix_data) :: scratch
  end type nec2_state

contains

  !============================================================================
  ! INITIALIZATION ROUTINES
  !============================================================================

  subroutine init_geometry_data(geom, maxseg)
    type(geometry_data), intent(inout) :: geom
    integer, intent(in) :: maxseg

    allocate(geom%x(maxseg))
    allocate(geom%y(maxseg))
    allocate(geom%z(maxseg))
    allocate(geom%si(maxseg))
    allocate(geom%bi(maxseg))
    allocate(geom%alp(maxseg))
    allocate(geom%bet(maxseg))
    allocate(geom%icon1(2*maxseg))
    allocate(geom%icon2(2*maxseg))
    allocate(geom%itag(2*maxseg))
    allocate(geom%iconx(maxseg))

    ! Initialize to zero
    geom%x = 0.0d0
    geom%y = 0.0d0
    geom%z = 0.0d0
    geom%si = 0.0d0
    geom%bi = 0.0d0
    geom%alp = 0.0d0
    geom%bet = 0.0d0
    geom%icon1 = 0
    geom%icon2 = 0
    geom%itag = 0
    geom%iconx = 0

    geom%wlam = 0.0d0
    geom%ld = maxseg
    geom%n1 = 0
    geom%n2 = 0
    geom%n = 0
    geom%np = 0
    geom%m1 = 0
    geom%m2 = 0
    geom%m = 0
    geom%mp = 0
    geom%ipsym = 0
  end subroutine init_geometry_data

  subroutine init_current_data(current, maxseg)
    type(current_data), intent(inout) :: current
    integer, intent(in) :: maxseg

    allocate(current%air(maxseg))
    allocate(current%aii(maxseg))
    allocate(current%bir(maxseg))
    allocate(current%bii(maxseg))
    allocate(current%cir(maxseg))
    allocate(current%cii(maxseg))
    allocate(current%cur(3*maxseg))

    current%air = 0.0d0
    current%aii = 0.0d0
    current%bir = 0.0d0
    current%bii = 0.0d0
    current%cir = 0.0d0
    current%cii = 0.0d0
    current%cur = (0.0d0, 0.0d0)
  end subroutine init_current_data

  subroutine init_loading_data(loading, maxseg)
    type(loading_data), intent(inout) :: loading
    integer, intent(in) :: maxseg

    allocate(loading%zarray(maxseg))
    loading%zarray = (0.0d0, 0.0d0)
    loading%nload = 0
    loading%nlodf = 0
  end subroutine init_loading_data

  subroutine init_nec2_state(state, maxseg, maxmat)
    type(nec2_state), intent(inout) :: state
    integer, intent(in) :: maxseg, maxmat
    integer :: iresrv

    iresrv = maxmat * maxmat

    ! Initialize geometry
    call init_geometry_data(state%geom, maxseg)

    ! Initialize matrix
    allocate(state%matrix%cm(iresrv))
    state%matrix%cm = (0.0d0, 0.0d0)

    ! Initialize current
    call init_current_data(state%current, maxseg)

    ! Initialize loading
    call init_loading_data(state%loading, maxseg)

    ! Initialize other structures...
    ! (Additional initialization can be added as needed)
  end subroutine init_nec2_state

  !============================================================================
  ! CLEANUP ROUTINES
  !============================================================================

  subroutine cleanup_geometry_data(geom)
    type(geometry_data), intent(inout) :: geom

    if (allocated(geom%x)) deallocate(geom%x)
    if (allocated(geom%y)) deallocate(geom%y)
    if (allocated(geom%z)) deallocate(geom%z)
    if (allocated(geom%si)) deallocate(geom%si)
    if (allocated(geom%bi)) deallocate(geom%bi)
    if (allocated(geom%alp)) deallocate(geom%alp)
    if (allocated(geom%bet)) deallocate(geom%bet)
    if (allocated(geom%icon1)) deallocate(geom%icon1)
    if (allocated(geom%icon2)) deallocate(geom%icon2)
    if (allocated(geom%itag)) deallocate(geom%itag)
    if (allocated(geom%iconx)) deallocate(geom%iconx)
  end subroutine cleanup_geometry_data

  subroutine cleanup_nec2_state(state)
    type(nec2_state), intent(inout) :: state

    call cleanup_geometry_data(state%geom)
    if (allocated(state%matrix%cm)) deallocate(state%matrix%cm)
    if (allocated(state%current%air)) deallocate(state%current%air)
    if (allocated(state%current%aii)) deallocate(state%current%aii)
    if (allocated(state%current%bir)) deallocate(state%current%bir)
    if (allocated(state%current%bii)) deallocate(state%current%bii)
    if (allocated(state%current%cir)) deallocate(state%current%cir)
    if (allocated(state%current%cii)) deallocate(state%current%cii)
    if (allocated(state%current%cur)) deallocate(state%current%cur)
    if (allocated(state%loading%zarray)) deallocate(state%loading%zarray)
    ! Add more cleanup as needed
  end subroutine cleanup_nec2_state

end module nec2_data_types
