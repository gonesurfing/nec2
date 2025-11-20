C     MODULE NEC2_PARAMETERS
C     Parameter definitions for NEC2D array sizes
C
C     This module replaces the NEC2DPAR.INC and NEC2Dxxxx.INC files
C     To change array sizes, modify the MAXSEG/MAXMAT values below
C
C     Available configurations:
C       500  segments:  MAXSEG=500,   NSMAX=60,  NETMX=60
C       1500 segments:  MAXSEG=1500,  NSMAX=120, NETMX=120
C       3000 segments:  MAXSEG=3000,  NSMAX=120, NETMX=240 (default)
C       5000 segments:  MAXSEG=5000,  NSMAX=120, NETMX=240
C       8000 segments:  MAXSEG=8000,  NSMAX=120, NETMX=240
C       11000 segments: MAXSEG=11000, NSMAX=240, NETMX=240
C
      MODULE NEC2_PARAMETERS
C
C     Primary size parameters - modify these for different configurations
      PARAMETER (MAXSEG=3000, MAXMAT=3000)
C
C     Derived parameters
      PARAMETER (LOADMX=MAXSEG/10)
      PARAMETER (NSMAX=120)
      PARAMETER (NETMX=240)
      PARAMETER (JMAX=60)
C
C     Matrix storage size
      PARAMETER (IRESRV=MAXMAT**2)
C
      END MODULE NEC2_PARAMETERS
