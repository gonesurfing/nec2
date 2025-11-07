! nec2_current.f90
! Current basis function calculations for NEC2
! Handles piecewise sinusoidal current basis functions on wires and patches

module nec2_current
  use nec2_constants
  use nec2_data_types
  use nec2_utilities
  implicit none
  private

  ! Public subroutines
  public :: tbf, sbf, trio, hintg

contains

  !============================================================================
  ! TBF - Compute basis function I
  !============================================================================
  subroutine tbf(geom, segj, i, icap)
    ! Computes basis function coefficients for segment I
    !
    ! The basis function is a piecewise sinusoidal function that is
    ! non-zero on segment I and adjacent connected segments
    !
    ! Arguments:
    !   geom  - geometry data
    !   segj  - segment junction data (output)
    !   i     - segment number
    !   icap  - capacitance end flag (0=no end capacitance, 1=use end cap)

    type(geometry_data), intent(in) :: geom
    type(segment_junction_data), intent(inout) :: segj
    integer, intent(in) :: i, icap

    integer :: jcox, jend, iend, jsno, njun1, njun2, jsnop
    real(8) :: pp, pm, sig, d, sdh, cdh, sd, cd, omc
    real(8) :: aj, ap, qp, qm, xxi

    segj%jsno = 0
    pp = 0.0d0
    jcox = geom%icon1(i)
    if (jcox > 10000) jcox = i
    jend = -1
    iend = -1
    sig = -1.0d0

    ! Process connections at end 1
    if (jcox == 0) goto 10
    if (jcox < 0) then
      jcox = -jcox
      goto 3
    end if

2   sig = -sig
    jend = -jend

3   segj%jsno = segj%jsno + 1
    if (segj%jsno >= DEFAULT_JMAX) then
      write(*,'(A,I5)') 'TBF - Segment connection error for segment', i
      stop 1
    end if

    segj%jco(segj%jsno) = jcox
    d = PI * geom%si(jcox)
    sdh = sin(d)
    cdh = cos(d)
    sd = 2.0d0 * sdh * cdh

    if (d > 0.015d0) then
      omc = 1.0d0 - cdh*cdh + sdh*sdh
    else
      omc = 4.0d0 * d * d
      omc = ((1.3888889d-3 * omc - 4.1666666667d-2) * omc + 0.5d0) * omc
    end if

    aj = 1.0d0 / (log(1.0d0 / (PI * geom%bi(jcox))) - EULER_GAMMA)
    pp = pp - omc / sd * aj
    segj%ax(segj%jsno) = aj / sd * sig
    segj%bx(segj%jsno) = aj / (2.0d0 * cdh)
    segj%cx(segj%jsno) = -aj / (2.0d0 * sdh) * sig

    if (jcox == i) goto 8
    if (jend == 1) then
      jcox = geom%icon1(jcox)
    else
      jcox = geom%icon2(jcox)
    end if

    if (abs(jcox) == i) goto 9
    if (jcox == 0) goto 28
    if (jcox < 0) goto 1
    goto 2

8   segj%bx(segj%jsno) = -segj%bx(segj%jsno)

9   if (iend == 1) goto 11

    ! Process connections at end 2
10  pm = -pp
    pp = 0.0d0
    njun1 = segj%jsno
    jcox = geom%icon2(i)
    if (jcox > 10000) jcox = i
    jend = 1
    iend = 1
    sig = -1.0d0
    if (jcox /= 0) then
      if (jcox < 0) goto 1
      goto 2
    end if

11  njun2 = segj%jsno - njun1
    jsnop = segj%jsno + 1
    segj%jco(jsnop) = i
    d = PI * geom%si(i)
    sdh = sin(d)
    cdh = cos(d)
    sd = 2.0d0 * sdh * cdh
    cd = cdh*cdh - sdh*sdh

    if (d > 0.015d0) then
      omc = 1.0d0 - cd
    else
      omc = 4.0d0 * d * d
      omc = ((1.3888889d-3 * omc - 4.1666666667d-2) * omc + 0.5d0) * omc
    end if

    ap = 1.0d0 / (log(1.0d0 / (PI * geom%bi(i))) - EULER_GAMMA)
    aj = ap

    ! Junction matching
    if (njun1 == 0) goto 16
    if (njun2 == 0) goto 20

    ! Both junctions present
    qp = sd * (pm*pp + aj*ap) + cd * (pm*ap - pp*aj)
    qm = (ap*omc - pp*sd) / qp
    qp = -(aj*omc + pm*sd) / qp
    segj%bx(jsnop) = (aj*qm + ap*qp) * sdh / sd
    segj%cx(jsnop) = (aj*qm - ap*qp) * cdh / sd

    do iend = 1, njun1
      segj%ax(iend) = segj%ax(iend) * qm
      segj%bx(iend) = segj%bx(iend) * qm
      segj%cx(iend) = segj%cx(iend) * qm
    end do

    do iend = njun1 + 1, segj%jsno
      segj%ax(iend) = -segj%ax(iend) * qp
      segj%bx(iend) = segj%bx(iend) * qp
      segj%cx(iend) = -segj%cx(iend) * qp
    end do
    goto 27

16  if (njun2 == 0) goto 24

    ! Junction 2 only
    if (icap /= 0) then
      qp = PI * geom%bi(i)
      xxi = qp * qp
      xxi = qp * (1.0d0 - 0.5d0 * xxi) / (1.0d0 - xxi)
    else
      xxi = 0.0d0
    end if

    qp = -(omc + xxi*sd) / (sd*(ap + xxi*pp) + cd*(xxi*ap - pp))
    d = cd - xxi*sd
    segj%bx(jsnop) = (sdh + ap*qp*(cdh - xxi*sdh)) / d
    segj%cx(jsnop) = (cdh + ap*qp*(sdh + xxi*cdh)) / d

    do iend = 1, njun2
      segj%ax(iend) = -segj%ax(iend) * qp
      segj%bx(iend) = segj%bx(iend) * qp
      segj%cx(iend) = -segj%cx(iend) * qp
    end do
    goto 27

20  continue  ! Junction 1 only
    if (icap /= 0) then
      qm = PI * geom%bi(i)
      xxi = qm * qm
      xxi = qm * (1.0d0 - 0.5d0 * xxi) / (1.0d0 - xxi)
    else
      xxi = 0.0d0
    end if

    qm = (omc + xxi*sd) / (sd*(aj - xxi*pm) + cd*(pm + xxi*aj))
    d = cd - xxi*sd
    segj%bx(jsnop) = (aj*qm*(cdh - xxi*sdh) - sdh) / d
    segj%cx(jsnop) = (cdh - aj*qm*(sdh + xxi*cdh)) / d

    do iend = 1, njun1
      segj%ax(iend) = segj%ax(iend) * qm
      segj%bx(iend) = segj%bx(iend) * qm
      segj%cx(iend) = segj%cx(iend) * qm
    end do
    goto 27

24  continue  ! No junctions
    segj%bx(jsnop) = 0.0d0
    if (icap /= 0) then
      qp = PI * geom%bi(i)
      xxi = qp * qp
      xxi = qp * (1.0d0 - 0.5d0 * xxi) / (1.0d0 - xxi)
    else
      xxi = 0.0d0
    end if
    segj%cx(jsnop) = 1.0d0 / (cdh - xxi*sdh)

27  segj%jsno = jsnop
    segj%ax(segj%jsno) = -1.0d0
    return

28  write(*,'(A,I5)') 'TBF - Segment connection error for segment', i
    stop 1

1   jcox = -jcox
    goto 3

  end subroutine tbf

  !============================================================================
  ! SBF - Compute component of basis function I on segment IS
  !============================================================================
  subroutine sbf(geom, i, is, aa, bb, cc)
    ! Computes the value of basis function I at segment IS
    !
    ! Arguments:
    !   geom - geometry data
    !   i    - basis function number
    !   is   - segment to evaluate on
    !   aa, bb, cc - output basis function coefficients
    !
    ! Original: nec2dxs.f lines 8713-8854

    type(geometry_data), intent(in) :: geom
    integer, intent(in) :: i, is
    real(8), intent(out) :: aa, bb, cc

    integer :: jcox, jend, iend, jsno, njun1, njun2, june
    real(8) :: pp, pm, sig, d, sdh, cdh, sd, cd, omc, aj, ap, qp, qm, xxi

    aa = 0.0d0
    bb = 0.0d0
    cc = 0.0d0
    june = 0
    jsno = 0
    pp = 0.0d0
    jcox = geom%icon1(i)

    if (jcox > 10000) jcox = i
    jend = -1
    iend = -1
    sig = -1.0d0

    ! Process connections at end 1
    if (jcox == 0) goto 11
    if (jcox < 0) goto 1

2   sig = -sig
    jend = -jend

3   jsno = jsno + 1
    if (jsno >= DEFAULT_JMAX) then
      write(*,'(A,I5)') 'SBF - Segment connection error for segment', i
      stop 1
    end if

    d = PI * geom%si(jcox)
    sdh = sin(d)
    cdh = cos(d)
    sd = 2.0d0 * sdh * cdh

    if (d > 0.015d0) then
      omc = 1.0d0 - cdh*cdh + sdh*sdh
    else
      omc = 4.0d0 * d * d
      omc = ((1.3888889d-3 * omc - 4.1666666667d-2) * omc + 0.5d0) * omc
    end if

    aj = 1.0d0 / (log(1.0d0 / (PI * geom%bi(jcox))) - EULER_GAMMA)
    pp = pp - omc / sd * aj

    ! Check if this is the target segment
    if (jcox == is) then
      aa = aj / sd * sig
      bb = aj / (2.0d0 * cdh)
      cc = -aj / (2.0d0 * sdh) * sig
      june = iend
    end if

6   if (jcox == i) goto 9

    if (jend == 1) then
      jcox = geom%icon2(jcox)
    else
      jcox = geom%icon1(jcox)
    end if

8   if (abs(jcox) == i) goto 10
    if (jcox == 0) goto 24
    if (jcox < 0) goto 1
    goto 2

9   if (jcox == is) bb = -bb

10  if (iend == 1) goto 12

    ! Process connections at end 2
11  pm = -pp
    pp = 0.0d0
    njun1 = jsno
    jcox = geom%icon2(i)
    if (jcox > 10000) jcox = i
    jend = 1
    iend = 1
    sig = -1.0d0
    if (jcox /= 0) then
      if (jcox < 0) goto 1
      goto 2
    end if

    ! Apply junction matching
12  njun2 = jsno - njun1
    d = PI * geom%si(i)
    sdh = sin(d)
    cdh = cos(d)
    sd = 2.0d0 * sdh * cdh
    cd = cdh*cdh - sdh*sdh

    if (d > 0.015d0) then
      omc = 1.0d0 - cd
    else
      omc = 4.0d0 * d * d
      omc = ((1.3888889d-3 * omc - 4.1666666667d-2) * omc + 0.5d0) * omc
    end if

    ap = 1.0d0 / (log(1.0d0 / (PI * geom%bi(i))) - EULER_GAMMA)
    aj = ap

    if (njun1 == 0) goto 19
    if (njun2 == 0) goto 21

    ! Both junctions present
    qp = sd * (pm*pp + aj*ap) + cd * (pm*ap - pp*aj)
    qm = (ap*omc - pp*sd) / qp
    qp = -(aj*omc + pm*sd) / qp

    if (june < 0) then
      ! Match at end 1
      aa = aa * qm
      bb = bb * qm
      cc = cc * qm
    else if (june > 0) then
      ! Match at end 2
      aa = -aa * qp
      bb = bb * qp
      cc = -cc * qp
    end if

    if (i == is) then
      aa = aa - 1.0d0
      bb = bb + (aj*qm + ap*qp) * sdh / sd
      cc = cc + (aj*qm - ap*qp) * cdh / sd
    end if
    return

    ! Junction 2 only
19  if (njun2 == 0) goto 23

    qp = PI * geom%bi(i)
    xxi = qp * qp
    xxi = qp * (1.0d0 - 0.5d0 * xxi) / (1.0d0 - xxi)
    qp = -(omc + xxi*sd) / (sd*(ap + xxi*pp) + cd*(xxi*ap - pp))

    if (june == 1) then
      aa = -aa * qp
      bb = bb * qp
      cc = -cc * qp
    end if

    if (i == is) then
      aa = aa - 1.0d0
      d = cd - xxi*sd
      bb = bb + (sdh + ap*qp*(cdh - xxi*sdh)) / d
      cc = cc + (cdh + ap*qp*(sdh + xxi*cdh)) / d
    end if
    return

    ! Junction 1 only
21  qm = PI * geom%bi(i)
    xxi = qm * qm
    xxi = qm * (1.0d0 - 0.5d0 * xxi) / (1.0d0 - xxi)
    qm = (omc + xxi*sd) / (sd*(aj - xxi*pm) + cd*(pm + xxi*aj))

    if (june == -1) then
      aa = aa * qm
      bb = bb * qm
      cc = cc * qm
    end if

    if (i == is) then
      aa = aa - 1.0d0
      d = cd - xxi*sd
      bb = bb + (aj*qm*(cdh - xxi*sdh) - sdh) / d
      cc = cc + (cdh - aj*qm*(sdh + xxi*cdh)) / d
    end if
    return

    ! No junctions - isolated segment
23  aa = -1.0d0
    qp = PI * geom%bi(i)
    xxi = qp * qp
    xxi = qp * (1.0d0 - 0.5d0 * xxi) / (1.0d0 - xxi)
    cc = 1.0d0 / (cdh - xxi*sdh)
    return

24  write(*,'(A,I5)') 'SBF - Segment connection error for segment', i
    stop 1

1   jcox = -jcox
    goto 3

  end subroutine sbf

  !============================================================================
  ! TRIO - Compute all basis functions on segment J
  !============================================================================
  subroutine trio(geom, segj, j)
    ! Computes components of all basis functions on segment J
    !
    ! Arguments:
    !   geom - geometry data
    !   segj - segment junction data (output)
    !   j    - segment number

    type(geometry_data), intent(in) :: geom
    type(segment_junction_data), intent(inout) :: segj
    integer, intent(in) :: j

    integer :: jcox, jend, iend
    real(8) :: aa, bb, cc

    segj%jsno = 0
    jcox = geom%icon1(j)

    if (jcox > 10000) goto 7
    jend = -1
    iend = -1

    if (jcox < 0) goto 1
    if (jcox == 0) goto 7
    goto 2

1   jcox = -jcox
    goto 3

2   jend = -jend

3   if (jcox == j) goto 6

    segj%jsno = segj%jsno + 1
    if (segj%jsno >= DEFAULT_JMAX) goto 9

    call sbf(geom, jcox, j, aa, bb, cc)
    segj%ax(segj%jsno) = aa
    segj%bx(segj%jsno) = bb
    segj%cx(segj%jsno) = cc
    segj%jco(segj%jsno) = jcox

    if (jend == 1) then
      jcox = geom%icon2(jcox)
    else
      jcox = geom%icon1(jcox)
    end if

    if (jcox < 0) goto 1
    if (jcox == 0) goto 9
    goto 2

6   if (iend == 1) goto 8

7   jcox = geom%icon2(j)
    if (jcox > 10000) goto 8
    jend = 1
    iend = 1
    if (jcox < 0) goto 1
    if (jcox == 0) goto 8
    goto 2

8   segj%jsno = segj%jsno + 1
    call sbf(geom, j, j, aa, bb, cc)
    segj%ax(segj%jsno) = aa
    segj%bx(segj%jsno) = bb
    segj%cx(segj%jsno) = cc
    segj%jco(segj%jsno) = j
    return

9   write(*,'(A,I5)') 'TRIO - Segment connection error for segment', j
    stop 1

  end subroutine trio

  !============================================================================
  ! HINTG - H field from patch current
  !============================================================================
  subroutine hintg(dataj, ground, xi, yi, zi)
    ! Computes H field of a patch current
    !
    ! Arguments:
    !   dataj  - junction data with current info
    !   ground - ground parameters
    !   xi, yi, zi - observation point

    type(dataj_data), intent(inout) :: dataj
    type(ground_data), intent(in) :: ground
    real(8), intent(in) :: xi, yi, zi

    complex(8) :: gam, f1x, f1y, f1z, f2x, f2y, f2z
    complex(8) :: rrv, rrh
    real(8) :: rx, ry, rz, rfl, rsq, r, rk, cr, sr
    real(8) :: t1zr, t2zr, xymag, px, py, cth
    integer :: ip
    real(8), parameter :: fpi = 12.56637062d0

    rx = xi - dataj%xj
    ry = yi - dataj%yj
    rfl = -1.0d0

    dataj%exk = (0.0d0, 0.0d0)
    dataj%eyk = (0.0d0, 0.0d0)
    dataj%ezk = (0.0d0, 0.0d0)
    dataj%exs = (0.0d0, 0.0d0)
    dataj%eys = (0.0d0, 0.0d0)
    dataj%ezs = (0.0d0, 0.0d0)

    ! Sum over image sources for ground plane
    do ip = 1, ground%ksymp
      rfl = -rfl
      rz = zi - dataj%zj * rfl
      rsq = rx*rx + ry*ry + rz*rz

      if (rsq < 1.0d-20) cycle

      r = sqrt(rsq)
      rk = TWO_PI * r
      cr = cos(rk)
      sr = sin(rk)
      gam = -(cmplx(cr, -sr, kind=8) + rk*cmplx(sr, cr, kind=8)) / (fpi * rsq * r) * dataj%s

      ! Calculate cross products for H field
      dataj%exc = gam * rx
      dataj%eyc = gam * ry
      dataj%ezc = gam * rz

      ! Apply reflection for image source
      t1zr = dataj%salpj * rfl  ! t1z with reflection
      t2zr = dataj%t2z * rfl     ! t2z with reflection

      ! Cross products: F1 = EXC cross T1, F2 = EXC cross T2
      f1x = dataj%eyc * t1zr - dataj%ezc * dataj%sabj
      f1y = dataj%ezc * dataj%cabj - dataj%exc * t1zr
      f1z = dataj%exc * dataj%sabj - dataj%eyc * dataj%cabj

      f2x = dataj%eyc * t2zr - dataj%ezc * dataj%t2y
      f2y = dataj%ezc * dataj%b - dataj%exc * t2zr
      f2z = dataj%exc * dataj%t2y - dataj%eyc * dataj%b

      ! Apply ground reflection coefficients
      if (ip == 2) then
        ! Second pass: apply ground effects
        if (ground%iperf == 1) then
          ! Perfect ground: simple sign flip
          f1x = -f1x
          f1y = -f1y
          f1z = -f1z
          f2x = -f2x
          f2y = -f2y
          f2z = -f2z
        else
          ! Finite conductivity ground
          xymag = sqrt(rx*rx + ry*ry)

          if (xymag > 1.0d-6) then
            px = -ry / xymag
            py = rx / xymag
            cth = rz / r
            rrv = sqrt((1.0d0, 0.0d0) - ground%zrati * ground%zrati * (1.0d0 - cth*cth))
          else
            px = 0.0d0
            py = 0.0d0
            cth = 1.0d0
            rrv = (1.0d0, 0.0d0)
          end if

          ! Reflection coefficients
          rrh = ground%zrati * cth
          rrh = (rrh - rrv) / (rrh + rrv)
          rrv = ground%zrati * rrv
          rrv = -(cth - rrv) / (cth + rrv)

          ! Apply reflection to F1
          gam = (f1x*px + f1y*py) * (rrv - rrh)
          f1x = f1x * rrh + gam * px
          f1y = f1y * rrh + gam * py
          f1z = f1z * rrh

          ! Apply reflection to F2
          gam = (f2x*px + f2y*py) * (rrv - rrh)
          f2x = f2x * rrh + gam * px
          f2y = f2y * rrh + gam * py
          f2z = f2z * rrh
        end if
      end if

      ! Accumulate contributions
      dataj%exk = dataj%exk + f1x
      dataj%eyk = dataj%eyk + f1y
      dataj%ezk = dataj%ezk + f1z
      dataj%exs = dataj%exs + f2x
      dataj%eys = dataj%eys + f2y
      dataj%ezs = dataj%ezs + f2z

    end do

  end subroutine hintg


end module nec2_current
