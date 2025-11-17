!***********************************************************************
!     NEC2D ISEGNO Function Module
!***********************************************************************
!     Contains the segment number lookup function
!***********************************************************************

MODULE nec2d_isegno
  USE nec2d_params
  USE nec2d_commons
  IMPLICIT NONE

  CONTAINS

!***********************************************************************
      FUNCTION ISEGNO (ITAGI,MX)
!***********************************************************************
!     ISEGNO RETURNS THE SEGMENT NUMBER OF THE MTH SEGMENT HAVING THE
!     TAG NUMBER ITAGI.  IF ITAGI=0 SEGMENT NUMBER M IS RETURNED.
!***********************************************************************
      IMPLICIT REAL*8(A-H,O-Z)
      INTEGER :: ISEGNO, ITAGI, MX, ICNT, I

      IF (MX.GT.0) GO TO 1
      WRITE(*,6)
      STOP
1     ICNT=0
      IF (ITAGI.NE.0) GO TO 2
      ISEGNO=MX
      RETURN
2     IF (N.LT.1) GO TO 4
      DO 3 I=1,N
      IF (ITAG(I).NE.ITAGI) GO TO 3
      ICNT=ICNT+1
      IF (ICNT.EQ.MX) GO TO 5
3     CONTINUE
4     WRITE(*,7)  ITAGI
      STOP
5     ISEGNO=I
      RETURN

6     FORMAT (4X,'CHECK DATA, PARAMETER SPECIFYING SEGMENT POSITION IN',&
     &' A GROUP OF EQUAL TAGS MUST NOT BE ZERO')
7     FORMAT (///,10X,'NO SEGMENT HAS AN ITAG OF ',I5)
      END FUNCTION ISEGNO

END MODULE nec2d_isegno
