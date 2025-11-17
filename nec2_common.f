C     MODULE NEC2_COMMON
C     Common blocks and parameters for NEC2D
C     This module contains COMMON blocks used in the main program
C
      MODULE NEC2_COMMON
C
C     Include parameter definitions
      INCLUDE 'NEC2DPAR.INC'
      PARAMETER (IRESRV=MAXMAT**2)
C
C     Use traditional implicit typing like main code
      IMPLICIT REAL*8(A-H,O-Z)
C
C     Complex type declarations for variables in COMMON blocks
      COMPLEX*16 CM,CUR
      COMPLEX*16 ZRATI,ZRATI2,FRATI,T1
      COMPLEX*16 ZARRAY
      COMPLEX*16 Y11A,Y12A
      COMPLEX*16 VQD,VSANT,VQDS
      COMPLEX*16 ZPED
      COMPLEX*16 U,U2,XX1,XX2
      COMPLEX*16 AR1,AR2,AR3,EPSCF
C
C     COMMON blocks used in main program (from nec2dxs.f lines 33-61)
C     Note: /DATA/ excluded because it uses EQUIVALENCE in main program
C
C     /CMB/ - Complex matrix storage
      COMMON /CMB/CM(IRESRV)
C
C     /MATPAR/ - Matrix parameters
      COMMON /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,
     1ICASX,NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
C
C     /SAVE/ and /CSAVE/ - Saved parameters
      COMMON/SAVE/EPSR,SIG,SCRWLT,SCRWRT,FMHZ,IP(2*MAXSEG),KCOM
      COMMON/CSAVE/COM(19,5)
C
C     /CRNT/ - Current arrays
      COMMON /CRNT/ AIR(MAXSEG),AII(MAXSEG),BIR(MAXSEG),BII(MAXSEG),
     1CIR(MAXSEG),CII(MAXSEG),CUR(3*MAXSEG)
C
C     /GND/ - Ground parameters
      COMMON /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL,
     1KSYMP,IFAR,IPERF
C
C     /ZLOAD/ - Impedance loading
      COMMON /ZLOAD/ ZARRAY(MAXSEG),NLOAD,NLODF
C
C     /YPARM/ - Coupling parameters
      COMMON/YPARM/Y11A(5),Y12A(20),NCOUP,ICOUP,NCTAG(5),NCSEG(5)
C
C     /SEGJ/ - Segment junction data
      COMMON /SEGJ/ AX(JMAX),BX(JMAX),CX(JMAX),JCO(JMAX),
     1JSNO,ISCON(50),NSCON,IPCON(10),NPCON
C
C     /VSORC/ - Voltage source data
      COMMON/VSORC/VQD(NSMAX),VSANT(NSMAX),VQDS(NSMAX),IVQD(NSMAX),
     1ISANT(NSMAX),IQDS(NSMAX),NVQD,NSANT,NQDS
C
C     /NETCX/ - Network data
      COMMON/NETCX/ZPED,PIN,PNLS,X11R(NETMX),X11I(NETMX),X12R(NETMX),
     1X12I(NETMX),X22R(NETMX),X22I(NETMX),NTYP(NETMX),ISEG1(NETMX),
     2ISEG2(NETMX),NEQ,NPEQ,NEQ2,NONET,NTSOL,NPRINT,MASYM
C
C     /FPAT/ - Field pattern parameters
      COMMON/FPAT/THETS,PHIS,DTH,DPH,RFLD,GNOR,CLT,CHT,EPSR2,SIG2,
     1XPR6,PINR,PNLR,PLOSS,XNR,YNR,ZNR,DXNR,DYNR,DZNR,NTH,NPH,IPD,IAVP,
     2INOR,IAX,IXTYP,NEAR,NFEH,NRX,NRY,NRZ
C
C     /GGRID/ - Grid data for numerical Green's function
      COMMON /GGRID/ AR1(11,10,4),AR2(17,5,4),AR3(9,8,4),EPSCF,DXA(3),
     1DYA(3),XSA(3),YSA(3),NXA(3),NYA(3)
C
C     /GWAV/ - Wave parameters
      COMMON/GWAV/U,U2,XX1,XX2,R1,R2,ZMH,ZPH
C
C     /PLOT/ - Plot control flags
      COMMON /PLOT/ IPLP1,IPLP2,IPLP3,IPLP4
C
      END MODULE NEC2_COMMON
