C     LFACTR.F - Out-of-core Gauss-Doolittle factorization subroutine
C
C     LFACTR performs Gauss-Doolittle manipulations on the two blocks of
C     the transposed matrix in core storage. The Gauss-Doolittle algorithm
C     is based on A. Ralston -- A First Course in Numerical Analysis,
C     pages 411-416. Handles partial pivoting and LU decomposition for
C     out-of-core matrix solutions.
C
      SUBROUTINE LFACTR (A,NROW,IX1,IX2,IP)
C ***
C     DOUBLE PRECISION 6/4/85
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     LFACTR PERFORMS GAUSS-DOOLITTLE MANIPULATIONS ON THE TWO BLOCKS OF
C     THE TRANSPOSED MATRIX IN CORE STORAGE.  THE GAUSS-DOOLITTLE
C     ALGORITHM IS PRESENTED ON PAGES 411-416 OF A. RALSTON -- A FIRST
C     COURSE IN NUMERICAL ANALYSIS.  COMMENTS BELOW REFER TO COMMENTS IN
C     RALSTONS TEXT.
C
      COMPLEX*16 A,D,AJR
      INTEGER R,R1,R2,PJ,PR
      LOGICAL L1,L2,L3
      COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,I
     1CASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
      COMMON /SCRATM/ D(2*MAXSEG)
      DIMENSION A(NROW,1), IP(NROW)
      IFLG=0
C
C     INITIALIZE R1,R2,J1,J2
C
      L1=IX1.EQ.1.AND.IX2.EQ.2
      L2=(IX2-1).EQ.IX1
      L3=IX2.EQ.NBLSYM
      IF (L1) GO TO 1
      GO TO 2
1     R1=1
      R2=2*NPSYM
      J1=1
      J2=-1
      GO TO 5
2     R1=NPSYM+1
      R2=2*NPSYM
      J1=(IX1-1)*NPSYM+1
      IF (L2) GO TO 3
      GO TO 4
3     J2=J1+NPSYM-2
      GO TO 5
4     J2=J1+NPSYM-1
5     IF (L3) R2=NPSYM+NLSYM
      DO 16 R=R1,R2
C
C     STEP 1
C
      DO 6 K=J1,NROW
      D(K)=A(K,R)
6     CONTINUE
C
C     STEPS 2 AND 3
C
      IF (L1.OR.L2) J2=J2+1
      IF (J1.GT.J2) GO TO 9
      IXJ=0
      DO 8 J=J1,J2
      IXJ=IXJ+1
      PJ=IP(J)
      AJR=D(PJ)
      A(J,R)=AJR
      D(PJ)=D(J)
      JP1=J+1
      DO 7 I=JP1,NROW
      D(I)=D(I)-A(I,IXJ)*AJR
7     CONTINUE
8     CONTINUE
9     CONTINUE
C
C     STEP 4
C
      J2P1=J2+1
      IF (L1.OR.L2) GO TO 11
      IF (NROW.LT.J2P1) GO TO 16
      DO 10 I=J2P1,NROW
      A(I,R)=D(I)
10    CONTINUE
      GO TO 16
11    DMAX=DREAL(D(J2P1)*DCONJG(D(J2P1)))
      IP(J2P1)=J2P1
      J2P2=J2+2
      IF (J2P2.GT.NROW) GO TO 13
      DO 12 I=J2P2,NROW
      ELMAG=DREAL(D(I)*DCONJG(D(I)))
      IF (ELMAG.LT.DMAX) GO TO 12
      DMAX=ELMAG
      IP(J2P1)=I
12    CONTINUE
13    CONTINUE
      IF (DMAX.LT.1.D-10) IFLG=1
      PR=IP(J2P1)
      A(J2P1,R)=D(PR)
      D(PR)=D(J2P1)
C
C     STEP 5
C
      IF (J2P2.GT.NROW) GO TO 15
      AJR=1./A(J2P1,R)
      DO 14 I=J2P2,NROW
      A(I,R)=D(I)*AJR
14    CONTINUE
15    CONTINUE
      IF (IFLG.EQ.0) GO TO 16
      WRITE(*,17)  J2,DMAX
      IFLG=0
16    CONTINUE
      RETURN
C
17    FORMAT (1H ,6HPIVOT(,I3,2H)=,1P,E16.8)
      END
