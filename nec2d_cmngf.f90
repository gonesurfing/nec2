! =============================================================================
! nec2d_cmngf - Matrix NGF Filling
! =============================================================================
! Purpose: Fill interaction matrices B, C, and D for NGF solution
! Contains: CMNGF
! GOTOs eliminated: 38
! =============================================================================
subroutine CMNGF (CB,CC,CD,NB,NC,ND,RKHX,IEXKX)
  use nec2d_params
  use nec2d_commons, only: &
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

  implicit real*8(A-H,O-Z)

  complex*16 CB,CC,CD
  dimension CB(NB,1), CC(NC,1), CD(ND,1)

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
  if (NSCON.gt.0) ITX=2

  ! Initialize matrices and rewind files based on ICASX
  if (ICASX.eq.1) then
    ! ICASX=1: Initialize all matrices
    do J=1,ND
      do I=1,ND
        CD(I,J)=(0.,0.)
      end do
      do I=1,NB
        CB(I,J)=(0.,0.)
        CC(I,J)=(0.,0.)
      end do
    end do
  else
    ! ICASX != 1: Rewind files
    rewind 12
    rewind 14
    rewind 15
    if (ICASX.le.2) then
      ! ICASX=2: Also initialize matrices
      do J=1,ND
        do I=1,ND
          CD(I,J)=(0.,0.)
        end do
        do I=1,NB
          CB(I,J)=(0.,0.)
          CC(I,J)=(0.,0.)
        end do
      end do
    end if
  end if

  IST=N-N1+1
  IT=NPBX
  ISV=-NPBX

  ! ========================================================================
  ! LOOP THRU 24: FILLS B. FOR ICASX=1 OR 2 ALSO FILLS D(WW), D(WS)
  ! ========================================================================
  do IBLK=1,NBBX
    ISV=ISV+NPBX
    if (IBLK.eq.NBBX) IT=NLBX

    ! For ICASX >= 3: Zero out CB for this block
    if (ICASX.ge.3) then
      do J=1,ND
        do I=1,IT
          CB(I,J)=(0.,0.)
        end do
      end do
    end if

    I1=ISV+1
    I2=ISV+IT
    IN2=I2
    if (IN2.gt.N1) IN2=N1
    IM1=I1-N1
    IM2=I2-N1
    if (IM1.lt.1) IM1=1
    IMX=1
    if (I1.le.N1) IMX=N1-I1+2

    ! FILL B(WW),B(WS). FOR ICASX=1,2 FILL D(WW),D(WS)
    if (N2.le.N) then
      do J=N2,N
        call TRIO (J)

        ! Process JCO array
        do I=1,JSNO
          JSS=JCO(I)
          if (JSS.ge.N2) then
            ! SET JCO WHEN SOURCE IS NEW BASIS FUNCTION ON NEW SEGMENT
            JCO(I)=JSS-N1
          else
            ! SOURCE IS PORTION OF MODIFIED BASIS FUNCTION ON NEW SEGMENT
            JCO(I)=NEQS+ICONX(JSS)
          end if
        end do

        if (I1.le.IN2) call CMWW (J,I1,IN2,CB,NB,CB,NB,0)
        if (IM1.le.IM2) call CMWS (J,IM1,IM2,CB(IMX,1),NB,CB,NB,0)

        if (ICASX.le.2) then
          call CMWW (J,N2,N,CD,ND,CD,ND,1)
          if (M2.le.M) call CMWS (J,M2EQ,MEQ,CD(1,IST),ND,CD,ND,1)

          ! LOADING IN D(WW)
          if (NLOAD.ne.0) then
            IR=J-N1
            EXK=ZARRAY(J)
            do I=1,JSNO
              JSS=JCO(I)
              CD(JSS,IR)=CD(JSS,IR)-(AX(I)+CX(I))*EXK
            end do
          end if
        end if
      end do
    end if

    ! FILL B(WW)PRIME
    if (NSCON.gt.0) then
      do I=1,NSCON
        J=ISCON(I)
        ! SOURCES ARE NEW OR MODIFIED BASIS FUNCTIONS ON OLD SEGMENTS WHICH
        ! CONNECT TO NEW SEGMENTS
        call TRIO (J)
        JSS=0

        do IX=1,JSNO
          IR=JCO(IX)
          if (IR.ge.N2) then
            IR=IR-N1
          else
            IR=ICONX(IR)
            if (IR.eq.0) cycle
            IR=NEQS+IR
          end if
          JSS=JSS+1
          JCO(JSS)=IR
          AX(JSS)=AX(IX)
          BX(JSS)=BX(IX)
          CX(JSS)=CX(IX)
        end do

        JSNO=JSS
        if (I1.le.IN2) call CMWW (J,I1,IN2,CB,NB,CB,NB,0)
        if (IM1.le.IM2) call CMWS (J,IM1,IM2,CB(IMX,1),NB,CB,NB,0)

        ! SOURCE IS SINGULAR COMPONENT OF PATCH CURRENT THAT IS PART OF
        ! MODIFIED BASIS FUNCTION FOR OLD SEGMENT THAT CONNECTS TO A NEW
        ! SEGMENT ON END OPPOSITE PATCH.
        if (I1.le.IN2) call CMSW (J,I,I1,IN2,CB,CB,0,NB,-1)

        if (NLODF.ne.0) then
          JX=J-ISV
          if (JX.ge.1.and.JX.le.IT) then
            EXK=ZARRAY(J)
            do IX=1,JSNO
              JSS=JCO(IX)
              CB(JX,JSS)=CB(JX,JSS)-(AX(IX)+CX(IX))*EXK
            end do
          end if
        end if

        ! SOURCES ARE PORTIONS OF MODIFIED BASIS FUNCTION J ON OLD SEGMENTS
        ! EXCLUDING OLD SEGMENTS THAT DIRECTLY CONNECT TO NEW SEGMENTS.
        call TBF (J,1)
        JSX=JSNO
        JSNO=1
        IR=JCO(1)
        JCO(1)=NEQS+I

        do IX=1,JSX
          if (IX.ne.1) then
            IR=JCO(IX)
            AX(1)=AX(IX)
            BX(1)=BX(IX)
            CX(1)=CX(IX)
          end if

          if (IR.le.N1) then
            if (ICONX(IR).EQ.0) then
              if (I1.le.IN2) call CMWW (IR,I1,IN2,CB,NB,CB,NB,0)
              if (IM1.le.IM2) call CMWS (IR,IM1,IM2,CB(IMX,1),NB,CB,NB,0)

              ! LOADING FOR B(WW)PRIME
              if (NLODF.ne.0) then
                JX=IR-ISV
                if (JX.ge.1.and.JX.le.IT) then
                  EXK=ZARRAY(IR)
                  JSS=JCO(1)
                  CB(JX,JSS)=CB(JX,JSS)-(AX(1)+CX(1))*EXK
                end if
              end if
            end if
          end if
        end do
      end do
    end if

    ! FILL B(SS)PRIME TO SET OLD PATCH BASIS FUNCTIONS TO ZERO FOR
    ! PATCHES THAT CONNECT TO NEW SEGMENTS
    if (NPCON.gt.0) then
      JSS=NEQP
      do I=1,NPCON
        IX=IPCON(I)*2+N1-ISV
        IR=IX-1
        JSS=JSS+1
        if (IR.gt.0.and.IR.le.IT) CB(IR,JSS)=(1.,0.)
        JSS=JSS+1
        if (IX.gt.0.and.IX.le.IT) CB(IX,JSS)=(1.,0.)
      end do
    end if

    ! FILL B(SW) AND B(SS)
    if (M2.le.M) then
      if (I1.le.IN2) call CMSW (M2,M,I1,IN2,CB(1,IST),CB,N1,NB,0)
      if (IM1.le.IM2) call CMSS (M2,M,IM1,IM2,CB(IMX,IST),NB,0)
    end if

    if (ICASX.ne.1) then
      write (14) ((CB(I,J),I=1,IT),J=1,ND)
    end if
  end do

  ! ========================================================================
  ! FILLING B COMPLETE. START ON C AND D
  ! ========================================================================
  IT=NPBL
  ISV=-NPBL

  do IBLK=1,NBBL
    ISV=ISV+NPBL
    ISVV=ISV+NC
    if (IBLK.eq.NBBL) IT=NLBL

    ! For ICASX >= 3: Zero out CC and CD for this block
    if (ICASX.ge.3) then
      do J=1,IT
        do I=1,NC
          CC(I,J)=(0.,0.)
        end do
        do I=1,ND
          CD(I,J)=(0.,0.)
        end do
      end do
    end if

    I1=ISVV+1
    I2=ISVV+IT
    IN1=I1-M1EQ
    IN2=I2-M1EQ
    if (IN2.gt.N) IN2=N
    IM1=I1-N
    IM2=I2-N
    if (IM1.lt.M2EQ) IM1=M2EQ
    if (IM2.gt.MEQ) IM2=MEQ
    IMX=1
    if (IN1.le.IN2) IMX=NEQN-I1+2

    ! SAME AS FIRST LOOP TO FILL D(WW) FOR ICASX GREATER THAN 2
    if (ICASX.ge.3.and.N2.le.N) then
      do J=N2,N
        call TRIO (J)

        do I=1,JSNO
          JSS=JCO(I)
          if (JSS.ge.N2) then
            JCO(I)=JSS-N1
          else
            JCO(I)=NEQS+ICONX(JSS)
          end if
        end do

        if (IN1.le.IN2) call CMWW (J,IN1,IN2,CD,ND,CD,ND,1)
        if (IM1.le.IM2) call CMWS (J,IM1,IM2,CD(1,IMX),ND,CD,ND,1)

        if (NLOAD.ne.0) then
          IR=J-N1-ISV
          if (IR.ge.1.and.IR.le.IT) then
            EXK=ZARRAY(J)
            do I=1,JSNO
              JSS=JCO(I)
              CD(JSS,IR)=CD(JSS,IR)-(AX(I)+CX(I))*EXK
            end do
          end if
        end if
      end do
    end if

    ! FILL D(SW) AND D(SS)
    if (M2.le.M) then
      if (IN1.le.IN2) call CMSW (M2,M,IN1,IN2,CD(IST,1),CD,N1,ND,1)
      if (IM1.le.IM2) call CMSS (M2,M,IM1,IM2,CD(IST,IMX),ND,1)
    end if

    ! FILL C(WW),C(WS), D(WW)PRIME, AND D(WS)PRIME.
    if (N1.ge.1) then
      do J=1,N1
        call TRIO (J)

        if (NSCON.gt.0) then
          do IX=1,JSNO
            JSS=JCO(IX)
            if (JSS.ge.N2) then
              JCO(IX)=JSS+M1EQ
            else
              IR=ICONX(JSS)
              if (IR.ne.0) JCO(IX)=NEQSP+IR
            end if
          end do
        end if

        if (IN1.le.IN2) call CMWW (J,IN1,IN2,CC,NC,CD,ND,ITX)
        if (IM1.le.IM2) call CMWS (J,IM1,IM2,CC(1,IMX),NC,CD(1,IMX),ND,ITX)
      end do

      ! FILL C(WW)PRIME
      if (NSCON.gt.0) then
        do IX=1,NSCON
          IR=ISCON(IX)
          JSS=NEQS+IX-ISV
          if (JSS.gt.0.and.JSS.le.IT) CC(IR,JSS)=(1.,0.)
        end do
      end if
    end if

    ! FILL C(SS)PRIME
    if (NPCON.gt.0) then
      JSS=NEQP-ISV
      do I=1,NPCON
        IX=IPCON(I)*2+N1
        IR=IX-1
        JSS=JSS+1
        if (JSS.gt.0.and.JSS.le.IT) CC(IR,JSS)=(1.,0.)
        JSS=JSS+1
        if (JSS.gt.0.and.JSS.le.IT) CC(IX,JSS)=(1.,0.)
      end do
    end if

    ! FILL C(SW) AND C(SS)
    if (M1.ge.1) then
      if (IN1.le.IN2) call CMSW (1,M1,IN1,IN2,CC(N2,1),CC,0,NC,1)
      if (IM1.le.IM2) call CMSS (1,M1,IM1,IM2,CC(N2,IMX),NC,1)
    end if

    if (ICASX.ne.1) then
      write (12) ((CD(J,I),J=1,ND),I=1,IT)
      write (15) ((CC(J,I),J=1,NC),I=1,IT)
    end if
  end do

  if(ICASX.eq.1)return
  rewind 12
  rewind 14
  rewind 15
  return
end subroutine CMNGF
