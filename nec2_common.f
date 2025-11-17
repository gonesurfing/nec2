C     MODULE NEC2_COMMON
C     Parameter definitions for NEC2D
C     This module contains ONLY parameters, NOT COMMON blocks or variables
C     Each file declares its own COMMON blocks locally (standard F77 practice)
C
      MODULE NEC2_COMMON
C
C     Include parameter definitions
      INCLUDE 'NEC2DPAR.INC'
      PARAMETER (IRESRV=MAXMAT**2)
C
C     Use traditional implicit typing like main code
      IMPLICIT REAL*8(A-H,O-Z)
C
C     NO COMMON BLOCKS OR MODULE VARIABLES HERE
C     Each compilation unit (.f file) declares COMMON blocks locally
C     The linker resolves COMMON blocks across compilation units
C
      END MODULE NEC2_COMMON
