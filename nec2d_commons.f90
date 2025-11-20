!***********************************************************************
!     NEC2D Common Blocks Module
!***********************************************************************
!     All COMMON blocks from nec2dxs.f converted to module variables
!     Preserves original data structures for compatibility
!***********************************************************************

module nec2d_commons
  use nec2d_params
  implicit none

  ! Common /DATA/ - Geometry data
  real*8 :: x(maxseg), y(maxseg), z(maxseg)
  real*8 :: si(maxseg), bi(maxseg)
  real*8 :: alp(maxseg), bet(maxseg)
  real*8 :: wlam
  integer :: icon1(2*maxseg), icon2(2*maxseg)
  integer :: itag(2*maxseg), iconx(maxseg)
  integer :: ld, n1, n2, n, np, m1, m2, m, mp, ipsym

  ! Common /CMB/ - Complex matrix
  complex*16 :: cm(iresrv)

  ! Common /MATPAR/ - Matrix parameters
  integer :: icase, nbloks, npblk, nlast, nblsym, npsym, nlsym, imat
  integer :: icasx, nbbx, npbx, nlbx, nbbl, npbl, nlbl

  ! Common /SAVE/ - Save parameters
  real*8 :: epsr, sig, scrwlt, scrwrt, fmhz
  integer :: ip(2*maxseg), kcom

  ! Common /CSAVE/ - Character save
  real*8 :: com(19,5)

  ! Common /CRNT/ - Current coefficients
  real*8 :: air(maxseg), aii(maxseg)
  real*8 :: bir(maxseg), bii(maxseg)
  real*8 :: cir(maxseg), cii(maxseg)
  complex*16 :: cur(3*maxseg)

  ! Common /GND/ - Ground parameters
  complex*16 :: zrati, zrati2, frati, t1, t2
  real*8 :: cl, ch, scrwl, scrwr
  integer :: nradl, ksymp, ifar, iperf

  ! Common /ZLOAD/ - Load impedances
  complex*16 :: zarray(maxseg)
  integer :: nload, nlodf

  ! Common /YPARM/ - Y-parameters
  complex*16 :: y11a(5), y12a(20)
  integer :: ncoup, icoup, nctag(5), ncseg(5)

  ! Common /SEGJ/ - Segment junction data
  real*8 :: ax(jmax), bx(jmax), cx(jmax)
  integer :: jco(jmax), jsno
  integer :: iscon(50), nscon
  integer :: ipcon(10), npcon

  ! Common /VSORC/ - Voltage sources
  complex*16 :: vqd(nsmax), vsant(nsmax), vqds(nsmax)
  integer :: ivqd(nsmax), isant(nsmax), iqds(nsmax)
  integer :: nvqd, nsant, nqds

  ! Common /NETCX/ - Network connections
  complex*16 :: zped
  real*8 :: pin, pnls
  real*8 :: x11r(netmx), x11i(netmx)
  real*8 :: x12r(netmx), x12i(netmx)
  real*8 :: x22r(netmx), x22i(netmx)
  integer :: ntyp(netmx), iseg1(netmx), iseg2(netmx)
  integer :: neq, npeq, neq2, nonet, ntsol, nprint, masym

  ! Common /FPAT/ - Far field pattern
  real*8 :: thets, phis, dth, dph, rfld, gnor
  real*8 :: clt, cht, epsr2, sig2
  real*8 :: xpr6, pinr, pnlr, ploss
  real*8 :: xnr, ynr, znr, dxnr, dynr, dznr
  integer :: nth, nph, ipd, iavp, inor, iax, ixtyp, near, nfeh
  integer :: nrx, nry, nrz

  ! Common /GGRID/ - Ground grid
  complex*16 :: ar1(11,10,4), ar2(17,5,4), ar3(9,8,4), epscf
  real*8 :: dxa(3), dya(3), xsa(3), ysa(3)
  integer :: nxa(3), nya(3)

  ! Common /GWAV/ - Ground wave
  complex*16 :: u, u2, xx1, xx2
  real*8 :: r1, r2, zmh, zph

  ! Common /PLOT/ - Plot flags
  integer :: iplp1, iplp2, iplp3, iplp4

  ! Common /ANGL/ - Angle data (used in some subroutines)
  real*8 :: salp(maxseg)

  ! Common /DATAJ/ - Data for junction calculations
  real*8 :: s_j, b_j, xj, yj, zj, cabj, sabj, salpj
  complex*16 :: exk, eyk, ezk, exs, eys, ezs, exc, eyc, ezc
  real*8 :: rkh
  integer :: ind1, indd1, ind2, indd2, iexk, ipgnd

  ! Common /EVLCOM/ - Evaluation common (Sommerfeld integration)
  complex*16 :: cksm, ct1, ct2, ct3, ck1, ck1sq, ck2, ck2sq
  real*8 :: tkmag, tsmag, ck1r, zph_ev, rho_ev
  integer :: jh

  ! Common /INCOM/ - Input common (field calculations)
  real*8 :: xo, yo, zo, sn, xsn, ysn
  integer :: isnor

  ! Common /CNTOUR/ - Contour integration
  real*8 :: a_cntour, b_cntour

  ! Common /SMAT/ - Small matrix for NGF
  complex*16 :: ssx(16,16)

  ! Common /SCRATM/ - Scratch memory (reused by different routines)
  ! Note: This is declared as union/overlay in different subroutines
  ! Maximum size needed
  real*8 :: scratm_real(4*maxseg)
  complex*16 :: scratm_cplx(2*maxseg)
  equivalence (scratm_real, scratm_cplx)

  ! Common /TMI/ - TM mode integration
  real*8 :: zpk_tmi, rkb2
  integer :: ijx_tmi

  ! Common /TMH/ - H field integration
  real*8 :: zpk_tmh, rhks

  ! Common /NGFNAM/ - NGF filename
  character*80 :: ngfnam

end module nec2d_commons
