! =============================================================================
! nec2d_rdpat - Radiation Patterns
! =============================================================================
! Purpose: Radiation pattern computation and output
! Contains: RDPAT
! =============================================================================
subroutine RDPAT
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  ! COMPUTE RADIATION PATTERN, GAIN, NORMALIZED GAIN
  !
  ! Modernized: Eliminated 44 GOTOs using structured control flow
  !
  implicit real*8(A-H,O-Z)

  ! Parameter from NEC2DPAR.INC
  integer, parameter :: MAXSEG = 3000
  integer, parameter :: NORMAX = 4*MAXSEG

  ! Character variables override IMPLICIT for these names
  character*6 IGNTP(10), IGAX(4), IGTP(4), HPOL(3), HCIR, HCLIF, ISENS
  character*1 HBLK

  complex*16 ETH,EPH,ERD,ZRATI,ZRATI2,T1,FRATI

  common /data/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
                ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
                ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  common/save/EPSR,SIG,SCRWLT,SCRWRT,FMHZ,IP(2*MAXSEG),KCOM
  common /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL, &
              KSYMP,IFAR,IPERF
  common/FPAT/THETS,PHIS,DTH,DPH,RFLD,GNOR,CLT,CHT,EPSR2,SIG2, &
              XPR6,PINR,PNLR,PLOSS,XNR,YNR,ZNR,DXNR,DYNR,DZNR,NTH,NPH,IPD,IAVP, &
              INOR,IAX,IXTYP,NEAR,NFEH,NRX,NRY,NRZ
  common /SCRATM/ GAIN(NORMAX)
  common /PLOT/ IPLP1,IPLP2,IPLP3,IPLP4

  data HPOL/'LINEAR','RIGHT','LEFT'/,HBLK,HCIR/' ','CIRCLE'/
  data IGTP/'    - ','POWER ','- DIRE','CTIVE '/
  data IGAX/' MAJOR',' MINOR',' VERT.',' HOR. '/
  data IGNTP/' MAJOR',' AXIS ',' MINOR',' AXIS ','   VER','TICAL ', &
             ' HORIZ','ONTAL ','      ','TOTAL '/
  data PI,TA,TD/3.141592654D+0,1.745329252D-02,57.29577951D+0/

  ! Section 1: Ground parameter output (labels 1, 2 eliminated)
  ! GOTO 1, 2 eliminated with structured IF-THEN-ELSE
  if (IFAR .GE. 2) then
    write(*,35)

    if (IFAR .GT. 3) then
      write(*,36) NRADL,SCRWLT,SCRWRT
    end if

    if (IFAR .NE. 4) then
      ! Label 1 path
      if (IFAR .EQ. 2 .OR. IFAR .EQ. 5) then
        HCLIF = HPOL(1)
      else if (IFAR .EQ. 3 .OR. IFAR .EQ. 6) then
        HCLIF = HCIR
      end if

      CL = CLT/WLAM
      CH = CHT/WLAM
      ZRATI2 = SQRT(1./DCMPLX(EPSR2,-SIG2*WLAM*59.96))
      write(*,37) HCLIF,CLT,CHT,EPSR2,SIG2
    end if
  end if

  ! Section 2: Header output (labels 3, 4, 5 eliminated)
  ! GOTO 3, 4, 5 eliminated with structured IF-THEN-ELSE
  if (IFAR .EQ. 1) then
    ! Near-field header
    write(*,41)
  else
    ! Far-field header (label 3)
    I = 2*IPD + 1
    J = I + 1
    ITMP1 = 2*IAX + 1
    ITMP2 = ITMP1 + 1
    write(*,38)

    ! GOTO 4 eliminated
    if (RFLD .GE. 1.D-20) then
      EXRM = 1./RFLD
      EXRA = RFLD/WLAM
      EXRA = -360.*(EXRA - AINT(EXRA))
      write(*,39) RFLD,EXRM,EXRA
    end if

    ! Label 4
    write(*,40) IGTP(I),IGTP(J),IGAX(ITMP1),IGAX(ITMP2)
  end if

  ! Section 3: Gain constant initialization (labels 6, 7, 8 eliminated)
  ! GOTO 6, 7, 8 eliminated with structured IF-THEN-ELSE
  if (IXTYP .NE. 0 .AND. IXTYP .NE. 5) then
    if (IXTYP .EQ. 4) then
      ! Label 6
      PINR = 394.51*XPR6*XPR6*WLAM*WLAM
    else
      ! Default path
      PRAD = 0.
      GCON = 4.*PI/(1.+XPR6*XPR6)
      GCOP = GCON
      ! Skip to label 8
    end if
  end if

  ! Label 7 and 8 combined
  if (IXTYP .EQ. 0 .OR. IXTYP .EQ. 5 .OR. IXTYP .EQ. 4) then
    GCOP = WLAM*WLAM*2.*PI/(376.73*PINR)
    PRAD = PINR - PLOSS - PNLR
    GCON = GCOP
    if (IPD .NE. 0) GCON = GCON*PINR/PRAD
  end if

  ! Label 8
  I = 0
  GMAX = -1.E10
  PINT = 0.
  TMP1 = DPH*TA
  TMP2 = .5*DTH*TA
  PHI = PHIS - DPH

  ! Main computation loop (label 29 is DO loop end)
  do KPH = 1, NPH
    PHI = PHI + DPH
    PHA = PHI*TA
    THET = THETS - DTH

    do KTH = 1, NTH
      THET = THET + DTH

      ! GOTO 29 eliminated with CYCLE
      if (KSYMP .EQ. 2 .AND. THET .GT. 90.01 .AND. IFAR .NE. 1) cycle

      THA = THET*TA

      ! Field computation (labels 9, 10 eliminated)
      ! GOTO 9, 10 eliminated with IF-THEN-ELSE
      if (IFAR .EQ. 1) then
        ! Label 9: Near field
        call GFLD(RFLD/WLAM, PHA, THET/WLAM, ETH, EPH, ERD, ZRATI, KSYMP)
        ERDM = ABS(ERD)
        ERDA = CANG(ERD)
      else
        ! Far field
        call FFLD(THA, PHA, ETH, EPH)
      end if

      ! Label 10: Common processing
      ETHM2 = DREAL(ETH*DCONJG(ETH))
      ETHM = SQRT(ETHM2)
      ETHA = CANG(ETH)
      EPHM2 = DREAL(EPH*DCONJG(EPH))
      EPHM = SQRT(EPHM2)
      EPHA = CANG(EPH)

      ! Near-field output (label 28) or elliptical polarization calc
      ! GOTO 28 eliminated with IF-THEN-ELSE
      if (IFAR .NE. 1) then
        ! Elliptical polarization calculation (labels 11-16 eliminated)
        ! GOTO 11, 12, 13, 14, 15, 16 eliminated with structured IF-THEN-ELSE
        if (ETHM2 .LE. 1.D-20 .AND. EPHM2 .LE. 1.D-20) then
          ! Zero field case
          TILTA = 0.
          EMAJR2 = 0.
          EMINR2 = 0.
          AXRAT = 0.
          ISENS = HBLK
        else
          ! Label 11: Non-zero field
          DFAZ = EPHA - ETHA

          ! GOTO 12, 13 eliminated
          if (EPHA .LT. 0.) then
            ! Label 12
            DFAZ2 = DFAZ + 360.
          else
            DFAZ2 = DFAZ - 360.
          end if

          ! Label 13
          if (ABS(DFAZ) .GT. ABS(DFAZ2)) DFAZ = DFAZ2

          CDFAZ = COS(DFAZ*TA)
          TSTOR1 = ETHM2 - EPHM2
          TSTOR2 = 2.*EPHM*ETHM*CDFAZ
          TILTA = .5*ATGN2(TSTOR2, TSTOR1)
          STILTA = SIN(TILTA)
          TSTOR1 = TSTOR1*STILTA*STILTA
          TSTOR2 = TSTOR2*STILTA*COS(TILTA)
          EMAJR2 = -TSTOR1 + TSTOR2 + ETHM2
          EMINR2 = TSTOR1 - TSTOR2 + EPHM2
          if (EMINR2 .LT. 0.) EMINR2 = 0.
          AXRAT = SQRT(EMINR2/EMAJR2)
          TILTA = TILTA*TD

          ! GOTO 14, 15, 16 eliminated with structured IF-THEN-ELSE
          if (AXRAT .LE. 1.D-5) then
            ISENS = HPOL(1)
          else
            ! Label 14
            if (DFAZ .LE. 0.) then
              ISENS = HPOL(2)
            else
              ! Label 15
              ISENS = HPOL(3)
            end if
          end if
        end if

        ! Label 16: Compute gains in dB
        GNMJ = DB10(GCON*EMAJR2)
        GNMN = DB10(GCON*EMINR2)
        GNV = DB10(GCON*ETHM2)
        GNH = DB10(GCON*EPHM2)
        GTOT = DB10(GCON*(ETHM2 + EPHM2))

        ! Gain normalization (labels 17-23 eliminated)
        ! GOTO 17-22 (computed GOTO) eliminated with SELECT CASE
        ! GOTO 23 eliminated with IF-THEN
        if (INOR .GE. 1) then
          I = I + 1

          ! GOTO 23 eliminated
          if (I .LE. NORMAX) then
            ! Computed GOTO replaced with SELECT CASE
            select case (INOR)
              case (1)
                ! Label 17
                TSTOR1 = GNMJ
              case (2)
                ! Label 18
                TSTOR1 = GNMN
              case (3)
                ! Label 19
                TSTOR1 = GNV
              case (4)
                ! Label 20
                TSTOR1 = GNH
              case (5)
                ! Label 21
                TSTOR1 = GTOT
            end select

            ! Label 22
            GAIN(I) = TSTOR1
            if (TSTOR1 .GT. GMAX) GMAX = TSTOR1
          end if
        end if

        ! Label 23: Average power integration and output
        ! GOTO 24, 29 eliminated with structured IF-THEN-ELSE
        if (IAVP .NE. 0) then
          TSTOR1 = GCOP*(ETHM2 + EPHM2)
          TMP3 = THA - TMP2
          TMP4 = THA + TMP2
          if (KTH .EQ. 1) TMP3 = THA
          if (KTH .EQ. NTH) TMP4 = THA
          DA = ABS(TMP1*(COS(TMP3) - COS(TMP4)))
          if (KPH .EQ. 1 .OR. KPH .EQ. NPH) DA = .5*DA
          PINT = PINT + TSTOR1*DA

          ! GOTO 29 eliminated with CYCLE
          if (IAVP .EQ. 2) cycle
        end if

        ! Label 24: Prepare output fields
        ! GOTO 25, 26 eliminated with IF-THEN-ELSE
        if (IAX .EQ. 1) then
          ! Label 25
          TMP5 = GNV
          TMP6 = GNH
        else
          TMP5 = GNMJ
          TMP6 = GNMN
        end if

        ! Label 26: Scale field magnitudes
        ETHM = ETHM*WLAM
        EPHM = EPHM*WLAM

        ! GOTO 27 eliminated with IF-THEN
        if (RFLD .GE. 1.D-20) then
          ETHM = ETHM*EXRM
          ETHA = ETHA + EXRA
          EPHM = EPHM*EXRM
          EPHA = EPHA + EXRA
        end if

        ! Label 27: Write far-field output
        write(*,42) THET,PHI,TMP5,TMP6,GTOT,AXRAT,TILTA,ISENS,ETHM,ETHA, &
                    EPHM,EPHA

        ! Plot data output (labels 290, 299 eliminated)
        ! GOTO 299, 290 eliminated with structured IF-THEN-ELSE
        if (IPLP1 .EQ. 3) then
          if (IPLP3 .NE. 0) then
            if (IPLP2 .EQ. 1 .AND. IPLP3 .EQ. 1) write(8,*) THET,ETHM,ETHA
            if (IPLP2 .EQ. 1 .AND. IPLP3 .EQ. 2) write(8,*) THET,EPHM,EPHA
            if (IPLP2 .EQ. 2 .AND. IPLP3 .EQ. 1) write(8,*) PHI,ETHM,ETHA
            if (IPLP2 .EQ. 2 .AND. IPLP3 .EQ. 2) write(8,*) PHI,EPHM,EPHA

            if (IPLP4 .EQ. 0) cycle  ! GOTO 299 eliminated
          end if

          ! Label 290
          if (IPLP2 .EQ. 1 .AND. IPLP4 .EQ. 1) write(8,*) THET,TMP5
          if (IPLP2 .EQ. 1 .AND. IPLP4 .EQ. 2) write(8,*) THET,TMP6
          if (IPLP2 .EQ. 1 .AND. IPLP4 .EQ. 3) write(8,*) THET,GTOT
          if (IPLP2 .EQ. 2 .AND. IPLP4 .EQ. 1) write(8,*) PHI,TMP5
          if (IPLP2 .EQ. 2 .AND. IPLP4 .EQ. 2) write(8,*) PHI,TMP6
          if (IPLP2 .EQ. 2 .AND. IPLP4 .EQ. 3) write(8,*) PHI,GTOT
        end if

        ! Label 299: Continue loop
      else
        ! Label 28: Near-field output
        write(*,43) RFLD,PHI,THET,ETHM,ETHA,EPHM,EPHA,ERDM,ERDA
      end if

    end do  ! Label 29: KTH loop
  end do  ! KPH loop

  ! Section 4: Summary statistics (labels 30-34 eliminated)
  ! GOTO 30, 34 eliminated with structured IF-THEN-ELSE
  if (IAVP .NE. 0) then
    ! Label 30: Average power output
    TMP3 = THETS*TA
    TMP4 = TMP3 + DTH*TA*DFLOAT(NTH - 1)
    TMP3 = ABS(DPH*TA*DFLOAT(NPH - 1)*(COS(TMP3) - COS(TMP4)))
    PINT = PINT/TMP3
    TMP3 = TMP3/PI
    write(*,44) PINT,TMP3
  end if

  ! Normalized gain output
  ! GOTO 34 eliminated with IF-THEN
  if (INOR .NE. 0) then
    if (ABS(GNOR) .GT. 1.D-20) GMAX = GNOR

    ITMP1 = (INOR - 1)*2 + 1
    ITMP2 = ITMP1 + 1
    write(*,45) IGNTP(ITMP1),IGNTP(ITMP2),GMAX

    ITMP2 = NPH*NTH
    if (ITMP2 .GT. NORMAX) ITMP2 = NORMAX
    ITMP1 = (ITMP2 + 2)/3
    ITMP2 = ITMP1*3 - ITMP2
    ITMP3 = ITMP1
    ITMP4 = 2*ITMP1
    if (ITMP2 .EQ. 2) ITMP4 = ITMP4 - 1

    do I = 1, ITMP1
      ITMP3 = ITMP3 + 1
      ITMP4 = ITMP4 + 1

      J = (I - 1)/NTH
      TMP1 = THETS + DFLOAT(I - J*NTH - 1)*DTH
      TMP2 = PHIS + DFLOAT(J)*DPH

      J = (ITMP3 - 1)/NTH
      TMP3 = THETS + DFLOAT(ITMP3 - J*NTH - 1)*DTH
      TMP4 = PHIS + DFLOAT(J)*DPH

      J = (ITMP4 - 1)/NTH
      TMP5 = THETS + DFLOAT(ITMP4 - J*NTH - 1)*DTH
      TMP6 = PHIS + DFLOAT(J)*DPH

      TSTOR1 = GAIN(I) - GMAX

      ! GOTO 32, 33, 34 (labels 31, 32, 33) eliminated with structured IF-THEN-ELSE
      if (I .EQ. ITMP1 .AND. ITMP2 .NE. 0) then
        ! Label 32: Last iteration with incomplete row
        if (ITMP2 .EQ. 2) then
          ! Label 33: Only one value
          write(*,46) TMP1,TMP2,TSTOR1
        else
          ! Two values
          TSTOR2 = GAIN(ITMP3) - GMAX
          write(*,46) TMP1,TMP2,TSTOR1,TMP3,TMP4,TSTOR2
        end if
        exit  ! GOTO 34 eliminated
      else
        ! Label 31: Normal three-column output
        TSTOR2 = GAIN(ITMP3) - GMAX
        PINT = GAIN(ITMP4) - GMAX
        write(*,46) TMP1,TMP2,TSTOR1,TMP3,TMP4,TSTOR2,TMP5,TMP6,PINT
      end if
    end do
  end if

  ! Label 34: Return
  return

  ! Format statements (Hollerith converted to quoted strings)
35 format (///,31X,'- - - FAR FIELD GROUND PARAMETERS - - -',//)
36 format (40X,'RADIAL WIRE GROUND SCREEN',/,40X,I5,' WIRES',/,40X, &
           'WIRE LENGTH=',F8.2,' METERS',/,40X,'WIRE RADIUS=',1P,E10.3, &
           ' METERS')
37 format (40X,A6,' CLIFF',/,40X,'EDGE DISTANCE=',F9.2,' METERS',/,40X, &
           'HEIGHT=',F8.2,' METERS',/,40X,'SECOND MEDIUM -',/,40X, &
           'RELATIVE DIELECTRIC CONST.=',F7.3,/,40X,'CONDUCTIVITY=',1P,E10.3, &
           ' MHOS')
38 format (///,48X,'- - - RADIATION PATTERNS - - -')
39 format (54X,'RANGE=',1P,E13.6,' METERS',/,54X,'EXP(-JKR)/R=', &
           E12.5,' AT PHASE',0P,F7.2,' DEGREES',/)
40 format (/,2X,'- - ANGLES - -',7X,2A6,'GAINS -',7X, &
           '- - - POLARIZATION - - -',4X,'- - - E(THETA) - - -',4X, &
           '- - - E(PHI) - - -',/,2X,'THETA',5X,'PHI',7X,A6,2X,A6,3X, &
           'TOTAL',6X,'AXIAL',5X,'TILT',3X,'SENSE',2(5X,'MAGNITUDE',4X, &
           'PHASE '),/,2(1X,'DEGREES',1X),3(6X,'DB'),8X,'RATIO',5X,'DEG.',8X, &
           2(6X,'VOLTS/M',4X,'DEGREES'))
41 format (///,28X,' - - - RADIATED FIELDS NEAR GROUND - - -',//,8X, &
           '- - - LOCATION - - -',10X,'- - E(THETA) - -',8X, &
           '- - E(PHI) - -',8X,'- - E(RADIAL) - -',/,7X,'RHO',6X,'PHI',9X, &
           'Z',12X,'MAG',6X,'PHASE',9X,'MAG',6X,'PHASE',9X,'MAG',6X,'PHASE',/, &
           5X,'METERS',3X,'DEGREES',4X,'METERS',8X,'VOLTS/M',3X,'DEGREES',6X, &
           'VOLTS/M',3X,'DEGREES',6X,'VOLTS/M',3X,'DEGREES',/)
42 format(1X,F7.2,F9.2,3X,3F8.2,F11.5,F9.2,2X,A6,2(1P,E15.5,0P,F9.2))
43 format (3X,F9.2,2X,F7.2,2X,F9.2,1X,3(3X,1P,E11.4,2X,0P,F7.2))
44 format (//,3X,'AVERAGE POWER GAIN=',1P,E12.5,7X, &
           'SOLID ANGLE USED IN AVERAGING=(',0P,F7.4,')*PI STERADIANS.',//)
45 format (//,37X,'- - - - NORMALIZED GAIN - - - -',//,37X,2A6,'GAIN',/, &
           38X,'NORMALIZATION FACTOR =',F9.2,' DB',//,3(4X,'- - ANGLES - -', &
           6X,'GAIN',7X),/,3(4X,'THETA',5X,'PHI',8X,'DB',8X),/,3(3X,'DEGREES', &
           2X,'DEGREES',16X))
46 format (3(1X,2F9.2,1X,F9.2,6X))

end subroutine RDPAT
