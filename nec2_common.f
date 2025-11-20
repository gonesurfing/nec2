C     MODULE NEC2_COMMON
C     Common parameter access for NEC2D
C     This module provides access to all parameters through NEC2_PARAMETERS
C     Each file declares its own COMMON blocks locally (standard F77 practice)
C
      MODULE NEC2_COMMON
C
C     Get all parameter definitions from parameters module
      USE NEC2_PARAMETERS
C
C     Use traditional implicit typing like main code
      IMPLICIT REAL*8(A-H,O-Z)
C
C     NO COMMON BLOCKS OR MODULE VARIABLES HERE
C     Each compilation unit (.f file) declares COMMON blocks locally
C     The linker resolves COMMON blocks across compilation units
C
      END MODULE NEC2_COMMON
