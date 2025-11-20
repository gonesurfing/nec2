! =============================================================================
! nec2d_dataproc - Data Processing and Input
! =============================================================================
! Purpose: Geometry data input and field calculations
! Contains: DATAGN, EFLD, ETMNS
! GOTOs eliminated: 92
! =============================================================================
subroutine DATAGN
! ***
! DOUBLE PRECISION 6/4/85
!
! MODERNIZED VERSION: Converted from fixed-form to free-form Fortran 90
! - Eliminated all 51 GOTOs using structured control flow
! - Converted labeled DO loops to DO...END DO
! - Used SELECT CASE for command dispatching
! - Used logical flags and structured IF/ELSE blocks
! - Maintained IMPLICIT REAL*8 for COMMON block compatibility
! - All COMMON blocks unchanged
!
! DATAGN IS THE MAIN ROUTINE FOR INPUT OF GEOMETRY DATA.
!
! ***
      include 'NEC2D3000.INC'
      implicit real*8(A-H,O-Z)
! ***
      character*2 GM,ATST
! ***
      common /data/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
     &ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
     &ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
      common /ANGL/ SALP(MAXSEG)
! ***
      common /PLOT/ IPLP1,IPLP2,IPLP3,IPLP4
! ***
      dimension X2(1), Y2(1), Z2(1), T1X(1), T1Y(1), T1Z(1), T2X(1), T2Y(1), &
     &T2Z(1), ATST(13), IFX(2), IFY(2), IFZ(2), CAB(1), SAB(1), IPT(4)
      equivalence (T1X,SI), (T1Y,ALP), (T1Z,BET), (T2X,ICON1), (T2Y,ICON2), &
     &(T2Z,ITAG), (X2,SI), (Y2,ALP), (Z2,BET), (CAB,ALP), (SAB,BET)
! ***
      data ATST/'GW','GX','GR','GS','GE','GM','SP','SM','GF','GA','SC', &
     &'GC','GH'/
! ***
      data IFX/1H ,1HX/,IFY/1H ,1HY/,IFZ/1H ,1HZ/
      data TA/0.01745329252D+0/,TD/57.29577951D+0/,IPT/1HP,1HR,1HT,1HQ/

      ! Initialize variables
      IPSYM=0
      NWIRE=0
      N=0
      NP=0
      M=0
      MP=0
      N1=0
      N2=1
      M1=0
      M2=1
      ISCT=0
      IPHD=0

      ! Main geometry reading loop - replaces label 1 and multiple GO TO 1 statements
      do while (.TRUE.)
         ! Read geometry data card and branch to section for operation requested
         call READGM(5,GM,ITG,NS,XW1,YW1,ZW1,XW2,YW2,ZW2,RAD)

         ! Check for dimension overflow
         if (N+M > LD) then
            write(*,50)
            stop
         end if

         ! Handle special case: read numerical Green's function tape
         if (GM == ATST(9)) then
            ! GF command must be first
            if (N+M /= 0) then
               write(*,52)
               stop
            end if
            call GFIL (ITG)
            NPSAV=NP
            MPSAV=MP
            IPSAV=IPSYM
            cycle  ! Continue to next iteration
         end if

         ! Print header on first non-GF card
         if (IPHD == 0) then
            write(*,40)
            write(*,41)
            IPHD=1
         end if

         ! Handle SC (surface continuation) command separately
         if (GM == ATST(11)) then
            ! SC command logic
            if (ISCT /= 0) then
               I1=M+1
               NS=NS+1
               if (ITG == 0) then
                  if (NS == 2 .OR. NS == 4) then
                     XS1=X4
                     YS1=Y4
                     ZS1=Z4
                     XS2=X3
                     YS2=Y3
                     ZS2=Z3
                     X3=XW1
                     Y3=YW1
                     Z3=ZW1

                     if (NS == 4) then
                        X4=XW2
                        Y4=YW2
                        Z4=ZW2
                     end if

                     XW1=XS1
                     YW1=YS1
                     ZW1=ZS1
                     XW2=XS2
                     YW2=YS2
                     ZW2=ZS2

                     if (NS /= 4) then
                        X4=XW1+X3-XW2
                        Y4=YW1+Y3-YW2
                        Z4=ZW1+Z3-ZW2
                     end if

                     write(*,51) I1,IPT(NS),XW1,YW1,ZW1,XW2,YW2,ZW2
                     write(*,39) X3,Y3,Z3,X4,Y4,Z4
                     call PATCH (ITG,NS,XW1,YW1,ZW1,XW2,YW2,ZW2,X3,Y3,Z3,X4,Y4,Z4)
                     cycle  ! Continue to next iteration
                  else
                     write(*,60)
                     stop
                  end if
               else
                  write(*,60)
                  stop
               end if
            else
               write(*,60)
               stop
            end if
         end if

         ! Reset surface continuation flag for other commands
         ISCT=0

         ! Dispatch based on geometry command type using SELECT CASE
         select case (GM)

         case ('GW')  ! 'GW' - Generate segment data for straight wire
            NWIRE=NWIRE+1
            I1=N+1
            I2=N+NS
            write(*,43) NWIRE,XW1,YW1,ZW1,XW2,YW2,ZW2,RAD,NS,I1,I2,ITG

            if (RAD == 0.0D0) then
               ! Read taper data
               call READGM(5,GM,IX,IY,XS1,YS1,ZS1,DUMMY,DUMMY,DUMMY,DUMMY)

               if (GM /= ATST(12)) then  ! Not 'GC'
                  write(*,48)
                  stop
               end if

               write(*,61) XS1,YS1,ZS1
               if (YS1 == 0.0D0 .OR. ZS1 == 0.0D0) then
                  write(*,48)
                  stop
               end if

               RAD=YS1
               YS1=(ZS1/YS1)**(1.0D0/(NS-1))
               XS1=1.0D0
            else
               XS1=1.0D0
               YS1=1.0D0
            end if

            call WIRE (XW1,YW1,ZW1,XW2,YW2,ZW2,RAD,XS1,YS1,NS,ITG)

         case ('GX')  ! 'GX' - Reflect structure along X, Y, or Z axes
            IY=NS/10
            IZ=NS-IY*10
            IX=IY/10
            IY=IY-IX*10
            if (IX /= 0) IX=1
            if (IY /= 0) IY=1
            if (IZ /= 0) IZ=1
            write(*,44) IFX(IX+1),IFY(IY+1),IFZ(IZ+1),ITG
            call REFLC (IX,IY,IZ,ITG,NS)

         case ('GR')  ! 'GR' - Rotate to form cylinder
            write(*,45) NS,ITG
            IX=-1
            call REFLC (IX,IY,IZ,ITG,NS)

         case ('GS')  ! 'GS' - Scale structure dimensions by factor XW1
            ! Scale wire segments
            if (N >= N2) then
               do I=N2,N
                  X(I)=X(I)*XW1
                  Y(I)=Y(I)*XW1
                  Z(I)=Z(I)*XW1
                  X2(I)=X2(I)*XW1
                  Y2(I)=Y2(I)*XW1
                  Z2(I)=Z2(I)*XW1
                  BI(I)=BI(I)*XW1
               end do
            end if

            ! Scale patches
            if (M >= M2) then
               YW1=XW1*XW1
               IX=LD+1-M
               IY=LD-M1
               do I=IX,IY
                  X(I)=X(I)*XW1
                  Y(I)=Y(I)*XW1
                  Z(I)=Z(I)*XW1
                  BI(I)=BI(I)*YW1
               end do
            end if

            write(*,46) XW1

         case ('GE')  ! 'GE' - Terminate structure geometry input
            ! Set plot flags if NS=0
            if (NS == 0) then
               IPLP1=1
               IPLP2=1
            end if

            IX=N1+M1

            ! Process connections
            if (IX /= 0) then
               NP=N
               MP=M
               IPSYM=0
            end if

            call CONECT (ITG)

            if (IX /= 0) then
               NP=NPSAV
               MP=MPSAV
               IPSYM=IPSAV
            end if

            ! Check dimension limit again
            if (N+M > LD) then
               write(*,50)
               stop
            end if

            ! Print wire segment data
            if (N > 0) then
               write(*,53)
               write(*,54)

               do I=1,N
                  XW1=X2(I)-X(I)
                  YW1=Y2(I)-Y(I)
                  ZW1=Z2(I)-Z(I)
                  X(I)=(X(I)+X2(I))*0.5D0
                  Y(I)=(Y(I)+Y2(I))*0.5D0
                  Z(I)=(Z(I)+Z2(I))*0.5D0
                  XW2=XW1*XW1+YW1*YW1+ZW1*ZW1
                  YW2=SQRT(XW2)
                  YW2=(XW2/YW2+YW2)*0.5D0
                  SI(I)=YW2
                  CAB(I)=XW1/YW2
                  SAB(I)=YW1/YW2
                  XW2=ZW1/YW2
                  if (XW2 > 1.0D0) XW2=1.0D0
                  if (XW2 < -1.0D0) XW2=-1.0D0
                  SALP(I)=XW2
                  XW2=ASIN(XW2)*TD
                  YW2=ATGN2(YW1,XW1)*TD
                  write(*,55) I,X(I),Y(I),Z(I),SI(I),XW2,YW2,BI(I),ICON1(I),I, &
                          &ICON2(I),ITAG(I)

                  ! Write to plot file if enabled
                  if (IPLP1 == 1) then
                     write(8,*) X(I),Y(I),Z(I),SI(I),XW2,YW2,BI(I),ICON1(I),I,ICON2(I)
                  end if

                  ! Check for segment data error
                  if (SI(I) <= 1.0D-20 .OR. BI(I) <= 0.0D0) then
                     write(*,56)
                     stop
                  end if
               end do
            end if

            ! Print patch data
            if (M > 0) then
               write(*,57)
               J=LD+1
               do I=1,M
                  J=J-1
                  XW1=(T1Y(J)*T2Z(J)-T1Z(J)*T2Y(J))*SALP(J)
                  YW1=(T1Z(J)*T2X(J)-T1X(J)*T2Z(J))*SALP(J)
                  ZW1=(T1X(J)*T2Y(J)-T1Y(J)*T2X(J))*SALP(J)
                  write(*,58) I,X(J),Y(J),Z(J),XW1,YW1,ZW1,BI(J),T1X(J),T1Y(J), &
                          &T1Z(J),T2X(J),T2Y(J),T2Z(J)
               end do
            end if

            return  ! Exit subroutine after geometry is complete

         case ('GM')  ! 'GM' - Move structure or reproduce in new positions
            write(*,47) ITG,NS,XW1,YW1,ZW1,XW2,YW2,ZW2,RAD
            XW1=XW1*TA
            YW1=YW1*TA
            ZW1=ZW1*TA
            call MOVE (XW1,YW1,ZW1,XW2,YW2,ZW2,INT(RAD+0.5D0),NS,ITG)

         case ('SP')  ! 'SP' - Generate single new patch
            I1=M+1
            NS=NS+1

            if (ITG /= 0) then
               write(*,60)
               stop
            end if

            write(*,51) I1,IPT(NS),XW1,YW1,ZW1,XW2,YW2,ZW2
            if (NS == 2 .OR. NS == 4) ISCT=1

            if (NS > 1) then
               ! Read additional corner data
               call READGM(5,GM,IX,IY,X3,Y3,Z3,X4,Y4,Z4,DUMMY)
               if (NS /= 2 .AND. ITG < 1) then
                  write(*,39) X3,Y3,Z3,X4,Y4,Z4
                  if (GM /= ATST(11)) then
                     write(*,60)
                     stop
                  end if
                  call PATCH (ITG,NS,XW1,YW1,ZW1,XW2,YW2,ZW2,X3,Y3,Z3,X4,Y4,Z4)
               else
                  X4=XW1+X3-XW2
                  Y4=YW1+Y3-YW2
                  Z4=ZW1+Z3-ZW2
                  write(*,39) X3,Y3,Z3,X4,Y4,Z4
                  if (GM /= ATST(11)) then
                     write(*,60)
                     stop
                  end if
                  call PATCH (ITG,NS,XW1,YW1,ZW1,XW2,YW2,ZW2,X3,Y3,Z3,X4,Y4,Z4)
               end if
            else
               ! NS = 1 (arbitrary patch)
               XW2=XW2*TA
               YW2=YW2*TA
               call PATCH (ITG,NS,XW1,YW1,ZW1,XW2,YW2,ZW2,X3,Y3,Z3,X4,Y4,Z4)
            end if

         case ('SM')  ! 'SM' - Generate multiple-patch surface
            I1=M+1
            write(*,59) I1,IPT(2),XW1,YW1,ZW1,XW2,YW2,ZW2,ITG,NS

            if (ITG < 1 .OR. NS < 1) then
               write(*,60)
               stop
            end if

            call READGM(5,GM,IX,IY,X3,Y3,Z3,X4,Y4,Z4,DUMMY)

            if (NS /= 2 .AND. ITG < 1) then
               write(*,39) X3,Y3,Z3,X4,Y4,Z4
            else
               X4=XW1+X3-XW2
               Y4=YW1+Y3-YW2
               Z4=ZW1+Z3-ZW2
               write(*,39) X3,Y3,Z3,X4,Y4,Z4
            end if

            if (GM /= ATST(11)) then
               write(*,60)
               stop
            end if
            call PATCH (ITG,NS,XW1,YW1,ZW1,XW2,YW2,ZW2,X3,Y3,Z3,X4,Y4,Z4)

         case ('GA')  ! 'GA' - Generate segment data for wire arc
            NWIRE=NWIRE+1
            I1=N+1
            I2=N+NS
            write(*,38) NWIRE,XW1,YW1,ZW1,XW2,NS,I1,I2,ITG
            call ARC (ITG,NS,XW1,YW1,ZW1,XW2)

         case ('GH')  ! 'GH' - Generate helix
            NWIRE=NWIRE+1
            I1=N+1
            I2=N+NS
            write(*,124) XW1,YW1,NWIRE,ZW1,XW2,YW2,ZW2,RAD,NS,I1,I2,ITG
            call HELIX(XW1,YW1,ZW1,XW2,YW2,ZW2,RAD,NS,ITG)

         case default
            ! Unknown geometry command
            write(*,48)
            write(*,49) GM,ITG,NS,XW1,YW1,ZW1,XW2,YW2,ZW2,RAD
            stop

         end select

      end do  ! End of main geometry reading loop

! Format statements
38    format (1X,I5,2X,'ARC RADIUS =',F9.5,2X,'FROM',F8.3,' TO',F8.3,' DEGREES',11X,F11.5,2X,I5,4X,I5,1X,I5,3X,I5)
39    format (6X,3F11.5,1X,3F11.5)
40    format (////,33X,'- - - STRUCTURE SPECIFICATION - - -',//,37X, &
         'COORDINATES MUST BE INPUT IN',/,37X,'METERS OR BE SCALED TO METERS',/,37X, &
         'BEFORE STRUCTURE INPUT IS ENDED',//)
41    format (2X,'WIRE',79X,'NO. OF',4X,'FIRST',2X,'LAST',5X,'TAG',/,2X,'NO.',8X, &
         'X1',9X,'Y1',9X,'Z1',10X,'X2',9X,'Y2',9X,'Z2',6X,'RADIUS',3X,'SEG.', &
         5X,'SEG.',3X,'SEG.',5X,'NO.')
42    format (A2,I3,I5,7F10.5)
43    format (1X,I5,3F11.5,1X,4F11.5,2X,I5,4X,I5,1X,I5,3X,I5)
44    format (6X,'STRUCTURE REFLECTED ALONG THE AXES',3(1X,A1),'.  TAGS INCREMENTED BY',I5)
45    format (6X,'STRUCTURE ROTATED ABOUT Z-AXIS',I3,' TIMES.  LABELS INCREMENTED BY',I5)
46    format (6X,'STRUCTURE SCALED BY FACTOR',F10.5)
47    format (6X,'THE STRUCTURE HAS BEEN MOVED, MOVE DATA CARD IS -',/,6X,I3,I5,7F10.5)
48    format ('GEOMETRY DATA CARD ERROR')
49    format (1X,A2,I3,I5,7F10.5)
50    format ('NUMBER OF WIRE SEGMENTS AND SURFACE PATCHES EXCEEDS DIMENSION LIMIT.')
51    format (1X,I5,A1,F10.5,2F11.5,1X,3F11.5)
52    format ('ERROR - GF MUST BE FIRST GEOMETRY DATA CARD')
53    format (////,33X,'- - - - SEGMENTATION DATA - - - -',//,40X,'COORDINATES IN METERS',//, &
         25X,'I+ AND I- INDICATE THE SEGMENTS BEFORE AND AFTER I',//)
54    format (2X,'SEG.',3X,'COORDINATES OF SEG. CENTER',5X,'SEG.',5X,'ORIENTATION ANGLES', &
         4X,'WIRE',4X,'CONNECTION DATA',3X,'TAG',/,2X,'NO.',7X,'X',9X,'Y',9X,'Z',7X, &
         'LENGTH',5X,'ALPHA',5X,'BETA',6X,'RADIUS',4X,'I-',3X,'I',4X,'I+',4X,'NO.')
55    format (1X,I5,4F10.5,1X,3F10.5,1X,3I5,2X,I5)
56    format ('SEGMENT DATA ERROR')
57    format (////,44X,'- - - SURFACE PATCH DATA - - -',//,49X,'COORDINATES IN METERS',//, &
         1X,'PATCH',5X,'COORD. OF PATCH CENTER',7X,'UNIT NORMAL VECTOR',6X,'PATCH',12X, &
         'COMPONENTS OF UNIT TANGENT VECTORS',/,2X,'NO.',6X,'X',9X,'Y',9X,'Z',9X,'X', &
         7X,'Y',7X,'Z',7X,'AREA',7X,'X1',6X,'Y1',6X,'Z1',7X,'X2',6X,'Y2',6X,'Z2')
58    format (1X,I4,3F10.5,1X,3F8.4,F10.5,1X,3F8.4,1X,3F8.4)
59    format (1X,I5,A1,F10.5,2F11.5,1X,3F11.5,5X,'SURFACE -',I4,' BY',I3,' PATCHES')
60    format ('PATCH DATA ERROR')
61    format (9X,'ABOVE WIRE IS TAPERED.  SEG. LENGTH RATIO =',F9.5,/, &
         33X,'RADIUS FROM',F9.5,' TO',F9.5)
124   format(5X,'HELIX STRUCTURE-   AXIAL SPACING BETWEEN TURNS =',F8.3, &
         ' TOTAL AXIAL LENGTH =',F8.3,/,1X,I5,2X,'RADIUS OF HELIX =',4(2X,F8.3),7X, &
         F11.5,I8,4X,I5,1X,I5,3X,I5)

end subroutine DATAGN

!==============================================================================
! EFLD - Electric Field Computation with Ground Effects
!==============================================================================
! Modernized from nec2dxs_integrated.f (lines 2132-2378)
! Converted from fixed-form Fortran 77 to free-form Fortran 90
! All GOTOs eliminated using structured control flow
!
! Modernization Summary:
! - Eliminated 35 GOTO statements
! - Converted labeled DO loops to DO...END DO
! - Converted fixed-form to free-form Fortran 90
! - Replaced arithmetic IF with logical IF
! - Added structured EXIT and logical flags where needed
! - Added comments explaining control flow
!
! Original Purpose:
! Compute near E fields of a segment with sine, cosine, and constant currents.
! Ground effect included.
!==============================================================================

subroutine EFLD (XI,YI,ZI,AI,IJ)
  implicit real*8(A-H,O-Z)

  complex*16 TXK,TYK,TZK,TXS,TYS,TZS,TXC,TYC,TZC,EXK,EYK,EZK,EXS,EYS
  complex*16 EZS,EXC,EYC,EZC,EPX,EPY,ZRATI,REFS,REFPS,ZRSIN,ZRATX,T1,ZSCRN
  complex*16 ZRATI2,TEZS,TERS,TEZC,TERC,TEZK,TERK,EGND,FRATI

  common /DATAJ/ S,B,XJ,YJ,ZJ,CABJ,SABJ,SALPJ,EXK,EYK,EZK,EXS,EYS, &
                 EZS,EXC,EYC,EZC,RKH,IND1,INDD1,IND2,INDD2,IEXK,IPGND
  common /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL, &
              KSYMP,IFAR,IPERF
  common /INCOM/ XO,YO,ZO,SN,XSN,YSN,ISNOR

  dimension EGND(9)

  equivalence (EGND(1),TXK), (EGND(2),TYK), (EGND(3),TZK), (EGND(4), &
               TXS), (EGND(5),TYS), (EGND(6),TZS), (EGND(7),TXC), (EGND(8),TYC), &
               (EGND(9),TZC)

  data ETA/376.73/,PI/3.141592654D+0/,TP/6.283185308D+0/

  ! Initialize position vectors
  XIJ = XI - XJ
  YIJ = YI - YJ
  IJX = IJ
  RFL = -1.0D0

  !---------------------------------------------------------------------------
  ! Main loop over symmetry planes (KSYMP=1 or 2)
  ! Eliminated: DO 12 with GOTO 12 (label-based loop)
  ! Replaced with: DO...END DO
  !---------------------------------------------------------------------------
  do IP = 1, KSYMP

    ! Handle symmetry plane
    if (IP == 2) then
      IJX = 1
    end if
    RFL = -RFL
    SALPR = SALPJ * RFL
    ZIJ = ZI - RFL * ZJ

    ! Compute projection onto segment and perpendicular distance
    ZP = XIJ*CABJ + YIJ*SABJ + ZIJ*SALPR
    RHOX = XIJ - CABJ*ZP
    RHOY = YIJ - SABJ*ZP
    RHOZ = ZIJ - SALPR*ZP
    RH = SQRT(RHOX*RHOX + RHOY*RHOY + RHOZ*RHOZ + AI*AI)

    !-------------------------------------------------------------------------
    ! Normalize perpendicular direction vectors
    ! Eliminated: GO TO 1, label 1, GO TO 2, label 2
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (RH > 1.0D-10) then
      ! Label 1: Normalize direction
      RHOX = RHOX / RH
      RHOY = RHOY / RH
      RHOZ = RHOZ / RH
    else
      ! Continue to label 2: Zero direction
      RHOX = 0.0D0
      RHOY = 0.0D0
      RHOZ = 0.0D0
    end if

    ! Label 2: Compute total distance
    R = SQRT(ZP*ZP + RH*RH)

    !-------------------------------------------------------------------------
    ! Choose field computation method based on distance
    ! Eliminated: GO TO 3, GO TO 6
    ! Replaced with: IF...THEN...ELSE...END IF blocks
    !-------------------------------------------------------------------------
    if (R >= RKH) then
      !-----------------------------------------------------------------------
      ! Lumped current element approximation for large separations
      ! (Skip to label 6)
      !-----------------------------------------------------------------------
      RMAG = TP * R
      CTH = ZP / R
      PX = RH / R
      TXK = DCMPLX(COS(RMAG), -SIN(RMAG))
      PY = TP * R * R
      TYK = ETA*CTH*TXK*DCMPLX(1.0D0, -1.0D0/RMAG) / PY
      TZK = ETA*PX*TXK*DCMPLX(1.0D0, RMAG-1.0D0/RMAG) / (2.0D0*PY)
      TEZK = TYK*CTH - TZK*PX
      TERK = TYK*PX + TZK*CTH
      RMAG = SIN(PI*S) / PI
      TEZC = TEZK * RMAG
      TERC = TERK * RMAG
      TEZK = TEZK * S
      TERK = TERK * S
      TXS = (0.0D0, 0.0D0)
      TYS = (0.0D0, 0.0D0)
      TZS = (0.0D0, 0.0D0)

    else
      !-----------------------------------------------------------------------
      ! Label 3: Use extended kernel for close separation
      ! Eliminated: GO TO 4, label 4, GO TO 5
      ! Replaced with: IF...THEN...ELSE...END IF
      !-----------------------------------------------------------------------
      if (IEXK == 1) then
        ! Label 4: Extended thin wire approximation
        call EKSCX (B,S,ZP,RH,TP,IJX,IND1,IND2,TEZS,TERS,TEZC,TERC,TEZK,TERK)
      else
        ! Thin wire approximation
        call EKSC (S,ZP,RH,TP,IJX,TEZS,TERS,TEZC,TERC,TEZK,TERK)
      end if

      ! Label 5: Transform from cylindrical to Cartesian coordinates
      TXS = TEZS*CABJ + TERS*RHOX
      TYS = TEZS*SABJ + TERS*RHOY
      TZS = TEZS*SALPR + TERS*RHOZ
    end if

    ! Label 6: Transform K and C components to Cartesian coordinates
    TXK = TEZK*CABJ + TERK*RHOX
    TYK = TEZK*SABJ + TERK*RHOY
    TZK = TEZK*SALPR + TERK*RHOZ
    TXC = TEZC*CABJ + TERC*RHOX
    TYC = TEZC*SABJ + TERC*RHOY
    TZC = TEZC*SALPR + TERC*RHOZ

    !-------------------------------------------------------------------------
    ! Handle ground reflection (second pass IP=2)
    ! Eliminated: GO TO 11, label 11, GO TO 12
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (IP /= 2) then
      ! Label 11: First pass - initialize field components
      EXK = TXK
      EYK = TYK
      EZK = TZK
      EXS = TXS
      EYS = TYS
      EZS = TZS
      EXC = TXC
      EYC = TYC
      EZC = TZC

    else
      ! Second pass - handle ground effects
      !-----------------------------------------------------------------------
      ! Ground effect calculations
      ! Eliminated: GO TO 10, label 10
      ! Replaced with: IF...THEN...ELSE...END IF
      !-----------------------------------------------------------------------
      if (IPERF <= 0) then
        ! Compute ground reflection coefficients
        ZRATX = ZRATI
        RMAG = R
        XYMAG = SQRT(XIJ*XIJ + YIJ*YIJ)

        !---------------------------------------------------------------------
        ! Set parameters for radial wire ground screen
        ! Eliminated: GO TO 7, label 7 (two paths)
        ! Replaced with: IF...THEN...END IF
        !---------------------------------------------------------------------
        if (NRADL /= 0) then
          XSPEC = (XI*ZJ + ZI*XJ) / (ZI + ZJ)
          YSPEC = (YI*ZJ + ZI*YJ) / (ZI + ZJ)
          RHOSPC = SQRT(XSPEC*XSPEC + YSPEC*YSPEC + T2*T2)

          if (RHOSPC <= SCRWL) then
            ZSCRN = T1 * RHOSPC * LOG(RHOSPC/T2)
            ZRATX = (ZSCRN*ZRATI) / (ETA*ZRATI + ZSCRN)
          end if
        end if

        ! Label 7: Calculation of reflection coefficients
        !-------------------------------------------------------------------
        ! Eliminated: GO TO 8, label 8, GO TO 9
        ! Replaced with: IF...THEN...ELSE...END IF
        !-------------------------------------------------------------------
        if (XYMAG > 1.0D-6) then
          ! Label 8: Non-vertical incidence
          PX = -YIJ / XYMAG
          PY = XIJ / XYMAG
          CTH = ZIJ / RMAG
          ZRSIN = SQRT(1.0D0 - ZRATX*ZRATX*(1.0D0 - CTH*CTH))
        else
          ! Vertical incidence
          PX = 0.0D0
          PY = 0.0D0
          CTH = 1.0D0
          ZRSIN = (1.0D0, 0.0D0)
        end if

        ! Label 9: Compute reflection coefficients
        REFS = (CTH - ZRATX*ZRSIN) / (CTH + ZRATX*ZRSIN)
        REFPS = -(ZRATX*CTH - ZRSIN) / (ZRATX*CTH + ZRSIN)
        REFPS = REFPS - REFS

        ! Apply reflection coefficients to K components
        EPY = PX*TXK + PY*TYK
        EPX = PX*EPY
        EPY = PY*EPY
        TXK = REFS*TXK + REFPS*EPX
        TYK = REFS*TYK + REFPS*EPY
        TZK = REFS*TZK

        ! Apply reflection coefficients to S components
        EPY = PX*TXS + PY*TYS
        EPX = PX*EPY
        EPY = PY*EPY
        TXS = REFS*TXS + REFPS*EPX
        TYS = REFS*TYS + REFPS*EPY
        TZS = REFS*TZS

        ! Apply reflection coefficients to C components
        EPY = PX*TXC + PY*TYC
        EPX = PX*EPY
        EPY = PY*EPY
        TXC = REFS*TXC + REFPS*EPX
        TYC = REFS*TYC + REFPS*EPY
        TZC = REFS*TZC
      end if

      ! Label 10: Subtract reflected field components
      EXK = EXK - TXK*FRATI
      EYK = EYK - TYK*FRATI
      EZK = EZK - TZK*FRATI
      EXS = EXS - TXS*FRATI
      EYS = EYS - TYS*FRATI
      EZS = EZS - TZS*FRATI
      EXC = EXC - TXC*FRATI
      EYC = EYC - TYC*FRATI
      EZC = EZC - TZC*FRATI
    end if

  end do  ! Label 12: End of main symmetry loop

  !---------------------------------------------------------------------------
  ! Optional Sommerfeld/Norton ground field computation
  ! Eliminated: GO TO 13, label 13
  ! Replaced with: IF...THEN...END IF
  !---------------------------------------------------------------------------
  if (IPERF == 2) then
    ! Label 13: Field due to ground using Sommerfeld/Norton

    SN = SQRT(CABJ*CABJ + SABJ*SABJ)

    !-------------------------------------------------------------------------
    ! Normalize segment direction in xy-plane
    ! Eliminated: GO TO 14, label 14, GO TO 15
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (SN >= 1.0D-5) then
      XSN = CABJ / SN
      YSN = SABJ / SN
    else
      ! Label 14: Segment is vertical
      SN = 0.0D0
      XSN = 1.0D0
      YSN = 0.0D0
    end if

    ! Label 15: Displace observation point for thin wire approximation
    ZIJ = ZI + ZJ
    SALPR = -SALPJ
    RHOX = SABJ*ZIJ - SALPR*YIJ
    RHOY = SALPR*XIJ - CABJ*ZIJ
    RHOZ = CABJ*YIJ - SABJ*XIJ
    RH = RHOX*RHOX + RHOY*RHOY + RHOZ*RHOZ

    !-------------------------------------------------------------------------
    ! Compute displaced observation point
    ! Eliminated: GO TO 16, label 16, GO TO 17
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (RH > 1.0D-10) then
      ! Label 16: Non-zero displacement
      RH = AI / SQRT(RH)
      if (RHOZ < 0.0D0) RH = -RH
      XO = XI + RH*RHOX
      YO = YI + RH*RHOY
      ZO = ZI + RH*RHOZ
    else
      ! Zero displacement case
      XO = XI - AI*YSN
      YO = YI + AI*XSN
      ZO = ZI
    end if

    ! Label 17: Determine integration method
    R = XIJ*XIJ + YIJ*YIJ + ZIJ*ZIJ

    !-------------------------------------------------------------------------
    ! Choose between integration and direct field computation
    ! Eliminated: GO TO 18, GO TO 19, GO TO 22
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (R > 0.95D0) then
      ! Label 18: Norton field equations and lumped current element
      ISNOR = 2
      call SFLDS (0.0D0, EGND)
      ! Skip to label 22

    else
      ! Field from interpolation is integrated over segment
      ISNOR = 1
      DMIN = EXK*DCONJG(EXK) + EYK*DCONJG(EYK) + EZK*DCONJG(EZK)
      DMIN = 0.01D0 * SQRT(DMIN)
      SHAF = 0.5D0 * S
      call ROM2 (-SHAF, SHAF, EGND, DMIN)

      ! Label 19: Additional field adjustments
      ZP = XIJ*CABJ + YIJ*SABJ + ZIJ*SALPR
      RH = R - ZP*ZP

      !-----------------------------------------------------------------------
      ! Compute direction adjustment factor
      ! Eliminated: GO TO 20, label 20, GO TO 21, label 21, GO TO 22
      ! Replaced with: IF...THEN...ELSE...END IF
      !-----------------------------------------------------------------------
      if (RH > 1.0D-10) then
        ! Label 20: Non-zero perpendicular distance
        DMIN = SQRT(RH / (RH + AI*AI))
      else
        ! Zero perpendicular distance
        DMIN = 0.0D0
      end if

      ! Label 21: Apply directional weighting if needed
      if (DMIN <= 0.95D0) then
        PX = 1.0D0 - DMIN

        ! Adjust K components
        TERK = (TXK*CABJ + TYK*SABJ + TZK*SALPR) * PX
        TXK = DMIN*TXK + TERK*CABJ
        TYK = DMIN*TYK + TERK*SABJ
        TZK = DMIN*TZK + TERK*SALPR

        ! Adjust S components
        TERS = (TXS*CABJ + TYS*SABJ + TZS*SALPR) * PX
        TXS = DMIN*TXS + TERS*CABJ
        TYS = DMIN*TYS + TERS*SABJ
        TZS = DMIN*TZS + TERS*SALPR

        ! Adjust C components
        TERC = (TXC*CABJ + TYC*SABJ + TZC*SALPR) * PX
        TXC = DMIN*TXC + TERC*CABJ
        TYC = DMIN*TYC + TERC*SABJ
        TZC = DMIN*TZC + TERC*SALPR
      end if
    end if

    ! Label 22: Add ground field contributions
    EXK = EXK + TXK
    EYK = EYK + TYK
    EZK = EZK + TZK
    EXS = EXS + TXS
    EYS = EYS + TYS
    EZS = EZS + TZS
    EXC = EXC + TXC
    EYC = EYC + TYC
    EZC = EZC + TZC
  end if

  return
end subroutine EFLD

subroutine ETMNS (P1,P2,P3,P4,P5,P6,IPR,E)
! ***
! MODERNIZATION NOTES:
! - Converted from fixed-form to free-form Fortran 90
! - Eliminated 17 GOTO statements using structured control flow
! - Converted labeled DO loops to DO...END DO syntax
! - Restructured nested conditionals for clarity
! - Added descriptive comments for each major section
! - Kept IMPLICIT REAL*8 for COMMON block compatibility
! - Kept COMMON blocks unchanged
! ***
! DOUBLE PRECISION 6/4/85
!
  include 'NEC2D3000.INC'
  implicit real*8(A-H,O-Z)
! ***
!
! ETMNS FILLS THE ARRAY E WITH THE NEGATIVE OF THE ELECTRIC FIELD
! INCIDENT ON THE STRUCTURE.  E IS THE RIGHT HAND SIDE OF THE MATRIX
! EQUATION.
!
  complex*16 E,CX,CY,CZ,VSANT,ER,ET,EZH,ERH,VQD,VQDS,ZRATI
  complex*16 ZRATI2,RRV,RRH,T1,TT1,TT2,FRATI

  common /data/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
       ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
       ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  common /ANGL/ SALP(MAXSEG)
  common /VSORC/ VQD(NSMAX),VSANT(NSMAX),VQDS(NSMAX),IVQD(NSMAX), &
       ISANT(NSMAX),IQDS(NSMAX),NVQD,NSANT,NQDS
  common /GND/ZRATI,ZRATI2,FRATI,T1,T2,CL,CH,SCRWL,SCRWR,NRADL, &
       KSYMP,IFAR,IPERF

  dimension CAB(1), SAB(1), E(2*MAXSEG)
  dimension T1X(1), T1Y(1), T1Z(1), T2X(1), T2Y(1), T2Z(1)

  equivalence (CAB,ALP), (SAB,BET)
  equivalence (T1X,SI), (T1Y,ALP), (T1Z,BET), (T2X,ICON1), (T2Y,ICON2), (T2Z,ITAG)

  data TP/6.283185308D+0/,RETA/2.654420938D-3/

  NEQ = N + 2*M
  NQDS = 0

  ! MODERNIZATION: Restructured main branching logic using IF-THEN-ELSE
  ! Original used: IF (IPR.GT.0.AND.IPR.NE.5) GO TO 5
  if (IPR <= 0 .OR. IPR == 5) then
    !
    ! APPLIED FIELD OF VOLTAGE SOURCES FOR TRANSMITTING CASE
    ! MODERNIZATION: Eliminated GOTO 3, GOTO 5 using structured IF blocks
    !
    ! Initialize E array to zero
    do I = 1, NEQ
      E(I) = (0.0D0, 0.0D0)
    end do

    ! Apply voltage source fields if present
    ! MODERNIZATION: Eliminated GOTO 3 by inverting condition
    if (NSANT /= 0) then
      do I = 1, NSANT
        IS = ISANT(I)
        E(IS) = -VSANT(I) / (SI(IS)*WLAM)
      end do
    end if

    ! Apply VQD sources if present
    ! MODERNIZATION: Eliminated early RETURN by checking condition
    if (NVQD /= 0) then
      do I = 1, NVQD
        IS = IVQD(I)
        call QDSRC (IS, VQD(I), E)
      end do
    end if

  else if (IPR > 3) then
    !
    ! INCIDENT FIELD OF AN ELEMENTARY CURRENT SOURCE
    ! MODERNIZATION: Eliminated GOTOs 19-24 using structured control flow
    !
    WZ = COS(P4)
    WX = WZ * COS(P5)
    WY = WZ * SIN(P5)
    WZ = SIN(P4)
    DS = P6 * 59.958D0
    DSH = P6 / (2.0D0 * TP)
    NPM = N + M
    IS = LD + 1
    I1 = N - 1

    ! MODERNIZATION: Converted labeled DO 24 to DO...END DO with structured IF blocks
    do I = 1, NPM
      II = I

      ! MODERNIZATION: Eliminated GOTO 20 by inverting condition
      if (I > N) then
        IS = IS - 1
        II = IS
        I1 = I1 + 2
        I2 = I1 + 1
      end if

      ! Label 20: Compute source field contribution
      PX = X(II) - P1
      PY = Y(II) - P2
      PZ = Z(II) - P3
      RS = PX*PX + PY*PY + PZ*PZ

      ! MODERNIZATION: Eliminated GOTO 24 (CYCLE to skip iteration)
      if (RS >= 1.0D-30) then
        R = SQRT(RS)
        PX = PX / R
        PY = PY / R
        PZ = PZ / R
        CTH = PX*WX + PY*WY + PZ*WZ
        STH = SQRT(1.0D0 - CTH*CTH)
        QX = PX - WX*CTH
        QY = PY - WY*CTH
        QZ = PZ - WZ*CTH
        ARG = SQRT(QX*QX + QY*QY + QZ*QZ)

        ! MODERNIZATION: Eliminated GOTO 21, GOTO 22 using IF-THEN-ELSE
        if (ARG < 1.0D-30) then
          ! Label 21: Set default Q direction
          QX = 1.0D0
          QY = 0.0D0
          QZ = 0.0D0
        else
          QX = QX / ARG
          QY = QY / ARG
          QZ = QZ / ARG
        end if

        ! Label 22: Compute field components
        ARG = -TP * R
        TT1 = DCMPLX(COS(ARG), SIN(ARG))

        ! MODERNIZATION: Eliminated GOTO 23, GOTO 24 using IF-THEN-ELSE
        if (I <= N) then
          ! Wire segment field
          TT2 = DCMPLX(1.0D0, -1.0D0/(R*TP)) / RS
          ER = DS * TT1 * TT2 * CTH
          ET = 0.5D0 * DS * TT1 * ((0.0D0,1.0D0)*TP/R + TT2) * STH
          EZH = ER*CTH - ET*STH
          ERH = ER*STH + ET*CTH
          CX = EZH*WX + ERH*QX
          CY = EZH*WY + ERH*QY
          CZ = EZH*WZ + ERH*QZ
          E(I) = -(CX*CAB(I) + CY*SAB(I) + CZ*SALP(I))
        else
          ! Label 23: Patch field
          PX = WY*QZ - WZ*QY
          PY = WZ*QX - WX*QZ
          PZ = WX*QY - WY*QX
          TT2 = DSH * TT1 * DCMPLX(1.0D0/R, TP) / R * STH * SALP(II)
          CX = TT2 * PX
          CY = TT2 * PY
          CZ = TT2 * PZ
          E(I2) = CX*T1X(II) + CY*T1Y(II) + CZ*T1Z(II)
          E(I1) = CX*T2X(II) + CY*T2Y(II) + CZ*T2Z(II)
        end if

      end if  ! RS >= 1.0D-30
      ! Label 24 (loop continuation)
    end do

  else
    !
    ! INCIDENT PLANE WAVE (IPR = 1, 2, or 3)
    ! MODERNIZATION: Eliminated GOTOs 5-18 using structured IF-THEN-ELSE
    !
    ! Label 5: Compute wave propagation and polarization vectors
    CTH = COS(P1)
    STH = SIN(P1)
    CPH = COS(P2)
    SPH = SIN(P2)
    CET = COS(P3)
    SET = SIN(P3)
    PX = CTH*CPH*CET - SPH*SET
    PY = CTH*SPH*CET + CPH*SET
    PZ = -STH*CET
    WX = -STH*CPH
    WY = -STH*SPH
    WZ = -CTH
    QX = WY*PZ - WZ*PY
    QY = WZ*PX - WX*PZ
    QZ = WX*PY - WY*PX

    ! MODERNIZATION: Eliminated GOTO 6, GOTO 7 using structured conditionals
    if (KSYMP /= 1) then
      ! Compute ground reflection coefficients
      if (IPERF /= 1) then
        ! Imperfect ground
        RRV = SQRT(1.0D0 - ZRATI*ZRATI*STH*STH)
        RRH = ZRATI * CTH
        RRH = (RRH - RRV) / (RRH + RRV)
        RRV = ZRATI * RRV
        RRV = -(CTH - RRV) / (CTH + RRV)
      else
        ! Label 6: Perfect ground
        RRV = -(1.0D0, 0.0D0)
        RRH = -(1.0D0, 0.0D0)
      end if
    end if
    ! Label 7

    ! MODERNIZATION: Eliminated GOTO 13 using IF-THEN-ELSE for polarization type
    if (IPR <= 1) then
      !
      ! LINEARLY POLARIZED INCIDENT PLANE WAVE
      !
      ! MODERNIZATION: Eliminated GOTO 10 by inverting condition
      if (N /= 0) then
        ! Compute incident field on wire segments
        do I = 1, N
          ARG = -TP * (WX*X(I) + WY*Y(I) + WZ*Z(I))
          E(I) = -(PX*CAB(I) + PY*SAB(I) + PZ*SALP(I)) * DCMPLX(COS(ARG), SIN(ARG))
        end do

        ! Add ground reflection contribution
        ! MODERNIZATION: Eliminated GOTO 10
        if (KSYMP /= 1) then
          TT1 = (PY*CPH - PX*SPH) * (RRH - RRV)
          CX = RRV*PX - TT1*SPH
          CY = RRV*PY + TT1*CPH
          CZ = -RRV*PZ
          do I = 1, N
            ARG = -TP * (WX*X(I) + WY*Y(I) - WZ*Z(I))
            E(I) = E(I) - (CX*CAB(I) + CY*SAB(I) + CZ*SALP(I)) * &
                 DCMPLX(COS(ARG), SIN(ARG))
          end do
        end if
      end if

      ! Label 10: Process patches if present
      if (M /= 0) then
        ! Compute incident field on patches
        I = LD + 1
        I1 = N - 1
        do IS = 1, M
          I = I - 1
          I1 = I1 + 2
          I2 = I1 + 1
          ARG = -TP * (WX*X(I) + WY*Y(I) + WZ*Z(I))
          TT1 = DCMPLX(COS(ARG), SIN(ARG)) * SALP(I) * RETA
          E(I2) = (QX*T1X(I) + QY*T1Y(I) + QZ*T1Z(I)) * TT1
          E(I1) = (QX*T2X(I) + QY*T2Y(I) + QZ*T2Z(I)) * TT1
        end do

        ! Add ground reflection contribution for patches
        if (KSYMP /= 1) then
          TT1 = (QY*CPH - QX*SPH) * (RRV - RRH)
          CX = -(RRH*QX - TT1*SPH)
          CY = -(RRH*QY + TT1*CPH)
          CZ = RRH * QZ
          I = LD + 1
          I1 = N - 1
          do IS = 1, M
            I = I - 1
            I1 = I1 + 2
            I2 = I1 + 1
            ARG = -TP * (WX*X(I) + WY*Y(I) - WZ*Z(I))
            TT1 = DCMPLX(COS(ARG), SIN(ARG)) * SALP(I) * RETA
            E(I2) = E(I2) + (CX*T1X(I) + CY*T1Y(I) + CZ*T1Z(I)) * TT1
            E(I1) = E(I1) + (CX*T2X(I) + CY*T2Y(I) + CZ*T2Z(I)) * TT1
          end do
        end if
      end if

    else
      !
      ! Label 13: ELLIPTIC POLARIZATION (IPR = 2 or 3)
      !
      TT1 = -(0.0D0, 1.0D0) * P6
      if (IPR == 3) TT1 = -TT1

      ! MODERNIZATION: Eliminated GOTO 16 by inverting condition
      if (N /= 0) then
        ! Compute incident field on wire segments
        CX = PX + TT1*QX
        CY = PY + TT1*QY
        CZ = PZ + TT1*QZ
        do I = 1, N
          ARG = -TP * (WX*X(I) + WY*Y(I) + WZ*Z(I))
          E(I) = -(CX*CAB(I) + CY*SAB(I) + CZ*SALP(I)) * DCMPLX(COS(ARG), SIN(ARG))
        end do

        ! Add ground reflection contribution
        ! MODERNIZATION: Eliminated GOTO 16
        if (KSYMP /= 1) then
          TT2 = (CY*CPH - CX*SPH) * (RRH - RRV)
          CX = RRV*CX - TT2*SPH
          CY = RRV*CY + TT2*CPH
          CZ = -RRV*CZ
          do I = 1, N
            ARG = -TP * (WX*X(I) + WY*Y(I) - WZ*Z(I))
            E(I) = E(I) - (CX*CAB(I) + CY*SAB(I) + CZ*SALP(I)) * &
                 DCMPLX(COS(ARG), SIN(ARG))
          end do
        end if
      end if

      ! Label 16: Process patches if present
      if (M /= 0) then
        ! Compute incident field on patches
        CX = QX - TT1*PX
        CY = QY - TT1*PY
        CZ = QZ - TT1*PZ
        I = LD + 1
        I1 = N - 1
        do IS = 1, M
          I = I - 1
          I1 = I1 + 2
          I2 = I1 + 1
          ARG = -TP * (WX*X(I) + WY*Y(I) + WZ*Z(I))
          TT2 = DCMPLX(COS(ARG), SIN(ARG)) * SALP(I) * RETA
          E(I2) = (CX*T1X(I) + CY*T1Y(I) + CZ*T1Z(I)) * TT2
          E(I1) = (CX*T2X(I) + CY*T2Y(I) + CZ*T2Z(I)) * TT2
        end do

        ! Add ground reflection contribution for patches
        if (KSYMP /= 1) then
          TT1 = (CY*CPH - CX*SPH) * (RRV - RRH)
          CX = -(RRH*CX - TT1*SPH)
          CY = -(RRH*CY + TT1*CPH)
          CZ = RRH * CZ
          I = LD + 1
          I1 = N - 1
          do IS = 1, M
            I = I - 1
            I1 = I1 + 2
            I2 = I1 + 1
            ARG = -TP * (WX*X(I) + WY*Y(I) - WZ*Z(I))
            TT1 = DCMPLX(COS(ARG), SIN(ARG)) * SALP(I) * RETA
            E(I2) = E(I2) + (CX*T1X(I) + CY*T1Y(I) + CZ*T1Z(I)) * TT1
            E(I1) = E(I1) + (CX*T2X(I) + CY*T2Y(I) + CZ*T2Z(I)) * TT1
          end do
        end if
      end if

    end if  ! IPR <= 1 or IPR > 1 (linear vs elliptic polarization)

  end if  ! Main IPR branching

  return
end subroutine ETMNS
