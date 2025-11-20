! =============================================================================
! nec2d_rdpat - Radiation Patterns
! =============================================================================
! Purpose: Radiation pattern computation and output
! Contains: RDPAT
! =============================================================================
subroutine rdpat
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  ! COMPUTE RADIATION PATTERN, GAIN, NORMALIZED GAIN
  !
  ! Modernized: Eliminated 44 GOTOs using structured control flow
  !
  implicit real*8(a-h,o-z)

  ! Parameter from NEC2DPAR.INC
  integer, parameter :: maxseg = 3000
  integer, parameter :: normax = 4*maxseg

  ! Character variables override IMPLICIT for these names
  character*6 igntp(10), igax(4), igtp(4), hpol(3), hcir, hclif, isens
  character*1 hblk

  complex*16 eth,eph,erd,zrati,zrati2,t1,frati

  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
                alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
                itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common/save/epsr,sig,scrwlt,scrwrt,fmhz,ip(2*maxseg),kcom
  common /gnd/zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl, &
              ksymp,ifar,iperf
  common/fpat/thets,phis,dth,dph,rfld,gnor,clt,cht,epsr2,sig2, &
              xpr6,pinr,pnlr,ploss,xnr,ynr,znr,dxnr,dynr,dznr,nth,nph,ipd,iavp, &
              inor,iax,ixtyp,near,nfeh,nrx,nry,nrz
  common /scratm/ gain(normax)
  common /plot/ iplp1,iplp2,iplp3,iplp4

  data hpol/'LINEAR','RIGHT','LEFT'/,hblk,hcir/' ','CIRCLE'/
  data igtp/'    - ','POWER ','- DIRE','CTIVE '/
  data igax/' MAJOR',' MINOR',' VERT.',' HOR. '/
  data igntp/' MAJOR',' AXIS ',' MINOR',' AXIS ','   VER','TICAL ', &
             ' HORIZ','ONTAL ','      ','TOTAL '/
  data pi,ta,td/3.141592654d+0,1.745329252d-02,57.29577951d+0/

  ! Section 1: Ground parameter output (labels 1, 2 eliminated)
  ! GOTO 1, 2 eliminated with structured IF-THEN-ELSE
  if (ifar .ge. 2) then
    write(*,35)

    if (ifar .gt. 3) then
      write(*,36) nradl,scrwlt,scrwrt
    end if

    if (ifar .ne. 4) then
      ! Label 1 path
      if (ifar .eq. 2 .or. ifar .eq. 5) then
        hclif = hpol(1)
      else if (ifar .eq. 3 .or. ifar .eq. 6) then
        hclif = hcir
      end if

      cl = clt/wlam
      ch = cht/wlam
      zrati2 = sqrt(1./dcmplx(epsr2,-sig2*wlam*59.96))
      write(*,37) hclif,clt,cht,epsr2,sig2
    end if
  end if

  ! Section 2: Header output (labels 3, 4, 5 eliminated)
  ! GOTO 3, 4, 5 eliminated with structured IF-THEN-ELSE
  if (ifar .eq. 1) then
    ! Near-field header
    write(*,41)
  else
    ! Far-field header (label 3)
    i = 2*ipd + 1
    j = i + 1
    itmp1 = 2*iax + 1
    itmp2 = itmp1 + 1
    write(*,38)

    ! GOTO 4 eliminated
    if (rfld .ge. 1.d-20) then
      exrm = 1./rfld
      exra = rfld/wlam
      exra = -360.*(exra - aint(exra))
      write(*,39) rfld,exrm,exra
    end if

    ! Label 4
    write(*,40) igtp(i),igtp(j),igax(itmp1),igax(itmp2)
  end if

  ! Section 3: Gain constant initialization (labels 6, 7, 8 eliminated)
  ! GOTO 6, 7, 8 eliminated with structured IF-THEN-ELSE
  if (ixtyp .ne. 0 .and. ixtyp .ne. 5) then
    if (ixtyp .eq. 4) then
      ! Label 6
      pinr = 394.51*xpr6*xpr6*wlam*wlam
    else
      ! Default path
      prad = 0.
      gcon = 4.*pi/(1.+xpr6*xpr6)
      gcop = gcon
      ! Skip to label 8
    end if
  end if

  ! Label 7 and 8 combined
  if (ixtyp .eq. 0 .or. ixtyp .eq. 5 .or. ixtyp .eq. 4) then
    gcop = wlam*wlam*2.*pi/(376.73*pinr)
    prad = pinr - ploss - pnlr
    gcon = gcop
    if (ipd .ne. 0) gcon = gcon*pinr/prad
  end if

  ! Label 8
  i = 0
  gmax = -1.e10
  pint = 0.
  tmp1 = dph*ta
  tmp2 = .5*dth*ta
  phi = phis - dph

  ! Main computation loop (label 29 is DO loop end)
  do kph = 1, nph
    phi = phi + dph
    pha = phi*ta
    thet = thets - dth

    do kth = 1, nth
      thet = thet + dth

      ! GOTO 29 eliminated with CYCLE
      if (ksymp .eq. 2 .and. thet .gt. 90.01 .and. ifar .ne. 1) cycle

      tha = thet*ta

      ! Field computation (labels 9, 10 eliminated)
      ! GOTO 9, 10 eliminated with IF-THEN-ELSE
      if (ifar .eq. 1) then
        ! Label 9: Near field
        call gfld(rfld/wlam, pha, thet/wlam, eth, eph, erd, zrati, ksymp)
        erdm = abs(erd)
        erda = cang(erd)
      else
        ! Far field
        call ffld(tha, pha, eth, eph)
      end if

      ! Label 10: Common processing
      ethm2 = dreal(eth*dconjg(eth))
      ethm = sqrt(ethm2)
      etha = cang(eth)
      ephm2 = dreal(eph*dconjg(eph))
      ephm = sqrt(ephm2)
      epha = cang(eph)

      ! Near-field output (label 28) or elliptical polarization calc
      ! GOTO 28 eliminated with IF-THEN-ELSE
      if (ifar .ne. 1) then
        ! Elliptical polarization calculation (labels 11-16 eliminated)
        ! GOTO 11, 12, 13, 14, 15, 16 eliminated with structured IF-THEN-ELSE
        if (ethm2 .le. 1.d-20 .and. ephm2 .le. 1.d-20) then
          ! Zero field case
          tilta = 0.
          emajr2 = 0.
          eminr2 = 0.
          axrat = 0.
          isens = hblk
        else
          ! Label 11: Non-zero field
          dfaz = epha - etha

          ! GOTO 12, 13 eliminated
          if (epha .lt. 0.) then
            ! Label 12
            dfaz2 = dfaz + 360.
          else
            dfaz2 = dfaz - 360.
          end if

          ! Label 13
          if (abs(dfaz) .gt. abs(dfaz2)) dfaz = dfaz2

          cdfaz = cos(dfaz*ta)
          tstor1 = ethm2 - ephm2
          tstor2 = 2.*ephm*ethm*cdfaz
          tilta = .5*atgn2(tstor2, tstor1)
          stilta = sin(tilta)
          tstor1 = tstor1*stilta*stilta
          tstor2 = tstor2*stilta*cos(tilta)
          emajr2 = -tstor1 + tstor2 + ethm2
          eminr2 = tstor1 - tstor2 + ephm2
          if (eminr2 .lt. 0.) eminr2 = 0.
          axrat = sqrt(eminr2/emajr2)
          tilta = tilta*td

          ! GOTO 14, 15, 16 eliminated with structured IF-THEN-ELSE
          if (axrat .le. 1.d-5) then
            isens = hpol(1)
          else
            ! Label 14
            if (dfaz .le. 0.) then
              isens = hpol(2)
            else
              ! Label 15
              isens = hpol(3)
            end if
          end if
        end if

        ! Label 16: Compute gains in dB
        gnmj = db10(gcon*emajr2)
        gnmn = db10(gcon*eminr2)
        gnv = db10(gcon*ethm2)
        gnh = db10(gcon*ephm2)
        gtot = db10(gcon*(ethm2 + ephm2))

        ! Gain normalization (labels 17-23 eliminated)
        ! GOTO 17-22 (computed GOTO) eliminated with SELECT CASE
        ! GOTO 23 eliminated with IF-THEN
        if (inor .ge. 1) then
          i = i + 1

          ! GOTO 23 eliminated
          if (i .le. normax) then
            ! Computed GOTO replaced with SELECT CASE
            select case (inor)
              case (1)
                ! Label 17
                tstor1 = gnmj
              case (2)
                ! Label 18
                tstor1 = gnmn
              case (3)
                ! Label 19
                tstor1 = gnv
              case (4)
                ! Label 20
                tstor1 = gnh
              case (5)
                ! Label 21
                tstor1 = gtot
            end select

            ! Label 22
            gain(i) = tstor1
            if (tstor1 .gt. gmax) gmax = tstor1
          end if
        end if

        ! Label 23: Average power integration and output
        ! GOTO 24, 29 eliminated with structured IF-THEN-ELSE
        if (iavp .ne. 0) then
          tstor1 = gcop*(ethm2 + ephm2)
          tmp3 = tha - tmp2
          tmp4 = tha + tmp2
          if (kth .eq. 1) tmp3 = tha
          if (kth .eq. nth) tmp4 = tha
          da = abs(tmp1*(cos(tmp3) - cos(tmp4)))
          if (kph .eq. 1 .or. kph .eq. nph) da = .5*da
          pint = pint + tstor1*da

          ! GOTO 29 eliminated with CYCLE
          if (iavp .eq. 2) cycle
        end if

        ! Label 24: Prepare output fields
        ! GOTO 25, 26 eliminated with IF-THEN-ELSE
        if (iax .eq. 1) then
          ! Label 25
          tmp5 = gnv
          tmp6 = gnh
        else
          tmp5 = gnmj
          tmp6 = gnmn
        end if

        ! Label 26: Scale field magnitudes
        ethm = ethm*wlam
        ephm = ephm*wlam

        ! GOTO 27 eliminated with IF-THEN
        if (rfld .ge. 1.d-20) then
          ethm = ethm*exrm
          etha = etha + exra
          ephm = ephm*exrm
          epha = epha + exra
        end if

        ! Label 27: Write far-field output
        write(*,42) thet,phi,tmp5,tmp6,gtot,axrat,tilta,isens,ethm,etha, &
                    ephm,epha

        ! Plot data output (labels 290, 299 eliminated)
        ! GOTO 299, 290 eliminated with structured IF-THEN-ELSE
        if (iplp1 .eq. 3) then
          if (iplp3 .ne. 0) then
            if (iplp2 .eq. 1 .and. iplp3 .eq. 1) write(8,*) thet,ethm,etha
            if (iplp2 .eq. 1 .and. iplp3 .eq. 2) write(8,*) thet,ephm,epha
            if (iplp2 .eq. 2 .and. iplp3 .eq. 1) write(8,*) phi,ethm,etha
            if (iplp2 .eq. 2 .and. iplp3 .eq. 2) write(8,*) phi,ephm,epha

            if (iplp4 .eq. 0) cycle  ! GOTO 299 eliminated
          end if

          ! Label 290
          if (iplp2 .eq. 1 .and. iplp4 .eq. 1) write(8,*) thet,tmp5
          if (iplp2 .eq. 1 .and. iplp4 .eq. 2) write(8,*) thet,tmp6
          if (iplp2 .eq. 1 .and. iplp4 .eq. 3) write(8,*) thet,gtot
          if (iplp2 .eq. 2 .and. iplp4 .eq. 1) write(8,*) phi,tmp5
          if (iplp2 .eq. 2 .and. iplp4 .eq. 2) write(8,*) phi,tmp6
          if (iplp2 .eq. 2 .and. iplp4 .eq. 3) write(8,*) phi,gtot
        end if

        ! Label 299: Continue loop
      else
        ! Label 28: Near-field output
        write(*,43) rfld,phi,thet,ethm,etha,ephm,epha,erdm,erda
      end if

    end do  ! Label 29: KTH loop
  end do  ! KPH loop

  ! Section 4: Summary statistics (labels 30-34 eliminated)
  ! GOTO 30, 34 eliminated with structured IF-THEN-ELSE
  if (iavp .ne. 0) then
    ! Label 30: Average power output
    tmp3 = thets*ta
    tmp4 = tmp3 + dth*ta*dfloat(nth - 1)
    tmp3 = abs(dph*ta*dfloat(nph - 1)*(cos(tmp3) - cos(tmp4)))
    pint = pint/tmp3
    tmp3 = tmp3/pi
    write(*,44) pint,tmp3
  end if

  ! Normalized gain output
  ! GOTO 34 eliminated with IF-THEN
  if (inor .ne. 0) then
    if (abs(gnor) .gt. 1.d-20) gmax = gnor

    itmp1 = (inor - 1)*2 + 1
    itmp2 = itmp1 + 1
    write(*,45) igntp(itmp1),igntp(itmp2),gmax

    itmp2 = nph*nth
    if (itmp2 .gt. normax) itmp2 = normax
    itmp1 = (itmp2 + 2)/3
    itmp2 = itmp1*3 - itmp2
    itmp3 = itmp1
    itmp4 = 2*itmp1
    if (itmp2 .eq. 2) itmp4 = itmp4 - 1

    do i = 1, itmp1
      itmp3 = itmp3 + 1
      itmp4 = itmp4 + 1

      j = (i - 1)/nth
      tmp1 = thets + dfloat(i - j*nth - 1)*dth
      tmp2 = phis + dfloat(j)*dph

      j = (itmp3 - 1)/nth
      tmp3 = thets + dfloat(itmp3 - j*nth - 1)*dth
      tmp4 = phis + dfloat(j)*dph

      j = (itmp4 - 1)/nth
      tmp5 = thets + dfloat(itmp4 - j*nth - 1)*dth
      tmp6 = phis + dfloat(j)*dph

      tstor1 = gain(i) - gmax

      ! GOTO 32, 33, 34 (labels 31, 32, 33) eliminated with structured IF-THEN-ELSE
      if (i .eq. itmp1 .and. itmp2 .ne. 0) then
        ! Label 32: Last iteration with incomplete row
        if (itmp2 .eq. 2) then
          ! Label 33: Only one value
          write(*,46) tmp1,tmp2,tstor1
        else
          ! Two values
          tstor2 = gain(itmp3) - gmax
          write(*,46) tmp1,tmp2,tstor1,tmp3,tmp4,tstor2
        end if
        exit  ! GOTO 34 eliminated
      else
        ! Label 31: Normal three-column output
        tstor2 = gain(itmp3) - gmax
        pint = gain(itmp4) - gmax
        write(*,46) tmp1,tmp2,tstor1,tmp3,tmp4,tstor2,tmp5,tmp6,pint
      end if
    end do
  end if

  ! Label 34: Return
  return

  ! Format statements (Hollerith converted to quoted strings)
35 format (///,31x,'- - - FAR FIELD GROUND PARAMETERS - - -',//)
36 format (40x,'RADIAL WIRE GROUND SCREEN',/,40x,i5,' WIRES',/,40x, &
           'WIRE LENGTH=',f8.2,' METERS',/,40x,'WIRE RADIUS=',1p,e10.3, &
           ' METERS')
37 format (40x,a6,' CLIFF',/,40x,'EDGE DISTANCE=',f9.2,' METERS',/,40x, &
           'HEIGHT=',f8.2,' METERS',/,40x,'SECOND MEDIUM -',/,40x, &
           'RELATIVE DIELECTRIC CONST.=',f7.3,/,40x,'CONDUCTIVITY=',1p,e10.3, &
           ' MHOS')
38 format (///,48x,'- - - RADIATION PATTERNS - - -')
39 format (54x,'RANGE=',1p,e13.6,' METERS',/,54x,'EXP(-JKR)/R=', &
           e12.5,' AT PHASE',0p,f7.2,' DEGREES',/)
40 format (/,2x,'- - ANGLES - -',7x,2a6,'GAINS -',7x, &
           '- - - POLARIZATION - - -',4x,'- - - E(THETA) - - -',4x, &
           '- - - E(PHI) - - -',/,2x,'THETA',5x,'PHI',7x,a6,2x,a6,3x, &
           'TOTAL',6x,'AXIAL',5x,'TILT',3x,'SENSE',2(5x,'MAGNITUDE',4x, &
           'PHASE '),/,2(1x,'DEGREES',1x),3(6x,'DB'),8x,'RATIO',5x,'DEG.',8x, &
           2(6x,'VOLTS/M',4x,'DEGREES'))
41 format (///,28x,' - - - RADIATED FIELDS NEAR GROUND - - -',//,8x, &
           '- - - LOCATION - - -',10x,'- - E(THETA) - -',8x, &
           '- - E(PHI) - -',8x,'- - E(RADIAL) - -',/,7x,'RHO',6x,'PHI',9x, &
           'Z',12x,'MAG',6x,'PHASE',9x,'MAG',6x,'PHASE',9x,'MAG',6x,'PHASE',/, &
           5x,'METERS',3x,'DEGREES',4x,'METERS',8x,'VOLTS/M',3x,'DEGREES',6x, &
           'VOLTS/M',3x,'DEGREES',6x,'VOLTS/M',3x,'DEGREES',/)
42 format(1x,f7.2,f9.2,3x,3f8.2,f11.5,f9.2,2x,a6,2(1p,e15.5,0p,f9.2))
43 format (3x,f9.2,2x,f7.2,2x,f9.2,1x,3(3x,1p,e11.4,2x,0p,f7.2))
44 format (//,3x,'AVERAGE POWER GAIN=',1p,e12.5,7x, &
           'SOLID ANGLE USED IN AVERAGING=(',0p,f7.4,')*PI STERADIANS.',//)
45 format (//,37x,'- - - - NORMALIZED GAIN - - - -',//,37x,2a6,'GAIN',/, &
           38x,'NORMALIZATION FACTOR =',f9.2,' DB',//,3(4x,'- - ANGLES - -', &
           6x,'GAIN',7x),/,3(4x,'THETA',5x,'PHI',8x,'DB',8x),/,3(3x,'DEGREES', &
           2x,'DEGREES',16x))
46 format (3(1x,2f9.2,1x,f9.2,6x))

end subroutine rdpat
