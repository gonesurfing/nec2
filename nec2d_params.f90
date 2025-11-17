!***********************************************************************
!     NEC2D Parameter Module
!***********************************************************************
!     Converted from NEC2D3000.INC and NEC2DPAR.INC
!     Defines dimensional parameters for NEC2D arrays
!***********************************************************************

MODULE nec2d_params
  IMPLICIT NONE

  ! Main dimensional parameters
  INTEGER, PARAMETER :: MAXSEG = 3000    ! Maximum number of segments
  INTEGER, PARAMETER :: MAXMAT = 3000    ! Maximum matrix dimension
  INTEGER, PARAMETER :: LOADMX = MAXSEG/10  ! Maximum number of loads
  INTEGER, PARAMETER :: NSMAX  = 120     ! Maximum voltage sources
  INTEGER, PARAMETER :: NETMX  = 240     ! Maximum network connections
  INTEGER, PARAMETER :: JMAX   = 60      ! Maximum number of junctions

  ! Derived parameter for matrix storage
  INTEGER, PARAMETER :: IRESRV = MAXMAT**2  ! Reserved matrix storage

END MODULE nec2d_params
