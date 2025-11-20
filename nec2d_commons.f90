!***********************************************************************
!     NEC2D Common Blocks Module
!***********************************************************************
!     All COMMON blocks from nec2dxs.f converted to module variables
!     Preserves original data structures for compatibility
!***********************************************************************

module nec2d_commons
  use nec2d_params
  implicit NONE

  ! Common /DATA/ - Geometry data
  real*8 :: X(MAXSEG), Y(MAXSEG), Z(MAXSEG)
  real*8 :: SI(MAXSEG), BI(MAXSEG)
  real*8 :: ALP(MAXSEG), BET(MAXSEG)
  real*8 :: WLAM
  integer :: ICON1(2*MAXSEG), ICON2(2*MAXSEG)
  integer :: ITAG(2*MAXSEG), ICONX(MAXSEG)
  integer :: LD, N1, N2, N, NP, M1, M2, M, MP, IPSYM

  ! Common /CMB/ - Complex matrix
  complex*16 :: CM(IRESRV)

  ! Common /MATPAR/ - Matrix parameters
  integer :: ICASE, NBLOKS, NPBLK, NLAST, NBLSYM, NPSYM, NLSYM, IMAT
  integer :: ICASX, NBBX, NPBX, NLBX, NBBL, NPBL, NLBL

  ! Common /SAVE/ - Save parameters
  real*8 :: EPSR, SIG, SCRWLT, SCRWRT, FMHZ
  integer :: IP(2*MAXSEG), KCOM

  ! Common /CSAVE/ - Character save
  real*8 :: COM(19,5)

  ! Common /CRNT/ - Current coefficients
  real*8 :: AIR(MAXSEG), AII(MAXSEG)
  real*8 :: BIR(MAXSEG), BII(MAXSEG)
  real*8 :: CIR(MAXSEG), CII(MAXSEG)
  complex*16 :: CUR(3*MAXSEG)

  ! Common /GND/ - Ground parameters
  complex*16 :: ZRATI, ZRATI2, FRATI, T1, T2
  real*8 :: CL, CH, SCRWL, SCRWR
  integer :: NRADL, KSYMP, IFAR, IPERF

  ! Common /ZLOAD/ - Load impedances
  complex*16 :: ZARRAY(MAXSEG)
  integer :: NLOAD, NLODF

  ! Common /YPARM/ - Y-parameters
  complex*16 :: Y11A(5), Y12A(20)
  integer :: NCOUP, ICOUP, NCTAG(5), NCSEG(5)

  ! Common /SEGJ/ - Segment junction data
  real*8 :: AX(JMAX), BX(JMAX), CX(JMAX)
  integer :: JCO(JMAX), JSNO
  integer :: ISCON(50), NSCON
  integer :: IPCON(10), NPCON

  ! Common /VSORC/ - Voltage sources
  complex*16 :: VQD(NSMAX), VSANT(NSMAX), VQDS(NSMAX)
  integer :: IVQD(NSMAX), ISANT(NSMAX), IQDS(NSMAX)
  integer :: NVQD, NSANT, NQDS

  ! Common /NETCX/ - Network connections
  complex*16 :: ZPED
  real*8 :: PIN, PNLS
  real*8 :: X11R(NETMX), X11I(NETMX)
  real*8 :: X12R(NETMX), X12I(NETMX)
  real*8 :: X22R(NETMX), X22I(NETMX)
  integer :: NTYP(NETMX), ISEG1(NETMX), ISEG2(NETMX)
  integer :: NEQ, NPEQ, NEQ2, NONET, NTSOL, NPRINT, MASYM

  ! Common /FPAT/ - Far field pattern
  real*8 :: THETS, PHIS, DTH, DPH, RFLD, GNOR
  real*8 :: CLT, CHT, EPSR2, SIG2
  real*8 :: XPR6, PINR, PNLR, PLOSS
  real*8 :: XNR, YNR, ZNR, DXNR, DYNR, DZNR
  integer :: NTH, NPH, IPD, IAVP, INOR, IAX, IXTYP, NEAR, NFEH
  integer :: NRX, NRY, NRZ

  ! Common /GGRID/ - Ground grid
  complex*16 :: AR1(11,10,4), AR2(17,5,4), AR3(9,8,4), EPSCF
  real*8 :: DXA(3), DYA(3), XSA(3), YSA(3)
  integer :: NXA(3), NYA(3)

  ! Common /GWAV/ - Ground wave
  complex*16 :: U, U2, XX1, XX2
  real*8 :: R1, R2, ZMH, ZPH

  ! Common /PLOT/ - Plot flags
  integer :: IPLP1, IPLP2, IPLP3, IPLP4

  ! Common /ANGL/ - Angle data (used in some subroutines)
  real*8 :: SALP(MAXSEG)

  ! Common /DATAJ/ - Data for junction calculations
  real*8 :: S_J, B_J, XJ, YJ, ZJ, CABJ, SABJ, SALPJ
  complex*16 :: EXK, EYK, EZK, EXS, EYS, EZS, EXC, EYC, EZC
  real*8 :: RKH
  integer :: IND1, INDD1, IND2, INDD2, IEXK, IPGND

  ! Common /EVLCOM/ - Evaluation common (Sommerfeld integration)
  complex*16 :: CKSM, CT1, CT2, CT3, CK1, CK1SQ, CK2, CK2SQ
  real*8 :: TKMAG, TSMAG, CK1R, ZPH_EV, RHO_EV
  integer :: JH

  ! Common /INCOM/ - Input common (field calculations)
  real*8 :: XO, YO, ZO, SN, XSN, YSN
  integer :: ISNOR

  ! Common /CNTOUR/ - Contour integration
  real*8 :: A_CNTOUR, B_CNTOUR

  ! Common /SMAT/ - Small matrix for NGF
  complex*16 :: SSX(16,16)

  ! Common /SCRATM/ - Scratch memory (reused by different routines)
  ! Note: This is declared as union/overlay in different subroutines
  ! Maximum size needed
  real*8 :: SCRATM_REAL(4*MAXSEG)
  complex*16 :: SCRATM_CPLX(2*MAXSEG)
  equivalence (SCRATM_REAL, SCRATM_CPLX)

  ! Common /TMI/ - TM mode integration
  real*8 :: ZPK_TMI, RKB2
  integer :: IJX_TMI

  ! Common /TMH/ - H field integration
  real*8 :: ZPK_TMH, RHKS

  ! Common /NGFNAM/ - NGF filename
  character*80 :: NGFNAM

end module nec2d_commons
