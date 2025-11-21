C     SOLVE_UTILS.F - Matrix and solver utility routines for NEC2D
C
C     This file contains utility subroutines for matrix setup, factorization,
C     and solution operations including:
C     - REBLK: Reblock array for NGF
C     - SOLVE: Basic LU solve
C
C     Extracted to separate files:
C     - CMSET: cmset.f
C     - CMSW: cmsw.f
C     - CMWW: cmww.f
C     - SOLVES: solves.f
C     - SOLGF: solgf.f
C     - LFACTR: lfactr.f
C     - CMSS: cmss.f
C     - CMWS: cmws.f
C     - FACGF: facgf.f
C     - FACTR: factr.f
C     - FACTRS: factrs.f
C     - FBLOCK: fblock.f
C     - FBNGF: fbngf.f
C     - LTSOLV: ltsolv.f
C     - LUNSCR: lunscr.f
C     - FACIO: facio.f
C
      MODULE NEC2_SOLVE
      END MODULE NEC2_SOLVE
C
      SUBROUTINE REBLK (B,BX,NB,NBX,N2C)
C ***
C     DOUBLE PRECISION 6/4/85
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C     REBLOCK ARRAY B IN N.G.F. SOLUTION FROM BLOCKS OF ROWS ON TAPE14
C     TO BLOCKS OF COLUMNS ON TAPE16
      COMPLEX*16 B,BX
      COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,I
     1CASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
      DIMENSION B(NB,1), BX(NBX,1)
      REWIND 16
      NIB=0
      NPB=NPBL
      DO 3 IB=1,NBBL
      IF (IB.EQ.NBBL) NPB=NLBL
      REWIND 14
      NIX=0
      NPX=NPBX
      DO 2 IBX=1,NBBX
      IF (IBX.EQ.NBBX) NPX=NLBX
      READ (14) ((BX(I,J),I=1,NPX),J=1,N2C)
      DO 1 I=1,NPX
      IX=I+NIX
      DO 1 J=1,NPB
1     B(IX,J)=BX(I,J+NIB)
2     NIX=NIX+NPBX
      WRITE (16) ((B(I,J),I=1,NB),J=1,NPB)
3     NIB=NIB+NPBL
      REWIND 14
      REWIND 16
      RETURN
      END
      SUBROUTINE SOLVE (N,A,IP,B,NDIM)
C ***
C     DOUBLE PRECISION 6/4/85
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     SUBROUTINE TO SOLVE THE MATRIX EQUATION LU*X=B WHERE L IS A UNIT
C     LOWER TRIANGULAR MATRIX AND U IS AN UPPER TRIANGULAR MATRIX BOTH
C     OF WHICH ARE STORED IN A.  THE RHS VECTOR B IS INPUT AND THE
C     SOLUTION IS RETURNED THROUGH VECTOR B.
C
      COMPLEX*16 A,B,Y,SUM
      INTEGER PI
      COMMON /SCRATM/ Y(2*MAXSEG)
      DIMENSION A(NDIM,NDIM), IP(NDIM), B(NDIM)
C
C     FORWARD SUBSTITUTION
C
      DO 3 I=1,N
      PI=IP(I)
      Y(I)=B(PI)
      B(PI)=B(I)
      IP1=I+1
      IF (IP1.GT.N) GO TO 2
      DO 1 J=IP1,N
      B(J)=B(J)-A(J,I)*Y(I)
1     CONTINUE
2     CONTINUE
3     CONTINUE
C
C     BACKWARD SUBSTITUTION
C
      DO 6 K=1,N
      I=N-K+1
      SUM=(0.,0.)
      IP1=I+1
      IF (IP1.GT.N) GO TO 5
      DO 4 J=IP1,N
      SUM=SUM+A(I,J)*B(J)
4     CONTINUE
5     CONTINUE
      B(I)=(Y(I)-SUM)/A(I,I)
6     CONTINUE
      RETURN
      END
