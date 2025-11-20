C     SOLGF.F - NGF current solution subroutine
C
C     SOLGF solves for current in the N.G.F. (Numerical Green's Function)
C     procedure. It computes the solution using block matrix operations:
C     INV(A)E1, E2-C(INV(A)E1), INV(D)(E2-C(INV(A)E1)), and the final
C     current array I1 = INV(A)E1 - (INV(A)B)I2.
C
      SUBROUTINE SOLGF (A,B,C,D,XY,IP,NP,N1,N,MP,M1,M,N1C,N2C,N2CZ)
C ***
C     DOUBLE PRECISION 6/4/85
C
      USE NEC2_COMMON
      IMPLICIT REAL*8(A-H,O-Z)
C ***
C     SOLVE FOR CURRENT IN N.G.F. PROCEDURE
      COMPLEX*16 A,B,C,D,SUM,XY,Y
      COMMON /SCRATM/ Y(2*MAXSEG)
      COMMON /SEGJ/ AX(JMAX),BX(JMAX),CX(JMAX),JCO(JMAX),
     1JSNO,ISCON(50),NSCON,IPCON(10),NPCON
      COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,I
     1CASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
      DIMENSION A(1), B(N1C,1), C(N1C,1), D(N2CZ,1), IP(1), XY(1)
      IFL=14
      IF (ICASX.GT.0) IFL=13
      IF (N2C.GT.0) GO TO 1
C     NORMAL SOLUTION.  NOT N.G.F.
      CALL SOLVES (A,IP,XY,N1C,1,NP,N,MP,M,13,IFL)
      GO TO 22
1     IF (N1.EQ.N.OR.M1.EQ.0) GO TO 5
C     REORDER EXCITATION ARRAY
      N2=N1+1
      JJ=N+1
      NPM=N+2*M1
      DO 2 I=N2,NPM
2     Y(I)=XY(I)
      J=N1
      DO 3 I=JJ,NPM
      J=J+1
3     XY(J)=Y(I)
      DO 4 I=N2,N
      J=J+1
4     XY(J)=Y(I)
5     NEQS=NSCON+2*NPCON
      IF (NEQS.EQ.0) GO TO 7
      NEQ=N1C+N2C
      NEQS=NEQ-NEQS+1
C     COMPUTE INV(A)E1
      DO 6 I=NEQS,NEQ
6     XY(I)=(0.,0.)
7     CALL SOLVES (A,IP,XY,N1C,1,NP,N1,MP,M1,13,IFL)
      NI=0
      NPB=NPBL
C     COMPUTE E2-C(INV(A)E1)
      DO 10 JJ=1,NBBL
      IF (JJ.EQ.NBBL) NPB=NLBL
      IF (ICASX.GT.1) READ (15) ((C(I,J),I=1,N1C),J=1,NPB)
      II=N1C+NI
      DO 9 I=1,NPB
      SUM=(0.,0.)
      DO 8 J=1,N1C
8     SUM=SUM+C(J,I)*XY(J)
      J=II+I
9     XY(J)=XY(J)-SUM
10    NI=NI+NPBL
      IF (ICASX.GT.1) REWIND 15
      JJ=N1C+1
C     COMPUTE INV(D)(E2-C(INV(A)E1)) = I2
      IF (ICASX.GT.1) GO TO 11
      CALL SOLVE (N2C,D,IP(JJ),XY(JJ),N2C)
      GO TO 13
11    IF (ICASX.EQ.4) GO TO 12
      NI=N2C*N2C
      READ (11) (B(J,1),J=1,NI)
      REWIND 11
      CALL SOLVE (N2C,B,IP(JJ),XY(JJ),N2C)
      GO TO 13
12    NBLSYS=NBLSYM
      NPSYS=NPSYM
      NLSYS=NLSYM
      ICASS=ICASE
      NBLSYM=NBBL
      NPSYM=NPBL
      NLSYM=NLBL
      ICASE=3
      REWIND 11
      REWIND 16
      CALL LTSOLV (B,N2C,IP(JJ),XY(JJ),N2C,1,11,16)
      REWIND 11
      REWIND 16
      NBLSYM=NBLSYS
      NPSYM=NPSYS
      NLSYM=NLSYS
      ICASE=ICASS
13    NI=0
      NPB=NPBL
C     COMPUTE INV(A)E1-(INV(A)B)I2 = I1
      DO 16 JJ=1,NBBL
      IF (JJ.EQ.NBBL) NPB=NLBL
      IF (ICASX.GT.1) READ (14) ((B(I,J),I=1,N1C),J=1,NPB)
      II=N1C+NI
      DO 15 I=1,N1C
      SUM=(0.,0.)
      DO 14 J=1,NPB
      JP=II+J
14    SUM=SUM+B(I,J)*XY(JP)
15    XY(I)=XY(I)-SUM
16    NI=NI+NPBL
      IF (ICASX.GT.1) REWIND 14
      IF (N1.EQ.N.OR.M1.EQ.0) GO TO 20
C     REORDER CURRENT ARRAY
      DO 17 I=N2,NPM
17    Y(I)=XY(I)
      JJ=N1C+1
      J=N1
      DO 18 I=JJ,NPM
      J=J+1
18    XY(J)=Y(I)
      DO 19 I=N2,N1C
      J=J+1
19    XY(J)=Y(I)
20    IF (NSCON.EQ.0) GO TO 22
      J=NEQS-1
      DO 21 I=1,NSCON
      J=J+1
      JJ=ISCON(I)
21    XY(JJ)=XY(J)
22    RETURN
      END
