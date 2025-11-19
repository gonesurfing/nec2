! ========================================================================
!     NEC2D - Numerical Electromagnetics Code (2D version)
!     Modernized Fortran 90 Module: Matrix NGF Filling (CMNGF)
! ========================================================================
!     Original: CMNGF subroutine from nec2dxs_integrated.f
!     Modernized: 2025-11-19
!     GOTOs eliminated: 38
!     COMMON blocks: Replaced with MODULE USE (2025-11-19)
! ========================================================================

SUBROUTINE CMNGF (CB,CC,CD,NB,NC,ND,RKHX,IEXKX)
  USE nec2d_params
  USE nec2d_commons, ONLY: &
    ! /DATA/ - geometry and segment data (22 variables)
    X, Y, Z, SI, BI, ALP, BET, WLAM, ICON1, ICON2, ITAG, ICONX, &
    LD, N1, N2, N, NP, M1, M2, M, MP, IPSYM, &
    ! /ZLOAD/ - load impedances (3 variables)
    ZARRAY, NLOAD, NLODF, &
    ! /SEGJ/ - segment junction data (9 variables)
    AX, BX, CX, JCO, JSNO, ISCON, NSCON, IPCON, NPCON, &
    ! /DATAJ/ - data for junction calculations (24 variables)
    S_J, B_J, XJ, YJ, ZJ, CABJ, SABJ, SALPJ, &
    EXK, EYK, EZK, EXS, EYS, EZS, EXC, EYC, EZC, &
    RKH, IND1, INDD1, IND2, INDD2, IEXK, IPGND, &
    ! /MATPAR/ - matrix parameters (15 variables)
    ICASE, NBLOKS, NPBLK, NLAST, NBLSYM, NPSYM, NLSYM, IMAT, &
    ICASX, NBBX, NPBX, NLBX, NBBL, NPBL, NLBL
! ***
!     DOUBLE PRECISION 6/4/85
!     CMNGF FILLS INTERACTION MATRICIES B, C, AND D FOR N.G.F. SOLUTION

  IMPLICIT REAL*8(A-H,O-Z)

  COMPLEX*16 CB,CC,CD
  DIMENSION CB(NB,1), CC(NC,1), CD(ND,1)

  RKH=RKHX
  IEXK=IEXKX
  M1EQ=2*M1
  M2EQ=M1EQ+1
  MEQ=2*M
  NEQP=ND-NPCON*2
  NEQS=NEQP-NSCON
  NEQSP=NEQS+NC
  NEQN=NC+N-N1
  ITX=1
  IF (NSCON.GT.0) ITX=2

  ! Initialize matrices and rewind files based on ICASX
  IF (ICASX.EQ.1) THEN
    ! ICASX=1: Initialize all matrices
    DO J=1,ND
      DO I=1,ND
        CD(I,J)=(0.,0.)
      END DO
      DO I=1,NB
        CB(I,J)=(0.,0.)
        CC(I,J)=(0.,0.)
      END DO
    END DO
  ELSE
    ! ICASX != 1: Rewind files
    REWIND 12
    REWIND 14
    REWIND 15
    IF (ICASX.LE.2) THEN
      ! ICASX=2: Also initialize matrices
      DO J=1,ND
        DO I=1,ND
          CD(I,J)=(0.,0.)
        END DO
        DO I=1,NB
          CB(I,J)=(0.,0.)
          CC(I,J)=(0.,0.)
        END DO
      END DO
    END IF
  END IF

  IST=N-N1+1
  IT=NPBX
  ISV=-NPBX

  ! ========================================================================
  ! LOOP THRU 24: FILLS B. FOR ICASX=1 OR 2 ALSO FILLS D(WW), D(WS)
  ! ========================================================================
  DO IBLK=1,NBBX
    ISV=ISV+NPBX
    IF (IBLK.EQ.NBBX) IT=NLBX

    ! For ICASX >= 3: Zero out CB for this block
    IF (ICASX.GE.3) THEN
      DO J=1,ND
        DO I=1,IT
          CB(I,J)=(0.,0.)
        END DO
      END DO
    END IF

    I1=ISV+1
    I2=ISV+IT
    IN2=I2
    IF (IN2.GT.N1) IN2=N1
    IM1=I1-N1
    IM2=I2-N1
    IF (IM1.LT.1) IM1=1
    IMX=1
    IF (I1.LE.N1) IMX=N1-I1+2

    ! FILL B(WW),B(WS). FOR ICASX=1,2 FILL D(WW),D(WS)
    IF (N2.LE.N) THEN
      DO J=N2,N
        CALL TRIO (J)

        ! Process JCO array
        DO I=1,JSNO
          JSS=JCO(I)
          IF (JSS.GE.N2) THEN
            ! SET JCO WHEN SOURCE IS NEW BASIS FUNCTION ON NEW SEGMENT
            JCO(I)=JSS-N1
          ELSE
            ! SOURCE IS PORTION OF MODIFIED BASIS FUNCTION ON NEW SEGMENT
            JCO(I)=NEQS+ICONX(JSS)
          END IF
        END DO

        IF (I1.LE.IN2) CALL CMWW (J,I1,IN2,CB,NB,CB,NB,0)
        IF (IM1.LE.IM2) CALL CMWS (J,IM1,IM2,CB(IMX,1),NB,CB,NB,0)

        IF (ICASX.LE.2) THEN
          CALL CMWW (J,N2,N,CD,ND,CD,ND,1)
          IF (M2.LE.M) CALL CMWS (J,M2EQ,MEQ,CD(1,IST),ND,CD,ND,1)

          ! LOADING IN D(WW)
          IF (NLOAD.NE.0) THEN
            IR=J-N1
            EXK=ZARRAY(J)
            DO I=1,JSNO
              JSS=JCO(I)
              CD(JSS,IR)=CD(JSS,IR)-(AX(I)+CX(I))*EXK
            END DO
          END IF
        END IF
      END DO
    END IF

    ! FILL B(WW)PRIME
    IF (NSCON.GT.0) THEN
      DO I=1,NSCON
        J=ISCON(I)
        ! SOURCES ARE NEW OR MODIFIED BASIS FUNCTIONS ON OLD SEGMENTS WHICH
        ! CONNECT TO NEW SEGMENTS
        CALL TRIO (J)
        JSS=0

        DO IX=1,JSNO
          IR=JCO(IX)
          IF (IR.GE.N2) THEN
            IR=IR-N1
          ELSE
            IR=ICONX(IR)
            IF (IR.EQ.0) CYCLE
            IR=NEQS+IR
          END IF
          JSS=JSS+1
          JCO(JSS)=IR
          AX(JSS)=AX(IX)
          BX(JSS)=BX(IX)
          CX(JSS)=CX(IX)
        END DO

        JSNO=JSS
        IF (I1.LE.IN2) CALL CMWW (J,I1,IN2,CB,NB,CB,NB,0)
        IF (IM1.LE.IM2) CALL CMWS (J,IM1,IM2,CB(IMX,1),NB,CB,NB,0)

        ! SOURCE IS SINGULAR COMPONENT OF PATCH CURRENT THAT IS PART OF
        ! MODIFIED BASIS FUNCTION FOR OLD SEGMENT THAT CONNECTS TO A NEW
        ! SEGMENT ON END OPPOSITE PATCH.
        IF (I1.LE.IN2) CALL CMSW (J,I,I1,IN2,CB,CB,0,NB,-1)

        IF (NLODF.NE.0) THEN
          JX=J-ISV
          IF (JX.GE.1.AND.JX.LE.IT) THEN
            EXK=ZARRAY(J)
            DO IX=1,JSNO
              JSS=JCO(IX)
              CB(JX,JSS)=CB(JX,JSS)-(AX(IX)+CX(IX))*EXK
            END DO
          END IF
        END IF

        ! SOURCES ARE PORTIONS OF MODIFIED BASIS FUNCTION J ON OLD SEGMENTS
        ! EXCLUDING OLD SEGMENTS THAT DIRECTLY CONNECT TO NEW SEGMENTS.
        CALL TBF (J,1)
        JSX=JSNO
        JSNO=1
        IR=JCO(1)
        JCO(1)=NEQS+I

        DO IX=1,JSX
          IF (IX.NE.1) THEN
            IR=JCO(IX)
            AX(1)=AX(IX)
            BX(1)=BX(IX)
            CX(1)=CX(IX)
          END IF

          IF (IR.LE.N1) THEN
            IF (ICONX(IR).EQ.0) THEN
              IF (I1.LE.IN2) CALL CMWW (IR,I1,IN2,CB,NB,CB,NB,0)
              IF (IM1.LE.IM2) CALL CMWS (IR,IM1,IM2,CB(IMX,1),NB,CB,NB,0)

              ! LOADING FOR B(WW)PRIME
              IF (NLODF.NE.0) THEN
                JX=IR-ISV
                IF (JX.GE.1.AND.JX.LE.IT) THEN
                  EXK=ZARRAY(IR)
                  JSS=JCO(1)
                  CB(JX,JSS)=CB(JX,JSS)-(AX(1)+CX(1))*EXK
                END IF
              END IF
            END IF
          END IF
        END DO
      END DO
    END IF

    ! FILL B(SS)PRIME TO SET OLD PATCH BASIS FUNCTIONS TO ZERO FOR
    ! PATCHES THAT CONNECT TO NEW SEGMENTS
    IF (NPCON.GT.0) THEN
      JSS=NEQP
      DO I=1,NPCON
        IX=IPCON(I)*2+N1-ISV
        IR=IX-1
        JSS=JSS+1
        IF (IR.GT.0.AND.IR.LE.IT) CB(IR,JSS)=(1.,0.)
        JSS=JSS+1
        IF (IX.GT.0.AND.IX.LE.IT) CB(IX,JSS)=(1.,0.)
      END DO
    END IF

    ! FILL B(SW) AND B(SS)
    IF (M2.LE.M) THEN
      IF (I1.LE.IN2) CALL CMSW (M2,M,I1,IN2,CB(1,IST),CB,N1,NB,0)
      IF (IM1.LE.IM2) CALL CMSS (M2,M,IM1,IM2,CB(IMX,IST),NB,0)
    END IF

    IF (ICASX.NE.1) THEN
      WRITE (14) ((CB(I,J),I=1,IT),J=1,ND)
    END IF
  END DO

  ! ========================================================================
  ! FILLING B COMPLETE. START ON C AND D
  ! ========================================================================
  IT=NPBL
  ISV=-NPBL

  DO IBLK=1,NBBL
    ISV=ISV+NPBL
    ISVV=ISV+NC
    IF (IBLK.EQ.NBBL) IT=NLBL

    ! For ICASX >= 3: Zero out CC and CD for this block
    IF (ICASX.GE.3) THEN
      DO J=1,IT
        DO I=1,NC
          CC(I,J)=(0.,0.)
        END DO
        DO I=1,ND
          CD(I,J)=(0.,0.)
        END DO
      END DO
    END IF

    I1=ISVV+1
    I2=ISVV+IT
    IN1=I1-M1EQ
    IN2=I2-M1EQ
    IF (IN2.GT.N) IN2=N
    IM1=I1-N
    IM2=I2-N
    IF (IM1.LT.M2EQ) IM1=M2EQ
    IF (IM2.GT.MEQ) IM2=MEQ
    IMX=1
    IF (IN1.LE.IN2) IMX=NEQN-I1+2

    ! SAME AS FIRST LOOP TO FILL D(WW) FOR ICASX GREATER THAN 2
    IF (ICASX.GE.3.AND.N2.LE.N) THEN
      DO J=N2,N
        CALL TRIO (J)

        DO I=1,JSNO
          JSS=JCO(I)
          IF (JSS.GE.N2) THEN
            JCO(I)=JSS-N1
          ELSE
            JCO(I)=NEQS+ICONX(JSS)
          END IF
        END DO

        IF (IN1.LE.IN2) CALL CMWW (J,IN1,IN2,CD,ND,CD,ND,1)
        IF (IM1.LE.IM2) CALL CMWS (J,IM1,IM2,CD(1,IMX),ND,CD,ND,1)

        IF (NLOAD.NE.0) THEN
          IR=J-N1-ISV
          IF (IR.GE.1.AND.IR.LE.IT) THEN
            EXK=ZARRAY(J)
            DO I=1,JSNO
              JSS=JCO(I)
              CD(JSS,IR)=CD(JSS,IR)-(AX(I)+CX(I))*EXK
            END DO
          END IF
        END IF
      END DO
    END IF

    ! FILL D(SW) AND D(SS)
    IF (M2.LE.M) THEN
      IF (IN1.LE.IN2) CALL CMSW (M2,M,IN1,IN2,CD(IST,1),CD,N1,ND,1)
      IF (IM1.LE.IM2) CALL CMSS (M2,M,IM1,IM2,CD(IST,IMX),ND,1)
    END IF

    ! FILL C(WW),C(WS), D(WW)PRIME, AND D(WS)PRIME.
    IF (N1.GE.1) THEN
      DO J=1,N1
        CALL TRIO (J)

        IF (NSCON.GT.0) THEN
          DO IX=1,JSNO
            JSS=JCO(IX)
            IF (JSS.GE.N2) THEN
              JCO(IX)=JSS+M1EQ
            ELSE
              IR=ICONX(JSS)
              IF (IR.NE.0) JCO(IX)=NEQSP+IR
            END IF
          END DO
        END IF

        IF (IN1.LE.IN2) CALL CMWW (J,IN1,IN2,CC,NC,CD,ND,ITX)
        IF (IM1.LE.IM2) CALL CMWS (J,IM1,IM2,CC(1,IMX),NC,CD(1,IMX),ND,ITX)
      END DO

      ! FILL C(WW)PRIME
      IF (NSCON.GT.0) THEN
        DO IX=1,NSCON
          IR=ISCON(IX)
          JSS=NEQS+IX-ISV
          IF (JSS.GT.0.AND.JSS.LE.IT) CC(IR,JSS)=(1.,0.)
        END DO
      END IF
    END IF

    ! FILL C(SS)PRIME
    IF (NPCON.GT.0) THEN
      JSS=NEQP-ISV
      DO I=1,NPCON
        IX=IPCON(I)*2+N1
        IR=IX-1
        JSS=JSS+1
        IF (JSS.GT.0.AND.JSS.LE.IT) CC(IR,JSS)=(1.,0.)
        JSS=JSS+1
        IF (JSS.GT.0.AND.JSS.LE.IT) CC(IX,JSS)=(1.,0.)
      END DO
    END IF

    ! FILL C(SW) AND C(SS)
    IF (M1.GE.1) THEN
      IF (IN1.LE.IN2) CALL CMSW (1,M1,IN1,IN2,CC(N2,1),CC,0,NC,1)
      IF (IM1.LE.IM2) CALL CMSS (1,M1,IM1,IM2,CC(N2,IMX),NC,1)
    END IF

    IF (ICASX.NE.1) THEN
      WRITE (12) ((CD(J,I),J=1,ND),I=1,IT)
      WRITE (15) ((CC(J,I),J=1,NC),I=1,IT)
    END IF
  END DO

  IF(ICASX.EQ.1)RETURN
  REWIND 12
  REWIND 14
  REWIND 15
  RETURN
END SUBROUTINE CMNGF
