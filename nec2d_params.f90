!***********************************************************************
!     NEC2D Parameter Module
!***********************************************************************
!     Converted from NEC2D3000.INC and NEC2DPAR.INC
!     Defines dimensional parameters for NEC2D arrays
!***********************************************************************

module nec2d_params
  implicit NONE

  ! Main dimensional parameters
  integer, parameter :: MAXSEG = 3000    ! Maximum number of segments
  integer, parameter :: MAXMAT = 3000    ! Maximum matrix dimension
  integer, parameter :: LOADMX = MAXSEG/10  ! Maximum number of loads
  integer, parameter :: NSMAX  = 120     ! Maximum voltage sources
  integer, parameter :: NETMX  = 240     ! Maximum network connections
  integer, parameter :: JMAX   = 60      ! Maximum number of junctions

  ! Derived parameter for matrix storage
  integer, parameter :: IRESRV = MAXMAT**2  ! Reserved matrix storage

end module nec2d_params
