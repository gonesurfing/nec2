C     SOLVES.F - Symmetric structure matrix solve subroutine
C
C     SOLVES handles the transformation of the right hand side vector and
C     solution of the matrix equation for symmetric structures. It transforms
C     the RHS vector according to symmetry modes, solves each mode equation,
C     and performs inverse transformation of the mode solutions.
C
      SUBROUTINE SOLVES (A,IP,B,NEQ,NRH,NP,N,MP,M,IFL1,IFL2)
C ***
C     DOUBLE PRECISION 6/4/85
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C
C     SUBROUTINE SOLVES, FOR SYMMETRIC STRUCTURES, HANDLES THE
C     TRANSFORMATION OF THE RIGHT HAND SIDE VECTOR AND SOLUTION OF THE
C     MATRIX EQ.
C
      COMPLEX*16 A,B,Y,SUM,SSX
      COMMON /SMAT/ SSX(16,16)
      COMMON /SCRATM/ Y(2*MAXSEG)
      COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,I
     1CASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
      DIMENSION A(1), IP(1), B(NEQ,NRH)
      NPEQ=NP+2*MP
      NOP=NEQ/NPEQ
      FNOP=NOP
      FNORM=1./FNOP
      NROW=NEQ
      IF (ICASE.GT.3) NROW=NPEQ
      IF (NOP.EQ.1) GO TO 11
      DO 10 IC=1,NRH
      IF (N.EQ.0.OR.M.EQ.0) GO TO 6
      DO 1 I=1,NEQ
1     Y(I)=B(I,IC)
      KK=2*MP
      IA=NP
      IB=N
      J=NP
      DO 5 K=1,NOP
      IF (K.EQ.1) GO TO 3
      DO 2 I=1,NP
      IA=IA+1
      J=J+1
2     B(J,IC)=Y(IA)
      IF (K.EQ.NOP) GO TO 5
3     DO 4 I=1,KK
      IB=IB+1
      J=J+1
4     B(J,IC)=Y(IB)
5     CONTINUE
C
C     TRANSFORM MATRIX EQ. RHS VECTOR ACCORDING TO SYMMETRY MODES
C
6     DO 10 I=1,NPEQ
      DO 7 K=1,NOP
      IA=I+(K-1)*NPEQ
7     Y(K)=B(IA,IC)
      SUM=Y(1)
      DO 8 K=2,NOP
8     SUM=SUM+Y(K)
      B(I,IC)=SUM*FNORM
      DO 10 K=2,NOP
      IA=I+(K-1)*NPEQ
      SUM=Y(1)
      DO 9 J=2,NOP
9     SUM=SUM+Y(J)*DCONJG(SSX(K,J))
10    B(IA,IC)=SUM*FNORM
11    IF (ICASE.LT.3) GO TO 12
      REWIND IFL1
      REWIND IFL2
C
C     SOLVE EACH MODE EQUATION
C
12    DO 16 KK=1,NOP
      IA=(KK-1)*NPEQ+1
      IB=IA
      IF (ICASE.NE.4) GO TO 13
      I=NPEQ*NPEQ
      READ (IFL1) (A(J),J=1,I)
      IB=1
13    IF (ICASE.EQ.3.OR.ICASE.EQ.5) GO TO 15
      DO 14 IC=1,NRH
14    CALL SOLVE (NPEQ,A(IB),IP(IA),B(IA,IC),NROW)
      GO TO 16
15    CALL LTSOLV (A,NPEQ,IP(IA),B(IA,1),NEQ,NRH,IFL1,IFL2)
16    CONTINUE
      IF (NOP.EQ.1) RETURN
C
C     INVERSE TRANSFORM THE MODE SOLUTIONS
C
      DO 26 IC=1,NRH
      DO 20 I=1,NPEQ
      DO 17 K=1,NOP
      IA=I+(K-1)*NPEQ
17    Y(K)=B(IA,IC)
      SUM=Y(1)
      DO 18 K=2,NOP
18    SUM=SUM+Y(K)
      B(I,IC)=SUM
      DO 20 K=2,NOP
      IA=I+(K-1)*NPEQ
      SUM=Y(1)
      DO 19 J=2,NOP
19    SUM=SUM+Y(J)*SSX(K,J)
20    B(IA,IC)=SUM
      IF (N.EQ.0.OR.M.EQ.0) GO TO 26
      DO 21 I=1,NEQ
21    Y(I)=B(I,IC)
      KK=2*MP
      IA=NP
      IB=N
      J=NP
      DO 25 K=1,NOP
      IF (K.EQ.1) GO TO 23
      DO 22 I=1,NP
      IA=IA+1
      J=J+1
22    B(IA,IC)=Y(J)
      IF (K.EQ.NOP) GO TO 25
23    DO 24 I=1,KK
      IB=IB+1
      J=J+1
24    B(IB,IC)=Y(J)
25    CONTINUE
26    CONTINUE
      RETURN
      END
