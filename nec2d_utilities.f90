! =============================================================================
! nec2d_utilities - Utility Routines
! =============================================================================
! Purpose: Network parameter setup and general utilities
! Contains: TRIO, UNERE, ROM1
! GOTOs eliminated: 32
! =============================================================================
subroutine trio(j)
!
! trio computes the components of all basis functions on segment j
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)
  common /data/ x(maxseg), y(maxseg), z(maxseg), si(maxseg), bi(maxseg), &
                alp(maxseg), bet(maxseg), wlam, icon1(2*maxseg), icon2(2*maxseg), &
                itag(2*maxseg), iconx(maxseg), ld, n1, n2, n, np, m1, m2, m, mp, ipsym
  common /segj/ ax(jmax), bx(jmax), cx(jmax), jco(jmax), &
                jsno, iscon(50), nscon, ipcon(10), npcon

  integer :: iend

  jsno = 0

  ! Process connections from both ends
  do iend = 1, 2
    ! Get connection for current end
    if (iend == 1) then
      ! Process first end
      jcox = icon1(j)
      if (jcox > 10000 .or. jcox == 0) cycle
      jend = -1
    else
      ! Process second end
      jcox = icon2(j)
      if (jcox > 10000 .or. jcox == 0) exit
      jend = 1
    end if

    ! Traverse connected segments from this end
    do while (.true.)
      ! Normalize JCOX and update JEND based on connection sign
      if (jcox < 0) then
        jcox = -jcox
      else if (jcox > 0) then
        jend = -jend
      else  ! jcox == 0
        write(*,10) j
        stop
      end if

      ! Check if we've reached the current segment
      if (jcox == j) exit

      ! Add this segment to the basis function list
      jsno = jsno + 1
      if (jsno >= jmax) then
        write(*,10) j
        stop
      end if

      call sbf(jcox, j, ax(jsno), bx(jsno), cx(jsno))
      jco(jsno) = jcox

      ! Get next connected segment
      if (jend == 1) then
        jcox = icon2(jcox)
      else
        jcox = icon1(jcox)
      end if
    end do
  end do

  ! Add self-segment basis function
  jsno = jsno + 1
  call sbf(j, j, ax(jsno), bx(jsno), cx(jsno))
  jco(jsno) = j

10 format(' TRIO - SEGMENT CONNENTION ERROR FOR SEGMENT', i5)

end subroutine trio

subroutine unere(xob, yob, zob)
!
! unere calculates the electric field due to unit current in the t1 and t2
! directions on a patch
!
  implicit real*8(a-h, o-z)
  complex*16 exk, eyk, ezk, exs, eys, ezs, exc, eyc, ezc, zrati, zrati2, t1
  complex*16 er, q1, q2, rrv, rrh, edp, frati

  common /dataj/ s, b, xj, yj, zj, cabj, sabj, salpj, exk, eyk, ezk, exs, eys, &
                 ezs, exc, eyc, ezc, rkh, ind1, indd1, ind2, indd2, iexk, ipgnd
  common /gnd/ zrati, zrati2, frati, t1, t2, cl, ch, scrwl, scrwr, nradl, &
               ksymp, ifar, iperf

  equivalence (t1xj, cabj), (t1yj, sabj), (t1zj, salpj), (t2xj, b), &
              (t2yj, ind1), (t2zj, ind2)

  data tpi, const /6.283185308d+0, 4.771341188d+0/
  ! const=eta/(8.*pi**2)

  zr = zj
  t1zr = t1zj
  t2zr = t2zj

  ! Coordinate transformation for ground plane case
  if (ipgnd == 2) then
    zr = -zr
    t1zr = -t1zr
    t2zr = -t2zr
  end if

  ! Calculate distance
  rx = xob - xj
  ry = yob - yj
  rz = zob - zr
  r2 = rx*rx + ry*ry + rz*rz

  ! Check for singularity
  if (r2 <= 1.d-20) then
    exk = (0.d0, 0.d0)
    eyk = (0.d0, 0.d0)
    ezk = (0.d0, 0.d0)
    exs = (0.d0, 0.d0)
    eys = (0.d0, 0.d0)
    ezs = (0.d0, 0.d0)
    return
  end if

  ! Main field calculation
  r = sqrt(r2)
  tt1 = -tpi * r
  tt2 = tt1 * tt1
  rt = r2 * r
  er = dcmplx(sin(tt1), -cos(tt1)) * (const * s)
  q1 = dcmplx(tt2 - 1.d0, tt1) * er / rt
  q2 = dcmplx(3.d0 - tt2, -3.d0 * tt1) * er / (rt * r2)

  ! T1 direction field
  er = q2 * (t1xj*rx + t1yj*ry + t1zr*rz)
  exk = q1 * t1xj + er * rx
  eyk = q1 * t1yj + er * ry
  ezk = q1 * t1zr + er * rz

  ! T2 direction field
  er = q2 * (t2xj*rx + t2yj*ry + t2zr*rz)
  exs = q1 * t2xj + er * rx
  eys = q1 * t2yj + er * ry
  ezs = q1 * t2zr + er * rz

  ! Ground reflection handling
  if (ipgnd /= 1) then
    if (iperf == 1) then
      ! Perfect ground reflection
      exk = -exk
      eyk = -eyk
      ezk = -ezk
      exs = -exs
      eys = -eys
      ezs = -ezs
    else
      ! Imperfect ground reflection
      xymag = sqrt(rx*rx + ry*ry)

      ! Vertical vs normal incidence
      if (xymag <= 1.d-6) then
        ! Vertical incidence case
        px = 0.d0
        py = 0.d0
        cth = 1.d0
        rrv = (1.d0, 0.d0)
      else
        ! Normal incidence case
        px = -ry / xymag
        py = rx / xymag
        cth = rz / sqrt(xymag*xymag + rz*rz)
        rrv = sqrt(1.d0 - zrati*zrati*(1.d0 - cth*cth))
      end if

      ! Calculate reflection coefficients
      rrh = zrati * cth
      rrh = (rrh - rrv) / (rrh + rrv)
      rrv = zrati * rrv
      rrv = -(cth - rrv) / (cth + rrv)

      ! Apply reflection to T1 direction field
      edp = (exk*px + eyk*py) * (rrh - rrv)
      exk = exk * rrv + edp * px
      eyk = eyk * rrv + edp * py
      ezk = ezk * rrv

      ! Apply reflection to T2 direction field
      edp = (exs*px + eys*py) * (rrh - rrv)
      exs = exs * rrv + edp * px
      eys = eys * rrv + edp * py
      ezs = ezs * rrv
    end if
  end if

end subroutine unere

subroutine rom1(n, sum, nx)
!
! rom1 integrates the 6 sommerfeld integrals from a to b in lambda.
! the method of variable interval width romberg integration is used.
!
  implicit real*8(a-h,o-z)
  save
  complex*16 a, b, sum, g1, g2, g3, g4, g5, t00, t01, t10, t02, t11, t20
  common /cntour/ a, b
  dimension sum(6), g1(6), g2(6), g3(6), g4(6), g5(6), t01(6), t10(6), t20(6)
  data nm, nts, rx /131072, 4, 1.e-4/

  lstep = 0
  z = 0.d0
  ze = 1.d0
  s = 1.d0
  ep = s / (1.e4 * nm)
  zend = ze - ep

  do i = 1, n
    sum(i) = (0.d0, 0.d0)
  end do

  ns = nx
  nt = 0
  call saoa(z, g1)

  ! Main integration loop
  main_loop: do while (.true.)
    dz = s / ns

    ! Adjust DZ if it would overshoot ZE
    if (z + dz > ze) then
      dz = ze - z
      if (dz <= ep) exit main_loop
    end if

    ! Compute function values at intermediate points
    dzot = dz * 0.5d0
    call saoa(z + dzot, g3)
    call saoa(z + dz, g5)

    ! Inner refinement loop
    ! This loop refines the step size until convergence is achieved
    refine_loop: do while (.true.)
      ! Test convergence of 3-point Romberg result
      nogo = 0
      do i = 1, n
        t00 = (g1(i) + g5(i)) * dzot
        t01(i) = (t00 + dz * g3(i)) * 0.5d0
        t10(i) = (4.d0 * t01(i) - t00) / 3.d0

        ! Test convergence
        call test(dreal(t01(i)), dreal(t10(i)), tr, &
                  dimag(t01(i)), dimag(t10(i)), ti, 0.d0)
        if (tr > rx .or. ti > rx) nogo = 1
      end do

      if (nogo == 0) then
        ! 3-point Romberg converged
        do i = 1, n
          sum(i) = sum(i) + t10(i)
        end do
        nt = nt + 2
        exit refine_loop
      end if

      ! 3-point didn't converge, try 5-point Romberg
      call saoa(z + dz * 0.25d0, g2)
      call saoa(z + dz * 0.75d0, g4)

      nogo = 0
      do i = 1, n
        t02 = (t01(i) + dzot * (g2(i) + g4(i))) * 0.5d0
        t11 = (4.d0 * t02 - t01(i)) / 3.d0
        t20(i) = (16.d0 * t11 - t10(i)) / 15.d0

        ! Test convergence of 5-point Romberg result
        call test(dreal(t11), dreal(t20(i)), tr, &
                  dimag(t11), dimag(t20(i)), ti, 0.d0)
        if (tr > rx .or. ti > rx) nogo = 1
      end do

      if (nogo == 0) then
        ! 5-point Romberg converged
        do i = 1, n
          sum(i) = sum(i) + t20(i)
        end do
        nt = nt + 1
        exit refine_loop
      end if

      ! 5-point didn't converge, need to refine step
      nt = 0

      if (ns >= nm) then
        ! Already at maximum refinement, warn and accept result
        if (lstep == 0) then
          lstep = 1
          call lambda(z, t00, t11)
          write(*, 18) t00
          write(*, 19) z, dz, a, b
          do i = 1, n
            write(*, 19) g1(i), g2(i), g3(i), g4(i), g5(i)
          end do
        end if

        ! Accept 5-point result despite non-convergence
        do i = 1, n
          sum(i) = sum(i) + t20(i)
        end do
        nt = nt + 1
        exit refine_loop
      end if

      ! Double NS (halve step size) and retry
      ns = ns * 2
      dz = s / ns
      dzot = dz * 0.5d0
      do i = 1, n
        g5(i) = g3(i)
        g3(i) = g2(i)
      end do
    end do refine_loop

    ! Advance to next interval
    z = z + dz
    if (z > zend) exit main_loop

    ! Copy G5 to G1 for next step
    do i = 1, n
      g1(i) = g5(i)
    end do

    ! Check if we should reduce step size (increase NS)
    if (nt >= nts .and. ns > nx) then
      ns = ns / 2
      nt = 1
    end if
  end do main_loop

18 format(38h rom1 -- step size limited at lambda =, 1p2e12.5)
19 format(1x, 1p10e12.5)

end subroutine rom1
