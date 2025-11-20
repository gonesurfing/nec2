! =============================================================================
! nec2d_matrix3 - Patch and Wire Matrix Routines
! =============================================================================
! Purpose: Patch-to-patch and wire-to-patch interactions
! Contains: CMSW, CMWS, CMWW
! GOTOs eliminated: 60
! =============================================================================
subroutine cmsw(j1, j2, i1, i2, cm, cw, ncw, nrow, itrp)
!
! cmsw computes matrix elements for e along wires due to patch current
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)
  complex*16 cm, zrati, zrati2, t1, exk, eyk, ezk, exs, eys, ezs, exc, eyc, ezc
  complex*16 emel, cw, frati

  common /data/ x(maxseg), y(maxseg), z(maxseg), si(maxseg), bi(maxseg), &
                alp(maxseg), bet(maxseg), wlam, icon1(2*maxseg), icon2(2*maxseg), &
                itag(2*maxseg), iconx(maxseg), ld, n1, n2, n, np, m1, m2, m, mp, ipsym
  common /angl/ salp(maxseg)
  common /gnd/ zrati, zrati2, frati, t1, t2, cl, ch, scrwl, scrwr, nradl, &
               ksymp, ifar, iperf
  common /dataj/ s, b, xj, yj, zj, cabj, sabj, salpj, exk, eyk, ezk, exs, eys, &
                 ezs, exc, eyc, ezc, rkh, ind1, indd1, ind2, indd2, iexk, ipgnd
  common /segj/ ax(jmax), bx(jmax), cx(jmax), jco(jmax), &
                jsno, iscon(50), nscon, ipcon(10), npcon

  dimension cab(1), sab(1), cm(nrow,1), cw(nrow,1)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1), emel(9)

  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), &
              (t2z,itag), (cab,alp), (sab,bet)
  equivalence (t1xj,cabj), (t1yj,sabj), (t1zj,salpj), (t2xj,b), &
              (t2yj,ind1), (t2zj,ind2)

  data pi/3.141592654d+0/

  ldp = ld + 1
  neqs = n - n1 + 2*(m - m1)

  ! Check if this is the special case (ITRP < 0)
  if (itrp < 0) then
    ! Special path: For old segment connecting to old patch on one end
    ! and new segment on other end - integrate singular component (9)
    ! of surface current only

    if (j1 >= i1 .and. j1 <= i2) then
      ipch = icon1(j1)

      ! Check ICON1 first
      if (ipch >= 10000) then
        ipch = ipch - 10000
        fsign = -1.0d0
      else
        ! Check ICON2
        ipch = icon2(j1)
        if (ipch >= 10000) then
          ipch = ipch - 10000
          fsign = 1.0d0
        end if
      end if

      ! Only proceed if IPCH is valid
      if (ipch >= 10000 .and. ipch <= m1) then
        js = ldp - ipch
        ipgnd = 1
        t1xj = t1x(js)
        t1yj = t1y(js)
        t1zj = t1z(js)
        t2xj = t2x(js)
        t2yj = t2y(js)
        t2zj = t2z(js)
        xj = x(js)
        yj = y(js)
        zj = z(js)
        s = bi(js)
        xi = x(j1)
        yi = y(j1)
        zi = z(j1)
        cabi = cab(j1)
        sabi = sab(j1)
        salpi = salp(j1)

        call pcint(xi, yj, zi, cabi, sabi, salpi, emel)
        py = pi * si(j1) * fsign
        px = sin(py)
        py = cos(py)
        exc = emel(9) * fsign
        il = jco(jsno)
        k = j1 - i1 + 1
        cw(k,il) = cw(k,il) + exc * (ax(jsno) + bx(jsno)*px + cx(jsno)*py)
      end if
    end if

  else
    ! Normal path: Standard matrix element computation

    k = 0
    icgo = 1

    ! Observation loop
    do i = i1, i2
      k = k + 1
      xi = x(i)
      yi = y(i)
      zi = z(i)
      cabi = cab(i)
      sabi = sab(i)
      salpi = salp(i)
      ipch = 0

      ! Check which connection has a patch
      if (icon1(i) >= 10000) then
        ipch = icon1(i) - 10000
        fsign = -1.0d0
      else if (icon2(i) >= 10000) then
        ipch = icon2(i) - 10000
        fsign = 1.0d0
      end if

      jl = 0

      ! Source loop
      do j = j1, j2
        js = ldp - j
        jl = jl + 2
        t1xj = t1x(js)
        t1yj = t1y(js)
        t1zj = t1z(js)
        t2xj = t2x(js)
        t2yj = t2y(js)
        t2zj = t2z(js)
        xj = x(js)
        yj = y(js)
        zj = z(js)
        s = bi(js)

        ! Ground loop
        do ip = 1, ksymp
          ipgnd = ip

          ! Check if we need special patch integration
          if ((ipch == j .or. icgo /= 1) .and. ip /= 2) then
            ! Patch integration path

            ! Only compute PCINT if ICGO=1
            if (icgo == 1) then
              call pcint(xi, yi, zi, cabi, sabi, salpi, emel)
              py = pi * si(i) * fsign
              px = sin(py)
              py = cos(py)
              exc = emel(9) * fsign
              call trio(i)

              ! Compute IL index
              if (i > n1) then
                il = i - ncw
                if (i <= np) il = ((il-1)/np) * 2*mp + il
              else
                il = neqs + iconx(i)
              end if

              ! Fill CW based on ITRP
              if (itrp == 0) then
                cw(k,il) = cw(k,il) + exc * (ax(jsno) + bx(jsno)*px + cx(jsno)*py)
              else
                cw(il,k) = cw(il,k) + exc * (ax(jsno) + bx(jsno)*px + cx(jsno)*py)
              end if
            end if

            ! Fill CM based on ITRP
            if (itrp == 0) then
              cm(k,jl-1) = emel(icgo)
              cm(k,jl) = emel(icgo+4)
            else
              cm(jl-1,k) = emel(icgo)
              cm(jl,k) = emel(icgo+4)
            end if

            icgo = icgo + 1
            if (icgo == 5) icgo = 1

          else
            ! Standard field computation path

            call unere(xi, yi, zi)

            ! Fill CM based on ITRP
            if (itrp == 0) then
              ! Normal fill
              cm(k,jl-1) = cm(k,jl-1) + exk*cabi + eyk*sabi + ezk*salpi
              cm(k,jl) = cm(k,jl) + exs*cabi + eys*sabi + ezs*salpi
            else
              ! Transposed fill
              cm(jl-1,k) = cm(jl-1,k) + exk*cabi + eyk*sabi + ezk*salpi
              cm(jl,k) = cm(jl,k) + exs*cabi + eys*sabi + ezs*salpi
            end if

          end if  ! End of patch vs. standard computation

        end do  ! End ground loop (IP)
      end do  ! End source loop (J)
    end do  ! End observation loop (I)

  end if  ! End of ITRP check

end subroutine cmsw

subroutine cmws(j, i1, i2, cm, nr, cw, nw, itrp)
!
! cmws computes matrix elements for wire-surface interactions
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)

  complex*16 cm, cw, etk, ets, etc, exk, eyk, ezk, exs, eys, ezs, exc, eyc, ezc
  common /data/ x(maxseg), y(maxseg), z(maxseg), si(maxseg), bi(maxseg), &
                alp(maxseg), bet(maxseg), wlam, icon1(2*maxseg), icon2(2*maxseg), &
                itag(2*maxseg), iconx(maxseg), ld, n1, n2, n, np, m1, m2, m, mp, ipsym
  common /angl/ salp(maxseg)
  common /segj/ ax(jmax), bx(jmax), cx(jmax), jco(jmax), &
                jsno, iscon(50), nscon, ipcon(10), npcon
  common /dataj/ s, b, xj, yj, zj, cabj, sabj, salpj, exk, eyk, ezk, exs, eys, &
                 ezs, exc, eyc, ezc, rkh, ind1, indd1, ind2, indd2, iexk, ipgnd
  dimension cm(nr,1), cw(nw,1), cab(1), sab(1)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1)
  equivalence (cab,alp), (sab,bet), (t1x,si), (t1y,alp), (t1z,bet)
  equivalence (t2x,icon1), (t2y,icon2), (t2z,itag)

  ldp = ld + 1
  s = si(j)
  b = bi(j)
  xj = x(j)
  yj = y(j)
  zj = z(j)
  cabj = cab(j)
  sabj = sab(j)
  salpj = salp(j)

  ! Observation loop
  ipr = 0
  do i = i1, i2
    ipr = ipr + 1
    ipatch = (i+1) / 2
    ik = i - (i/2) * 2

    ! Compute JS and call HSFLD unless IK==0 and IPR!=1
    if (.not. (ik == 0 .and. ipr /= 1)) then
      js = ldp - ipatch
      xi = x(js)
      yi = y(js)
      zi = z(js)
      call hsfld(xi, yi, zi, 0.d0)
    end if

    ! Select between T1 and T2 vectors based on IK
    if (ik == 0) then
      tx = t1x(js)
      ty = t1y(js)
      tz = t1z(js)
    else
      tx = t2x(js)
      ty = t2y(js)
      tz = t2z(js)
    end if

    ! Compute field components
    etk = -(exk*tx + eyk*ty + ezk*tz) * salp(js)
    ets = -(exs*tx + eys*ty + ezs*tz) * salp(js)
    etc = -(exc*tx + eyc*ty + ezc*tz) * salp(js)

    ! Fill matrix elements - element locations determined by connection data
    if (itrp == 0) then
      ! Normal fill
      do ij = 1, jsno
        jx = jco(ij)
        cm(ipr,jx) = cm(ipr,jx) + etk*ax(ij) + ets*bx(ij) + etc*cx(ij)
      end do

    else if (itrp == 1) then
      ! Transposed fill
      do ij = 1, jsno
        jx = jco(ij)
        cm(jx,ipr) = cm(jx,ipr) + etk*ax(ij) + ets*bx(ij) + etc*cx(ij)
      end do

    else if (itrp == 2) then
      ! Transposed fill - C(WS) and D(WS)PRIME (=CW)
      do ij = 1, jsno
        jx = jco(ij)
        if (jx > nr) then
          ! Use CW array for indices beyond NR
          jx = jx - nr
          cw(jx,ipr) = cw(jx,ipr) + etk*ax(ij) + ets*bx(ij) + etc*cx(ij)
        else
          ! Use CM array for indices within NR
          cm(jx,ipr) = cm(jx,ipr) + etk*ax(ij) + ets*bx(ij) + etc*cx(ij)
        end if
      end do

    end if

  end do

end subroutine cmws

subroutine cmww(j, i1, i2, cm, nr, cw, nw, itrp)
!
! cmww computes matrix elements for wire-wire interactions
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)

  complex*16 cm, cw, etk, ets, etc, exk, eyk, ezk, exs, eys, ezs, exc, eyc, ezc
  common /data/ x(maxseg), y(maxseg), z(maxseg), si(maxseg), bi(maxseg), &
                alp(maxseg), bet(maxseg), wlam, icon1(2*maxseg), icon2(2*maxseg), &
                itag(2*maxseg), iconx(maxseg), ld, n1, n2, n, np, m1, m2, m, mp, ipsym
  common /angl/ salp(maxseg)
  common /segj/ ax(jmax), bx(jmax), cx(jmax), jco(jmax), &
                jsno, iscon(50), nscon, ipcon(10), npcon
  common /dataj/ s, b, xj, yj, zj, cabj, sabj, salpj, exk, eyk, ezk, exs, eys, &
                 ezs, exc, eyc, ezc, rkh, ind1, indd1, ind2, indd2, iexk, ipgnd
  dimension cm(nr,1), cw(nw,1), cab(1), sab(1)
  equivalence (cab,alp), (sab,bet)

  ! Set source segment parameters
  s = si(j)
  b = bi(j)
  xj = x(j)
  yj = y(j)
  zj = z(j)
  cabj = cab(j)
  sabj = sab(j)
  salpj = salp(j)

  ! Decide whether ext. t.w. approx. can be used
  ! Determine IND1 based on connection data ICON1(J)

  if (iexk /= 0) then
    ! Check ICON1(J) to determine IND1
    ipr = icon1(j)

    if (ipr > 10000) then
      ! Special segment flag - use approximation
      ind1 = 0
    else if (ipr < 0) then
      ! Negative connection - check reverse connection
      ipr = -ipr
      if (-icon1(ipr) == j) then
        ! Valid reverse connection - check alignment
        xi = abs(cabj*cab(ipr) + sabj*sab(ipr) + salpj*salp(ipr))
        if (xi >= 0.999999d0 .and. abs(bi(ipr)/b - 1.d0) <= 1.d-6) then
          ind1 = 0  ! Aligned, use approximation
        else
          ind1 = 2  ! Not aligned, full calculation
        end if
      else
        ind1 = 2  ! Invalid connection, full calculation
      end if
    else if (ipr == 0) then
      ! No connection at end 1
      ind1 = 1
    else  ! ipr > 0
      ! Positive connection - check forward connection
      if (ipr == j) then
        ! Self-connection - check if segment is effectively zero
        if (cabj*cabj + sabj*sabj > 1.d-8) then
          ind1 = 2  ! Non-zero segment, full calculation
        else
          ind1 = 0  ! Zero segment, use approximation
        end if
      else if (icon2(ipr) == j) then
        ! Connected via end 2 of IPR - check alignment
        xi = abs(cabj*cab(ipr) + sabj*sab(ipr) + salpj*salp(ipr))
        if (xi >= 0.999999d0 .and. abs(bi(ipr)/b - 1.d0) <= 1.d-6) then
          ind1 = 0  ! Aligned, use approximation
        else
          ind1 = 2  ! Not aligned, full calculation
        end if
      else
        ind1 = 2  ! Invalid connection, full calculation
      end if
    end if

    ! Determine IND2 based on connection data ICON2(J)
    ipr = icon2(j)

    if (ipr > 10000) then
      ! Special segment flag - full calculation
      ind2 = 2
    else if (ipr < 0) then
      ! Negative connection - check reverse connection
      ipr = -ipr
      if (-icon2(ipr) == j) then
        ! Valid reverse connection - check alignment
        xi = abs(cabj*cab(ipr) + sabj*sab(ipr) + salpj*salp(ipr))
        if (xi >= 0.999999d0 .and. abs(bi(ipr)/b - 1.d0) <= 1.d-6) then
          ind2 = 0  ! Aligned, use approximation
        else
          ind2 = 2  ! Not aligned, full calculation
        end if
      else
        ind2 = 2  ! Invalid connection, full calculation
      end if
    else if (ipr == 0) then
      ! No connection at end 2
      ind2 = 1
    else  ! ipr > 0
      ! Positive connection - check forward connection
      if (ipr == j) then
        ! Self-connection - check if segment is effectively zero
        if (cabj*cabj + sabj*sabj > 1.d-8) then
          ind2 = 2  ! Non-zero segment, full calculation
        else
          ind2 = 0  ! Zero segment, use approximation
        end if
      else if (icon1(ipr) == j) then
        ! Connected via end 1 of IPR - check alignment
        xi = abs(cabj*cab(ipr) + sabj*sab(ipr) + salpj*salp(ipr))
        if (xi >= 0.999999d0 .and. abs(bi(ipr)/b - 1.d0) <= 1.d-6) then
          ind2 = 0  ! Aligned, use approximation
        else
          ind2 = 2  ! Not aligned, full calculation
        end if
      else
        ind2 = 2  ! Invalid connection, full calculation
      end if
    end if
  end if

  ! Observation loop
  ipr = 0

  do i = i1, i2
    ipr = ipr + 1
    ij = i - j
    xi = x(i)
    yi = y(i)
    zi = z(i)
    ai = bi(i)
    cabi = cab(i)
    sabi = sab(i)
    salpi = salp(i)
    call efld(xi, yi, zi, ai, ij)
    etk = exk*cabi + eyk*sabi + ezk*salpi
    ets = exs*cabi + eys*sabi + ezs*salpi
    etc = exc*cabi + eyc*sabi + ezc*salpi

    ! Fill matrix elements - element locations determined by connection data

    if (itrp == 0) then
      ! Normal fill
      do ij = 1, jsno
        jx = jco(ij)
        cm(ipr,jx) = cm(ipr,jx) + etk*ax(ij) + ets*bx(ij) + etc*cx(ij)
      end do

    else if (itrp == 1) then
      ! Transposed fill
      do ij = 1, jsno
        jx = jco(ij)
        cm(jx,ipr) = cm(jx,ipr) + etk*ax(ij) + ets*bx(ij) + etc*cx(ij)
      end do

    else  ! itrp == 2
      ! Trans. fill for C(WW) - test for elements for D(WW)PRIME. (=CW)
      do ij = 1, jsno
        jx = jco(ij)
        if (jx > nr) then
          ! Element belongs to CW matrix
          cw(jx-nr,ipr) = cw(jx-nr,ipr) + etk*ax(ij) + ets*bx(ij) + etc*cx(ij)
        else
          ! Element belongs to CM matrix
          cm(jx,ipr) = cm(jx,ipr) + etk*ax(ij) + ets*bx(ij) + etc*cx(ij)
        end if
      end do
    end if

  end do  ! End observation loop

end subroutine cmww
