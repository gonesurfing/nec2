!***********************************************************************
!     NEC2D Common Blocks Module
!***********************************************************************
!     All COMMON blocks from nec2dxs.f converted to module variables
!     Preserves original data structures for compatibility
!***********************************************************************

MODULE nec2d_commons
  USE nec2d_params
  IMPLICIT NONE

  ! Common /DATA/ - Geometry data
  REAL*8 :: X(MAXSEG), Y(MAXSEG), Z(MAXSEG)
  REAL*8 :: SI(MAXSEG), BI(MAXSEG)
  REAL*8 :: ALP(MAXSEG), BET(MAXSEG)
  REAL*8 :: WLAM
  INTEGER :: ICON1(2*MAXSEG), ICON2(2*MAXSEG)
  INTEGER :: ITAG(2*MAXSEG), ICONX(MAXSEG)
  INTEGER :: LD, N1, N2, N, NP, M1, M2, M, MP, IPSYM

  ! Common /CMB/ - Complex matrix
  COMPLEX*16 :: CM(IRESRV)

  ! Common /MATPAR/ - Matrix parameters
  INTEGER :: ICASE, NBLOKS, NPBLK, NLAST, NBLSYM, NPSYM, NLSYM, IMAT
  INTEGER :: ICASX, NBBX, NPBX, NLBX, NBBL, NPBL, NLBL

  ! Common /SAVE/ - Save parameters
  REAL*8 :: EPSR, SIG, SCRWLT, SCRWRT, FMHZ
  INTEGER :: IP(2*MAXSEG), KCOM

  ! Common /CSAVE/ - Character save
  REAL*8 :: COM(19,5)

  ! Common /CRNT/ - Current coefficients
  REAL*8 :: AIR(MAXSEG), AII(MAXSEG)
  REAL*8 :: BIR(MAXSEG), BII(MAXSEG)
  REAL*8 :: CIR(MAXSEG), CII(MAXSEG)
  COMPLEX*16 :: CUR(3*MAXSEG)

  ! Common /GND/ - Ground parameters
  COMPLEX*16 :: ZRATI, ZRATI2, FRATI, T1, T2
  REAL*8 :: CL, CH, SCRWL, SCRWR
  INTEGER :: NRADL, KSYMP, IFAR, IPERF

  ! Common /ZLOAD/ - Load impedances
  COMPLEX*16 :: ZARRAY(MAXSEG)
  INTEGER :: NLOAD, NLODF

  ! Common /YPARM/ - Y-parameters
  COMPLEX*16 :: Y11A(5), Y12A(20)
  INTEGER :: NCOUP, ICOUP, NCTAG(5), NCSEG(5)

  ! Common /SEGJ/ - Segment junction data
  REAL*8 :: AX(JMAX), BX(JMAX), CX(JMAX)
  INTEGER :: JCO(JMAX), JSNO
  INTEGER :: ISCON(50), NSCON
  INTEGER :: IPCON(10), NPCON

  ! Common /VSORC/ - Voltage sources
  COMPLEX*16 :: VQD(NSMAX), VSANT(NSMAX), VQDS(NSMAX)
  INTEGER :: IVQD(NSMAX), ISANT(NSMAX), IQDS(NSMAX)
  INTEGER :: NVQD, NSANT, NQDS

  ! Common /NETCX/ - Network connections
  COMPLEX*16 :: ZPED
  REAL*8 :: PIN, PNLS
  REAL*8 :: X11R(NETMX), X11I(NETMX)
  REAL*8 :: X12R(NETMX), X12I(NETMX)
  REAL*8 :: X22R(NETMX), X22I(NETMX)
  INTEGER :: NTYP(NETMX), ISEG1(NETMX), ISEG2(NETMX)
  INTEGER :: NEQ, NPEQ, NEQ2, NONET, NTSOL, NPRINT, MASYM

  ! Common /FPAT/ - Far field pattern
  REAL*8 :: THETS, PHIS, DTH, DPH, RFLD, GNOR
  REAL*8 :: CLT, CHT, EPSR2, SIG2
  REAL*8 :: XPR6, PINR, PNLR, PLOSS
  REAL*8 :: XNR, YNR, ZNR, DXNR, DYNR, DZNR
  INTEGER :: NTH, NPH, IPD, IAVP, INOR, IAX, IXTYP, NEAR, NFEH
  INTEGER :: NRX, NRY, NRZ

  ! Common /GGRID/ - Ground grid
  COMPLEX*16 :: AR1(11,10,4), AR2(17,5,4), AR3(9,8,4), EPSCF
  REAL*8 :: DXA(3), DYA(3), XSA(3), YSA(3)
  INTEGER :: NXA(3), NYA(3)

  ! Common /GWAV/ - Ground wave
  COMPLEX*16 :: U, U2, XX1, XX2
  REAL*8 :: R1, R2, ZMH, ZPH

  ! Common /PLOT/ - Plot flags
  INTEGER :: IPLP1, IPLP2, IPLP3, IPLP4

  ! Common /ANGL/ - Angle data (used in some subroutines)
  REAL*8 :: SALP(MAXSEG)

  ! Common /DATAJ/ - Data for junction calculations
  REAL*8 :: S_J, B_J, XJ, YJ, ZJ, CABJ, SABJ, SALPJ
  COMPLEX*16 :: EXK, EYK, EZK, EXS, EYS, EZS, EXC, EYC, EZC
  REAL*8 :: RKH
  INTEGER :: IND1, INDD1, IND2, INDD2, IEXK, IPGND

  ! Common /EVLCOM/ - Evaluation common (Sommerfeld integration)
  COMPLEX*16 :: CKSM, CT1, CT2, CT3, CK1, CK1SQ, CK2, CK2SQ
  REAL*8 :: TKMAG, TSMAG, CK1R, ZPH_EV, RHO_EV
  INTEGER :: JH

  ! Common /INCOM/ - Input common (field calculations)
  REAL*8 :: XO, YO, ZO, SN, XSN, YSN
  INTEGER :: ISNOR

  ! Common /CNTOUR/ - Contour integration
  REAL*8 :: A_CNTOUR, B_CNTOUR

  ! Common /SMAT/ - Small matrix for NGF
  COMPLEX*16 :: SSX(16,16)

  ! Common /SCRATM/ - Scratch memory (reused by different routines)
  ! Note: This is declared as union/overlay in different subroutines
  ! Maximum size needed
  REAL*8 :: SCRATM_REAL(4*MAXSEG)
  COMPLEX*16 :: SCRATM_CPLX(2*MAXSEG)
  EQUIVALENCE (SCRATM_REAL, SCRATM_CPLX)

  ! Common /TMI/ - TM mode integration
  REAL*8 :: ZPK_TMI, RKB2
  INTEGER :: IJX_TMI

  ! Common /TMH/ - H field integration
  REAL*8 :: ZPK_TMH, RHKS

  ! Common /NGFNAM/ - NGF filename
  CHARACTER*80 :: NGFNAM

END MODULE nec2d_commons
