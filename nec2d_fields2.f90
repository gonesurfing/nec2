! =============================================================================
! nec2d_fields2 - Far Field Patterns
! =============================================================================
! Purpose: Far field radiation pattern calculations
! Contains: REFLC, SBF, NFPAT
! GOTOs eliminated: 18
! =============================================================================
subroutine REFLC (IX,IY,IZ,ITX,NOP)
! *****************************************************************************
! Modernized from: nec2dxs_integrated.f (lines 3279-3495)
! Tier 2 modernization: Free-form F90, eliminated 18 GOTOs
! Original: NEC2D Double Precision 6/4/85
! *****************************************************************************
!
! REFLC reflects partial structure along X, Y, or Z axes or rotates
! structure to complete a symmetric structure.
!
  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)

  common /data/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
    ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
    ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  common /ANGL/ SALP(MAXSEG)
  dimension T1X(1), T1Y(1), T1Z(1), T2X(1), T2Y(1), T2Z(1), X2(1), &
    Y2(1), Z2(1)
  equivalence (T1X,SI), (T1Y,ALP), (T1Z,BET), (T2X,ICON1), (T2Y,ICON2), &
    (T2Z,ITAG), (X2,SI), (Y2,ALP), (Z2,BET)

  NP=N
  MP=M
  IPSYM=0
  ITI=ITX

  ! GOTO 19 eliminated: Use structured IF to separate rotation vs reflection
  if (IX.lt.0) then
    ! -------------------------------------------------------------------------
    ! REPRODUCE STRUCTURE WITH ROTATION TO FORM CYLINDRICAL STRUCTURE
    ! -------------------------------------------------------------------------
    FNOP=NOP
    IPSYM=-1
    SAM=6.283185308D+0/FNOP
    CS=COS(SAM)
    SS=SIN(SAM)

    ! GOTO 21 eliminated: Use structured IF for conditional wire rotation
    if (N.ge.N2) then
      N=N1+(N-N1)*NOP
      NX=NP+1
      do I=NX,N
        K=I-NP+N1
        XK=X(K)
        YK=Y(K)
        X(I)=XK*CS-YK*SS
        Y(I)=XK*SS+YK*CS
        Z(I)=Z(K)
        XK=X2(K)
        YK=Y2(K)
        X2(I)=XK*CS-YK*SS
        Y2(I)=XK*SS+YK*CS
        Z2(I)=Z2(K)
        ITAGI=ITAG(K)
        if (ITAGI.eq.0) ITAG(I)=0
        if (ITAGI.ne.0) ITAG(I)=ITAGI+ITI
        BI(I)=BI(K)
      end do
    end if

    ! GOTO 23 eliminated: Use structured IF for conditional patch rotation
    if (M.ge.M2) then
      M=M1+(M-M1)*NOP
      NX=MP+1
      K=LD+1-M1
      do I=NX,M
        K=K-1
        J=K-MP+M1
        XK=X(K)
        YK=Y(K)
        X(J)=XK*CS-YK*SS
        Y(J)=XK*SS+YK*CS
        Z(J)=Z(K)
        XK=T1X(K)
        YK=T1Y(K)
        T1X(J)=XK*CS-YK*SS
        T1Y(J)=XK*SS+YK*CS
        T1Z(J)=T1Z(K)
        XK=T2X(K)
        YK=T2Y(K)
        T2X(J)=XK*CS-YK*SS
        T2Y(J)=XK*SS+YK*CS
        T2Z(J)=T2Z(K)
        SALP(J)=SALP(K)
        BI(J)=BI(K)
      end do
    end if

    return
  end if

  ! -------------------------------------------------------------------------
  ! REFLECTION MODE
  ! -------------------------------------------------------------------------
  if (NOP.eq.0) return
  IPSYM=1

  ! GOTO 6 eliminated: Use structured IF for Z axis reflection
  if (IZ.ne.0) then
    ! REFLECT ALONG Z AXIS
    IPSYM=2

    ! GOTO 3 eliminated: Use structured IF for conditional wire reflection
    if (N.ge.N2) then
      do I=N2,N
        NX=I+N-N1
        E1=Z(I)
        E2=Z2(I)
        ! GOTO 1 eliminated: Invert error check condition
        if (ABS(E1)+ABS(E2).LE.1.D-5.or.E1*E2.LT.-1.D-6) then
          write(*,24)  I
          stop
        end if
        X(NX)=X(I)
        Y(NX)=Y(I)
        Z(NX)=-E1
        X2(NX)=X2(I)
        Y2(NX)=Y2(I)
        Z2(NX)=-E2
        ITAGI=ITAG(I)
        if (ITAGI.eq.0) ITAG(NX)=0
        if (ITAGI.ne.0) ITAG(NX)=ITAGI+ITI
        BI(NX)=BI(I)
      end do
      N=N*2-N1
      ITI=ITI*2
    end if

    ! GOTO 6 eliminated: Use structured IF for conditional patch reflection
    if (M.ge.M2) then
      NXX=LD+1-M1
      do I=M2,M
        NXX=NXX-1
        NX=NXX-M+M1
        ! GOTO 4 eliminated: Invert error check condition
        if (ABS(Z(NXX)).LE.1.D-10) then
          write(*,25)  I
          stop
        end if
        X(NX)=X(NXX)
        Y(NX)=Y(NXX)
        Z(NX)=-Z(NXX)
        T1X(NX)=T1X(NXX)
        T1Y(NX)=T1Y(NXX)
        T1Z(NX)=-T1Z(NXX)
        T2X(NX)=T2X(NXX)
        T2Y(NX)=T2Y(NXX)
        T2Z(NX)=-T2Z(NXX)
        SALP(NX)=-SALP(NXX)
        BI(NX)=BI(NXX)
      end do
      M=M*2-M1
    end if
  end if

  ! GOTO 12 eliminated: Use structured IF for Y axis reflection
  if (IY.ne.0) then
    ! REFLECT ALONG Y AXIS

    ! GOTO 9 eliminated: Use structured IF for conditional wire reflection
    if (N.ge.N2) then
      do I=N2,N
        NX=I+N-N1
        E1=Y(I)
        E2=Y2(I)
        ! GOTO 7 eliminated: Invert error check condition
        if (ABS(E1)+ABS(E2).LE.1.D-5.or.E1*E2.LT.-1.D-6) then
          write(*,24)  I
          stop
        end if
        X(NX)=X(I)
        Y(NX)=-E1
        Z(NX)=Z(I)
        X2(NX)=X2(I)
        Y2(NX)=-E2
        Z2(NX)=Z2(I)
        ITAGI=ITAG(I)
        if (ITAGI.eq.0) ITAG(NX)=0
        if (ITAGI.ne.0) ITAG(NX)=ITAGI+ITI
        BI(NX)=BI(I)
      end do
      N=N*2-N1
      ITI=ITI*2
    end if

    ! GOTO 12 eliminated: Use structured IF for conditional patch reflection
    if (M.ge.M2) then
      NXX=LD+1-M1
      do I=M2,M
        NXX=NXX-1
        NX=NXX-M+M1
        ! GOTO 10 eliminated: Invert error check condition
        if (ABS(Y(NXX)).LE.1.D-10) then
          write(*,25)  I
          stop
        end if
        X(NX)=X(NXX)
        Y(NX)=-Y(NXX)
        Z(NX)=Z(NXX)
        T1X(NX)=T1X(NXX)
        T1Y(NX)=-T1Y(NXX)
        T1Z(NX)=T1Z(NXX)
        T2X(NX)=T2X(NXX)
        T2Y(NX)=-T2Y(NXX)
        T2Z(NX)=T2Z(NXX)
        SALP(NX)=-SALP(NXX)
        BI(NX)=BI(NXX)
      end do
      M=M*2-M1
    end if
  end if

  ! GOTO 18 eliminated: Use structured IF for X axis reflection
  if (IX.ne.0) then
    ! REFLECT ALONG X AXIS

    ! GOTO 15 eliminated: Use structured IF for conditional wire reflection
    if (N.ge.N2) then
      do I=N2,N
        NX=I+N-N1
        E1=X(I)
        E2=X2(I)
        ! GOTO 13 eliminated: Invert error check condition
        if (ABS(E1)+ABS(E2).LE.1.D-5.or.E1*E2.LT.-1.D-6) then
          write(*,24)  I
          stop
        end if
        X(NX)=-E1
        Y(NX)=Y(I)
        Z(NX)=Z(I)
        X2(NX)=-E2
        Y2(NX)=Y2(I)
        Z2(NX)=Z2(I)
        ITAGI=ITAG(I)
        if (ITAGI.eq.0) ITAG(NX)=0
        if (ITAGI.ne.0) ITAG(NX)=ITAGI+ITI
        BI(NX)=BI(I)
      end do
      N=N*2-N1
    end if

    ! GOTO 18 eliminated: Use structured IF for conditional patch reflection
    if (M.ge.M2) then
      NXX=LD+1-M1
      do I=M2,M
        NXX=NXX-1
        NX=NXX-M+M1
        ! GOTO 16 eliminated: Invert error check condition
        if (ABS(X(NXX)).LE.1.D-10) then
          write(*,25)  I
          stop
        end if
        X(NX)=-X(NXX)
        Y(NX)=Y(NXX)
        Z(NX)=Z(NXX)
        T1X(NX)=-T1X(NXX)
        T1Y(NX)=T1Y(NXX)
        T1Z(NX)=T1Z(NXX)
        T2X(NX)=-T2X(NXX)
        T2Y(NX)=T2Y(NXX)
        T2Z(NX)=T2Z(NXX)
        SALP(NX)=-SALP(NXX)
        BI(NX)=BI(NXX)
      end do
      M=M*2-M1
    end if
  end if

  return

24 format (29H GEOMETRY data ERROR--SEGMENT,I5,26H LIES IN PLANE OF SYMMETRY)
25 format (27H GEOMETRY data ERROR--PATCH,I4,26H LIES IN PLANE OF SYMMETRY)
end subroutine REFLC


! ======================================================================
! SUBROUTINE SBF - Segment Basis Function
! ======================================================================
! Modernized from: nec2dxs_integrated.f (lines 3496-3630)
! GOTOs eliminated: 18
! ======================================================================

subroutine SBF(I, IS, AA, BB, CC)
  ! COMPUTE COMPONENT OF BASIS FUNCTION I ON SEGMENT IS.

  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)

  common /data/ X(MAXSEG), Y(MAXSEG), Z(MAXSEG), SI(MAXSEG), BI(MAXSEG), &
    ALP(MAXSEG), BET(MAXSEG), WLAM, ICON1(2*MAXSEG), ICON2(2*MAXSEG), &
    ITAG(2*MAXSEG), ICONX(MAXSEG), LD, N1, N2, N, NP, M1, M2, M, MP, IPSYM

  data PI/3.141592654D+0/

  ! Initialize output parameters
  AA = 0.
  BB = 0.
  CC = 0.
  JUNE = 0
  JSNO = 0
  PP = 0.

  ! Process first end connection (ICON1)
  JCOX = ICON1(I)
  if (JCOX > 10000) JCOX = I
  JEND = -1
  IEND = -1
  SIG = -1.

  ! GOTO 1,11,2 elimination: Structured three-way branch on JCOX
  if (JCOX /= 0) then
    ! First connection traversal loop
    do while (.TRUE.)
      ! GOTO 1,2,3 elimination: Handle JCOX sign and set direction
      if (JCOX < 0) then
        ! Label 1: Negative JCOX
        JCOX = -JCOX
      else
        ! Label 2: Positive JCOX
        SIG = -SIG
        JEND = -JEND
      end if

      ! Label 3: Process current segment
      JSNO = JSNO + 1

      ! GOTO 24 elimination: Check for segment limit
      if (JSNO >= JMAX) then
        write(*,25) I
        stop
      end if

      D = PI * SI(JCOX)
      SDH = SIN(D)
      CDH = COS(D)
      SD = 2. * SDH * CDH

      ! GOTO 4,5 elimination: D-dependent OMC calculation
      if (D > 0.015) then
        ! Label 4: Large D
        OMC = 1. - CDH * CDH + SDH * SDH
      else
        ! Small D: Series expansion
        OMC = 4. * D * D
        OMC = ((1.3888889D-3 * OMC - 4.1666666667D-2) * OMC + .5) * OMC
      end if

      ! Label 5: Continue with basis function calculation
      AJ = 1. / (LOG(1./(PI*BI(JCOX))) - .577215664D+0)
      PP = PP - OMC / SD * AJ

      ! GOTO 6 elimination: Check if current segment is IS
      if (JCOX == IS) then
        AA = AJ / SD * SIG
        BB = AJ / (2. * CDH)
        CC = -AJ / (2. * SDH) * SIG
        JUNE = IEND
      end if

      ! Label 6: Check if we've reached segment I
      ! GOTO 9 elimination: Check if JCOX equals I
      if (JCOX == I) then
        ! Label 9: Special handling when JCOX = I
        if (JCOX == IS) BB = -BB
        exit  ! Exit to label 10 logic
      end if

      ! Continue traversal: Get next segment
      ! GOTO 7,8 elimination: Select next connection based on JEND
      if (JEND == 1) then
        ! Label 7: Use ICON2
        JCOX = ICON2(JCOX)
      else
        ! Use ICON1
        JCOX = ICON1(JCOX)
      end if

      ! Label 8: Check if next segment is I
      ! GOTO 10 elimination: Check if we've reached I
      if (ABS(JCOX) == I) then
        exit  ! Exit to label 10
      end if

      ! GOTO 1,24,2 elimination: Loop back with three-way branch
      if (JCOX == 0) then
        ! Error condition
        write(*,25) I
        stop
      end if
      ! Continue loop - will branch on JCOX sign at top
    end do
  end if

  ! Label 10: First end complete, check if second end needed
  ! GOTO 12 elimination: Check IEND
  if (IEND /= 1) then
    ! Label 11: Process second end connection (ICON2)
    PM = -PP
    PP = 0.
    NJUN1 = JSNO
    JCOX = ICON2(I)
    if (JCOX > 10000) JCOX = I
    JEND = 1
    IEND = 1
    SIG = -1.

    ! GOTO 1,12,2 elimination: Three-way branch for second traversal
    if (JCOX /= 0) then
      ! Second connection traversal loop (similar to first)
      do while (.TRUE.)
        ! Handle JCOX sign and set direction
        if (JCOX < 0) then
          JCOX = -JCOX
        else
          SIG = -SIG
          JEND = -JEND
        end if

        ! Process current segment
        JSNO = JSNO + 1

        if (JSNO >= JMAX) then
          write(*,25) I
          stop
        end if

        D = PI * SI(JCOX)
        SDH = SIN(D)
        CDH = COS(D)
        SD = 2. * SDH * CDH

        ! D-dependent OMC calculation
        if (D > 0.015) then
          OMC = 1. - CDH * CDH + SDH * SDH
        else
          OMC = 4. * D * D
          OMC = ((1.3888889D-3 * OMC - 4.1666666667D-2) * OMC + .5) * OMC
        end if

        AJ = 1. / (LOG(1./(PI*BI(JCOX))) - .577215664D+0)
        PP = PP - OMC / SD * AJ

        if (JCOX == IS) then
          AA = AJ / SD * SIG
          BB = AJ / (2. * CDH)
          CC = -AJ / (2. * SDH) * SIG
          JUNE = IEND
        end if

        if (JCOX == I) then
          if (JCOX == IS) BB = -BB
          exit
        end if

        if (JEND == 1) then
          JCOX = ICON2(JCOX)
        else
          JCOX = ICON1(JCOX)
        end if

        if (ABS(JCOX) == I) then
          exit
        end if

        if (JCOX == 0) then
          write(*,25) I
          stop
        end if
      end do
    end if
  end if

  ! Label 12: Both ends processed, compute final values
  NJUN2 = JSNO - NJUN1
  D = PI * SI(I)
  SDH = SIN(D)
  CDH = COS(D)
  SD = 2. * SDH * CDH
  CD = CDH * CDH - SDH * SDH

  ! GOTO 13,14 elimination: D-dependent OMC calculation for segment I
  if (D > 0.015) then
    ! Label 13: Large D
    OMC = 1. - CD
  else
    ! Small D: Series expansion
    OMC = 4. * D * D
    OMC = ((1.3888889D-3 * OMC - 4.1666666667D-2) * OMC + .5) * OMC
  end if

  ! Label 14: Continue with junction handling
  AP = 1. / (LOG(1./(PI*BI(I))) - .577215664D+0)
  AJ = AP

  ! GOTO 19 elimination: Check NJUN1
  if (NJUN1 == 0) then
    ! Label 19: No junction at beginning
    ! GOTO 23 elimination: Check NJUN2
    if (NJUN2 == 0) then
      ! Label 23: No junctions at all
      AA = -1.
      QP = PI * BI(I)
      XXI = QP * QP
      XXI = QP * (1. - .5 * XXI) / (1. - XXI)
      CC = 1. / (CDH - XXI * SDH)
      return
    else
      ! Junction at end only
      QP = PI * BI(I)
      XXI = QP * QP
      XXI = QP * (1. - .5 * XXI) / (1. - XXI)
      QP = -(OMC + XXI * SD) / (SD * (AP + XXI * PP) + CD * (XXI * AP - PP))

      ! GOTO 20 elimination: Check JUNE
      if (JUNE == 1) then
        AA = -AA * QP
        BB = BB * QP
        CC = -CC * QP
        if (I == IS) then
          AA = AA - 1.
          D = CD - XXI * SD
          BB = BB + (SDH + AP * QP * (CDH - XXI * SDH)) / D
          CC = CC + (CDH + AP * QP * (SDH + XXI * CDH)) / D
        end if
        return
      else
        ! Label 20: JUNE /= 1
        AA = AA - 1.
        D = CD - XXI * SD
        BB = BB + (SDH + AP * QP * (CDH - XXI * SDH)) / D
        CC = CC + (CDH + AP * QP * (SDH + XXI * CDH)) / D
        return
      end if
    end if
  end if

  ! GOTO 21 elimination: Check NJUN2
  if (NJUN2 == 0) then
    ! Label 21: Junction at beginning only
    QM = PI * BI(I)
    XXI = QM * QM
    XXI = QM * (1. - .5 * XXI) / (1. - XXI)
    QM = (OMC + XXI * SD) / (SD * (AJ - XXI * PM) + CD * (PM + XXI * AJ))

    ! GOTO 22 elimination: Check JUNE
    if (JUNE == -1) then
      AA = AA * QM
      BB = BB * QM
      CC = CC * QM
      if (I == IS) then
        AA = AA - 1.
        D = CD - XXI * SD
        BB = BB + (AJ * QM * (CDH - XXI * SDH) - SDH) / D
        CC = CC + (CDH - AJ * QM * (SDH + XXI * CDH)) / D
      end if
      return
    else
      ! Label 22: JUNE /= -1
      AA = AA - 1.
      D = CD - XXI * SD
      BB = BB + (AJ * QM * (CDH - XXI * SDH) - SDH) / D
      CC = CC + (CDH - AJ * QM * (SDH + XXI * CDH)) / D
      return
    end if
  end if

  ! Junctions at both ends (NJUN1 /= 0 and NJUN2 /= 0)
  QP = SD * (PM * PP + AJ * AP) + CD * (PM * AP - PP * AJ)
  QM = (AP * OMC - PP * SD) / QP
  QP = -(AJ * OMC + PM * SD) / QP

  ! GOTO 15,18,16 elimination: Three-way branch on JUNE
  if (JUNE < 0) then
    ! Label 15: JUNE < 0
    AA = AA * QM
    BB = BB * QM
    CC = CC * QM
    ! GOTO 17 elimination: Continue to label 17
  else if (JUNE > 0) then
    ! Label 16: JUNE > 0
    AA = -AA * QP
    BB = BB * QP
    CC = -CC * QP
    ! Fall through to check I = IS
  else
    ! JUNE = 0: Skip to label 18
    ! Label 18: Add corrections
    AA = AA - 1.
    BB = BB + (AJ * QM + AP * QP) * SDH / SD
    CC = CC + (AJ * QM - AP * QP) * CDH / SD
    return
  end if

  ! Label 17: Check if I = IS
  if (I /= IS) return

  ! Label 18: Add corrections when I = IS
  AA = AA - 1.
  BB = BB + (AJ * QM + AP * QP) * SDH / SD
  CC = CC + (AJ * QM - AP * QP) * CDH / SD
  return

25 format(43H SBF - SEGMENT CONNECTION ERROR FOR SEGMENT, I5)
end subroutine SBF


! ============================================================================
! SUBROUTINE NFPAT - Near Field Pattern
! ============================================================================
! Modernized from: nec2dxs_integrated.f (lines 2772-2869)
! GOTOs eliminated: 14
! ============================================================================

subroutine NFPAT
  ! COMPUTE NEAR E OR H FIELDS OVER A RANGE OF POINTS

  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)

  complex*16 EX,EY,EZ
  common /data/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
    ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
    ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  common/FPAT/THETS,PHIS,DTH,DPH,RFLD,GNOR,CLT,CHT,EPSR2,SIG2, &
    XPR6,PINR,PNLR,PLOSS,XNR,YNR,ZNR,DXNR,DYNR,DZNR,NTH,NPH,IPD,IAVP, &
    INOR,IAX,IXTYP,NEAR,NFEH,NRX,NRY,NRZ
  common /PLOT/ IPLP1,IPLP2,IPLP3,IPLP4

  data TA/1.745329252D-02/

  ! GOTO elimination: Replaced IF(NFEH.EQ.1) GO TO 1 and GO TO 2 pattern
  ! with IF/ELSE structure to select appropriate header format
  if (NFEH .EQ. 1) then
    write(*,12)
  else
    write(*,10)
  end if

  ZNRT = ZNR - DZNR
  do I = 1, NRZ
    ZNRT = ZNRT + DZNR

    ! GOTO elimination: Replaced IF(NEAR.EQ.0) GO TO 3 pattern
    ! with IF structure to conditionally compute CTH and STH
    if (NEAR .NE. 0) then
      CTH = COS(TA*ZNRT)
      STH = SIN(TA*ZNRT)
    end if

    YNRT = YNR - DYNR
    do J = 1, NRY
      YNRT = YNRT + DYNR

      ! GOTO elimination: Replaced IF(NEAR.EQ.0) GO TO 4 pattern
      ! with IF structure to conditionally compute CPH and SPH
      if (NEAR .NE. 0) then
        CPH = COS(TA*YNRT)
        SPH = SIN(TA*YNRT)
      end if

      XNRT = XNR - DXNR
      do KK = 1, NRX
        XNRT = XNRT + DXNR

        ! GOTO elimination: Replaced IF(NEAR.EQ.0) GO TO 5 and GO TO 6 pattern
        ! with IF/ELSE to select coordinate system (spherical vs rectangular)
        if (NEAR .NE. 0) then
          XOB = XNRT*STH*CPH
          YOB = XNRT*STH*SPH
          ZOB = XNRT*CTH
        else
          XOB = XNRT
          YOB = YNRT
          ZOB = ZNRT
        end if

        TMP1 = XOB/WLAM
        TMP2 = YOB/WLAM
        TMP3 = ZOB/WLAM

        ! GOTO elimination: Replaced IF(NFEH.EQ.1) GO TO 7 and GO TO 8 pattern
        ! with IF/ELSE to select field computation (electric vs magnetic)
        if (NFEH .EQ. 1) then
          call NHFLD (TMP1,TMP2,TMP3,EX,EY,EZ)
        else
          call NEFLD (TMP1,TMP2,TMP3,EX,EY,EZ)
        end if

        TMP1 = ABS(EX)
        TMP2 = CANG(EX)
        TMP3 = ABS(EY)
        TMP4 = CANG(EY)
        TMP5 = ABS(EZ)
        TMP6 = CANG(EZ)
        write(*,11) XOB,YOB,ZOB,TMP1,TMP2,TMP3,TMP4,TMP5,TMP6

        ! GOTO elimination: Replaced complex plotting logic with nested IF/ELSE
        ! Original had: IF(IPLP1.NE.2) GO TO 9, computed GO TO, and multiple jumps
        if (IPLP1 .EQ. 2) then
          ! GOTO elimination: Replaced computed GO TO (14,15,16),IPLP4
          ! with SELECT CASE structure for coordinate selection
          select case (IPLP4)
          case (1)
            XXX = XOB
          case (2)
            XXX = YOB
          case (3)
            XXX = ZOB
          end select

          ! GOTO elimination: Replaced IF(IPLP2.NE.2) GO TO 13 and subsequent jumps
          ! with IF/ELSE structure for output format selection
          if (IPLP2 .EQ. 2) then
            if (IPLP3 .EQ. 1) write(8,*) XXX,TMP1,TMP2
            if (IPLP3 .EQ. 2) write(8,*) XXX,TMP3,TMP4
            if (IPLP3 .EQ. 3) write(8,*) XXX,TMP5,TMP6
            if (IPLP3 .EQ. 4) write(8,*) XXX,TMP1,TMP2,TMP3,TMP4,TMP5,TMP6
          else if (IPLP2 .EQ. 1) then
            if (IPLP3 .EQ. 1) write(8,*) XXX,EX
            if (IPLP3 .EQ. 2) write(8,*) XXX,EY
            if (IPLP3 .EQ. 3) write(8,*) XXX,EZ
            if (IPLP3 .EQ. 4) write(8,*) XXX,EX,EY,EZ
          end if
        end if
      end do
    end do
  end do

  return

10 format (///,35X,'- - - NEAR ELECTRIC FIELDS - - -',//,12X, &
    '-  LOCATION  -',21X,'-  EX  -',15X,'-  EY  -',15X,'-  EZ  -', &
    /,8X,'X',10X,'Y',10X,'Z',10X,'MAGNITUDE',3X,'PHASE',6X,'MAGNITUDE', &
    3X,'PHASE',6X,'MAGNITUDE',3X,'PHASE',/,6X,'METERS',5X,'METERS',5X, &
    'METERS',8X,'VOLTS/M',3X,'DEGREES',6X,'VOLTS/M',3X,'DEGREES',6X, &
    'VOLTS/M',3X,'DEGREES')
11 format (2X,3(2X,F9.4),1X,3(3X,1P,E11.4,2X,0P,F7.2))
12 format (///,35X,'- - - NEAR MAGNETIC FIELDS - - -',//,12X, &
    '-  LOCATION  -',21X,'-  HX  -',15X,'-  HY  -',15X,'-  HZ  -', &
    /,8X,'X',10X,'Y',10X,'Z',10X,'MAGNITUDE',3X,'PHASE',6X,'MAGNITUDE', &
    3X,'PHASE',6X,'MAGNITUDE',3X,'PHASE',/,6X,'METERS',5X,'METERS',5X, &
    'METERS',9X,'AMPS/M',3X,'DEGREES',7X,'AMPS/M',3X,'DEGREES',7X, &
    'AMPS/M',3X,'DEGREES')
end subroutine NFPAT
