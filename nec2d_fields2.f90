! =============================================================================
! nec2d_fields2 - Far Field Patterns
! =============================================================================
! Purpose: Far field radiation pattern calculations
! Contains: REFLC, SBF, NFPAT
! GOTOs eliminated: 18
! =============================================================================
subroutine reflc (ix,iy,iz,itx,nop)
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
  implicit real*8(a-h,o-z)

  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /angl/ salp(maxseg)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1), x2(1), &
    y2(1), z2(1)
  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), &
    (t2z,itag), (x2,si), (y2,alp), (z2,bet)

  np=n
  mp=m
  ipsym=0
  iti=itx

  ! GOTO 19 eliminated: Use structured IF to separate rotation vs reflection
  if (ix.lt.0) then
    ! -------------------------------------------------------------------------
    ! REPRODUCE STRUCTURE WITH ROTATION TO FORM CYLINDRICAL STRUCTURE
    ! -------------------------------------------------------------------------
    fnop=nop
    ipsym=-1
    sam=6.283185308d+0/fnop
    cs=cos(sam)
    ss=sin(sam)

    ! GOTO 21 eliminated: Use structured IF for conditional wire rotation
    if (n.ge.n2) then
      n=n1+(n-n1)*nop
      nx=np+1
      do i=nx,n
        k=i-np+n1
        xk=x(k)
        yk=y(k)
        x(i)=xk*cs-yk*ss
        y(i)=xk*ss+yk*cs
        z(i)=z(k)
        xk=x2(k)
        yk=y2(k)
        x2(i)=xk*cs-yk*ss
        y2(i)=xk*ss+yk*cs
        z2(i)=z2(k)
        itagi=itag(k)
        if (itagi.eq.0) itag(i)=0
        if (itagi.ne.0) itag(i)=itagi+iti
        bi(i)=bi(k)
      end do
    end if

    ! GOTO 23 eliminated: Use structured IF for conditional patch rotation
    if (m.ge.m2) then
      m=m1+(m-m1)*nop
      nx=mp+1
      k=ld+1-m1
      do i=nx,m
        k=k-1
        j=k-mp+m1
        xk=x(k)
        yk=y(k)
        x(j)=xk*cs-yk*ss
        y(j)=xk*ss+yk*cs
        z(j)=z(k)
        xk=t1x(k)
        yk=t1y(k)
        t1x(j)=xk*cs-yk*ss
        t1y(j)=xk*ss+yk*cs
        t1z(j)=t1z(k)
        xk=t2x(k)
        yk=t2y(k)
        t2x(j)=xk*cs-yk*ss
        t2y(j)=xk*ss+yk*cs
        t2z(j)=t2z(k)
        salp(j)=salp(k)
        bi(j)=bi(k)
      end do
    end if

    return
  end if

  ! -------------------------------------------------------------------------
  ! REFLECTION MODE
  ! -------------------------------------------------------------------------
  if (nop.eq.0) return
  ipsym=1

  ! GOTO 6 eliminated: Use structured IF for Z axis reflection
  if (iz.ne.0) then
    ! REFLECT ALONG Z AXIS
    ipsym=2

    ! GOTO 3 eliminated: Use structured IF for conditional wire reflection
    if (n.ge.n2) then
      do i=n2,n
        nx=i+n-n1
        e1=z(i)
        e2=z2(i)
        ! GOTO 1 eliminated: Invert error check condition
        if (abs(e1)+abs(e2).le.1.d-5.or.e1*e2.lt.-1.d-6) then
          write(*,24)  i
          stop
        end if
        x(nx)=x(i)
        y(nx)=y(i)
        z(nx)=-e1
        x2(nx)=x2(i)
        y2(nx)=y2(i)
        z2(nx)=-e2
        itagi=itag(i)
        if (itagi.eq.0) itag(nx)=0
        if (itagi.ne.0) itag(nx)=itagi+iti
        bi(nx)=bi(i)
      end do
      n=n*2-n1
      iti=iti*2
    end if

    ! GOTO 6 eliminated: Use structured IF for conditional patch reflection
    if (m.ge.m2) then
      nxx=ld+1-m1
      do i=m2,m
        nxx=nxx-1
        nx=nxx-m+m1
        ! GOTO 4 eliminated: Invert error check condition
        if (abs(z(nxx)).le.1.d-10) then
          write(*,25)  i
          stop
        end if
        x(nx)=x(nxx)
        y(nx)=y(nxx)
        z(nx)=-z(nxx)
        t1x(nx)=t1x(nxx)
        t1y(nx)=t1y(nxx)
        t1z(nx)=-t1z(nxx)
        t2x(nx)=t2x(nxx)
        t2y(nx)=t2y(nxx)
        t2z(nx)=-t2z(nxx)
        salp(nx)=-salp(nxx)
        bi(nx)=bi(nxx)
      end do
      m=m*2-m1
    end if
  end if

  ! GOTO 12 eliminated: Use structured IF for Y axis reflection
  if (iy.ne.0) then
    ! REFLECT ALONG Y AXIS

    ! GOTO 9 eliminated: Use structured IF for conditional wire reflection
    if (n.ge.n2) then
      do i=n2,n
        nx=i+n-n1
        e1=y(i)
        e2=y2(i)
        ! GOTO 7 eliminated: Invert error check condition
        if (abs(e1)+abs(e2).le.1.d-5.or.e1*e2.lt.-1.d-6) then
          write(*,24)  i
          stop
        end if
        x(nx)=x(i)
        y(nx)=-e1
        z(nx)=z(i)
        x2(nx)=x2(i)
        y2(nx)=-e2
        z2(nx)=z2(i)
        itagi=itag(i)
        if (itagi.eq.0) itag(nx)=0
        if (itagi.ne.0) itag(nx)=itagi+iti
        bi(nx)=bi(i)
      end do
      n=n*2-n1
      iti=iti*2
    end if

    ! GOTO 12 eliminated: Use structured IF for conditional patch reflection
    if (m.ge.m2) then
      nxx=ld+1-m1
      do i=m2,m
        nxx=nxx-1
        nx=nxx-m+m1
        ! GOTO 10 eliminated: Invert error check condition
        if (abs(y(nxx)).le.1.d-10) then
          write(*,25)  i
          stop
        end if
        x(nx)=x(nxx)
        y(nx)=-y(nxx)
        z(nx)=z(nxx)
        t1x(nx)=t1x(nxx)
        t1y(nx)=-t1y(nxx)
        t1z(nx)=t1z(nxx)
        t2x(nx)=t2x(nxx)
        t2y(nx)=-t2y(nxx)
        t2z(nx)=t2z(nxx)
        salp(nx)=-salp(nxx)
        bi(nx)=bi(nxx)
      end do
      m=m*2-m1
    end if
  end if

  ! GOTO 18 eliminated: Use structured IF for X axis reflection
  if (ix.ne.0) then
    ! REFLECT ALONG X AXIS

    ! GOTO 15 eliminated: Use structured IF for conditional wire reflection
    if (n.ge.n2) then
      do i=n2,n
        nx=i+n-n1
        e1=x(i)
        e2=x2(i)
        ! GOTO 13 eliminated: Invert error check condition
        if (abs(e1)+abs(e2).le.1.d-5.or.e1*e2.lt.-1.d-6) then
          write(*,24)  i
          stop
        end if
        x(nx)=-e1
        y(nx)=y(i)
        z(nx)=z(i)
        x2(nx)=-e2
        y2(nx)=y2(i)
        z2(nx)=z2(i)
        itagi=itag(i)
        if (itagi.eq.0) itag(nx)=0
        if (itagi.ne.0) itag(nx)=itagi+iti
        bi(nx)=bi(i)
      end do
      n=n*2-n1
    end if

    ! GOTO 18 eliminated: Use structured IF for conditional patch reflection
    if (m.ge.m2) then
      nxx=ld+1-m1
      do i=m2,m
        nxx=nxx-1
        nx=nxx-m+m1
        ! GOTO 16 eliminated: Invert error check condition
        if (abs(x(nxx)).le.1.d-10) then
          write(*,25)  i
          stop
        end if
        x(nx)=-x(nxx)
        y(nx)=y(nxx)
        z(nx)=z(nxx)
        t1x(nx)=-t1x(nxx)
        t1y(nx)=t1y(nxx)
        t1z(nx)=t1z(nxx)
        t2x(nx)=-t2x(nxx)
        t2y(nx)=t2y(nxx)
        t2z(nx)=t2z(nxx)
        salp(nx)=-salp(nxx)
        bi(nx)=bi(nxx)
      end do
      m=m*2-m1
    end if
  end if

  return

24 format (29h geometry data error--segment,i5,26h lies in plane of symmetry)
25 format (27h geometry data error--patch,i4,26h lies in plane of symmetry)
end subroutine reflc


! ======================================================================
! SUBROUTINE SBF - Segment Basis Function
! ======================================================================
! Modernized from: nec2dxs_integrated.f (lines 3496-3630)
! GOTOs eliminated: 18
! ======================================================================

subroutine sbf(i, is, aa, bb, cc)
  ! COMPUTE COMPONENT OF BASIS FUNCTION I ON SEGMENT IS.

  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)

  common /data/ x(maxseg), y(maxseg), z(maxseg), si(maxseg), bi(maxseg), &
    alp(maxseg), bet(maxseg), wlam, icon1(2*maxseg), icon2(2*maxseg), &
    itag(2*maxseg), iconx(maxseg), ld, n1, n2, n, np, m1, m2, m, mp, ipsym

  data pi/3.141592654d+0/

  ! Initialize output parameters
  aa = 0.
  bb = 0.
  cc = 0.
  june = 0
  jsno = 0
  pp = 0.

  ! Process first end connection (ICON1)
  jcox = icon1(i)
  if (jcox > 10000) jcox = i
  jend = -1
  iend = -1
  sig = -1.

  ! GOTO 1,11,2 elimination: Structured three-way branch on JCOX
  if (jcox /= 0) then
    ! First connection traversal loop
    do while (.true.)
      ! GOTO 1,2,3 elimination: Handle JCOX sign and set direction
      if (jcox < 0) then
        ! Label 1: Negative JCOX
        jcox = -jcox
      else
        ! Label 2: Positive JCOX
        sig = -sig
        jend = -jend
      end if

      ! Label 3: Process current segment
      jsno = jsno + 1

      ! GOTO 24 elimination: Check for segment limit
      if (jsno >= jmax) then
        write(*,25) i
        stop
      end if

      d = pi * si(jcox)
      sdh = sin(d)
      cdh = cos(d)
      sd = 2. * sdh * cdh

      ! GOTO 4,5 elimination: D-dependent OMC calculation
      if (d > 0.015) then
        ! Label 4: Large D
        omc = 1. - cdh * cdh + sdh * sdh
      else
        ! Small D: Series expansion
        omc = 4. * d * d
        omc = ((1.3888889d-3 * omc - 4.1666666667d-2) * omc + .5) * omc
      end if

      ! Label 5: Continue with basis function calculation
      aj = 1. / (log(1./(pi*bi(jcox))) - .577215664d+0)
      pp = pp - omc / sd * aj

      ! GOTO 6 elimination: Check if current segment is IS
      if (jcox == is) then
        aa = aj / sd * sig
        bb = aj / (2. * cdh)
        cc = -aj / (2. * sdh) * sig
        june = iend
      end if

      ! Label 6: Check if we've reached segment I
      ! GOTO 9 elimination: Check if JCOX equals I
      if (jcox == i) then
        ! Label 9: Special handling when JCOX = I
        if (jcox == is) bb = -bb
        exit  ! Exit to label 10 logic
      end if

      ! Continue traversal: Get next segment
      ! GOTO 7,8 elimination: Select next connection based on JEND
      if (jend == 1) then
        ! Label 7: Use ICON2
        jcox = icon2(jcox)
      else
        ! Use ICON1
        jcox = icon1(jcox)
      end if

      ! Label 8: Check if next segment is I
      ! GOTO 10 elimination: Check if we've reached I
      if (abs(jcox) == i) then
        exit  ! Exit to label 10
      end if

      ! GOTO 1,24,2 elimination: Loop back with three-way branch
      if (jcox == 0) then
        ! Error condition
        write(*,25) i
        stop
      end if
      ! Continue loop - will branch on JCOX sign at top
    end do
  end if

  ! Label 10: First end complete, check if second end needed
  ! GOTO 12 elimination: Check IEND
  if (iend /= 1) then
    ! Label 11: Process second end connection (ICON2)
    pm = -pp
    pp = 0.
    njun1 = jsno
    jcox = icon2(i)
    if (jcox > 10000) jcox = i
    jend = 1
    iend = 1
    sig = -1.

    ! GOTO 1,12,2 elimination: Three-way branch for second traversal
    if (jcox /= 0) then
      ! Second connection traversal loop (similar to first)
      do while (.true.)
        ! Handle JCOX sign and set direction
        if (jcox < 0) then
          jcox = -jcox
        else
          sig = -sig
          jend = -jend
        end if

        ! Process current segment
        jsno = jsno + 1

        if (jsno >= jmax) then
          write(*,25) i
          stop
        end if

        d = pi * si(jcox)
        sdh = sin(d)
        cdh = cos(d)
        sd = 2. * sdh * cdh

        ! D-dependent OMC calculation
        if (d > 0.015) then
          omc = 1. - cdh * cdh + sdh * sdh
        else
          omc = 4. * d * d
          omc = ((1.3888889d-3 * omc - 4.1666666667d-2) * omc + .5) * omc
        end if

        aj = 1. / (log(1./(pi*bi(jcox))) - .577215664d+0)
        pp = pp - omc / sd * aj

        if (jcox == is) then
          aa = aj / sd * sig
          bb = aj / (2. * cdh)
          cc = -aj / (2. * sdh) * sig
          june = iend
        end if

        if (jcox == i) then
          if (jcox == is) bb = -bb
          exit
        end if

        if (jend == 1) then
          jcox = icon2(jcox)
        else
          jcox = icon1(jcox)
        end if

        if (abs(jcox) == i) then
          exit
        end if

        if (jcox == 0) then
          write(*,25) i
          stop
        end if
      end do
    end if
  end if

  ! Label 12: Both ends processed, compute final values
  njun2 = jsno - njun1
  d = pi * si(i)
  sdh = sin(d)
  cdh = cos(d)
  sd = 2. * sdh * cdh
  cd = cdh * cdh - sdh * sdh

  ! GOTO 13,14 elimination: D-dependent OMC calculation for segment I
  if (d > 0.015) then
    ! Label 13: Large D
    omc = 1. - cd
  else
    ! Small D: Series expansion
    omc = 4. * d * d
    omc = ((1.3888889d-3 * omc - 4.1666666667d-2) * omc + .5) * omc
  end if

  ! Label 14: Continue with junction handling
  ap = 1. / (log(1./(pi*bi(i))) - .577215664d+0)
  aj = ap

  ! GOTO 19 elimination: Check NJUN1
  if (njun1 == 0) then
    ! Label 19: No junction at beginning
    ! GOTO 23 elimination: Check NJUN2
    if (njun2 == 0) then
      ! Label 23: No junctions at all
      aa = -1.
      qp = pi * bi(i)
      xxi = qp * qp
      xxi = qp * (1. - .5 * xxi) / (1. - xxi)
      cc = 1. / (cdh - xxi * sdh)
      return
    else
      ! Junction at end only
      qp = pi * bi(i)
      xxi = qp * qp
      xxi = qp * (1. - .5 * xxi) / (1. - xxi)
      qp = -(omc + xxi * sd) / (sd * (ap + xxi * pp) + cd * (xxi * ap - pp))

      ! GOTO 20 elimination: Check JUNE
      if (june == 1) then
        aa = -aa * qp
        bb = bb * qp
        cc = -cc * qp
        if (i == is) then
          aa = aa - 1.
          d = cd - xxi * sd
          bb = bb + (sdh + ap * qp * (cdh - xxi * sdh)) / d
          cc = cc + (cdh + ap * qp * (sdh + xxi * cdh)) / d
        end if
        return
      else
        ! Label 20: JUNE /= 1
        aa = aa - 1.
        d = cd - xxi * sd
        bb = bb + (sdh + ap * qp * (cdh - xxi * sdh)) / d
        cc = cc + (cdh + ap * qp * (sdh + xxi * cdh)) / d
        return
      end if
    end if
  end if

  ! GOTO 21 elimination: Check NJUN2
  if (njun2 == 0) then
    ! Label 21: Junction at beginning only
    qm = pi * bi(i)
    xxi = qm * qm
    xxi = qm * (1. - .5 * xxi) / (1. - xxi)
    qm = (omc + xxi * sd) / (sd * (aj - xxi * pm) + cd * (pm + xxi * aj))

    ! GOTO 22 elimination: Check JUNE
    if (june == -1) then
      aa = aa * qm
      bb = bb * qm
      cc = cc * qm
      if (i == is) then
        aa = aa - 1.
        d = cd - xxi * sd
        bb = bb + (aj * qm * (cdh - xxi * sdh) - sdh) / d
        cc = cc + (cdh - aj * qm * (sdh + xxi * cdh)) / d
      end if
      return
    else
      ! Label 22: JUNE /= -1
      aa = aa - 1.
      d = cd - xxi * sd
      bb = bb + (aj * qm * (cdh - xxi * sdh) - sdh) / d
      cc = cc + (cdh - aj * qm * (sdh + xxi * cdh)) / d
      return
    end if
  end if

  ! Junctions at both ends (NJUN1 /= 0 and NJUN2 /= 0)
  qp = sd * (pm * pp + aj * ap) + cd * (pm * ap - pp * aj)
  qm = (ap * omc - pp * sd) / qp
  qp = -(aj * omc + pm * sd) / qp

  ! GOTO 15,18,16 elimination: Three-way branch on JUNE
  if (june < 0) then
    ! Label 15: JUNE < 0
    aa = aa * qm
    bb = bb * qm
    cc = cc * qm
    ! GOTO 17 elimination: Continue to label 17
  else if (june > 0) then
    ! Label 16: JUNE > 0
    aa = -aa * qp
    bb = bb * qp
    cc = -cc * qp
    ! Fall through to check I = IS
  else
    ! JUNE = 0: Skip to label 18
    ! Label 18: Add corrections
    aa = aa - 1.
    bb = bb + (aj * qm + ap * qp) * sdh / sd
    cc = cc + (aj * qm - ap * qp) * cdh / sd
    return
  end if

  ! Label 17: Check if I = IS
  if (i /= is) return

  ! Label 18: Add corrections when I = IS
  aa = aa - 1.
  bb = bb + (aj * qm + ap * qp) * sdh / sd
  cc = cc + (aj * qm - ap * qp) * cdh / sd
  return

25 format(43h sbf - segment connection error for segment, i5)
end subroutine sbf


! ============================================================================
! SUBROUTINE NFPAT - Near Field Pattern
! ============================================================================
! Modernized from: nec2dxs_integrated.f (lines 2772-2869)
! GOTOs eliminated: 14
! ============================================================================

subroutine nfpat
  ! COMPUTE NEAR E OR H FIELDS OVER A RANGE OF POINTS

  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)

  complex*16 ex,ey,ez
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common/fpat/thets,phis,dth,dph,rfld,gnor,clt,cht,epsr2,sig2, &
    xpr6,pinr,pnlr,ploss,xnr,ynr,znr,dxnr,dynr,dznr,nth,nph,ipd,iavp, &
    inor,iax,ixtyp,near,nfeh,nrx,nry,nrz
  common /plot/ iplp1,iplp2,iplp3,iplp4

  data ta/1.745329252d-02/

  ! GOTO elimination: Replaced IF(NFEH.EQ.1) GO TO 1 and GO TO 2 pattern
  ! with IF/ELSE structure to select appropriate header format
  if (nfeh .eq. 1) then
    write(*,12)
  else
    write(*,10)
  end if

  znrt = znr - dznr
  do i = 1, nrz
    znrt = znrt + dznr

    ! GOTO elimination: Replaced IF(NEAR.EQ.0) GO TO 3 pattern
    ! with IF structure to conditionally compute CTH and STH
    if (near .ne. 0) then
      cth = cos(ta*znrt)
      sth = sin(ta*znrt)
    end if

    ynrt = ynr - dynr
    do j = 1, nry
      ynrt = ynrt + dynr

      ! GOTO elimination: Replaced IF(NEAR.EQ.0) GO TO 4 pattern
      ! with IF structure to conditionally compute CPH and SPH
      if (near .ne. 0) then
        cph = cos(ta*ynrt)
        sph = sin(ta*ynrt)
      end if

      xnrt = xnr - dxnr
      do kk = 1, nrx
        xnrt = xnrt + dxnr

        ! GOTO elimination: Replaced IF(NEAR.EQ.0) GO TO 5 and GO TO 6 pattern
        ! with IF/ELSE to select coordinate system (spherical vs rectangular)
        if (near .ne. 0) then
          xob = xnrt*sth*cph
          yob = xnrt*sth*sph
          zob = xnrt*cth
        else
          xob = xnrt
          yob = ynrt
          zob = znrt
        end if

        tmp1 = xob/wlam
        tmp2 = yob/wlam
        tmp3 = zob/wlam

        ! GOTO elimination: Replaced IF(NFEH.EQ.1) GO TO 7 and GO TO 8 pattern
        ! with IF/ELSE to select field computation (electric vs magnetic)
        if (nfeh .eq. 1) then
          call nhfld (tmp1,tmp2,tmp3,ex,ey,ez)
        else
          call nefld (tmp1,tmp2,tmp3,ex,ey,ez)
        end if

        tmp1 = abs(ex)
        tmp2 = cang(ex)
        tmp3 = abs(ey)
        tmp4 = cang(ey)
        tmp5 = abs(ez)
        tmp6 = cang(ez)
        write(*,11) xob,yob,zob,tmp1,tmp2,tmp3,tmp4,tmp5,tmp6

        ! GOTO elimination: Replaced complex plotting logic with nested IF/ELSE
        ! Original had: IF(IPLP1.NE.2) GO TO 9, computed GO TO, and multiple jumps
        if (iplp1 .eq. 2) then
          ! GOTO elimination: Replaced computed GO TO (14,15,16),IPLP4
          ! with SELECT CASE structure for coordinate selection
          select case (iplp4)
          case (1)
            xxx = xob
          case (2)
            xxx = yob
          case (3)
            xxx = zob
          end select

          ! GOTO elimination: Replaced IF(IPLP2.NE.2) GO TO 13 and subsequent jumps
          ! with IF/ELSE structure for output format selection
          if (iplp2 .eq. 2) then
            if (iplp3 .eq. 1) write(8,*) xxx,tmp1,tmp2
            if (iplp3 .eq. 2) write(8,*) xxx,tmp3,tmp4
            if (iplp3 .eq. 3) write(8,*) xxx,tmp5,tmp6
            if (iplp3 .eq. 4) write(8,*) xxx,tmp1,tmp2,tmp3,tmp4,tmp5,tmp6
          else if (iplp2 .eq. 1) then
            if (iplp3 .eq. 1) write(8,*) xxx,ex
            if (iplp3 .eq. 2) write(8,*) xxx,ey
            if (iplp3 .eq. 3) write(8,*) xxx,ez
            if (iplp3 .eq. 4) write(8,*) xxx,ex,ey,ez
          end if
        end if
      end do
    end do
  end do

  return

10 format (///,35x,'- - - NEAR ELECTRIC FIELDS - - -',//,12x, &
    '-  LOCATION  -',21x,'-  EX  -',15x,'-  EY  -',15x,'-  EZ  -', &
    /,8x,'X',10x,'Y',10x,'Z',10x,'MAGNITUDE',3x,'PHASE',6x,'MAGNITUDE', &
    3x,'PHASE',6x,'MAGNITUDE',3x,'PHASE',/,6x,'METERS',5x,'METERS',5x, &
    'METERS',8x,'VOLTS/M',3x,'DEGREES',6x,'VOLTS/M',3x,'DEGREES',6x, &
    'VOLTS/M',3x,'DEGREES')
11 format (2x,3(2x,f9.4),1x,3(3x,1p,e11.4,2x,0p,f7.2))
12 format (///,35x,'- - - NEAR MAGNETIC FIELDS - - -',//,12x, &
    '-  LOCATION  -',21x,'-  HX  -',15x,'-  HY  -',15x,'-  HZ  -', &
    /,8x,'X',10x,'Y',10x,'Z',10x,'MAGNITUDE',3x,'PHASE',6x,'MAGNITUDE', &
    3x,'PHASE',6x,'MAGNITUDE',3x,'PHASE',/,6x,'METERS',5x,'METERS',5x, &
    'METERS',9x,'AMPS/M',3x,'DEGREES',7x,'AMPS/M',3x,'DEGREES',7x, &
    'AMPS/M',3x,'DEGREES')
end subroutine nfpat
