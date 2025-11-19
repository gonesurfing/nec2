  COMPLEX*16 FUNCTION FBAR(P)
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  IMPLICIT REAL*8(A-H,O-Z)
  ! ***
  !
  ! FBAR IS SOMMERFELD ATTENUATION FUNCTION FOR NUMERICAL DISTANCE P
  !
  COMPLEX*16 :: Z, ZS, SUM, POW, TERM, P, FJ
  DIMENSION FJX(2)
  EQUIVALENCE (FJ, FJX)
  DATA TOSP/1.128379167D+0/, ACCS/1.D-12/, SP/1.772453851D+0/, &
       FJX/0., 1./

  Z = FJ * SQRT(P)

  ! Choose between series expansion and asymptotic expansion
  IF (ABS(Z) .GT. 3.D0) THEN
    !
    ! ASYMPTOTIC EXPANSION
    !
    ! Determine sign handling
    IF (DREAL(Z) .GE. 0.D0) THEN
      MINUS = 0
    ELSE
      MINUS = 1
      Z = -Z
    END IF

    ZS = 0.5D0 / (Z * Z)
    SUM = (0.D0, 0.D0)
    TERM = (1.D0, 0.D0)

    DO I = 1, 6
      TERM = -TERM * (2.D0 * I - 1.D0) * ZS
      SUM = SUM + TERM
    END DO

    IF (MINUS .EQ. 1) SUM = SUM - 2.D0 * SP * Z * EXP(Z * Z)
    FBAR = -SUM

  ELSE
    !
    ! SERIES EXPANSION
    !
    ZS = Z * Z
    SUM = Z
    POW = Z

    DO I = 1, 100
      POW = -POW * ZS / DFLOAT(I)
      TERM = POW / (2.D0 * I + 1.D0)
      SUM = SUM + TERM
      TMS = DREAL(TERM * DCONJG(TERM))
      SMS = DREAL(SUM * DCONJG(SUM))
      ! Exit loop when convergence criterion is met
      IF (TMS / SMS .LT. ACCS) EXIT
    END DO

    FBAR = 1.D0 - (1.D0 - SUM * TOSP) * Z * EXP(ZS) * SP

  END IF

  RETURN
  END FUNCTION FBAR
COMPLEX*16 FUNCTION ZINT(SIGL, ROLAM)
! ***
! DOUBLE PRECISION 6/4/85
!
  IMPLICIT REAL*8(A-H, O-Z)
! ***
!
! ZINT COMPUTES THE INTERNAL IMPEDANCE OF A CIRCULAR WIRE
!
!
  COMPLEX*16 TH, PH, F, G, FJ, CN, BR1, BR2
  COMPLEX*16 CC1, CC2, CC3, CC4, CC5, CC6, CC7, CC8, CC9, CC10, CC11, CC12, &
             CC13, CC14
  DIMENSION FJX(2), CNX(2), CCN(28)
  EQUIVALENCE (FJ, FJX), (CN, CNX), (CC1, CCN(1)), (CC2, CCN(3)), (CC3, &
              CCN(5)), (CC4, CCN(7)), (CC5, CCN(9)), (CC6, CCN(11)), (CC7, CCN(13)), &
              (CC8, CCN(15)), (CC9, CCN(17)), (CC10, CCN(19)), (CC11, CCN(21)), (CC12, &
              CCN(23)), (CC13, CCN(25)), (CC14, CCN(27))
  DATA PI, POT, TP, TPCMU/3.1415926D+0, 1.5707963D+0, 6.2831853D+0, &
                          2.368705D+3/
  DATA CMOTP/60.00/, FJX/0., 1./, CNX/.70710678D+0, .70710678D+0/
  DATA CCN/6.D-7, 1.9D-6, -3.4D-6, 5.1D-6, -2.52D-5, 0., -9.06D-5, -9.01D-5, &
          0., -9.765D-4, .0110486D+0, -.0110485D+0, 0., -.3926991D+0, 1.6D-6, &
          -3.2D-6, 1.17D-5, -2.4D-6, 3.46D-5, 3.38D-5, 5.D-7, 2.452D-4, -1.3813D-3, &
          1.3811D-3, -6.25001D-2, -1.D-7, .7071068D+0, .7071068D+0/
  TH(D) = (((((CC1*D + CC2)*D + CC3)*D + CC4)*D + CC5)*D + CC6)*D + CC7
  PH(D) = (((((CC8*D + CC9)*D + CC10)*D + CC11)*D + CC12)*D + CC13)*D + CC14
  F(D) = SQRT(POT/D) * EXP(-CN*D + TH(-8./X))
  G(D) = EXP(CN*D + TH(8./X)) / SQRT(TP*D)
  X = SQRT(TPCMU*SIGL) * ROLAM

  ! Structured control flow replacing GOTOs (lines 3733-3734, 3749, 3754)
  IF (X > 110.0D0) THEN
    ! Label 2: Large X approximation (line 3755)
    BR1 = DCMPLX(.70710678D+0, -.70710678D+0)
  ELSE IF (X > 8.0D0) THEN
    ! Label 1: Medium X using asymptotic forms (lines 3750-3753)
    BR2 = FJ * F(X) / PI
    BR1 = G(X) + BR2
    BR2 = G(X) * PH(8./X) - BR2 * PH(-8./X)
    BR1 = BR1 / BR2
  ELSE
    ! Small X using series expansion (lines 3735-3748)
    Y = X / 8.
    Y = Y * Y
    S = Y * Y
    BER = ((((((-9.01D-6*S + 1.22552D-3)*S - .08349609D+0)*S + 2.6419140D+0) &
          *S - 32.363456D+0)*S + 113.77778D+0)*S - 64.)*S + 1.
    BEI = ((((((1.1346D-4*S - .01103667D+0)*S + .52185615D+0)*S - &
          10.567658D+0)*S + 72.817777D+0)*S - 113.77778D+0)*S + 16.)*Y
    BR1 = DCMPLX(BER, BEI)
    BER = (((((((-3.94D-6*S + 4.5957D-4)*S - .02609253D+0)*S + .66047849D+0) &
          *S - 6.0681481D+0)*S + 14.222222D+0)*S - 4.)*Y)*X
    BEI = ((((((4.609D-5*S - 3.79386D-3)*S + .14677204D+0)*S - 2.3116751D+0) &
          *S + 11.377778D+0)*S - 10.666667D+0)*S + .5)*X
    BR2 = DCMPLX(BER, BEI)
    BR1 = BR1 / BR2
  END IF

  ! Label 3: Final computation (line 3756)
  ZINT = FJ * SQRT(CMOTP/SIGL) * BR1 / ROLAM
  RETURN
END FUNCTION ZINT
SUBROUTINE SFLDS(T, E)
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  IMPLICIT REAL*8(A-H,O-Z)
  ! ***
  !
  ! SFLDX RETURNS THE FIELD DUE TO GROUND FOR A CURRENT ELEMENT ON
  ! THE SOURCE SEGMENT AT T RELATIVE TO THE SEGMENT CENTER.
  !
  COMPLEX*16 E, ERV, EZV, ERH, EZH, EPH, T1, EXK, EYK, EZK, EXS, EYS, EZS, EXC, &
             EYC, EZC, XX1, XX2, U, U2, ZRATI, ZRATI2, FRATI, ER, ET, HRV, HZV, HRH
  COMMON /DATAJ/ S, B, XJ, YJ, ZJ, CABJ, SABJ, SALPJ, EXK, EYK, EZK, EXS, EYS, &
                 EZS, EXC, EYC, EZC, RKH, IND1, INDD1, IND2, INDD2, IEXK, IPGND
  COMMON /INCOM/ XO, YO, ZO, SN, XSN, YSN, ISNOR
  COMMON /GWAV/ U, U2, XX1, XX2, R1, R2, ZMH, ZPH
  COMMON /GND/ ZRATI, ZRATI2, FRATI, T1, T2, CL, CH, SCRWL, SCRWR, NRADL, &
               KSYMP, IFAR, IPERF
  DIMENSION E(9)
  DATA PI/3.141592654D+0/, TP/6.283185308D+0/, POT/1.570796327D+0/

  XT = XJ + T*CABJ
  YT = YJ + T*SABJ
  ZT = ZJ + T*SALPJ
  RHX = XO - XT
  RHY = YO - YT
  RHS = RHX*RHX + RHY*RHY
  RHO = SQRT(RHS)

  ! *** GOTO 1/2 eliminated: IF/ELSE for RHO handling (lines 3472-3477)
  IF (RHO .GT. 0.D0) THEN
    RHX = RHX/RHO
    RHY = RHY/RHO
    PHX = -RHY
    PHY = RHX
  ELSE
    RHX = 1.D0
    RHY = 0.D0
    PHX = 0.D0
    PHY = 1.D0
  END IF

  CPH = RHX*XSN + RHY*YSN
  SPH = RHY*XSN - RHX*YSN
  IF (ABS(CPH) .LT. 1.D-10) CPH = 0.D0
  IF (ABS(SPH) .LT. 1.D-10) SPH = 0.D0
  ZPH = ZO + ZT
  ZPHS = ZPH*ZPH
  R2S = RHS + ZPHS
  R2 = SQRT(R2S)
  RK = R2*TP
  XX2 = DCMPLX(COS(RK), -SIN(RK))

  ! *** GOTO 3 eliminated: IF/ELSE for Norton vs Sommerfeld (line 3492)
  IF (ISNOR .EQ. 1) THEN
    !
    ! INTERPOLATE IN SOMMERFELD FIELD TABLES
    !
    ! *** GOTO 4/5 eliminated: IF/ELSE for THET calculation (lines 3534-3537)
    IF (RHO .LT. 1.D-12) THEN
      THET = POT
    ELSE
      THET = ATAN(ZPH/RHO)
    END IF

    CALL INTRP(R2, THET, ERV, EZV, ERH, EPH)
    ! COMBINE VERTICAL AND HORIZONTAL COMPONENTS AND CONVERT TO X,Y,Z
    ! COMPONENTS.  MULTIPLY BY EXP(-JKR)/R.
    XX2 = XX2/R2
    SFAC = SN*CPH
    ERH = XX2*(SALPJ*ERV + SFAC*ERH)
    EZH = XX2*(SALPJ*EZV - SFAC*ERV)
    EPH = SN*SPH*XX2*EPH
    ! X,Y,Z FIELDS FOR CONSTANT CURRENT
    E(1) = ERH*RHX + EPH*PHX
    E(2) = ERH*RHY + EPH*PHY
    E(3) = EZH
    RK = TP*T
    ! X,Y,Z FIELDS FOR SINE CURRENT
    SFAC = SIN(RK)
    E(4) = E(1)*SFAC
    E(5) = E(2)*SFAC
    E(6) = E(3)*SFAC
    ! X,Y,Z FIELDS FOR COSINE CURRENT
    SFAC = COS(RK)
    E(7) = E(1)*SFAC
    E(8) = E(2)*SFAC
    E(9) = E(3)*SFAC
  ELSE
    !
    ! USE NORTON APPROXIMATION FOR FIELD DUE TO GROUND.  CURRENT IS
    ! LUMPED AT SEGMENT CENTER WITH CURRENT MOMENT FOR CONSTANT, SINE,
    ! OR COSINE DISTRIBUTION.
    !
    ZMH = 1.D0
    R1 = 1.D0
    XX1 = 0.D0
    CALL GWAVE(ERV, EZV, ERH, EZH, EPH)
    ET = -(0.D0, 4.77134D0)*FRATI*XX2/(R2S*R2)
    ER = 2.D0*ET*DCMPLX(1.D+0, RK)
    ET = ET*DCMPLX(1.D+0 - RK*RK, RK)
    HRV = (ER + ET)*RHO*ZPH/R2S
    HZV = (ZPHS*ER - RHS*ET)/R2S
    HRH = (RHS*ER - ZPHS*ET)/R2S
    ERV = ERV - HRV
    EZV = EZV - HZV
    ERH = ERH + HRH
    EZH = EZH + HRV
    EPH = EPH + ET
    ERV = ERV*SALPJ
    EZV = EZV*SALPJ
    ERH = ERH*SN*CPH
    EZH = EZH*SN*CPH
    EPH = EPH*SN*SPH
    ERH = ERV + ERH
    E(1) = (ERH*RHX + EPH*PHX)*S
    E(2) = (ERH*RHY + EPH*PHY)*S
    E(3) = (EZV + EZH)*S
    E(4) = 0.D0
    E(5) = 0.D0
    E(6) = 0.D0
    SFAC = PI*S
    SFAC = SIN(SFAC)/SFAC
    E(7) = E(1)*SFAC
    E(8) = E(2)*SFAC
    E(9) = E(3)*SFAC
  END IF

  RETURN
END SUBROUTINE SFLDS
SUBROUTINE FACGF(A, B, C, D, BX, IP, IX, NP, N1, MP, M1, N1C, N2C)
  !
  ! FACGF COMPUTES AND FACTORS D-C(INV(A)B).
  ! DOUBLE PRECISION 6/4/85
  !
  IMPLICIT REAL*8(A-H,O-Z)
  COMPLEX*16 A, B, C, D, BX, SUM
  COMMON /MATPAR/ ICASE, NBLOKS, NPBLK, NLAST, NBLSYM, NPSYM, NLSYM, IMAT, &
                  ICASX, NBBX, NPBX, NLBX, NBBL, NPBL, NLBL
  DIMENSION A(1), B(N1C,1), C(N1C,1), D(N2C,1), BX(N1C,1), IP(1), IX(1)

  IF (N2C == 0) RETURN

  ! Initialize tape unit flag
  IBFL = 14

  ! Convert B from blocks of rows on T14 to blocks of columns on T16 if needed
  IF (ICASX >= 3) THEN
    CALL REBLK(B, C, N1C, NPBX, N2C)
    IBFL = 16
  END IF

  ! Label 1: Compute INV(A)B and write on TAPE14
  NPB = NPBL
  IF (ICASX == 2) REWIND 14

  DO IB = 1, NBBL
    IF (IB == NBBL) NPB = NLBL
    IF (ICASX > 1) READ (IBFL) ((BX(I,J), I=1,N1C), J=1,NPB)
    CALL SOLVES(A, IP, BX, N1C, NPB, NP, N1, MP, M1, 13, 13)
    IF (ICASX == 2) REWIND 14
    IF (ICASX > 1) WRITE (14) ((BX(I,J), I=1,N1C), J=1,NPB)
  END DO

  ! Rewind tapes if ICASX /= 1
  IF (ICASX /= 1) THEN
    REWIND 11
    REWIND 12
    REWIND 15
    REWIND IBFL
  END IF

  ! Label 3: Compute D-C(INV(A)B) and write on TAPE11
  NPC = NPBL

  DO IC = 1, NBBL
    IF (IC == NBBL) NPC = NLBL

    ! Read C and D matrices if ICASX /= 1
    IF (ICASX /= 1) THEN
      READ (15) ((C(I,J), I=1,N1C), J=1,NPC)
      READ (12) ((D(I,J), I=1,N2C), J=1,NPC)
      REWIND 14
    END IF

    ! Label 4: Compute matrix product and update D
    NPB = NPBL
    NIC = 0

    DO IB = 1, NBBL
      IF (IB == NBBL) NPB = NLBL
      IF (ICASX > 1) READ (14) ((B(I,J), I=1,N1C), J=1,NPB)

      DO I = 1, NPB
        II = I + NIC
        DO J = 1, NPC
          SUM = (0.0D0, 0.0D0)
          DO K = 1, N1C
            SUM = SUM + B(K,I) * C(K,J)
          END DO
          D(II,J) = D(II,J) - SUM
        END DO
      END DO

      NIC = NIC + NPBL
    END DO

    IF (ICASX > 1) WRITE (11) ((D(I,J), I=1,N2C), J=1,NPBL)
  END DO

  ! Rewind tapes if ICASX /= 1
  IF (ICASX /= 1) THEN
    REWIND 11
    REWIND 12
    REWIND 14
    REWIND 15
  END IF

  ! Label 9: Factor D-C(INV(A)B)
  N1CP = N1C + 1

  ! Branch based on ICASX value
  IF (ICASX <= 1) THEN
    ! Case: ICASX = 0 or 1
    CALL FACTR(N2C, D, IP(N1CP), N2C)

  ELSE IF (ICASX == 4) THEN
    ! Label 12: Case ICASX = 4 - Use FACIO/LUNSCR for factorization
    NBLSYS = NBLSYM
    NPSYS = NPSYM
    NLSYS = NLSYM
    ICASS = ICASE
    NBLSYM = NBBL
    NPSYM = NPBL
    NLSYM = NLBL
    ICASE = 3
    CALL FACIO(B, N2C, 1, IX(N1CP), 11, 12, 16, 11)
    CALL LUNSCR(B, N2C, 1, IP(N1CP), IX(N1CP), 12, 11, 16)
    ! Restore original values
    NBLSYM = NBLSYS
    NPSYM = NPSYS
    NLSYM = NLSYS
    ICASE = ICASS

  ELSE
    ! Label 10: Case ICASX = 2 or 3
    NPB = NPBL
    IC = 0

    DO IB = 1, NBBL
      IF (IB == NBBL) NPB = NLBL
      II = IC + 1
      IC = IC + N2C * NPB
      READ (11) (B(I,1), I=II,IC)
    END DO

    REWIND 11
    CALL FACTR(N2C, B, IP(N1CP), N2C)
    NIC = N2C * N2C
    WRITE (11) (B(I,1), I=1,NIC)
    REWIND 11
  END IF

  ! Label 13: Return
  RETURN
END SUBROUTINE FACGF
subroutine gfld(rho, phi, rz, eth, epi, erd, ux, ksymp)
  !
  ! GFLD computes the radiated field including ground wave.
  !
  ! Modernized from FORTRAN 77 to free-form Fortran 90
  ! - Eliminated all 18 GOTOs using structured control flow
  ! - Converted to free-form syntax with ! comments and & continuation
  ! - Converted labeled DO loops to modern DO...END DO
  ! - Preserved all field computation logic exactly
  !

  ! Note: MAXSEG parameter comes from NEC2D3000.INC via compilation
  implicit real*8(a-h,o-z)
  integer, parameter :: maxseg = 3000

  complex*16 cur, epi, cix, ciy, ciz, exa, xx1, xx2, u, u2, erv, ezv, erh, eph
  complex*16 ezh, ex, ey, eth, ux, erd

  common /data/ x(maxseg), y(maxseg), z(maxseg), si(maxseg), bi(maxseg), &
                alp(maxseg), bet(maxseg), wlam, icon1(2*maxseg), icon2(2*maxseg), &
                itag(2*maxseg), iconx(maxseg), ld, n1, n2, n, np, m1, m2, m, mp, ipsym
  common /angl/ salp(maxseg)
  common /crnt/ air(maxseg), aii(maxseg), bir(maxseg), bii(maxseg), &
                cir(maxseg), cii(maxseg), cur(3*maxseg)
  common /gwav/ u, u2, xx1, xx2, r1, r2, zmh, zph

  dimension cab(1), sab(1)
  equivalence (cab(1), alp(1)), (sab(1), bet(1))

  data pi, tp / 3.141592654d+0, 6.283185308d+0 /

  r = sqrt(rho*rho + rz*rz)

  ! Check if only space wave computation is needed
  ! Original: lines 2002-2005 (3 GOTOs to label 1, 1 GOTO to label 4)
  if (ksymp == 1 .or. abs(ux) > 0.5d0 .or. r > 1.0d5) then

    ! ========================================================================
    ! Computation of space wave only (label 1, 2, 3)
    ! Original: lines 2009-2019 (2 GOTOs eliminated)
    ! ========================================================================

    ! Compute theta angle
    ! Original: lines 2009-2012 (GOTO 2, GOTO 3 eliminated)
    if (rz < 1.0d-20) then
      thet = pi * 0.5d0
    else
      thet = atan(rho/rz)
    end if

    ! Compute field and apply phase factor
    call ffld(thet, phi, eth, epi)
    arg = -tp * r
    exa = dcmplx(cos(arg), sin(arg)) / r
    eth = eth * exa
    epi = epi * exa
    erd = (0.0d0, 0.0d0)
    return

  else

    ! ========================================================================
    ! Computation of space and ground waves (label 4)
    ! Original: lines 2023-2130 (13 GOTOs eliminated)
    ! ========================================================================

    u = ux
    u2 = u * u
    phx = -sin(phi)
    phy = cos(phi)
    rx = rho * phy
    ry = -rho * phx
    cix = (0.0d0, 0.0d0)
    ciy = (0.0d0, 0.0d0)
    ciz = (0.0d0, 0.0d0)

    ! Summation of field from individual segments
    do i = 1, n
      dx = cab(i)
      dy = sab(i)
      dz = salp(i)
      rix = rx - x(i)
      riy = ry - y(i)
      rhs = rix*rix + riy*riy
      rhp = sqrt(rhs)

      ! Compute horizontal direction cosines
      ! Original: lines 2043-2048 (2 GOTOs eliminated)
      if (rhp < 1.0d-6) then
        rhx = 1.0d0
        rhy = 0.0d0
      else
        rhx = rix / rhp
        rhy = riy / rhp
      end if

      ! Compute angles
      ! Original: lines 2049-2058 (2 GOTOs eliminated)
      calp = 1.0d0 - dz*dz
      if (calp < 1.0d-6) then
        cph = rhx
        sph = rhy
      else
        calp = sqrt(calp)
        cbet = dx / calp
        sbet = dy / calp
        cph = rhx*cbet + rhy*sbet
        sph = rhy*cbet - rhx*sbet
      end if

      el = pi * si(i)
      rfl = -1.0d0

      ! Integration of (current)*(phase factor) over segment and image
      ! for constant, sine, and cosine current distributions
      do k = 1, 2
        rfl = -rfl
        riz = rz - z(i)*rfl
        rxyz = sqrt(rix*rix + riy*riy + riz*riz)
        rnx = rix / rxyz
        rny = riy / rxyz
        rnz = riz / rxyz
        omega = -(rnx*dx + rny*dy + rnz*dz*rfl)
        sill = omega * el
        top = el + sill
        bot = el - sill

        ! Compute A coefficient
        ! Original: lines 2076-2079 (2 GOTOs eliminated)
        if (abs(omega) < 1.0d-7) then
          a = (2.0d0 - omega*omega*el*el/3.0d0) * el
        else
          a = 2.0d0 * sin(sill) / omega
        end if

        ! Compute TOO for B and C coefficients
        ! Original: lines 2080-2083 (2 GOTOs eliminated)
        if (abs(top) < 1.0d-7) then
          too = 1.0d0 - top*top/6.0d0
        else
          too = sin(top) / top
        end if

        ! Compute BOO for B and C coefficients
        ! Original: lines 2084-2087 (2 GOTOs eliminated)
        if (abs(bot) < 1.0d-7) then
          boo = 1.0d0 - bot*bot/6.0d0
        else
          boo = sin(bot) / bot
        end if

        ! Compute B and C coefficients and combine with currents
        b = el * (boo - too)
        c = el * (boo + too)
        rr = a*air(i) + b*bii(i) + c*cir(i)
        ri = a*aii(i) - b*bir(i) + c*cii(i)
        arg = tp * (x(i)*rnx + y(i)*rny + z(i)*rnz*rfl)
        exa = dcmplx(cos(arg), sin(arg)) * dcmplx(rr, ri) / tp

        ! Store results for direct and image contributions
        ! Original: lines 2094-2101 (2 GOTOs eliminated)
        if (k == 1) then
          xx1 = exa
          r1 = rxyz
          zmh = riz
        else
          xx2 = exa
          r2 = rxyz
          zph = riz
        end if

      end do  ! k loop (label 16)

      ! Call subroutine to compute the field of segment including ground wave
      call gwave(erv, ezv, erh, ezh, eph)
      erh = erh*cph*calp + erv*dz
      eph = eph*sph*calp
      ezh = ezh*cph*calp + ezv*dz
      ex = erh*rhx - eph*rhy
      ey = erh*rhy + eph*rhx
      cix = cix + ex
      ciy = ciy + ey
      ciz = ciz + ezh

    end do  ! i loop (label 17)

    ! Apply final phase factor and transform to spherical components
    arg = -tp * r
    exa = dcmplx(cos(arg), sin(arg))
    cix = cix * exa
    ciy = ciy * exa
    ciz = ciz * exa
    rnx = rx / r
    rny = ry / r
    rnz = rz / r
    thx = rnz * phy
    thy = -rnz * phx
    thz = -rho / r
    eth = cix*thx + ciy*thy + ciz*thz
    epi = cix*phx + ciy*phy
    erd = cix*rnx + ciy*rny + ciz*rnz
    return

  end if

end subroutine gfld
