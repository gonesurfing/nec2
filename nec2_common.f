C     MODULE NEC2_COMMON
C     Parameters only for NEC2D - NO COMMON blocks
C     COMMON blocks must be declared locally in each subroutine
C
      MODULE NEC2_COMMON
C
C     Include parameter definitions
      INCLUDE 'NEC2DPAR.INC'
      PARAMETER (IRESRV=MAXMAT**2)
C
      END MODULE NEC2_COMMON
