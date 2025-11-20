!***********************************************************************
!     NEC2D Parameter Module
!***********************************************************************
!     Converted from NEC2D3000.INC and NEC2DPAR.INC
!     Defines dimensional parameters for NEC2D arrays
!***********************************************************************

module nec2d_params
  implicit none

  ! Main dimensional parameters
  integer, parameter :: maxseg = 3000    ! Maximum number of segments
  integer, parameter :: maxmat = 3000    ! Maximum matrix dimension
  integer, parameter :: loadmx = maxseg/10  ! Maximum number of loads
  integer, parameter :: nsmax  = 120     ! Maximum voltage sources
  integer, parameter :: netmx  = 240     ! Maximum network connections
  integer, parameter :: jmax   = 60      ! Maximum number of junctions

  ! Derived parameter for matrix storage
  integer, parameter :: iresrv = maxmat**2  ! Reserved matrix storage

end module nec2d_params
