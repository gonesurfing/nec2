SUBROUTINE RDPAT
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  ! COMPUTE RADIATION PATTERN, GAIN, NORMALIZED GAIN
  !
  ! Modernized: Eliminated 44 GOTOs using structured control flow
  !
  IMPLICIT REAL*8(A-H,O-Z)

  ! Parameter from NEC2DPAR.INC
  INTEGER, PARAMETER :: MAXSEG = 3000
  INTEGER, PARAMETER :: NORMAX = 4*MAXSEG

  ! Character variables override IMPLICIT for these names
  CHARACTER*6 IGNTP(10), IGAX(4), IGTP(4), HPOL(3), HCIR, HCLIF, ISENS
  CHARACTER*1 HBLK

  COMPLEX*16 ETH,EPH,ERD,ZRATI,ZRATI2,T1,FRATI

  COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
                ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
                ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  COMMON/SAVE/EPSR,SIG,SCRWLT,SCRWRT,FMHZ,IP(2*MAXSEG),KCOM
  COMMON /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL, &
              KSYMP,IFAR,IPERF
  COMMON/FPAT/THETS,PHIS,DTH,DPH,RFLD,GNOR,CLT,CHT,EPSR2,SIG2, &
              XPR6,PINR,PNLR,PLOSS,XNR,YNR,ZNR,DXNR,DYNR,DZNR,NTH,NPH,IPD,IAVP, &
              INOR,IAX,IXTYP,NEAR,NFEH,NRX,NRY,NRZ
  COMMON /SCRATM/ GAIN(NORMAX)
  COMMON /PLOT/ IPLP1,IPLP2,IPLP3,IPLP4

  DATA HPOL/'LINEAR','RIGHT','LEFT'/,HBLK,HCIR/' ','CIRCLE'/
  DATA IGTP/'    - ','POWER ','- DIRE','CTIVE '/
  DATA IGAX/' MAJOR',' MINOR',' VERT.',' HOR. '/
  DATA IGNTP/' MAJOR',' AXIS ',' MINOR',' AXIS ','   VER','TICAL ', &
             ' HORIZ','ONTAL ','      ','TOTAL '/
  DATA PI,TA,TD/3.141592654D+0,1.745329252D-02,57.29577951D+0/

  ! Section 1: Ground parameter output (labels 1, 2 eliminated)
  ! GOTO 1, 2 eliminated with structured IF-THEN-ELSE
  IF (IFAR .GE. 2) THEN
    WRITE(*,35)

    IF (IFAR .GT. 3) THEN
      WRITE(*,36) NRADL,SCRWLT,SCRWRT
    END IF

    IF (IFAR .NE. 4) THEN
      ! Label 1 path
      IF (IFAR .EQ. 2 .OR. IFAR .EQ. 5) THEN
        HCLIF = HPOL(1)
      ELSE IF (IFAR .EQ. 3 .OR. IFAR .EQ. 6) THEN
        HCLIF = HCIR
      END IF

      CL = CLT/WLAM
      CH = CHT/WLAM
      ZRATI2 = SQRT(1./DCMPLX(EPSR2,-SIG2*WLAM*59.96))
      WRITE(*,37) HCLIF,CLT,CHT,EPSR2,SIG2
    END IF
  END IF

  ! Section 2: Header output (labels 3, 4, 5 eliminated)
  ! GOTO 3, 4, 5 eliminated with structured IF-THEN-ELSE
  IF (IFAR .EQ. 1) THEN
    ! Near-field header
    WRITE(*,41)
  ELSE
    ! Far-field header (label 3)
    I = 2*IPD + 1
    J = I + 1
    ITMP1 = 2*IAX + 1
    ITMP2 = ITMP1 + 1
    WRITE(*,38)

    ! GOTO 4 eliminated
    IF (RFLD .GE. 1.D-20) THEN
      EXRM = 1./RFLD
      EXRA = RFLD/WLAM
      EXRA = -360.*(EXRA - AINT(EXRA))
      WRITE(*,39) RFLD,EXRM,EXRA
    END IF

    ! Label 4
    WRITE(*,40) IGTP(I),IGTP(J),IGAX(ITMP1),IGAX(ITMP2)
  END IF

  ! Section 3: Gain constant initialization (labels 6, 7, 8 eliminated)
  ! GOTO 6, 7, 8 eliminated with structured IF-THEN-ELSE
  IF (IXTYP .NE. 0 .AND. IXTYP .NE. 5) THEN
    IF (IXTYP .EQ. 4) THEN
      ! Label 6
      PINR = 394.51*XPR6*XPR6*WLAM*WLAM
    ELSE
      ! Default path
      PRAD = 0.
      GCON = 4.*PI/(1.+XPR6*XPR6)
      GCOP = GCON
      ! Skip to label 8
    END IF
  END IF

  ! Label 7 and 8 combined
  IF (IXTYP .EQ. 0 .OR. IXTYP .EQ. 5 .OR. IXTYP .EQ. 4) THEN
    GCOP = WLAM*WLAM*2.*PI/(376.73*PINR)
    PRAD = PINR - PLOSS - PNLR
    GCON = GCOP
    IF (IPD .NE. 0) GCON = GCON*PINR/PRAD
  END IF

  ! Label 8
  I = 0
  GMAX = -1.E10
  PINT = 0.
  TMP1 = DPH*TA
  TMP2 = .5*DTH*TA
  PHI = PHIS - DPH

  ! Main computation loop (label 29 is DO loop end)
  DO KPH = 1, NPH
    PHI = PHI + DPH
    PHA = PHI*TA
    THET = THETS - DTH

    DO KTH = 1, NTH
      THET = THET + DTH

      ! GOTO 29 eliminated with CYCLE
      IF (KSYMP .EQ. 2 .AND. THET .GT. 90.01 .AND. IFAR .NE. 1) CYCLE

      THA = THET*TA

      ! Field computation (labels 9, 10 eliminated)
      ! GOTO 9, 10 eliminated with IF-THEN-ELSE
      IF (IFAR .EQ. 1) THEN
        ! Label 9: Near field
        CALL GFLD(RFLD/WLAM, PHA, THET/WLAM, ETH, EPH, ERD, ZRATI, KSYMP)
        ERDM = ABS(ERD)
        ERDA = CANG(ERD)
      ELSE
        ! Far field
        CALL FFLD(THA, PHA, ETH, EPH)
      END IF

      ! Label 10: Common processing
      ETHM2 = DREAL(ETH*DCONJG(ETH))
      ETHM = SQRT(ETHM2)
      ETHA = CANG(ETH)
      EPHM2 = DREAL(EPH*DCONJG(EPH))
      EPHM = SQRT(EPHM2)
      EPHA = CANG(EPH)

      ! Near-field output (label 28) or elliptical polarization calc
      ! GOTO 28 eliminated with IF-THEN-ELSE
      IF (IFAR .NE. 1) THEN
        ! Elliptical polarization calculation (labels 11-16 eliminated)
        ! GOTO 11, 12, 13, 14, 15, 16 eliminated with structured IF-THEN-ELSE
        IF (ETHM2 .LE. 1.D-20 .AND. EPHM2 .LE. 1.D-20) THEN
          ! Zero field case
          TILTA = 0.
          EMAJR2 = 0.
          EMINR2 = 0.
          AXRAT = 0.
          ISENS = HBLK
        ELSE
          ! Label 11: Non-zero field
          DFAZ = EPHA - ETHA

          ! GOTO 12, 13 eliminated
          IF (EPHA .LT. 0.) THEN
            ! Label 12
            DFAZ2 = DFAZ + 360.
          ELSE
            DFAZ2 = DFAZ - 360.
          END IF

          ! Label 13
          IF (ABS(DFAZ) .GT. ABS(DFAZ2)) DFAZ = DFAZ2

          CDFAZ = COS(DFAZ*TA)
          TSTOR1 = ETHM2 - EPHM2
          TSTOR2 = 2.*EPHM*ETHM*CDFAZ
          TILTA = .5*ATGN2(TSTOR2, TSTOR1)
          STILTA = SIN(TILTA)
          TSTOR1 = TSTOR1*STILTA*STILTA
          TSTOR2 = TSTOR2*STILTA*COS(TILTA)
          EMAJR2 = -TSTOR1 + TSTOR2 + ETHM2
          EMINR2 = TSTOR1 - TSTOR2 + EPHM2
          IF (EMINR2 .LT. 0.) EMINR2 = 0.
          AXRAT = SQRT(EMINR2/EMAJR2)
          TILTA = TILTA*TD

          ! GOTO 14, 15, 16 eliminated with structured IF-THEN-ELSE
          IF (AXRAT .LE. 1.D-5) THEN
            ISENS = HPOL(1)
          ELSE
            ! Label 14
            IF (DFAZ .LE. 0.) THEN
              ISENS = HPOL(2)
            ELSE
              ! Label 15
              ISENS = HPOL(3)
            END IF
          END IF
        END IF

        ! Label 16: Compute gains in dB
        GNMJ = DB10(GCON*EMAJR2)
        GNMN = DB10(GCON*EMINR2)
        GNV = DB10(GCON*ETHM2)
        GNH = DB10(GCON*EPHM2)
        GTOT = DB10(GCON*(ETHM2 + EPHM2))

        ! Gain normalization (labels 17-23 eliminated)
        ! GOTO 17-22 (computed GOTO) eliminated with SELECT CASE
        ! GOTO 23 eliminated with IF-THEN
        IF (INOR .GE. 1) THEN
          I = I + 1

          ! GOTO 23 eliminated
          IF (I .LE. NORMAX) THEN
            ! Computed GOTO replaced with SELECT CASE
            SELECT CASE (INOR)
              CASE (1)
                ! Label 17
                TSTOR1 = GNMJ
              CASE (2)
                ! Label 18
                TSTOR1 = GNMN
              CASE (3)
                ! Label 19
                TSTOR1 = GNV
              CASE (4)
                ! Label 20
                TSTOR1 = GNH
              CASE (5)
                ! Label 21
                TSTOR1 = GTOT
            END SELECT

            ! Label 22
            GAIN(I) = TSTOR1
            IF (TSTOR1 .GT. GMAX) GMAX = TSTOR1
          END IF
        END IF

        ! Label 23: Average power integration and output
        ! GOTO 24, 29 eliminated with structured IF-THEN-ELSE
        IF (IAVP .NE. 0) THEN
          TSTOR1 = GCOP*(ETHM2 + EPHM2)
          TMP3 = THA - TMP2
          TMP4 = THA + TMP2
          IF (KTH .EQ. 1) TMP3 = THA
          IF (KTH .EQ. NTH) TMP4 = THA
          DA = ABS(TMP1*(COS(TMP3) - COS(TMP4)))
          IF (KPH .EQ. 1 .OR. KPH .EQ. NPH) DA = .5*DA
          PINT = PINT + TSTOR1*DA

          ! GOTO 29 eliminated with CYCLE
          IF (IAVP .EQ. 2) CYCLE
        END IF

        ! Label 24: Prepare output fields
        ! GOTO 25, 26 eliminated with IF-THEN-ELSE
        IF (IAX .EQ. 1) THEN
          ! Label 25
          TMP5 = GNV
          TMP6 = GNH
        ELSE
          TMP5 = GNMJ
          TMP6 = GNMN
        END IF

        ! Label 26: Scale field magnitudes
        ETHM = ETHM*WLAM
        EPHM = EPHM*WLAM

        ! GOTO 27 eliminated with IF-THEN
        IF (RFLD .GE. 1.D-20) THEN
          ETHM = ETHM*EXRM
          ETHA = ETHA + EXRA
          EPHM = EPHM*EXRM
          EPHA = EPHA + EXRA
        END IF

        ! Label 27: Write far-field output
        WRITE(*,42) THET,PHI,TMP5,TMP6,GTOT,AXRAT,TILTA,ISENS,ETHM,ETHA, &
                    EPHM,EPHA

        ! Plot data output (labels 290, 299 eliminated)
        ! GOTO 299, 290 eliminated with structured IF-THEN-ELSE
        IF (IPLP1 .EQ. 3) THEN
          IF (IPLP3 .NE. 0) THEN
            IF (IPLP2 .EQ. 1 .AND. IPLP3 .EQ. 1) WRITE(8,*) THET,ETHM,ETHA
            IF (IPLP2 .EQ. 1 .AND. IPLP3 .EQ. 2) WRITE(8,*) THET,EPHM,EPHA
            IF (IPLP2 .EQ. 2 .AND. IPLP3 .EQ. 1) WRITE(8,*) PHI,ETHM,ETHA
            IF (IPLP2 .EQ. 2 .AND. IPLP3 .EQ. 2) WRITE(8,*) PHI,EPHM,EPHA

            IF (IPLP4 .EQ. 0) CYCLE  ! GOTO 299 eliminated
          END IF

          ! Label 290
          IF (IPLP2 .EQ. 1 .AND. IPLP4 .EQ. 1) WRITE(8,*) THET,TMP5
          IF (IPLP2 .EQ. 1 .AND. IPLP4 .EQ. 2) WRITE(8,*) THET,TMP6
          IF (IPLP2 .EQ. 1 .AND. IPLP4 .EQ. 3) WRITE(8,*) THET,GTOT
          IF (IPLP2 .EQ. 2 .AND. IPLP4 .EQ. 1) WRITE(8,*) PHI,TMP5
          IF (IPLP2 .EQ. 2 .AND. IPLP4 .EQ. 2) WRITE(8,*) PHI,TMP6
          IF (IPLP2 .EQ. 2 .AND. IPLP4 .EQ. 3) WRITE(8,*) PHI,GTOT
        END IF

        ! Label 299: Continue loop
      ELSE
        ! Label 28: Near-field output
        WRITE(*,43) RFLD,PHI,THET,ETHM,ETHA,EPHM,EPHA,ERDM,ERDA
      END IF

    END DO  ! Label 29: KTH loop
  END DO  ! KPH loop

  ! Section 4: Summary statistics (labels 30-34 eliminated)
  ! GOTO 30, 34 eliminated with structured IF-THEN-ELSE
  IF (IAVP .NE. 0) THEN
    ! Label 30: Average power output
    TMP3 = THETS*TA
    TMP4 = TMP3 + DTH*TA*DFLOAT(NTH - 1)
    TMP3 = ABS(DPH*TA*DFLOAT(NPH - 1)*(COS(TMP3) - COS(TMP4)))
    PINT = PINT/TMP3
    TMP3 = TMP3/PI
    WRITE(*,44) PINT,TMP3
  END IF

  ! Normalized gain output
  ! GOTO 34 eliminated with IF-THEN
  IF (INOR .NE. 0) THEN
    IF (ABS(GNOR) .GT. 1.D-20) GMAX = GNOR

    ITMP1 = (INOR - 1)*2 + 1
    ITMP2 = ITMP1 + 1
    WRITE(*,45) IGNTP(ITMP1),IGNTP(ITMP2),GMAX

    ITMP2 = NPH*NTH
    IF (ITMP2 .GT. NORMAX) ITMP2 = NORMAX
    ITMP1 = (ITMP2 + 2)/3
    ITMP2 = ITMP1*3 - ITMP2
    ITMP3 = ITMP1
    ITMP4 = 2*ITMP1
    IF (ITMP2 .EQ. 2) ITMP4 = ITMP4 - 1

    DO I = 1, ITMP1
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
      IF (I .EQ. ITMP1 .AND. ITMP2 .NE. 0) THEN
        ! Label 32: Last iteration with incomplete row
        IF (ITMP2 .EQ. 2) THEN
          ! Label 33: Only one value
          WRITE(*,46) TMP1,TMP2,TSTOR1
        ELSE
          ! Two values
          TSTOR2 = GAIN(ITMP3) - GMAX
          WRITE(*,46) TMP1,TMP2,TSTOR1,TMP3,TMP4,TSTOR2
        END IF
        EXIT  ! GOTO 34 eliminated
      ELSE
        ! Label 31: Normal three-column output
        TSTOR2 = GAIN(ITMP3) - GMAX
        PINT = GAIN(ITMP4) - GMAX
        WRITE(*,46) TMP1,TMP2,TSTOR1,TMP3,TMP4,TSTOR2,TMP5,TMP6,PINT
      END IF
    END DO
  END IF

  ! Label 34: Return
  RETURN

  ! Format statements (Hollerith converted to quoted strings)
35 FORMAT (///,31X,'- - - FAR FIELD GROUND PARAMETERS - - -',//)
36 FORMAT (40X,'RADIAL WIRE GROUND SCREEN',/,40X,I5,' WIRES',/,40X, &
           'WIRE LENGTH=',F8.2,' METERS',/,40X,'WIRE RADIUS=',1P,E10.3, &
           ' METERS')
37 FORMAT (40X,A6,' CLIFF',/,40X,'EDGE DISTANCE=',F9.2,' METERS',/,40X, &
           'HEIGHT=',F8.2,' METERS',/,40X,'SECOND MEDIUM -',/,40X, &
           'RELATIVE DIELECTRIC CONST.=',F7.3,/,40X,'CONDUCTIVITY=',1P,E10.3, &
           ' MHOS')
38 FORMAT (///,48X,'- - - RADIATION PATTERNS - - -')
39 FORMAT (54X,'RANGE=',1P,E13.6,' METERS',/,54X,'EXP(-JKR)/R=', &
           E12.5,' AT PHASE',0P,F7.2,' DEGREES',/)
40 FORMAT (/,2X,'- - ANGLES - -',7X,2A6,'GAINS -',7X, &
           '- - - POLARIZATION - - -',4X,'- - - E(THETA) - - -',4X, &
           '- - - E(PHI) - - -',/,2X,'THETA',5X,'PHI',7X,A6,2X,A6,3X, &
           'TOTAL',6X,'AXIAL',5X,'TILT',3X,'SENSE',2(5X,'MAGNITUDE',4X, &
           'PHASE '),/,2(1X,'DEGREES',1X),3(6X,'DB'),8X,'RATIO',5X,'DEG.',8X, &
           2(6X,'VOLTS/M',4X,'DEGREES'))
41 FORMAT (///,28X,' - - - RADIATED FIELDS NEAR GROUND - - -',//,8X, &
           '- - - LOCATION - - -',10X,'- - E(THETA) - -',8X, &
           '- - E(PHI) - -',8X,'- - E(RADIAL) - -',/,7X,'RHO',6X,'PHI',9X, &
           'Z',12X,'MAG',6X,'PHASE',9X,'MAG',6X,'PHASE',9X,'MAG',6X,'PHASE',/, &
           5X,'METERS',3X,'DEGREES',4X,'METERS',8X,'VOLTS/M',3X,'DEGREES',6X, &
           'VOLTS/M',3X,'DEGREES',6X,'VOLTS/M',3X,'DEGREES',/)
42 FORMAT(1X,F7.2,F9.2,3X,3F8.2,F11.5,F9.2,2X,A6,2(1P,E15.5,0P,F9.2))
43 FORMAT (3X,F9.2,2X,F7.2,2X,F9.2,1X,3(3X,1P,E11.4,2X,0P,F7.2))
44 FORMAT (//,3X,'AVERAGE POWER GAIN=',1P,E12.5,7X, &
           'SOLID ANGLE USED IN AVERAGING=(',0P,F7.4,')*PI STERADIANS.',//)
45 FORMAT (//,37X,'- - - - NORMALIZED GAIN - - - -',//,37X,2A6,'GAIN',/, &
           38X,'NORMALIZATION FACTOR =',F9.2,' DB',//,3(4X,'- - ANGLES - -', &
           6X,'GAIN',7X),/,3(4X,'THETA',5X,'PHI',8X,'DB',8X),/,3(3X,'DEGREES', &
           2X,'DEGREES',16X))
46 FORMAT (3(1X,2F9.2,1X,F9.2,6X))

END SUBROUTINE RDPAT
