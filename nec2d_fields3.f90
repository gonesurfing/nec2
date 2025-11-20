! =============================================================================
! nec2d_fields3 - Additional Field Routines
! =============================================================================
! Purpose: FFLD, GFLD, and related field computations
! Contains: SFLDS, FACGF, GFLD
! GOTOs eliminated: 2
! =============================================================================
  complex*16 function fbar(p)
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  implicit real*8(a-h,o-z)
  ! ***
  !
  ! FBAR IS SOMMERFELD ATTENUATION FUNCTION FOR NUMERICAL DISTANCE P
  !
  complex*16 :: z, zs, sum, pow, term, p, fj
  dimension fjx(2)
  equivalence (fj, fjx)
  data tosp/1.128379167d+0/, accs/1.d-12/, sp/1.772453851d+0/, &
       fjx/0., 1./

  z = fj * sqrt(p)

  ! Choose between series expansion and asymptotic expansion
  if (abs(z) .gt. 3.d0) then
    !
    ! ASYMPTOTIC EXPANSION
    !
    ! Determine sign handling
    if (dreal(z) .ge. 0.d0) then
      minus = 0
    else
      minus = 1
      z = -z
    end if

    zs = 0.5d0 / (z * z)
    sum = (0.d0, 0.d0)
    term = (1.d0, 0.d0)

    do i = 1, 6
      term = -term * (2.d0 * i - 1.d0) * zs
      sum = sum + term
    end do

    if (minus .eq. 1) sum = sum - 2.d0 * sp * z * exp(z * z)
    fbar = -sum

  else
    !
    ! SERIES EXPANSION
    !
    zs = z * z
    sum = z
    pow = z

    do i = 1, 100
      pow = -pow * zs / dfloat(i)
      term = pow / (2.d0 * i + 1.d0)
      sum = sum + term
      tms = dreal(term * dconjg(term))
      sms = dreal(sum * dconjg(sum))
      ! Exit loop when convergence criterion is met
      if (tms / sms .lt. accs) exit
    end do

    fbar = 1.d0 - (1.d0 - sum * tosp) * z * exp(zs) * sp

  end if

  return
  end function fbar
complex*16 function zint(sigl, rolam)
! ***
! DOUBLE PRECISION 6/4/85
!
  implicit real*8(a-h, o-z)
! ***
!
! ZINT COMPUTES THE INTERNAL IMPEDANCE OF A CIRCULAR WIRE
!
!
  complex*16 th, ph, f, g, fj, cn, br1, br2
  complex*16 cc1, cc2, cc3, cc4, cc5, cc6, cc7, cc8, cc9, cc10, cc11, cc12, &
             cc13, cc14
  dimension fjx(2), cnx(2), ccn(28)
  equivalence (fj, fjx), (cn, cnx), (cc1, ccn(1)), (cc2, ccn(3)), (cc3, &
              ccn(5)), (cc4, ccn(7)), (cc5, ccn(9)), (cc6, ccn(11)), (cc7, ccn(13)), &
              (cc8, ccn(15)), (cc9, ccn(17)), (cc10, ccn(19)), (cc11, ccn(21)), (cc12, &
              ccn(23)), (cc13, ccn(25)), (cc14, ccn(27))
  data pi, pot, tp, tpcmu/3.1415926d+0, 1.5707963d+0, 6.2831853d+0, &
                          2.368705d+3/
  data cmotp/60.00/, fjx/0., 1./, cnx/.70710678d+0, .70710678d+0/
  data ccn/6.d-7, 1.9d-6, -3.4d-6, 5.1d-6, -2.52d-5, 0., -9.06d-5, -9.01d-5, &
          0., -9.765d-4, .0110486d+0, -.0110485d+0, 0., -.3926991d+0, 1.6d-6, &
          -3.2d-6, 1.17d-5, -2.4d-6, 3.46d-5, 3.38d-5, 5.d-7, 2.452d-4, -1.3813d-3, &
          1.3811d-3, -6.25001d-2, -1.d-7, .7071068d+0, .7071068d+0/
  th(d) = (((((cc1*d + cc2)*d + cc3)*d + cc4)*d + cc5)*d + cc6)*d + cc7
  ph(d) = (((((cc8*d + cc9)*d + cc10)*d + cc11)*d + cc12)*d + cc13)*d + cc14
  f(d) = sqrt(pot/d) * exp(-cn*d + th(-8./x))
  g(d) = exp(cn*d + th(8./x)) / sqrt(tp*d)
  x = sqrt(tpcmu*sigl) * rolam

  ! Structured control flow replacing GOTOs (lines 3733-3734, 3749, 3754)
  if (x > 110.0d0) then
    ! Label 2: Large X approximation (line 3755)
    br1 = dcmplx(.70710678d+0, -.70710678d+0)
  else if (x > 8.0d0) then
    ! Label 1: Medium X using asymptotic forms (lines 3750-3753)
    br2 = fj * f(x) / pi
    br1 = g(x) + br2
    br2 = g(x) * ph(8./x) - br2 * ph(-8./x)
    br1 = br1 / br2
  else
    ! Small X using series expansion (lines 3735-3748)
    y = x / 8.
    y = y * y
    s = y * y
    ber = ((((((-9.01d-6*s + 1.22552d-3)*s - .08349609d+0)*s + 2.6419140d+0) &
          *s - 32.363456d+0)*s + 113.77778d+0)*s - 64.)*s + 1.
    bei = ((((((1.1346d-4*s - .01103667d+0)*s + .52185615d+0)*s - &
          10.567658d+0)*s + 72.817777d+0)*s - 113.77778d+0)*s + 16.)*y
    br1 = dcmplx(ber, bei)
    ber = (((((((-3.94d-6*s + 4.5957d-4)*s - .02609253d+0)*s + .66047849d+0) &
          *s - 6.0681481d+0)*s + 14.222222d+0)*s - 4.)*y)*x
    bei = ((((((4.609d-5*s - 3.79386d-3)*s + .14677204d+0)*s - 2.3116751d+0) &
          *s + 11.377778d+0)*s - 10.666667d+0)*s + .5)*x
    br2 = dcmplx(ber, bei)
    br1 = br1 / br2
  end if

  ! Label 3: Final computation (line 3756)
  zint = fj * sqrt(cmotp/sigl) * br1 / rolam
  return
end function zint
subroutine sflds(t, e)
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  implicit real*8(a-h,o-z)
  ! ***
  !
  ! SFLDX RETURNS THE FIELD DUE TO GROUND FOR A CURRENT ELEMENT ON
  ! THE SOURCE SEGMENT AT T RELATIVE TO THE SEGMENT CENTER.
  !
  complex*16 e, erv, ezv, erh, ezh, eph, t1, exk, eyk, ezk, exs, eys, ezs, exc, &
             eyc, ezc, xx1, xx2, u, u2, zrati, zrati2, frati, er, et, hrv, hzv, hrh
  common /dataj/ s, b, xj, yj, zj, cabj, sabj, salpj, exk, eyk, ezk, exs, eys, &
                 ezs, exc, eyc, ezc, rkh, ind1, indd1, ind2, indd2, iexk, ipgnd
  common /incom/ xo, yo, zo, sn, xsn, ysn, isnor
  common /gwav/ u, u2, xx1, xx2, r1, r2, zmh, zph
  common /gnd/ zrati, zrati2, frati, t1, t2, cl, ch, scrwl, scrwr, nradl, &
               ksymp, ifar, iperf
  dimension e(9)
  data pi/3.141592654d+0/, tp/6.283185308d+0/, pot/1.570796327d+0/

  xt = xj + t*cabj
  yt = yj + t*sabj
  zt = zj + t*salpj
  rhx = xo - xt
  rhy = yo - yt
  rhs = rhx*rhx + rhy*rhy
  rho = sqrt(rhs)

  ! *** GOTO 1/2 eliminated: IF/ELSE for RHO handling (lines 3472-3477)
  if (rho .gt. 0.d0) then
    rhx = rhx/rho
    rhy = rhy/rho
    phx = -rhy
    phy = rhx
  else
    rhx = 1.d0
    rhy = 0.d0
    phx = 0.d0
    phy = 1.d0
  end if

  cph = rhx*xsn + rhy*ysn
  sph = rhy*xsn - rhx*ysn
  if (abs(cph) .lt. 1.d-10) cph = 0.d0
  if (abs(sph) .lt. 1.d-10) sph = 0.d0
  zph = zo + zt
  zphs = zph*zph
  r2s = rhs + zphs
  r2 = sqrt(r2s)
  rk = r2*tp
  xx2 = dcmplx(cos(rk), -sin(rk))

  ! *** GOTO 3 eliminated: IF/ELSE for Norton vs Sommerfeld (line 3492)
  if (isnor .eq. 1) then
    !
    ! INTERPOLATE IN SOMMERFELD FIELD TABLES
    !
    ! *** GOTO 4/5 eliminated: IF/ELSE for THET calculation (lines 3534-3537)
    if (rho .lt. 1.d-12) then
      thet = pot
    else
      thet = atan(zph/rho)
    end if

    call intrp(r2, thet, erv, ezv, erh, eph)
    ! COMBINE VERTICAL AND HORIZONTAL COMPONENTS AND CONVERT TO X,Y,Z
    ! COMPONENTS.  MULTIPLY BY EXP(-JKR)/R.
    xx2 = xx2/r2
    sfac = sn*cph
    erh = xx2*(salpj*erv + sfac*erh)
    ezh = xx2*(salpj*ezv - sfac*erv)
    eph = sn*sph*xx2*eph
    ! X,Y,Z FIELDS FOR CONSTANT CURRENT
    e(1) = erh*rhx + eph*phx
    e(2) = erh*rhy + eph*phy
    e(3) = ezh
    rk = tp*t
    ! X,Y,Z FIELDS FOR SINE CURRENT
    sfac = sin(rk)
    e(4) = e(1)*sfac
    e(5) = e(2)*sfac
    e(6) = e(3)*sfac
    ! X,Y,Z FIELDS FOR COSINE CURRENT
    sfac = cos(rk)
    e(7) = e(1)*sfac
    e(8) = e(2)*sfac
    e(9) = e(3)*sfac
  else
    !
    ! USE NORTON APPROXIMATION FOR FIELD DUE TO GROUND.  CURRENT IS
    ! LUMPED AT SEGMENT CENTER WITH CURRENT MOMENT FOR CONSTANT, SINE,
    ! OR COSINE DISTRIBUTION.
    !
    zmh = 1.d0
    r1 = 1.d0
    xx1 = 0.d0
    call gwave(erv, ezv, erh, ezh, eph)
    et = -(0.d0, 4.77134d0)*frati*xx2/(r2s*r2)
    er = 2.d0*et*dcmplx(1.d+0, rk)
    et = et*dcmplx(1.d+0 - rk*rk, rk)
    hrv = (er + et)*rho*zph/r2s
    hzv = (zphs*er - rhs*et)/r2s
    hrh = (rhs*er - zphs*et)/r2s
    erv = erv - hrv
    ezv = ezv - hzv
    erh = erh + hrh
    ezh = ezh + hrv
    eph = eph + et
    erv = erv*salpj
    ezv = ezv*salpj
    erh = erh*sn*cph
    ezh = ezh*sn*cph
    eph = eph*sn*sph
    erh = erv + erh
    e(1) = (erh*rhx + eph*phx)*s
    e(2) = (erh*rhy + eph*phy)*s
    e(3) = (ezv + ezh)*s
    e(4) = 0.d0
    e(5) = 0.d0
    e(6) = 0.d0
    sfac = pi*s
    sfac = sin(sfac)/sfac
    e(7) = e(1)*sfac
    e(8) = e(2)*sfac
    e(9) = e(3)*sfac
  end if

  return
end subroutine sflds
subroutine facgf(a, b, c, d, bx, ip, ix, np, n1, mp, m1, n1c, n2c)
  !
  ! FACGF COMPUTES AND FACTORS D-C(INV(A)B).
  ! DOUBLE PRECISION 6/4/85
  !
  implicit real*8(a-h,o-z)
  complex*16 a, b, c, d, bx, sum
  common /matpar/ icase, nbloks, npblk, nlast, nblsym, npsym, nlsym, imat, &
                  icasx, nbbx, npbx, nlbx, nbbl, npbl, nlbl
  dimension a(1), b(n1c,1), c(n1c,1), d(n2c,1), bx(n1c,1), ip(1), ix(1)

  if (n2c == 0) return

  ! Initialize tape unit flag
  ibfl = 14

  ! Convert B from blocks of rows on T14 to blocks of columns on T16 if needed
  if (icasx >= 3) then
    call reblk(b, c, n1c, npbx, n2c)
    ibfl = 16
  end if

  ! Label 1: Compute INV(A)B and write on TAPE14
  npb = npbl
  if (icasx == 2) rewind 14

  do ib = 1, nbbl
    if (ib == nbbl) npb = nlbl
    if (icasx > 1) read (ibfl) ((bx(i,j), i=1,n1c), j=1,npb)
    call solves(a, ip, bx, n1c, npb, np, n1, mp, m1, 13, 13)
    if (icasx == 2) rewind 14
    if (icasx > 1) write (14) ((bx(i,j), i=1,n1c), j=1,npb)
  end do

  ! Rewind tapes if ICASX /= 1
  if (icasx /= 1) then
    rewind 11
    rewind 12
    rewind 15
    rewind ibfl
  end if

  ! Label 3: Compute D-C(INV(A)B) and write on TAPE11
  npc = npbl

  do ic = 1, nbbl
    if (ic == nbbl) npc = nlbl

    ! Read C and D matrices if ICASX /= 1
    if (icasx /= 1) then
      read (15) ((c(i,j), i=1,n1c), j=1,npc)
      read (12) ((d(i,j), i=1,n2c), j=1,npc)
      rewind 14
    end if

    ! Label 4: Compute matrix product and update D
    npb = npbl
    nic = 0

    do ib = 1, nbbl
      if (ib == nbbl) npb = nlbl
      if (icasx > 1) read (14) ((b(i,j), i=1,n1c), j=1,npb)

      do i = 1, npb
        ii = i + nic
        do j = 1, npc
          sum = (0.0d0, 0.0d0)
          do k = 1, n1c
            sum = sum + b(k,i) * c(k,j)
          end do
          d(ii,j) = d(ii,j) - sum
        end do
      end do

      nic = nic + npbl
    end do

    if (icasx > 1) write (11) ((d(i,j), i=1,n2c), j=1,npbl)
  end do

  ! Rewind tapes if ICASX /= 1
  if (icasx /= 1) then
    rewind 11
    rewind 12
    rewind 14
    rewind 15
  end if

  ! Label 9: Factor D-C(INV(A)B)
  n1cp = n1c + 1

  ! Branch based on ICASX value
  if (icasx <= 1) then
    ! Case: ICASX = 0 or 1
    call factr(n2c, d, ip(n1cp), n2c)

  else if (icasx == 4) then
    ! Label 12: Case ICASX = 4 - Use FACIO/LUNSCR for factorization
    nblsys = nblsym
    npsys = npsym
    nlsys = nlsym
    icass = icase
    nblsym = nbbl
    npsym = npbl
    nlsym = nlbl
    icase = 3
    call facio(b, n2c, 1, ix(n1cp), 11, 12, 16, 11)
    call lunscr(b, n2c, 1, ip(n1cp), ix(n1cp), 12, 11, 16)
    ! Restore original values
    nblsym = nblsys
    npsym = npsys
    nlsym = nlsys
    icase = icass

  else
    ! Label 10: Case ICASX = 2 or 3
    npb = npbl
    ic = 0

    do ib = 1, nbbl
      if (ib == nbbl) npb = nlbl
      ii = ic + 1
      ic = ic + n2c * npb
      read (11) (b(i,1), i=ii,ic)
    end do

    rewind 11
    call factr(n2c, b, ip(n1cp), n2c)
    nic = n2c * n2c
    write (11) (b(i,1), i=1,nic)
    rewind 11
  end if

  ! Label 13: Return
  return
end subroutine facgf
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
