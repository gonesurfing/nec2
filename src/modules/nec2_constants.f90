! nec2_constants.f90
! Physical and numerical constants used throughout NEC2
! This is the first module to create - it has no dependencies

module nec2_constants
  implicit none
  public

  ! Mathematical constants
  real(8), parameter :: PI = 3.141592654d0
  real(8), parameter :: TWO_PI = 6.283185308d0  ! TP in original
  real(8), parameter :: PI_OVER_2 = 1.5707963d0
  real(8), parameter :: FOUR_PI = 12.56637061d0

  ! Degrees/radians conversion
  real(8), parameter :: DEG_TO_RAD = 0.01745329252d0  ! TA in original
  real(8), parameter :: RAD_TO_DEG = 57.29577951d0    ! TD in original

  ! Physical constants
  real(8), parameter :: SPEED_OF_LIGHT = 299.8d0  ! m/μs (CVEL in original)
  real(8), parameter :: ETA_0 = 376.73d0          ! Free space impedance (ohms)
  real(8), parameter :: RETA = 2.654420938d-3     ! 1/ETA_0

  ! Euler's constant
  real(8), parameter :: EULER_GAMMA = 0.5772156649d0

  ! Numerical tolerances
  real(8), parameter :: SMIN = 1.0d-3       ! Minimum separation
  real(8), parameter :: ACCS = 1.0d-12      ! Accuracy for convergence
  real(8), parameter :: CRIT = 1.0d-4       ! Critical value for iteration
  real(8), parameter :: RX_TOL = 1.0d-4     ! ROM1 tolerance

  ! Integration parameters
  integer, parameter :: MAXH = 20           ! Max Romberg steps
  integer, parameter :: NORMF = 200         ! Normalization factor
  integer, parameter :: NM_ROM = 131072     ! ROM1 maximum points
  integer, parameter :: NTS_ROM = 4         ! ROM1 step parameter

  ! Bessel function constants
  real(8), parameter :: TOSP = 1.128379167d0
  real(8), parameter :: SP = 1.772453851d0

  ! Complex constants
  complex(8), parameter :: J_UNIT = (0.0d0, 1.0d0)  ! FJ in original
  complex(8), parameter :: CCJ = (0.0d0, -0.01666666667d0)

  ! Hankel function initialization constants
  real(8), parameter :: POF = 0.7853981635d0
  real(8), parameter :: PTP = 6.283185308d0

  ! BESSEL/HANKEL function coefficients
  real(8), parameter :: C1_BH = -0.024578509d0
  real(8), parameter :: C2_BH = 0.0d0  ! Placeholder
  real(8), parameter :: C3_BH = 0.7978845608d0

  real(8), parameter :: P10 = 0.0703125d0
  real(8), parameter :: P11 = 0.1171875d0
  real(8), parameter :: P20 = 0.1121519633d0
  real(8), parameter :: P21 = 0.1441955566d0

  real(8), parameter :: Q10 = 0.125d0
  real(8), parameter :: Q11 = 0.375d0
  real(8), parameter :: Q20 = 0.0732421875d0
  real(8), parameter :: Q21 = 0.1025390625d0

  ! Grid array parameters
  integer, parameter :: NXA_DIM = 3
  integer, parameter :: NYA_DIM = 3
  integer, dimension(3), parameter :: NXA = [11, 17, 9]
  integer, dimension(3), parameter :: NYA = [10, 5, 8]
  real(8), dimension(3), parameter :: XSA = [0.0d0, 0.2d0, 0.2d0]
  real(8), dimension(3), parameter :: YSA = [0.0d0, 0.0d0, 0.3490658504d0]
  real(8), dimension(3), parameter :: DXA = [0.02d0, 0.05d0, 0.1d0]
  real(8), dimension(3), parameter :: DYA = [0.1745329252d0, 0.0872664626d0, 0.1745329252d0]

  ! Special constants for kernel calculations
  real(8), parameter :: CONX_REAL = 0.0d0
  real(8), parameter :: CONX_IMAG = 4.771341189d0
  complex(8), parameter :: CONX = cmplx(CONX_REAL, CONX_IMAG, kind=8)

  ! Maximum iterations
  integer, parameter :: NPMAX = 10  ! Max iterations for coupling

contains

  ! Helper functions for common conversions

  pure function to_radians(degrees) result(radians)
    real(8), intent(in) :: degrees
    real(8) :: radians
    radians = degrees * DEG_TO_RAD
  end function to_radians

  pure function to_degrees(radians) result(degrees)
    real(8), intent(in) :: radians
    real(8) :: degrees
    degrees = radians * RAD_TO_DEG
  end function to_degrees

  pure function wavelength(freq_mhz) result(lambda)
    ! Calculate wavelength in meters from frequency in MHz
    real(8), intent(in) :: freq_mhz
    real(8) :: lambda
    lambda = SPEED_OF_LIGHT / freq_mhz
  end function wavelength

end module nec2_constants
