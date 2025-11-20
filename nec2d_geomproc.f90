! =============================================================================
! nec2d_geomproc - Geometry and Matrix Processing
! =============================================================================
! Purpose: H field computation, matrix factorization, patch subdivision
! Contains: HSFLD, LFACTR, PATCH, SUBPH
! GOTOs eliminated: 39
! =============================================================================
subroutine HSFLD (XI,YI,ZI,AI)
  implicit real*8(A-H,O-Z)

  complex*16 EXK,EYK,EZK,EXS,EYS,EZS,EXC,EYC,EZC,ZRATI,ZRATI2,T1
  complex*16 HPK,HPS,HPC,QX,QY,QZ,RRV,RRH,ZRATX,FRATI

  common /DATAJ/ S,B,XJ,YJ,ZJ,CABJ,SABJ,SALPJ,EXK,EYK,EZK,EXS,EYS, &
                 EZS,EXC,EYC,EZC,RKH,IND1,INDD1,IND2,INDD2,IEXK,IPGND
  common /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL, &
              KSYMP,IFAR,IPERF

  data ETA/376.73/

  XIJ=XI-XJ
  YIJ=YI-YJ
  RFL=-1.

  ! Symmetry loop (formerly DO 7)
  do IP=1,KSYMP
    RFL=-RFL
    SALPR=SALPJ*RFL
    ZIJ=ZI-RFL*ZJ
    ZP=XIJ*CABJ+YIJ*SABJ+ZIJ*SALPR
    RHOX=XIJ-CABJ*ZP
    RHOY=YIJ-SABJ*ZP
    RHOZ=ZIJ-SALPR*ZP
    RH=SQRT(RHOX*RHOX+RHOY*RHOY+RHOZ*RHOZ+AI*AI)

    ! Handle zero RH case (formerly GO TO 1 / GO TO 7)
    if (RH.le.1.D-10) then
      EXK=0.
      EYK=0.
      EZK=0.
      EXS=0.
      EYS=0.
      EZS=0.
      EXC=0.
      EYC=0.
      EZC=0.
      cycle  ! Skip to next iteration
    end if

    ! Label 1: Normalize and compute field components
    RHOX=RHOX/RH
    RHOY=RHOY/RH
    RHOZ=RHOZ/RH
    PHX=SABJ*RHOZ-SALPR*RHOY
    PHY=SALPR*RHOX-CABJ*RHOZ
    PHZ=CABJ*RHOY-SABJ*RHOX
    call HSFLX (S,RH,ZP,HPK,HPS,HPC)

    ! Check iteration number (formerly GO TO 6)
    if (IP.ne.2) then
      ! Label 6: First iteration - set initial field values
      EXK=HPK*PHX
      EYK=HPK*PHY
      EZK=HPK*PHZ
      EXS=HPS*PHX
      EYS=HPS*PHY
      EZS=HPS*PHZ
      EXC=HPC*PHX
      EYC=HPC*PHY
      EZC=HPC*PHZ
    else
      ! Second iteration - apply ground effects
      ! Check for perfect ground (formerly GO TO 5)
      if (IPERF.eq.1) then
        ! Label 5: Perfect ground case
        EXK=EXK-HPK*PHX
        EYK=EYK-HPK*PHY
        EZK=EZK-HPK*PHZ
        EXS=EXS-HPS*PHX
        EYS=EYS-HPS*PHY
        EZS=EZS-HPS*PHZ
        EXC=EXC-HPC*PHX
        EYC=EYC-HPC*PHY
        EZC=EZC-HPC*PHZ
      else
        ! Imperfect ground case
        ZRATX=ZRATI
        RMAG=SQRT(ZP*ZP+RH*RH)
        XYMAG=SQRT(XIJ*XIJ+YIJ*YIJ)

        ! Set parameters for radial wire ground screen (formerly GO TO 2)
        if (NRADL.ne.0) then
          XSPEC=(XI*ZJ+ZI*XJ)/(ZI+ZJ)
          YSPEC=(YI*ZJ+ZI*YJ)/(ZI+ZJ)
          RHOSPC=SQRT(XSPEC*XSPEC+YSPEC*YSPEC+T2*T2)
          if (RHOSPC.le.SCRWL) then
            RRV=T1*RHOSPC*LOG(RHOSPC/T2)
            ZRATX=(RRV*ZRATI)/(ETA*ZRATI+RRV)
          end if
        end if

        ! Label 2: Calculation of reflection coefficients when ground is specified
        ! (formerly GO TO 3 / GO TO 4)
        if (XYMAG.le.1.D-6) then
          PX=0.
          PY=0.
          CTH=1.
          RRV=(1.,0.)
        else
          ! Label 3
          PX=-YIJ/XYMAG
          PY=XIJ/XYMAG
          CTH=ZIJ/RMAG
          RRV=SQRT(1.-ZRATX*ZRATX*(1.-CTH*CTH))
        end if

        ! Label 4: Compute reflection coefficients
        RRH=ZRATX*CTH
        RRH=-(RRH-RRV)/(RRH+RRV)
        RRV=ZRATX*RRV
        RRV=(CTH-RRV)/(CTH+RRV)
        QY=(PHX*PX+PHY*PY)*(RRV-RRH)
        QX=QY*PX+PHX*RRH
        QY=QY*PY+PHY*RRH
        QZ=PHZ*RRH
        EXK=EXK-HPK*QX
        EYK=EYK-HPK*QY
        EZK=EZK-HPK*QZ
        EXS=EXS-HPS*QX
        EYS=EYS-HPS*QY
        EZS=EZS-HPS*QZ
        EXC=EXC-HPC*QX
        EYC=EYC-HPC*QY
        EZC=EZC-HPC*QZ
      end if
    end if

  end do  ! IP loop (formerly label 7)

  return
end subroutine HSFLD

!==============================================================================
! LFACTR - Gauss-Doolittle LU Factorization
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 2388-2498)
! Original: Fixed-form Fortran 77 with 14 GOTOs
! Modernized: Free-form Fortran 90 with structured control flow
!
! Purpose: Performs Gauss-Doolittle manipulations on two blocks of the
!          transposed matrix in core storage. The Gauss-Doolittle algorithm
!          is presented on pages 411-416 of A. Ralston -- A First Course in
!          Numerical Analysis. Comments below refer to comments in Ralston's
!          text.
!
! GOTOs eliminated: 14 (labels 1-16)
!==============================================================================
subroutine LFACTR(A, NROW, IX1, IX2, IP)
  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)

  complex*16 A, D, AJR
  integer R, R1, R2, PJ, PR
  logical L1, L2, L3
  common /MATPAR/ ICASE,NBLOKS,NPBLK,NLAST,NBLSYM,NPSYM,NLSYM,IMAT,ICASX, &
                  NBBX,NPBX,NLBX,NBBL,NPBL,NLBL
  common /SCRATM/ D(2*MAXSEG)
  dimension A(NROW,1), IP(NROW)

  IFLG = 0

  ! Initialize R1, R2, J1, J2
  L1 = IX1.eq.1 .AND. IX2.eq.2
  L2 = (IX2-1).EQ.IX1
  L3 = IX2.eq.NBLSYM

  if (L1) then
    R1 = 1
    R2 = 2*NPSYM
    J1 = 1
    J2 = -1
  else
    R1 = NPSYM+1
    R2 = 2*NPSYM
    J1 = (IX1-1)*NPSYM+1
    if (L2) then
      J2 = J1+NPSYM-2
    else
      J2 = J1+NPSYM-1
    end if
  end if

  if (L3) R2 = NPSYM+NLSYM

  do R = R1, R2
    ! Step 1
    do K = J1, NROW
      D(K) = A(K,R)
    end do

    ! Steps 2 and 3
    if (L1 .OR. L2) J2 = J2+1

    if (J1 .LE. J2) then
      IXJ = 0
      do J = J1, J2
        IXJ = IXJ+1
        PJ = IP(J)
        AJR = D(PJ)
        A(J,R) = AJR
        D(PJ) = D(J)
        JP1 = J+1
        do I = JP1, NROW
          D(I) = D(I) - A(I,IXJ)*AJR
        end do
      end do
    end if

    ! Step 4
    J2P1 = J2+1

    if (L1 .OR. L2) then
      ! Pivot selection
      DMAX = DREAL(D(J2P1)*DCONJG(D(J2P1)))
      IP(J2P1) = J2P1
      J2P2 = J2+2

      if (J2P2 .LE. NROW) then
        do I = J2P2, NROW
          ELMAG = DREAL(D(I)*DCONJG(D(I)))
          if (ELMAG .GE. DMAX) then
            DMAX = ELMAG
            IP(J2P1) = I
          end if
        end do
      end if

      if (DMAX .LT. 1.D-10) IFLG = 1
      PR = IP(J2P1)
      A(J2P1,R) = D(PR)
      D(PR) = D(J2P1)

      ! Step 5
      if (J2P2 .LE. NROW) then
        AJR = 1./A(J2P1,R)
        do I = J2P2, NROW
          A(I,R) = D(I)*AJR
        end do
      end if

      if (IFLG .NE. 0) then
        write(*,17) J2, DMAX
        IFLG = 0
      end if

    else
      ! Non-pivot path
      if (NROW .GE. J2P1) then
        do I = J2P1, NROW
          A(I,R) = D(I)
        end do
      end if
    end if

  end do

  return

17 format (1H ,6HPIVOT(,I3,2H)=,1P,E16.8)
end subroutine LFACTR

!==============================================================================
! PATCH - Patch Geometry Generation
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 3201-3335)
! Tier 2: Eliminate GOTOs, convert to free-form Fortran 90
!
! Purpose: Generates and modifies patch geometry data
!
! Patch Types (NTP):
!   NX=0, NY=1: Arbitrary patch
!   NX=0, NY=2: Rectangular patch
!   NX=0, NY=3: Triangular patch
!   NX=0, NY=4: Quadrilateral patch
!   NX>0, NY>0: NX×NY rectangular surface
!
! GOTOs eliminated: 15 (labels 1-9)
!   - Converted patch type selection to structured IF/THEN/ELSE
!   - Eliminated singularity handling jumps
!   - Replaced labeled DO loops with modern DO...END DO
!==============================================================================
subroutine PATCH (NX,NY,X1,Y1,Z1,X2,Y2,Z2,X3,Y3,Z3,X4,Y4,Z4)
!
! DOUBLE PRECISION 6/4/85
!
  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)
!
! PATCH GENERATES AND MODIFIES PATCH GEOMETRY DATA
  common /data/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
       ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
       ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  common /ANGL/ SALP(MAXSEG)
  dimension T1X(1), T1Y(1), T1Z(1), T2X(1), T2Y(1), T2Z(1)
  equivalence (T1X,SI), (T1Y,ALP), (T1Z,BET), (T2X,ICON1), (T2Y,ICON2), &
       (T2Z,ITAG)

! NEW PATCHES.  FOR NX=0, NY=1,2,3,4 PATCH IS (RESPECTIVELY)
! ARBITRARY, RECTAGULAR, TRIANGULAR, OR QUADRILATERAL.
! FOR NX AND NY .GT. 0 A RECTANGULAR SURFACE IS PRODUCED WITH
! NX BY NY RECTANGULAR PATCHES.

  M=M+1
  MI=LD+1-M
  NTP=NY
  if (NX.gt.0) NTP=2

  if (NTP.le.1) then
    ! Arbitrary patch (NTP=1)
    X(MI)=X1
    Y(MI)=Y1
    Z(MI)=Z1
    BI(MI)=Z2
    ZNV=COS(X2)
    XNV=ZNV*COS(Y2)
    YNV=ZNV*SIN(Y2)
    ZNV=SIN(X2)
    XA=SQRT(XNV*XNV+YNV*YNV)

    if (XA.lt.1.D-6) then
      ! Singularity case - normal nearly vertical
      T1X(MI)=1.
      T1Y(MI)=0.
      T1Z(MI)=0.
    else
      ! Normal case - compute tangent perpendicular to normal
      T1X(MI)=-YNV/XA
      T1Y(MI)=XNV/XA
      T1Z(MI)=0.
    end if

  else
    ! Non-arbitrary patches (NTP=2,3,4)
    S1X=X2-X1
    S1Y=Y2-Y1
    S1Z=Z2-Z1
    S2X=X3-X2
    S2Y=Y3-Y2
    S2Z=Z3-Z2

    if (NX.ne.0) then
      ! For rectangular surface generation, divide sides by NX and NY
      S1X=S1X/NX
      S1Y=S1Y/NX
      S1Z=S1Z/NX
      S2X=S2X/NY
      S2Y=S2Y/NY
      S2Z=S2Z/NY
    end if

    ! Compute normal vector from cross product
    XNV=S1Y*S2Z-S1Z*S2Y
    YNV=S1Z*S2X-S1X*S2Z
    ZNV=S1X*S2Y-S1Y*S2X
    XA=SQRT(XNV*XNV+YNV*YNV+ZNV*ZNV)
    XNV=XNV/XA
    YNV=YNV/XA
    ZNV=ZNV/XA

    ! Compute first tangent vector
    XST=SQRT(S1X*S1X+S1Y*S1Y+S1Z*S1Z)
    T1X(MI)=S1X/XST
    T1Y(MI)=S1Y/XST
    T1Z(MI)=S1Z/XST

    if (NTP.le.2) then
      ! Rectangular patch (NTP=2)
      X(MI)=X1+.5*(S1X+S2X)
      Y(MI)=Y1+.5*(S1Y+S2Y)
      Z(MI)=Z1+.5*(S1Z+S2Z)
      BI(MI)=XA

    else if (NTP.eq.3) then
      ! Triangular patch (NTP=3)
      X(MI)=(X1+X2+X3)/3.
      Y(MI)=(Y1+Y2+Y3)/3.
      Z(MI)=(Z1+Z2+Z3)/3.
      BI(MI)=.5*XA

    else
      ! Quadrilateral patch (NTP=4)
      S1X=X3-X1
      S1Y=Y3-Y1
      S1Z=Z3-Z1
      S2X=X4-X1
      S2Y=Y4-Y1
      S2Z=Z4-Z1
      XN2=S1Y*S2Z-S1Z*S2Y
      YN2=S1Z*S2X-S1X*S2Z
      ZN2=S1X*S2Y-S1Y*S2X
      XST=SQRT(XN2*XN2+YN2*YN2+ZN2*ZN2)
      SALPN=1./(3.*(XA+XST))
      X(MI)=(XA*(X1+X2+X3)+XST*(X1+X3+X4))*SALPN
      Y(MI)=(XA*(Y1+Y2+Y3)+XST*(Y1+Y3+Y4))*SALPN
      Z(MI)=(XA*(Z1+Z2+Z3)+XST*(Z1+Z3+Z4))*SALPN
      BI(MI)=.5*(XA+XST)
      S1X=(XNV*XN2+YNV*YN2+ZNV*ZN2)/XST
      if (S1X.le.0.9998) then
        write(*,14)
        stop
      end if
    end if
  end if

  ! Compute second tangent vector (common to all patch types)
  T2X(MI)=YNV*T1Z(MI)-ZNV*T1Y(MI)
  T2Y(MI)=ZNV*T1X(MI)-XNV*T1Z(MI)
  T2Z(MI)=XNV*T1Y(MI)-YNV*T1X(MI)
  SALP(MI)=1.

  ! Generate NX×NY rectangular surface if NX>0
  if (NX.gt.0) then
    M=M+NX*NY-1
    XN2=X(MI)-S1X-S2X
    YN2=Y(MI)-S1Y-S2Y
    ZN2=Z(MI)-S1Z-S2Z
    XS=T1X(MI)
    YS=T1Y(MI)
    ZS=T1Z(MI)
    XT=T2X(MI)
    YT=T2Y(MI)
    ZT=T2Z(MI)
    MI=MI+1

    do IY=1,NY
      XN2=XN2+S2X
      YN2=YN2+S2Y
      ZN2=ZN2+S2Z
      do IX=1,NX
        XST=IX
        MI=MI-1
        X(MI)=XN2+XST*S1X
        Y(MI)=YN2+XST*S1Y
        Z(MI)=ZN2+XST*S1Z
        BI(MI)=XA
        SALP(MI)=1.
        T1X(MI)=XS
        T1Y(MI)=YS
        T1Z(MI)=ZS
        T2X(MI)=XT
        T2Y(MI)=YT
        T2Z(MI)=ZT
      end do
    end do
  end if

  IPSYM=0
  NP=N
  MP=M
  return

14 format ('ERROR -- CORNERS OF QUADRILATERAL PATCH DO NOT LIE IN A PLANE')

end subroutine PATCH

!==============================================================================
! SUBPH - Sub-Patch Handler
!==============================================================================
! Modernized from nec2dxs.f (ENTRY point in PATCH, lines 7517-7576)
! Purpose: Subdivides a patch or creates sub-patches
!==============================================================================
subroutine SUBPH (NX,NY,X1,Y1,Z1,X2,Y2,Z2,X3,Y3,Z3,X4,Y4,Z4)
  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)

  common /data/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
       ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
       ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  common /ANGL/ SALP(MAXSEG)
  dimension T1X(1), T1Y(1), T1Z(1), T2X(1), T2Y(1), T2Z(1)
  equivalence (T1X,SI), (T1Y,ALP), (T1Z,BET), (T2X,ICON1), (T2Y,ICON2), &
       (T2Z,ITAG)

  ! Shift patches if needed (formerly GO TO 10)
  if (NY.le.0 .AND. NX.ne.M) then
    NXP=NX+1
    IX=LD-M
    do IY=NXP,M
      IX=IX+1
      NYP=IX-3
      X(NYP)=X(IX)
      Y(NYP)=Y(IX)
      Z(NYP)=Z(IX)
      BI(NYP)=BI(IX)
      SALP(NYP)=SALP(IX)
      T1X(NYP)=T1X(IX)
      T1Y(NYP)=T1Y(IX)
      T1Z(NYP)=T1Z(IX)
      T2X(NYP)=T2X(IX)
      T2Y(NYP)=T2Y(IX)
      T2Z(NYP)=T2Z(IX)
    end do
  end if

  ! Label 10: Setup for subdividing patch
  MI=LD+1-NX
  XS=X(MI)
  YS=Y(MI)
  ZS=Z(MI)
  XA=BI(MI)*.25
  XST=SQRT(XA)*.5
  S1X=T1X(MI)
  S1Y=T1Y(MI)
  S1Z=T1Z(MI)
  S2X=T2X(MI)
  S2Y=T2Y(MI)
  S2Z=T2Z(MI)
  SALN=SALP(MI)
  XT=XST
  YT=XST

  ! Determine starting index (formerly GO TO 11/12)
  if (NY.gt.0) then
    M=M+1
    MP=MP+1
    MIA=LD+1-M
  else
    MIA=MI
  end if

  ! Create 4 sub-patches (formerly DO 13)
  do IX=1,4
    X(MIA)=XS+XT*S1X+YT*S2X
    Y(MIA)=YS+XT*S1Y+YT*S2Y
    Z(MIA)=ZS+XT*S1Z+YT*S2Z
    BI(MIA)=XA
    T1X(MIA)=S1X
    T1Y(MIA)=S1Y
    T1Z(MIA)=S1Z
    T2X(MIA)=S2X
    T2Y(MIA)=S2Y
    T2Z(MIA)=S2Z
    SALP(MIA)=SALN
    if (IX.eq.2) YT=-YT
    if (IX.eq.1.or.IX.eq.3) XT=-XT
    MIA=MIA-1
  end do

  M=M+3
  if (NX.le.MP) MP=MP+3
  if (NY.gt.0) Z(MI)=10000.

  return
end subroutine SUBPH
