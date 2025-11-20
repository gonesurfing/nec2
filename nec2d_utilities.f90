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

! -----------------------------------------------------------------------------
! load - extracted from nec2dxs_integrated.f
! -----------------------------------------------------------------------------
  subroutine load (ldtyp,ldtag,ldtagf,ldtagt,zlr,zli,zlc)
! ***
!     DOUBLE PRECISION 6/4/85
!
  use nec2d_params
  implicit real*8(a-h,o-z)
! ***
!
!     LOAD CALCULATES THE IMPEDANCE OF SPECIFIED SEGMENTS FOR VARIOUS
!     TYPES OF LOADING
!
  complex*16 zarray,zt,tpcj,zint
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg),alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg), &
    icon2(2*maxseg),itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /zload/ zarray(maxseg),nload,nlodf
  dimension ldtyp(1), ldtag(1), ldtagf(1), ldtagt(1), zlr(1), zli(1), zlc(1), tpcjx(2)
  equivalence (tpcj,tpcjx)
  data tpcjx/0.,1.883698955d+9/
!
!     WRITE(*,HEADING)
!
  write(*,25)
!
!     INITIALIZE D ARRAY, USED FOR TEMPORARY STORAGE OF LOADING
!     INFORMATION.
!
  do 1 i=n2,n
1 zarray(i)=(0.,0.)
  iwarn=0
!
!     CYCLE OVER LOADING CARDS
!
  istep=0
2 istep=istep+1
  if (istep.le.nload) go to 5
  if (iwarn.eq.1) write(*,26)
  if (n1+2*m1.gt.0) go to 4
  nop=n/np
  if (nop.eq.1) go to 4
  do 3 i=1,np
  zt=zarray(i)
  l1=i
  do 3 l2=2,nop
  l1=l1+np
3 zarray(l1)=zt
4 return
5 if (ldtyp(istep).le.5) go to 6
  write(*,27)  ldtyp(istep)
  stop
6 ldtags=ldtag(istep)
  jump=ldtyp(istep)+1
  ichk=0
!
!     SEARCH SEGMENTS FOR PROPER ITAGS
!
  l1=n2
  l2=n
  if (ldtags.ne.0) go to 7
  if (ldtagf(istep).eq.0.and.ldtagt(istep).eq.0) go to 7
  l1=ldtagf(istep)
  l2=ldtagt(istep)
  if (l1.gt.n1) go to 7
  write(*,29)
  stop
7 do 17 i=l1,l2
  if (ldtags.eq.0) go to 8
  if (ldtags.ne.itag(i)) go to 17
  if (ldtagf(istep).eq.0) go to 8
  ichk=ichk+1
  if (ichk.ge.ldtagf(istep).and.ichk.le.ldtagt(istep)) go to 9
  go to 17
8 ichk=1
!
!     CALCULATION OF LAMDA*IMPED. PER UNIT LENGTH, JUMP TO APPROPRIATE
!     SECTION FOR LOADING TYPE
!
9 go to (10,11,12,13,14,15), jump
10 zt=zlr(istep)/si(i)+tpcj*zli(istep)/(si(i)*wlam)
  if (abs(zlc(istep)).gt.1.d-20) zt=zt+wlam/(tpcj*si(i)*zlc(istep))
  go to 16
11 zt=tpcj*si(i)*zlc(istep)/wlam
  if (abs(zli(istep)).gt.1.d-20) zt=zt+si(i)*wlam/(tpcj*zli(istep))
  if (abs(zlr(istep)).gt.1.d-20) zt=zt+si(i)/zlr(istep)
  zt=1./zt
  go to 16
12 zt=zlr(istep)*wlam+tpcj*zli(istep)
  if (abs(zlc(istep)).gt.1.d-20) zt=zt+1./(tpcj*si(i)*si(i)*zlc(istep))
  go to 16
13 zt=tpcj*si(i)*si(i)*zlc(istep)
  if (abs(zli(istep)).gt.1.d-20) zt=zt+1./(tpcj*zli(istep))
  if (abs(zlr(istep)).gt.1.d-20) zt=zt+1./(zlr(istep)*wlam)
  zt=1./zt
  go to 16
14 zt=dcmplx(zlr(istep),zli(istep))/si(i)
  go to 16
15 zt=zint(zlr(istep)*wlam,bi(i))
16 if ((abs(dreal(zarray(i)))+abs(dimag(zarray(i)))).gt.1.d-20)iwarn=1
  zarray(i)=zarray(i)+zt
17 continue
  if (ichk.ne.0) go to 18
  write(*,28)  ldtags
  stop
!
!     PRINTING THE SEGMENT LOADING DATA, JUMP TO PROPER PRINT
!
18 go to (19,20,21,22,23,24), jump
19 call prnt (ldtags,ldtagf(istep),ldtagt(istep),zlr(istep),zli(istep),zlc(istep),0.d0,0.d0,0.d0,' SERIES ')
  go to 2
20 call prnt (ldtags,ldtagf(istep),ldtagt(istep),zlr(istep),zli(istep),zlc(istep),0.d0,0.d0,0.d0,'PARALLEL')
  go to 2
21 call prnt (ldtags,ldtagf(istep),ldtagt(istep),zlr(istep),zli(istep),zlc(istep),0.d0,0.d0,0.d0,' SERIES (PER METER) ')
  go to 2
22 call prnt (ldtags,ldtagf(istep),ldtagt(istep),zlr(istep),zli(istep),zlc(istep),0.d0,0.d0,0.d0,'PARALLEL (PER METER)')
  go to 2
23 call prnt (ldtags,ldtagf(istep),ldtagt(istep),0.d0,0.d0,0.d0,zlr(istep),zli(istep),0.d0,'FIXED IMPEDANCE ')
  go to 2
24 call prnt (ldtags,ldtagf(istep),ldtagt(istep),0.d0,0.d0,0.d0,0.d0,0.d0,zlr(istep),'  WIRE  ')
  go to 2
!
25 format (//,7x,8hLOCATION,10x,10hRESISTANCE,3x,10hINDUCTANCE,2x,11hCAPACITANCE,7x,16hIMPEDANCE (OHMS),5x, &
  12hCONDUCTIVITY,4x,4hTYPE,/,4x,4hITAG,10h FROM THRU,10x,4hOHMS,8x,6hHENRYS,7x,6hFARADS,8x,4hREAL,6x,9hIMAGINARY,4x, &
  10hMHOS/METER)
26 format (/,10x,74hNOTE, SOME OF THE ABOVE SEGMENTS HAVE BEEN LOADED TWICE - IMPEDANCES ADDED)
27 format (/,10x,46hIMPROPER LOAD TYPE CHOOSEN, REQUESTED TYPE IS ,i3)
28 format (/,10x,50hLOADING DATA CARD ERROR, NO SEGMENT HAS AN ITAG = ,i5)
29 format (63h ERROR - LOADING MAY NOT BE ADDED TO SEGMENTS IN N.G.F. SECTION)
  end

! -----------------------------------------------------------------------------
! netwk - extracted from nec2dxs_integrated.f
! -----------------------------------------------------------------------------
  subroutine netwk (cm,cmb,cmc,cmd,ip,einc)
! ***
!     DOUBLE PRECISION 6/4/85
!
  use nec2d_params
  implicit real*8(a-h,o-z)
! ***
!
!     SUBROUTINE NETWK SOLVES FOR STRUCTURE CURRENTS FOR A GIVEN
!     EXCITATION INCLUDING THE EFFECT OF NON-RADIATING NETWORKS IF
!     PRESENT.
!
  complex*16 cmn,rhnt,ymit,rhs,zped,einc,vsant,vlt,cur,vsrc,rhnx,vqd,vqds,cux,cm,cmb,cmc,cmd
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg),alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg), &
    icon2(2*maxseg),itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /crnt/ air(maxseg),aii(maxseg),bir(maxseg),bii(maxseg),cir(maxseg),cii(maxseg),cur(3*maxseg)
  common /vsorc/ vqd(nsmax),vsant(nsmax),vqds(nsmax),ivqd(nsmax),isant(nsmax),iqds(nsmax),nvqd,nsant,nqds
  common/netcx/zped,pin,pnls,x11r(netmx),x11i(netmx),x12r(netmx),x12i(netmx),x22r(netmx),x22i(netmx),ntyp(netmx), &
    iseg1(netmx),iseg2(netmx),neq,npeq,neq2,nonet,ntsol,nprint,masym
  dimension einc(1), ip(1),cm(1),cmb(1),cmc(1),cmd(1)
  dimension cmn(netmx,netmx), rhnt(netmx), ipnt(netmx),nteqa(netmx), ntsca(netmx), rhs(3*maxseg), vsrc(netmx),rhnx(netmx)
  parameter (netmx1=netmx+1)
  data ndimn,ndimnp/netmx,netmx1/,tp/6.283185308d+0/
  neqz2=neq2
  if(neqz2.eq.0)neqz2=1
  pin=0.
  pnls=0.
  neqt=neq+neq2
  if (ntsol.ne.0) go to 42
  nop=neq/npeq
  if (masym.eq.0) go to 14
!
!     COMPUTE RELATIVE MATRIX ASYMMETRY
!
  irow1=0
  if (nonet.eq.0) go to 5
  do 4 i=1,nonet
  nseg1=iseg1(i)
  do 3 isc1=1,2
  if (irow1.eq.0) go to 2
  do 1 j=1,irow1
  if (nseg1.eq.ipnt(j)) go to 3
1 continue
2 irow1=irow1+1
  ipnt(irow1)=nseg1
3 nseg1=iseg2(i)
4 continue
5 if (nsant.eq.0) go to 9
  do 8 i=1,nsant
  nseg1=isant(i)
  if (irow1.eq.0) go to 7
  do 6 j=1,irow1
  if (nseg1.eq.ipnt(j)) go to 8
6 continue
7 irow1=irow1+1
  ipnt(irow1)=nseg1
8 continue
9  if (irow1.lt.ndimnp) go to 10
  write(*,59)
  stop
10 if (irow1.lt.2) go to 14
  do 12 i=1,irow1
  isc1=ipnt(i)
  asm=si(isc1)
  do 11 j=1,neqt
11 rhs(j)=(0.,0.)
  rhs(isc1)=(1.,0.)
  call solgf (cm,cmb,cmc,cmd,rhs,ip,np,n1,n,mp,m1,m,neq,neq2,neqz2)
  call cabc (rhs)
  do 12 j=1,irow1
  isc1=ipnt(j)
12 cmn(j,i)=rhs(isc1)/asm
  asm=0.
  asa=0.
  do 13 i=2,irow1
  isc1=i-1
  do 13 j=1,isc1
  cux=cmn(i,j)
  pwr=abs((cux-cmn(j,i))/cux)
  asa=asa+pwr*pwr
  if (pwr.lt.asm) go to 13
  asm=pwr
  nteq=ipnt(i)
  ntsc=ipnt(j)
13 continue
  asa=sqrt(asa*2./dfloat(irow1*(irow1-1)))
  write(*,58)  asm,nteq,ntsc,asa
14 if (nonet.eq.0) go to 48
!
!     SOLUTION OF NETWORK EQUATIONS
!
  do 15 i=1,ndimn
  rhnx(i)=(0.,0.)
  do 15 j=1,ndimn
15 cmn(i,j)=(0.,0.)
  nteq=0
  ntsc=0
!
!     SORT NETWORK AND SOURCE DATA AND ASSIGN EQUATION NUMBERS TO
!     SEGMENTS.
!
  do 38 j=1,nonet
  nseg1=iseg1(j)
  nseg2=iseg2(j)
  if (ntyp(j).gt.1) go to 16
  y11r=x11r(j)
  y11i=x11i(j)
  y12r=x12r(j)
  y12i=x12i(j)
  y22r=x22r(j)
  y22i=x22i(j)
  go to 17
16 y22r=tp*x11i(j)/wlam
  y12r=0.
  y12i=1./(x11r(j)*sin(y22r))
  y11r=x12r(j)
  y11i=-y12i*cos(y22r)
  y22r=x22r(j)
  y22i=y11i+x22i(j)
  y11i=y11i+x12i(j)
  if (ntyp(j).eq.2) go to 17
  y12r=-y12r
  y12i=-y12i
17 if (nsant.eq.0) go to 19
  do 18 i=1,nsant
  if (nseg1.ne.isant(i)) go to 18
  isc1=i
  go to 22
18 continue
19 isc1=0
  if (nteq.eq.0) go to 21
  do 20 i=1,nteq
  if (nseg1.ne.nteqa(i)) go to 20
  irow1=i
  go to 25
20 continue
21 nteq=nteq+1
  irow1=nteq
  nteqa(nteq)=nseg1
  go to 25
22 if (ntsc.eq.0) go to 24
  do 23 i=1,ntsc
  if (nseg1.ne.ntsca(i)) go to 23
  irow1=ndimnp-i
  go to 25
23 continue
24 ntsc=ntsc+1
  irow1=ndimnp-ntsc
  ntsca(ntsc)=nseg1
  vsrc(ntsc)=vsant(isc1)
25 if (nsant.eq.0) go to 27
  do 26 i=1,nsant
  if (nseg2.ne.isant(i)) go to 26
  isc2=i
  go to 30
26 continue
27 isc2=0
  if (nteq.eq.0) go to 29
  do 28 i=1,nteq
  if (nseg2.ne.nteqa(i)) go to 28
  irow2=i
  go to 33
28 continue
29 nteq=nteq+1
  irow2=nteq
  nteqa(nteq)=nseg2
  go to 33
30 if (ntsc.eq.0) go to 32
  do 31 i=1,ntsc
  if (nseg2.ne.ntsca(i)) go to 31
  irow2=ndimnp-i
  go to 33
31 continue
32 ntsc=ntsc+1
  irow2=ndimnp-ntsc
  ntsca(ntsc)=nseg2
  vsrc(ntsc)=vsant(isc2)
33 if (ntsc+nteq.lt.ndimnp) go to 34
  write(*,59)
  stop
!
!     FILL NETWORK EQUATION MATRIX AND RIGHT HAND SIDE VECTOR WITH
!     NETWORK SHORT-CIRCUIT ADMITTANCE MATRIX COEFFICIENTS.
!
34 if (isc1.ne.0) go to 35
  cmn(irow1,irow1)=cmn(irow1,irow1)-dcmplx(y11r,y11i)*si(nseg1)
  cmn(irow1,irow2)=cmn(irow1,irow2)-dcmplx(y12r,y12i)*si(nseg1)
  go to 36
35 rhnx(irow1)=rhnx(irow1)+dcmplx(y11r,y11i)*vsant(isc1)/wlam
  rhnx(irow2)=rhnx(irow2)+dcmplx(y12r,y12i)*vsant(isc1)/wlam
36 if (isc2.ne.0) go to 37
  cmn(irow2,irow2)=cmn(irow2,irow2)-dcmplx(y22r,y22i)*si(nseg2)
  cmn(irow2,irow1)=cmn(irow2,irow1)-dcmplx(y12r,y12i)*si(nseg2)
  go to 38
37 rhnx(irow1)=rhnx(irow1)+dcmplx(y12r,y12i)*vsant(isc2)/wlam
  rhnx(irow2)=rhnx(irow2)+dcmplx(y22r,y22i)*vsant(isc2)/wlam
38 continue
!
!     ADD INTERACTION MATRIX ADMITTANCE ELEMENTS TO NETWORK EQUATION
!     MATRIX
!
  do 41 i=1,nteq
  do 39 j=1,neqt
39 rhs(j)=(0.,0.)
  irow1=nteqa(i)
  rhs(irow1)=(1.,0.)
  call solgf (cm,cmb,cmc,cmd,rhs,ip,np,n1,n,mp,m1,m,neq,neq2,neqz2)
  call cabc (rhs)
  do 40 j=1,nteq
  irow1=nteqa(j)
40 cmn(i,j)=cmn(i,j)+rhs(irow1)
41 continue
!
!     FACTOR NETWORK EQUATION MATRIX
!
  call factr (nteq,cmn,ipnt,ndimn)
!
!     ADD TO NETWORK EQUATION RIGHT HAND SIDE THE TERMS DUE TO ELEMENT
!     INTERACTIONS
!
42 if (nonet.eq.0) go to 48
  do 43 i=1,neqt
43 rhs(i)=einc(i)
  call solgf (cm,cmb,cmc,cmd,rhs,ip,np,n1,n,mp,m1,m,neq,neq2,neqz2)
  call cabc (rhs)
  do 44 i=1,nteq
  irow1=nteqa(i)
44 rhnt(i)=rhnx(i)+rhs(irow1)
!
!     SOLVE NETWORK EQUATIONS
!
  call solve (nteq,cmn,ipnt,rhnt,ndimn)
!
!     ADD FIELDS DUE TO NETWORK VOLTAGES TO ELECTRIC FIELDS APPLIED TO
!     STRUCTURE AND SOLVE FOR INDUCED CURRENT
!
  do 45 i=1,nteq
  irow1=nteqa(i)
45 einc(irow1)=einc(irow1)-rhnt(i)
  call solgf (cm,cmb,cmc,cmd,einc,ip,np,n1,n,mp,m1,m,neq,neq2,neqz2)
  call cabc (einc)
  if (nprint.eq.0) write(*,61)
  if (nprint.eq.0) write(*,60)
  do 46 i=1,nteq
  irow1=nteqa(i)
  vlt=rhnt(i)*si(irow1)*wlam
  cux=einc(irow1)*wlam
  ymit=cux/vlt
  zped=vlt/cux
  irow2=itag(irow1)
  pwr=.5*dreal(vlt*dconjg(cux))
  pnls=pnls-pwr
46 if (nprint.eq.0) write(*,62)  irow2,irow1,vlt,cux,zped,ymit,pwr
  if (ntsc.eq.0) go to 49
  do 47 i=1,ntsc
  irow1=ntsca(i)
  vlt=vsrc(i)
  cux=einc(irow1)*wlam
  ymit=cux/vlt
  zped=vlt/cux
  irow2=itag(irow1)
  pwr=.5*dreal(vlt*dconjg(cux))
  pnls=pnls-pwr
47 if (nprint.eq.0) write(*,62)  irow2,irow1,vlt,cux,zped,ymit,pwr
  go to 49
!
!     SOLVE FOR CURRENTS WHEN NO NETWORKS ARE PRESENT
!
48 call solgf (cm,cmb,cmc,cmd,einc,ip,np,n1,n,mp,m1,m,neq,neq2,neqz2)
  call cabc (einc)
  ntsc=0
49 if (nsant+nvqd.eq.0) return
  write(*,63)
  write(*,60)
  if (nsant.eq.0) go to 56
  do 55 i=1,nsant
  isc1=isant(i)
  vlt=vsant(i)
  if (ntsc.eq.0) go to 51
  do 50 j=1,ntsc
  if (ntsca(j).eq.isc1) go to 52
50 continue
51 cux=einc(isc1)*wlam
  irow1=0
  go to 54
52 irow1=ndimnp-j
  cux=rhnx(irow1)
  do 53 j=1,nteq
53 cux=cux-cmn(j,irow1)*rhnt(j)
  cux=(einc(isc1)+cux)*wlam
54 ymit=cux/vlt
  zped=vlt/cux
  pwr=.5*dreal(vlt*dconjg(cux))
  pin=pin+pwr
  if (irow1.ne.0) pnls=pnls+pwr
  irow2=itag(isc1)
55 write(*,62)  irow2,isc1,vlt,cux,zped,ymit,pwr
56 if (nvqd.eq.0) return
  do 57 i=1,nvqd
  isc1=ivqd(i)
  vlt=vqd(i)
  cux=dcmplx(air(isc1),aii(isc1))
  ymit=dcmplx(bir(isc1),bii(isc1))
  zped=dcmplx(cir(isc1),cii(isc1))
  pwr=si(isc1)*tp*.5
  cux=(cux-ymit*sin(pwr)+zped*cos(pwr))*wlam
  ymit=cux/vlt
  zped=vlt/cux
  pwr=.5*dreal(vlt*dconjg(cux))
  pin=pin+pwr
  irow2=itag(isc1)
57 write(*,64)  irow2,isc1,vlt,cux,zped,ymit,pwr
  return
!
58 format (///,3x,47hMAXIMUM RELATIVE ASYMMETRY OF THE DRIVING POINT,21h ADMITTANCE MATRIX IS,1p,e10.3,13h FOR SEGMENTS, &
  i5,4h AND,i5,/,3x,25hRMS RELATIVE ASYMMETRY IS,e10.3)
59 format (1x,44hERROR - - NETWORK ARRAY DIMENSIONS TOO SMALL)
60 format (/,3x,3hTAG,3x,4hSEG.,4x,15hVOLTAGE (VOLTS),9x,14hCURRENT (AMPS),9x,16hIMPEDANCE (OHMS),8x, &
  17hADMITTANCE (MHOS),6x,5hPOWER,/,3x,3hNO.,3x,3hNO.,4x,4hREAL,8x,5hIMAG.,3(7x,4hREAL,8x,5hIMAG.),5x,7h(WATTS))
61 format (///,27x,66h- - - STRUCTURE EXCITATION DATA AT NETWORK CONNECTION POINTS - - -)
62 format (2(1x,i5),1p,9e12.5)
63 format (///,42x,36h- - - ANTENNA INPUT PARAMETERS - - -)
64 format (1x,i5,2h *,i4,1p,9e12.5)
  end

! -----------------------------------------------------------------------------
! stopwtch - extracted from nec2dxs_integrated.f
! -----------------------------------------------------------------------------
    subroutine stopwtch(cputot,walltot,cpusplt,wallsplt)
!
!       This routine operates as a stopwatch.
!       When first called, the routine initializes the clock.
!       On subsequent calls, the routine returns:
!
!       Outputs: cputot   -- elapsed CPU time since initialization
!                walltot  -- elapsed wallclock time since initialization
!                cpusplt  -- split (delta) CPU time since previous call
!                wallsplt -- split wallclock time since previous call
!
!       These outputs will all be zero (or very close to it) on the
!       first (initialization) call.
!
!       Internal times (cpuinit,wallinit,cpunow,wallnow) are stored in
!       seconds.  cpuinit  and cpunow  are stored as reals,
!                 wallinit and wallnow are stored as integers.
!       Output times are converted to real minutes.
!
! History:
!   Date       Author            Reason
!   ---------  ----------------  ------------------------------------
!    early-90  Scott L. Ray      initial version
!      mid-90  Scott L. Ray      support for additional machines
!   14-JAN-91                    ---- Version 2.2/release    ----
!   23-MAY-91  Scott L. Ray      UNICOS branch
!   29-JAN-92  Scott L. Ray      FPS and NLTSS support dropped
!   29-JAN-92  Scott L. Ray      switch to cpp conditional compilation
!   18-SEP-92      Conditional compilation disabled for use in NEC
!
!  (C) Copyright 1990, 1992.
!  The Regents of the University of California.  All rights reserved.
! ----------------------------------------------------------------------
!
! parameter list
!
    real cputot,walltot,cpusplt,wallsplt
!
! locals (non sysdep)
!
    logical initiz
    integer wallinit,walllast,wallnow
    real cpuinit,cpulast,cpunow
    save initiz,cpuinit,cpulast,wallinit,walllast
!
! locals (sysdep)
!
!#include "machines.h"
!#ifdef VAX_VMS
!        integer istatus,iwall,icpu
!        real rwall
!        dimension iwall(2)
!#endif
!#ifdef SUN4TIMER
    integer time
    real tarray
    dimension tarray(2)
!#endif
!#ifdef CONVEX
!        real time, secnds, tarray
!        dimension tarray(2)
!        external secnds
!#endif
!#ifdef IBM_RISC
!        integer icpu
!        integer mclock
!#endif
!#ifdef IRIS4D
!        external time
!#endif
!#ifdef STARDENT
!        integer stime
!        real tarray
!        dimension tarray(2)
!#endif
!#ifdef UNICOS
!        real rwall
!#endif
!
! data initialization
!
    data initiz/.false./
!
! ----------------------------------------------------------------------
!
    if (.not. initiz) then
!
! ...      set the flag showing that the clock has been initialized
!
       initiz = .true.
!
! ...      set the initial times to default value of zero.  These may
!          be changed, depending on how an individual machine handles
!          its timer.
!
       cpuinit  = 0.0
       wallinit = 0
!
! ...      initialize the timer (may not be necessary on all machines)
!
!#ifdef VAX_VMS
!           istatus = lib$init_timer()
!#endif
!
!#ifdef SUN4TIMER
!          CPU timer on SUN4 initializes automatically on job startup.
!          However, we want t=0 to be defined when this routine is first
!          called.  Hence, define initial CPU time here.
!          Wall clock timer counts in seconds from 1-Jan-70  Thus,
!          initial wall clock time is non-zero.  It is obtained here.
!
       cpuinit  = etime(tarray)
       wallinit = time()
!#endif
!
!#ifdef CONVEX
!           cpuinit = etime(tarray)
!           time = secnds(0.0)
!           wallinit = ifix(time)
!#endif
!
!#ifdef IBM_RISC
!          no known wall clock timer
!
!           icpu = mclock( )
!           cpuinit  = float(icpu)/100.0
!           wallinit = 0
!#endif
!
!#ifdef STARDENT
!          CPU timer on STARDENT initializes automatically on job
!          startup.
!          However, we want t=0 to be defined when this routine is first
!          called.  Hence, define initial CPU time here.
!          Wall clock timer counts in seconds from 1-Jan-70  Thus,
!          initial wall clock time is non-zero.  It is obtained here.
!
!           cpuinit  = etime(tarray)
!           wallinit = stime()
!#endif
!
!#ifdef UNICOS
!          I hope that the "second" routine is true UNICOS and not a
!          local (LLNL) feature that was added on to keep things
!          consistent with NLTSS.
!          The "timef" routine returns real milliseconds; first
!          call initializes the timer and should return zero (not
!          that we care -- this routine works by taking differences).
!
!           call second(cpuinit)
!           call timef(rwall)
!           wallinit = ifix(rwall*1.0e-03)
!#endif
!
! ...      since this is the first call to this routine,
!          initialize the previous call times to the initial time.
!
       cpulast  =  cpuinit
       walllast = wallinit
!
    end if
!
! ...   Find the current cpu and wall times
!
!#ifdef HASTIMER
!#ifdef VAX_VMS
!
!       function "lib$stat_timer" is called as:
!       error_status = lib$stat_timer(input_code,output_result,junk)
!       where,
!        input_code = 1 returns elapsed wall clock time in VAX_VMS
!           binary internal format.  This format takes 64 bits to store,
!           hence output_result should be a 32 bit integer array of
!           length 2.
!           This internal format is converted to a floating point number
!           by calling "lib$cvtf_from_internal_time".  This function
!           is poorly documented in the VAX_VMS manuals.  Here are some
!           details:  First argument = 28 ==> result in real hours
!                                    = 29 ==> result in real minutes
!                                    = 30 ==> result in real seconds
!           The input to "lib$cvtf_from_internal_time" goes in the 3rd
!           argument, the result is returned in the 2nd argument.
!           input_code = 2 returns elapsed cpu time as an integer in
!           units of 10msec.  This is converted to seconds here.
!
!        istatus = lib$stat_timer(1,iwall,)
!        istatus = lib$cvtf_from_internal_time(30,rwall,iwall)
!        wallnow = rwall
!        istatus = lib$stat_timer(2,icpu,)
!        cpunow = icpu*(10.0e-3)
!#endif
!
!#ifdef SUN4TIMER
!       there is some ambiguity in the manual as to how to use
!       etime.  Function returns:
!          "elapsed execution time" = tarray(1) + tarray(2)
!                                   = user time + system time
!       I am uncertain whether to let cpunow = return value or
!       else tarray(1).
!
    cpunow  = etime(tarray)
    wallnow = time()
!#endif
!
!#ifdef CONVEX
!           cpunow = etime(tarray)
!           time = secnds(0.0)
!           wallnow = ifix(time)
!#endif
!
!#ifdef IBM_RISC
!       no known wall clock timer
!
!        icpu = mclock( )
!        cpunow  = float(icpu)/100.0
!        wallnow = 0
!#endif
!
!#ifdef STARDENT
!       there is some ambiguity in the manual as to how to use
!       etime.  Function returns:
!          "elapsed execution time" = tarray(1) + tarray(2)
!                                   = user time + system time
!       I am uncertain whether to let cpunow = return value or
!       else tarray(1).
!
!        cpunow  = etime(tarray)
!        wallnow = stime()
!#endif
!
!#ifdef UNICOS
!       I hope that the "second" routine is true UNICOS and not a
!       local (LLNL) feature that was added on to keep things
!       consistent with NLTSS.
!       The "timef" routine returns real milliseconds.
!
!        call second(cpunow)
!        call timef(rwall)
!        wallnow = ifix(rwall*1.0e-03)
!#endif
!#else
!       for machines without timers or with unknown timers,
!       set things to zero now to ensure that something is returned
!        cpunow  = 0.0
!        wallnow = 0
!#endif
!
! ...   calculate elapsed and split cpu and wall clock times,
!       convert to minutes on output.
!
    cputot   = (cpunow  - cpuinit )/60.0
    walltot  = float(wallnow - wallinit)/60.0
    cpusplt  = (cpunow  - cpulast )/60.0
    wallsplt = float(wallnow - walllast)/60.0
!
! ...   save "now" times in "last" times
!
    cpulast  = cpunow
    walllast = wallnow
!
    return
! **********************************************************************
    end
