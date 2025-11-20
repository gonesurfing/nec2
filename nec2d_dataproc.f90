! =============================================================================
! nec2d_dataproc - Data Processing and Input
! =============================================================================
! Purpose: Geometry data input and field calculations
! Contains: DATAGN, EFLD, ETMNS
! GOTOs eliminated: 92
! =============================================================================
subroutine datagn
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
      implicit real*8(a-h,o-z)
! ***
      character*2 gm,atst
! ***
      common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
     &alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
     &itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
      common /angl/ salp(maxseg)
! ***
      common /plot/ iplp1,iplp2,iplp3,iplp4
! ***
      dimension x2(1), y2(1), z2(1), t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), &
     &t2z(1), atst(13), ifx(2), ify(2), ifz(2), cab(1), sab(1), ipt(4)
      equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), &
     &(t2z,itag), (x2,si), (y2,alp), (z2,bet), (cab,alp), (sab,bet)
! ***
      data atst/'GW','GX','GR','GS','GE','GM','SP','SM','GF','GA','SC', &
     &'GC','GH'/
! ***
      data ifx/1h ,1hx/,ify/1h ,1hy/,ifz/1h ,1hz/
      data ta/0.01745329252d+0/,td/57.29577951d+0/,ipt/1hp,1hr,1ht,1hq/

      ! Initialize variables
      ipsym=0
      nwire=0
      n=0
      np=0
      m=0
      mp=0
      n1=0
      n2=1
      m1=0
      m2=1
      isct=0
      iphd=0

      ! Main geometry reading loop - replaces label 1 and multiple GO TO 1 statements
      do while (.true.)
         ! Read geometry data card and branch to section for operation requested
         call readgm(5,gm,itg,ns,xw1,yw1,zw1,xw2,yw2,zw2,rad)

         ! Check for dimension overflow
         if (n+m > ld) then
            write(*,50)
            stop
         end if

         ! Handle special case: read numerical Green's function tape
         if (gm == atst(9)) then
            ! GF command must be first
            if (n+m /= 0) then
               write(*,52)
               stop
            end if
            call gfil (itg)
            npsav=np
            mpsav=mp
            ipsav=ipsym
            cycle  ! Continue to next iteration
         end if

         ! Print header on first non-GF card
         if (iphd == 0) then
            write(*,40)
            write(*,41)
            iphd=1
         end if

         ! Handle SC (surface continuation) command separately
         if (gm == atst(11)) then
            ! SC command logic
            if (isct /= 0) then
               i1=m+1
               ns=ns+1
               if (itg == 0) then
                  if (ns == 2 .or. ns == 4) then
                     xs1=x4
                     ys1=y4
                     zs1=z4
                     xs2=x3
                     ys2=y3
                     zs2=z3
                     x3=xw1
                     y3=yw1
                     z3=zw1

                     if (ns == 4) then
                        x4=xw2
                        y4=yw2
                        z4=zw2
                     end if

                     xw1=xs1
                     yw1=ys1
                     zw1=zs1
                     xw2=xs2
                     yw2=ys2
                     zw2=zs2

                     if (ns /= 4) then
                        x4=xw1+x3-xw2
                        y4=yw1+y3-yw2
                        z4=zw1+z3-zw2
                     end if

                     write(*,51) i1,ipt(ns),xw1,yw1,zw1,xw2,yw2,zw2
                     write(*,39) x3,y3,z3,x4,y4,z4
                     call patch (itg,ns,xw1,yw1,zw1,xw2,yw2,zw2,x3,y3,z3,x4,y4,z4)
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
         isct=0

         ! Dispatch based on geometry command type using SELECT CASE
         select case (gm)

         case ('GW')  ! 'GW' - Generate segment data for straight wire
            nwire=nwire+1
            i1=n+1
            i2=n+ns
            write(*,43) nwire,xw1,yw1,zw1,xw2,yw2,zw2,rad,ns,i1,i2,itg

            if (rad == 0.0d0) then
               ! Read taper data
               call readgm(5,gm,ix,iy,xs1,ys1,zs1,dummy,dummy,dummy,dummy)

               if (gm /= atst(12)) then  ! Not 'GC'
                  write(*,48)
                  stop
               end if

               write(*,61) xs1,ys1,zs1
               if (ys1 == 0.0d0 .or. zs1 == 0.0d0) then
                  write(*,48)
                  stop
               end if

               rad=ys1
               ys1=(zs1/ys1)**(1.0d0/(ns-1))
               xs1=1.0d0
            else
               xs1=1.0d0
               ys1=1.0d0
            end if

            call wire (xw1,yw1,zw1,xw2,yw2,zw2,rad,xs1,ys1,ns,itg)

         case ('GX')  ! 'GX' - Reflect structure along X, Y, or Z axes
            iy=ns/10
            iz=ns-iy*10
            ix=iy/10
            iy=iy-ix*10
            if (ix /= 0) ix=1
            if (iy /= 0) iy=1
            if (iz /= 0) iz=1
            write(*,44) ifx(ix+1),ify(iy+1),ifz(iz+1),itg
            call reflc (ix,iy,iz,itg,ns)

         case ('GR')  ! 'GR' - Rotate to form cylinder
            write(*,45) ns,itg
            ix=-1
            call reflc (ix,iy,iz,itg,ns)

         case ('GS')  ! 'GS' - Scale structure dimensions by factor XW1
            ! Scale wire segments
            if (n >= n2) then
               do i=n2,n
                  x(i)=x(i)*xw1
                  y(i)=y(i)*xw1
                  z(i)=z(i)*xw1
                  x2(i)=x2(i)*xw1
                  y2(i)=y2(i)*xw1
                  z2(i)=z2(i)*xw1
                  bi(i)=bi(i)*xw1
               end do
            end if

            ! Scale patches
            if (m >= m2) then
               yw1=xw1*xw1
               ix=ld+1-m
               iy=ld-m1
               do i=ix,iy
                  x(i)=x(i)*xw1
                  y(i)=y(i)*xw1
                  z(i)=z(i)*xw1
                  bi(i)=bi(i)*yw1
               end do
            end if

            write(*,46) xw1

         case ('GE')  ! 'GE' - Terminate structure geometry input
            ! Set plot flags if NS=0
            if (ns == 0) then
               iplp1=1
               iplp2=1
            end if

            ix=n1+m1

            ! Process connections
            if (ix /= 0) then
               np=n
               mp=m
               ipsym=0
            end if

            call conect (itg)

            if (ix /= 0) then
               np=npsav
               mp=mpsav
               ipsym=ipsav
            end if

            ! Check dimension limit again
            if (n+m > ld) then
               write(*,50)
               stop
            end if

            ! Print wire segment data
            if (n > 0) then
               write(*,53)
               write(*,54)

               do i=1,n
                  xw1=x2(i)-x(i)
                  yw1=y2(i)-y(i)
                  zw1=z2(i)-z(i)
                  x(i)=(x(i)+x2(i))*0.5d0
                  y(i)=(y(i)+y2(i))*0.5d0
                  z(i)=(z(i)+z2(i))*0.5d0
                  xw2=xw1*xw1+yw1*yw1+zw1*zw1
                  yw2=sqrt(xw2)
                  yw2=(xw2/yw2+yw2)*0.5d0
                  si(i)=yw2
                  cab(i)=xw1/yw2
                  sab(i)=yw1/yw2
                  xw2=zw1/yw2
                  if (xw2 > 1.0d0) xw2=1.0d0
                  if (xw2 < -1.0d0) xw2=-1.0d0
                  salp(i)=xw2
                  xw2=asin(xw2)*td
                  yw2=atgn2(yw1,xw1)*td
                  write(*,55) i,x(i),y(i),z(i),si(i),xw2,yw2,bi(i),icon1(i),i, &
                          &icon2(i),itag(i)

                  ! Write to plot file if enabled
                  if (iplp1 == 1) then
                     write(8,*) x(i),y(i),z(i),si(i),xw2,yw2,bi(i),icon1(i),i,icon2(i)
                  end if

                  ! Check for segment data error
                  if (si(i) <= 1.0d-20 .or. bi(i) <= 0.0d0) then
                     write(*,56)
                     stop
                  end if
               end do
            end if

            ! Print patch data
            if (m > 0) then
               write(*,57)
               j=ld+1
               do i=1,m
                  j=j-1
                  xw1=(t1y(j)*t2z(j)-t1z(j)*t2y(j))*salp(j)
                  yw1=(t1z(j)*t2x(j)-t1x(j)*t2z(j))*salp(j)
                  zw1=(t1x(j)*t2y(j)-t1y(j)*t2x(j))*salp(j)
                  write(*,58) i,x(j),y(j),z(j),xw1,yw1,zw1,bi(j),t1x(j),t1y(j), &
                          &t1z(j),t2x(j),t2y(j),t2z(j)
               end do
            end if

            return  ! Exit subroutine after geometry is complete

         case ('GM')  ! 'GM' - Move structure or reproduce in new positions
            write(*,47) itg,ns,xw1,yw1,zw1,xw2,yw2,zw2,rad
            xw1=xw1*ta
            yw1=yw1*ta
            zw1=zw1*ta
            call move (xw1,yw1,zw1,xw2,yw2,zw2,int(rad+0.5d0),ns,itg)

         case ('SP')  ! 'SP' - Generate single new patch
            i1=m+1
            ns=ns+1

            if (itg /= 0) then
               write(*,60)
               stop
            end if

            write(*,51) i1,ipt(ns),xw1,yw1,zw1,xw2,yw2,zw2
            if (ns == 2 .or. ns == 4) isct=1

            if (ns > 1) then
               ! Read additional corner data
               call readgm(5,gm,ix,iy,x3,y3,z3,x4,y4,z4,dummy)
               if (ns /= 2 .and. itg < 1) then
                  write(*,39) x3,y3,z3,x4,y4,z4
                  if (gm /= atst(11)) then
                     write(*,60)
                     stop
                  end if
                  call patch (itg,ns,xw1,yw1,zw1,xw2,yw2,zw2,x3,y3,z3,x4,y4,z4)
               else
                  x4=xw1+x3-xw2
                  y4=yw1+y3-yw2
                  z4=zw1+z3-zw2
                  write(*,39) x3,y3,z3,x4,y4,z4
                  if (gm /= atst(11)) then
                     write(*,60)
                     stop
                  end if
                  call patch (itg,ns,xw1,yw1,zw1,xw2,yw2,zw2,x3,y3,z3,x4,y4,z4)
               end if
            else
               ! NS = 1 (arbitrary patch)
               xw2=xw2*ta
               yw2=yw2*ta
               call patch (itg,ns,xw1,yw1,zw1,xw2,yw2,zw2,x3,y3,z3,x4,y4,z4)
            end if

         case ('SM')  ! 'SM' - Generate multiple-patch surface
            i1=m+1
            write(*,59) i1,ipt(2),xw1,yw1,zw1,xw2,yw2,zw2,itg,ns

            if (itg < 1 .or. ns < 1) then
               write(*,60)
               stop
            end if

            call readgm(5,gm,ix,iy,x3,y3,z3,x4,y4,z4,dummy)

            if (ns /= 2 .and. itg < 1) then
               write(*,39) x3,y3,z3,x4,y4,z4
            else
               x4=xw1+x3-xw2
               y4=yw1+y3-yw2
               z4=zw1+z3-zw2
               write(*,39) x3,y3,z3,x4,y4,z4
            end if

            if (gm /= atst(11)) then
               write(*,60)
               stop
            end if
            call patch (itg,ns,xw1,yw1,zw1,xw2,yw2,zw2,x3,y3,z3,x4,y4,z4)

         case ('GA')  ! 'GA' - Generate segment data for wire arc
            nwire=nwire+1
            i1=n+1
            i2=n+ns
            write(*,38) nwire,xw1,yw1,zw1,xw2,ns,i1,i2,itg
            call arc (itg,ns,xw1,yw1,zw1,xw2)

         case ('GH')  ! 'GH' - Generate helix
            nwire=nwire+1
            i1=n+1
            i2=n+ns
            write(*,124) xw1,yw1,nwire,zw1,xw2,yw2,zw2,rad,ns,i1,i2,itg
            call helix(xw1,yw1,zw1,xw2,yw2,zw2,rad,ns,itg)

         case default
            ! Unknown geometry command
            write(*,48)
            write(*,49) gm,itg,ns,xw1,yw1,zw1,xw2,yw2,zw2,rad
            stop

         end select

      end do  ! End of main geometry reading loop

! Format statements
38    format (1x,i5,2x,'ARC RADIUS =',f9.5,2x,'FROM',f8.3,' TO',f8.3,' DEGREES',11x,f11.5,2x,i5,4x,i5,1x,i5,3x,i5)
39    format (6x,3f11.5,1x,3f11.5)
40    format (////,33x,'- - - STRUCTURE SPECIFICATION - - -',//,37x, &
         'COORDINATES MUST BE INPUT IN',/,37x,'METERS OR BE SCALED TO METERS',/,37x, &
         'BEFORE STRUCTURE INPUT IS ENDED',//)
41    format (2x,'WIRE',79x,'NO. OF',4x,'FIRST',2x,'LAST',5x,'TAG',/,2x,'NO.',8x, &
         'X1',9x,'Y1',9x,'Z1',10x,'X2',9x,'Y2',9x,'Z2',6x,'RADIUS',3x,'SEG.', &
         5x,'SEG.',3x,'SEG.',5x,'NO.')
42    format (a2,i3,i5,7f10.5)
43    format (1x,i5,3f11.5,1x,4f11.5,2x,i5,4x,i5,1x,i5,3x,i5)
44    format (6x,'STRUCTURE REFLECTED ALONG THE AXES',3(1x,a1),'.  TAGS INCREMENTED BY',i5)
45    format (6x,'STRUCTURE ROTATED ABOUT Z-AXIS',i3,' TIMES.  LABELS INCREMENTED BY',i5)
46    format (6x,'STRUCTURE SCALED BY FACTOR',f10.5)
47    format (6x,'THE STRUCTURE HAS BEEN MOVED, MOVE DATA CARD IS -',/,6x,i3,i5,7f10.5)
48    format ('GEOMETRY DATA CARD ERROR')
49    format (1x,a2,i3,i5,7f10.5)
50    format ('NUMBER OF WIRE SEGMENTS AND SURFACE PATCHES EXCEEDS DIMENSION LIMIT.')
51    format (1x,i5,a1,f10.5,2f11.5,1x,3f11.5)
52    format ('ERROR - GF MUST BE FIRST GEOMETRY DATA CARD')
53    format (////,33x,'- - - - SEGMENTATION DATA - - - -',//,40x,'COORDINATES IN METERS',//, &
         25x,'I+ AND I- INDICATE THE SEGMENTS BEFORE AND AFTER I',//)
54    format (2x,'SEG.',3x,'COORDINATES OF SEG. CENTER',5x,'SEG.',5x,'ORIENTATION ANGLES', &
         4x,'WIRE',4x,'CONNECTION DATA',3x,'TAG',/,2x,'NO.',7x,'X',9x,'Y',9x,'Z',7x, &
         'LENGTH',5x,'ALPHA',5x,'BETA',6x,'RADIUS',4x,'I-',3x,'I',4x,'I+',4x,'NO.')
55    format (1x,i5,4f10.5,1x,3f10.5,1x,3i5,2x,i5)
56    format ('SEGMENT DATA ERROR')
57    format (////,44x,'- - - SURFACE PATCH DATA - - -',//,49x,'COORDINATES IN METERS',//, &
         1x,'PATCH',5x,'COORD. OF PATCH CENTER',7x,'UNIT NORMAL VECTOR',6x,'PATCH',12x, &
         'COMPONENTS OF UNIT TANGENT VECTORS',/,2x,'NO.',6x,'X',9x,'Y',9x,'Z',9x,'X', &
         7x,'Y',7x,'Z',7x,'AREA',7x,'X1',6x,'Y1',6x,'Z1',7x,'X2',6x,'Y2',6x,'Z2')
58    format (1x,i4,3f10.5,1x,3f8.4,f10.5,1x,3f8.4,1x,3f8.4)
59    format (1x,i5,a1,f10.5,2f11.5,1x,3f11.5,5x,'SURFACE -',i4,' BY',i3,' PATCHES')
60    format ('PATCH DATA ERROR')
61    format (9x,'ABOVE WIRE IS TAPERED.  SEG. LENGTH RATIO =',f9.5,/, &
         33x,'RADIUS FROM',f9.5,' TO',f9.5)
124   format(5x,'HELIX STRUCTURE-   AXIAL SPACING BETWEEN TURNS =',f8.3, &
         ' TOTAL AXIAL LENGTH =',f8.3,/,1x,i5,2x,'RADIUS OF HELIX =',4(2x,f8.3),7x, &
         f11.5,i8,4x,i5,1x,i5,3x,i5)

end subroutine datagn

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

subroutine efld (xi,yi,zi,ai,ij)
  implicit real*8(a-h,o-z)

  complex*16 txk,tyk,tzk,txs,tys,tzs,txc,tyc,tzc,exk,eyk,ezk,exs,eys
  complex*16 ezs,exc,eyc,ezc,epx,epy,zrati,refs,refps,zrsin,zratx,t1,zscrn
  complex*16 zrati2,tezs,ters,tezc,terc,tezk,terk,egnd,frati

  common /dataj/ s,b,xj,yj,zj,cabj,sabj,salpj,exk,eyk,ezk,exs,eys, &
                 ezs,exc,eyc,ezc,rkh,ind1,indd1,ind2,indd2,iexk,ipgnd
  common /gnd/zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl, &
              ksymp,ifar,iperf
  common /incom/ xo,yo,zo,sn,xsn,ysn,isnor

  dimension egnd(9)

  equivalence (egnd(1),txk), (egnd(2),tyk), (egnd(3),tzk), (egnd(4), &
               txs), (egnd(5),tys), (egnd(6),tzs), (egnd(7),txc), (egnd(8),tyc), &
               (egnd(9),tzc)

  data eta/376.73/,pi/3.141592654d+0/,tp/6.283185308d+0/

  ! Initialize position vectors
  xij = xi - xj
  yij = yi - yj
  ijx = ij
  rfl = -1.0d0

  !---------------------------------------------------------------------------
  ! Main loop over symmetry planes (KSYMP=1 or 2)
  ! Eliminated: DO 12 with GOTO 12 (label-based loop)
  ! Replaced with: DO...END DO
  !---------------------------------------------------------------------------
  do ip = 1, ksymp

    ! Handle symmetry plane
    if (ip == 2) then
      ijx = 1
    end if
    rfl = -rfl
    salpr = salpj * rfl
    zij = zi - rfl * zj

    ! Compute projection onto segment and perpendicular distance
    zp = xij*cabj + yij*sabj + zij*salpr
    rhox = xij - cabj*zp
    rhoy = yij - sabj*zp
    rhoz = zij - salpr*zp
    rh = sqrt(rhox*rhox + rhoy*rhoy + rhoz*rhoz + ai*ai)

    !-------------------------------------------------------------------------
    ! Normalize perpendicular direction vectors
    ! Eliminated: GO TO 1, label 1, GO TO 2, label 2
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (rh > 1.0d-10) then
      ! Label 1: Normalize direction
      rhox = rhox / rh
      rhoy = rhoy / rh
      rhoz = rhoz / rh
    else
      ! Continue to label 2: Zero direction
      rhox = 0.0d0
      rhoy = 0.0d0
      rhoz = 0.0d0
    end if

    ! Label 2: Compute total distance
    r = sqrt(zp*zp + rh*rh)

    !-------------------------------------------------------------------------
    ! Choose field computation method based on distance
    ! Eliminated: GO TO 3, GO TO 6
    ! Replaced with: IF...THEN...ELSE...END IF blocks
    !-------------------------------------------------------------------------
    if (r >= rkh) then
      !-----------------------------------------------------------------------
      ! Lumped current element approximation for large separations
      ! (Skip to label 6)
      !-----------------------------------------------------------------------
      rmag = tp * r
      cth = zp / r
      px = rh / r
      txk = dcmplx(cos(rmag), -sin(rmag))
      py = tp * r * r
      tyk = eta*cth*txk*dcmplx(1.0d0, -1.0d0/rmag) / py
      tzk = eta*px*txk*dcmplx(1.0d0, rmag-1.0d0/rmag) / (2.0d0*py)
      tezk = tyk*cth - tzk*px
      terk = tyk*px + tzk*cth
      rmag = sin(pi*s) / pi
      tezc = tezk * rmag
      terc = terk * rmag
      tezk = tezk * s
      terk = terk * s
      txs = (0.0d0, 0.0d0)
      tys = (0.0d0, 0.0d0)
      tzs = (0.0d0, 0.0d0)

    else
      !-----------------------------------------------------------------------
      ! Label 3: Use extended kernel for close separation
      ! Eliminated: GO TO 4, label 4, GO TO 5
      ! Replaced with: IF...THEN...ELSE...END IF
      !-----------------------------------------------------------------------
      if (iexk == 1) then
        ! Label 4: Extended thin wire approximation
        call ekscx (b,s,zp,rh,tp,ijx,ind1,ind2,tezs,ters,tezc,terc,tezk,terk)
      else
        ! Thin wire approximation
        call eksc (s,zp,rh,tp,ijx,tezs,ters,tezc,terc,tezk,terk)
      end if

      ! Label 5: Transform from cylindrical to Cartesian coordinates
      txs = tezs*cabj + ters*rhox
      tys = tezs*sabj + ters*rhoy
      tzs = tezs*salpr + ters*rhoz
    end if

    ! Label 6: Transform K and C components to Cartesian coordinates
    txk = tezk*cabj + terk*rhox
    tyk = tezk*sabj + terk*rhoy
    tzk = tezk*salpr + terk*rhoz
    txc = tezc*cabj + terc*rhox
    tyc = tezc*sabj + terc*rhoy
    tzc = tezc*salpr + terc*rhoz

    !-------------------------------------------------------------------------
    ! Handle ground reflection (second pass IP=2)
    ! Eliminated: GO TO 11, label 11, GO TO 12
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (ip /= 2) then
      ! Label 11: First pass - initialize field components
      exk = txk
      eyk = tyk
      ezk = tzk
      exs = txs
      eys = tys
      ezs = tzs
      exc = txc
      eyc = tyc
      ezc = tzc

    else
      ! Second pass - handle ground effects
      !-----------------------------------------------------------------------
      ! Ground effect calculations
      ! Eliminated: GO TO 10, label 10
      ! Replaced with: IF...THEN...ELSE...END IF
      !-----------------------------------------------------------------------
      if (iperf <= 0) then
        ! Compute ground reflection coefficients
        zratx = zrati
        rmag = r
        xymag = sqrt(xij*xij + yij*yij)

        !---------------------------------------------------------------------
        ! Set parameters for radial wire ground screen
        ! Eliminated: GO TO 7, label 7 (two paths)
        ! Replaced with: IF...THEN...END IF
        !---------------------------------------------------------------------
        if (nradl /= 0) then
          xspec = (xi*zj + zi*xj) / (zi + zj)
          yspec = (yi*zj + zi*yj) / (zi + zj)
          rhospc = sqrt(xspec*xspec + yspec*yspec + t2*t2)

          if (rhospc <= scrwl) then
            zscrn = t1 * rhospc * log(rhospc/t2)
            zratx = (zscrn*zrati) / (eta*zrati + zscrn)
          end if
        end if

        ! Label 7: Calculation of reflection coefficients
        !-------------------------------------------------------------------
        ! Eliminated: GO TO 8, label 8, GO TO 9
        ! Replaced with: IF...THEN...ELSE...END IF
        !-------------------------------------------------------------------
        if (xymag > 1.0d-6) then
          ! Label 8: Non-vertical incidence
          px = -yij / xymag
          py = xij / xymag
          cth = zij / rmag
          zrsin = sqrt(1.0d0 - zratx*zratx*(1.0d0 - cth*cth))
        else
          ! Vertical incidence
          px = 0.0d0
          py = 0.0d0
          cth = 1.0d0
          zrsin = (1.0d0, 0.0d0)
        end if

        ! Label 9: Compute reflection coefficients
        refs = (cth - zratx*zrsin) / (cth + zratx*zrsin)
        refps = -(zratx*cth - zrsin) / (zratx*cth + zrsin)
        refps = refps - refs

        ! Apply reflection coefficients to K components
        epy = px*txk + py*tyk
        epx = px*epy
        epy = py*epy
        txk = refs*txk + refps*epx
        tyk = refs*tyk + refps*epy
        tzk = refs*tzk

        ! Apply reflection coefficients to S components
        epy = px*txs + py*tys
        epx = px*epy
        epy = py*epy
        txs = refs*txs + refps*epx
        tys = refs*tys + refps*epy
        tzs = refs*tzs

        ! Apply reflection coefficients to C components
        epy = px*txc + py*tyc
        epx = px*epy
        epy = py*epy
        txc = refs*txc + refps*epx
        tyc = refs*tyc + refps*epy
        tzc = refs*tzc
      end if

      ! Label 10: Subtract reflected field components
      exk = exk - txk*frati
      eyk = eyk - tyk*frati
      ezk = ezk - tzk*frati
      exs = exs - txs*frati
      eys = eys - tys*frati
      ezs = ezs - tzs*frati
      exc = exc - txc*frati
      eyc = eyc - tyc*frati
      ezc = ezc - tzc*frati
    end if

  end do  ! Label 12: End of main symmetry loop

  !---------------------------------------------------------------------------
  ! Optional Sommerfeld/Norton ground field computation
  ! Eliminated: GO TO 13, label 13
  ! Replaced with: IF...THEN...END IF
  !---------------------------------------------------------------------------
  if (iperf == 2) then
    ! Label 13: Field due to ground using Sommerfeld/Norton

    sn = sqrt(cabj*cabj + sabj*sabj)

    !-------------------------------------------------------------------------
    ! Normalize segment direction in xy-plane
    ! Eliminated: GO TO 14, label 14, GO TO 15
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (sn >= 1.0d-5) then
      xsn = cabj / sn
      ysn = sabj / sn
    else
      ! Label 14: Segment is vertical
      sn = 0.0d0
      xsn = 1.0d0
      ysn = 0.0d0
    end if

    ! Label 15: Displace observation point for thin wire approximation
    zij = zi + zj
    salpr = -salpj
    rhox = sabj*zij - salpr*yij
    rhoy = salpr*xij - cabj*zij
    rhoz = cabj*yij - sabj*xij
    rh = rhox*rhox + rhoy*rhoy + rhoz*rhoz

    !-------------------------------------------------------------------------
    ! Compute displaced observation point
    ! Eliminated: GO TO 16, label 16, GO TO 17
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (rh > 1.0d-10) then
      ! Label 16: Non-zero displacement
      rh = ai / sqrt(rh)
      if (rhoz < 0.0d0) rh = -rh
      xo = xi + rh*rhox
      yo = yi + rh*rhoy
      zo = zi + rh*rhoz
    else
      ! Zero displacement case
      xo = xi - ai*ysn
      yo = yi + ai*xsn
      zo = zi
    end if

    ! Label 17: Determine integration method
    r = xij*xij + yij*yij + zij*zij

    !-------------------------------------------------------------------------
    ! Choose between integration and direct field computation
    ! Eliminated: GO TO 18, GO TO 19, GO TO 22
    ! Replaced with: IF...THEN...ELSE...END IF
    !-------------------------------------------------------------------------
    if (r > 0.95d0) then
      ! Label 18: Norton field equations and lumped current element
      isnor = 2
      call sflds (0.0d0, egnd)
      ! Skip to label 22

    else
      ! Field from interpolation is integrated over segment
      isnor = 1
      dmin = exk*dconjg(exk) + eyk*dconjg(eyk) + ezk*dconjg(ezk)
      dmin = 0.01d0 * sqrt(dmin)
      shaf = 0.5d0 * s
      call rom2 (-shaf, shaf, egnd, dmin)

      ! Label 19: Additional field adjustments
      zp = xij*cabj + yij*sabj + zij*salpr
      rh = r - zp*zp

      !-----------------------------------------------------------------------
      ! Compute direction adjustment factor
      ! Eliminated: GO TO 20, label 20, GO TO 21, label 21, GO TO 22
      ! Replaced with: IF...THEN...ELSE...END IF
      !-----------------------------------------------------------------------
      if (rh > 1.0d-10) then
        ! Label 20: Non-zero perpendicular distance
        dmin = sqrt(rh / (rh + ai*ai))
      else
        ! Zero perpendicular distance
        dmin = 0.0d0
      end if

      ! Label 21: Apply directional weighting if needed
      if (dmin <= 0.95d0) then
        px = 1.0d0 - dmin

        ! Adjust K components
        terk = (txk*cabj + tyk*sabj + tzk*salpr) * px
        txk = dmin*txk + terk*cabj
        tyk = dmin*tyk + terk*sabj
        tzk = dmin*tzk + terk*salpr

        ! Adjust S components
        ters = (txs*cabj + tys*sabj + tzs*salpr) * px
        txs = dmin*txs + ters*cabj
        tys = dmin*tys + ters*sabj
        tzs = dmin*tzs + ters*salpr

        ! Adjust C components
        terc = (txc*cabj + tyc*sabj + tzc*salpr) * px
        txc = dmin*txc + terc*cabj
        tyc = dmin*tyc + terc*sabj
        tzc = dmin*tzc + terc*salpr
      end if
    end if

    ! Label 22: Add ground field contributions
    exk = exk + txk
    eyk = eyk + tyk
    ezk = ezk + tzk
    exs = exs + txs
    eys = eys + tys
    ezs = ezs + tzs
    exc = exc + txc
    eyc = eyc + tyc
    ezc = ezc + tzc
  end if

  return
end subroutine efld

subroutine etmns (p1,p2,p3,p4,p5,p6,ipr,e)
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
  implicit real*8(a-h,o-z)
! ***
!
! ETMNS FILLS THE ARRAY E WITH THE NEGATIVE OF THE ELECTRIC FIELD
! INCIDENT ON THE STRUCTURE.  E IS THE RIGHT HAND SIDE OF THE MATRIX
! EQUATION.
!
  complex*16 e,cx,cy,cz,vsant,er,et,ezh,erh,vqd,vqds,zrati
  complex*16 zrati2,rrv,rrh,t1,tt1,tt2,frati

  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
       alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
       itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /angl/ salp(maxseg)
  common /vsorc/ vqd(nsmax),vsant(nsmax),vqds(nsmax),ivqd(nsmax), &
       isant(nsmax),iqds(nsmax),nvqd,nsant,nqds
  common /gnd/zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl, &
       ksymp,ifar,iperf

  dimension cab(1), sab(1), e(2*maxseg)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1)

  equivalence (cab,alp), (sab,bet)
  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), (t2z,itag)

  data tp/6.283185308d+0/,reta/2.654420938d-3/

  neq = n + 2*m
  nqds = 0

  ! MODERNIZATION: Restructured main branching logic using IF-THEN-ELSE
  ! Original used: IF (IPR.GT.0.AND.IPR.NE.5) GO TO 5
  if (ipr <= 0 .or. ipr == 5) then
    !
    ! APPLIED FIELD OF VOLTAGE SOURCES FOR TRANSMITTING CASE
    ! MODERNIZATION: Eliminated GOTO 3, GOTO 5 using structured IF blocks
    !
    ! Initialize E array to zero
    do i = 1, neq
      e(i) = (0.0d0, 0.0d0)
    end do

    ! Apply voltage source fields if present
    ! MODERNIZATION: Eliminated GOTO 3 by inverting condition
    if (nsant /= 0) then
      do i = 1, nsant
        is = isant(i)
        e(is) = -vsant(i) / (si(is)*wlam)
      end do
    end if

    ! Apply VQD sources if present
    ! MODERNIZATION: Eliminated early RETURN by checking condition
    if (nvqd /= 0) then
      do i = 1, nvqd
        is = ivqd(i)
        call qdsrc (is, vqd(i), e)
      end do
    end if

  else if (ipr > 3) then
    !
    ! INCIDENT FIELD OF AN ELEMENTARY CURRENT SOURCE
    ! MODERNIZATION: Eliminated GOTOs 19-24 using structured control flow
    !
    wz = cos(p4)
    wx = wz * cos(p5)
    wy = wz * sin(p5)
    wz = sin(p4)
    ds = p6 * 59.958d0
    dsh = p6 / (2.0d0 * tp)
    npm = n + m
    is = ld + 1
    i1 = n - 1

    ! MODERNIZATION: Converted labeled DO 24 to DO...END DO with structured IF blocks
    do i = 1, npm
      ii = i

      ! MODERNIZATION: Eliminated GOTO 20 by inverting condition
      if (i > n) then
        is = is - 1
        ii = is
        i1 = i1 + 2
        i2 = i1 + 1
      end if

      ! Label 20: Compute source field contribution
      px = x(ii) - p1
      py = y(ii) - p2
      pz = z(ii) - p3
      rs = px*px + py*py + pz*pz

      ! MODERNIZATION: Eliminated GOTO 24 (CYCLE to skip iteration)
      if (rs >= 1.0d-30) then
        r = sqrt(rs)
        px = px / r
        py = py / r
        pz = pz / r
        cth = px*wx + py*wy + pz*wz
        sth = sqrt(1.0d0 - cth*cth)
        qx = px - wx*cth
        qy = py - wy*cth
        qz = pz - wz*cth
        arg = sqrt(qx*qx + qy*qy + qz*qz)

        ! MODERNIZATION: Eliminated GOTO 21, GOTO 22 using IF-THEN-ELSE
        if (arg < 1.0d-30) then
          ! Label 21: Set default Q direction
          qx = 1.0d0
          qy = 0.0d0
          qz = 0.0d0
        else
          qx = qx / arg
          qy = qy / arg
          qz = qz / arg
        end if

        ! Label 22: Compute field components
        arg = -tp * r
        tt1 = dcmplx(cos(arg), sin(arg))

        ! MODERNIZATION: Eliminated GOTO 23, GOTO 24 using IF-THEN-ELSE
        if (i <= n) then
          ! Wire segment field
          tt2 = dcmplx(1.0d0, -1.0d0/(r*tp)) / rs
          er = ds * tt1 * tt2 * cth
          et = 0.5d0 * ds * tt1 * ((0.0d0,1.0d0)*tp/r + tt2) * sth
          ezh = er*cth - et*sth
          erh = er*sth + et*cth
          cx = ezh*wx + erh*qx
          cy = ezh*wy + erh*qy
          cz = ezh*wz + erh*qz
          e(i) = -(cx*cab(i) + cy*sab(i) + cz*salp(i))
        else
          ! Label 23: Patch field
          px = wy*qz - wz*qy
          py = wz*qx - wx*qz
          pz = wx*qy - wy*qx
          tt2 = dsh * tt1 * dcmplx(1.0d0/r, tp) / r * sth * salp(ii)
          cx = tt2 * px
          cy = tt2 * py
          cz = tt2 * pz
          e(i2) = cx*t1x(ii) + cy*t1y(ii) + cz*t1z(ii)
          e(i1) = cx*t2x(ii) + cy*t2y(ii) + cz*t2z(ii)
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
    cth = cos(p1)
    sth = sin(p1)
    cph = cos(p2)
    sph = sin(p2)
    cet = cos(p3)
    set = sin(p3)
    px = cth*cph*cet - sph*set
    py = cth*sph*cet + cph*set
    pz = -sth*cet
    wx = -sth*cph
    wy = -sth*sph
    wz = -cth
    qx = wy*pz - wz*py
    qy = wz*px - wx*pz
    qz = wx*py - wy*px

    ! MODERNIZATION: Eliminated GOTO 6, GOTO 7 using structured conditionals
    if (ksymp /= 1) then
      ! Compute ground reflection coefficients
      if (iperf /= 1) then
        ! Imperfect ground
        rrv = sqrt(1.0d0 - zrati*zrati*sth*sth)
        rrh = zrati * cth
        rrh = (rrh - rrv) / (rrh + rrv)
        rrv = zrati * rrv
        rrv = -(cth - rrv) / (cth + rrv)
      else
        ! Label 6: Perfect ground
        rrv = -(1.0d0, 0.0d0)
        rrh = -(1.0d0, 0.0d0)
      end if
    end if
    ! Label 7

    ! MODERNIZATION: Eliminated GOTO 13 using IF-THEN-ELSE for polarization type
    if (ipr <= 1) then
      !
      ! LINEARLY POLARIZED INCIDENT PLANE WAVE
      !
      ! MODERNIZATION: Eliminated GOTO 10 by inverting condition
      if (n /= 0) then
        ! Compute incident field on wire segments
        do i = 1, n
          arg = -tp * (wx*x(i) + wy*y(i) + wz*z(i))
          e(i) = -(px*cab(i) + py*sab(i) + pz*salp(i)) * dcmplx(cos(arg), sin(arg))
        end do

        ! Add ground reflection contribution
        ! MODERNIZATION: Eliminated GOTO 10
        if (ksymp /= 1) then
          tt1 = (py*cph - px*sph) * (rrh - rrv)
          cx = rrv*px - tt1*sph
          cy = rrv*py + tt1*cph
          cz = -rrv*pz
          do i = 1, n
            arg = -tp * (wx*x(i) + wy*y(i) - wz*z(i))
            e(i) = e(i) - (cx*cab(i) + cy*sab(i) + cz*salp(i)) * &
                 dcmplx(cos(arg), sin(arg))
          end do
        end if
      end if

      ! Label 10: Process patches if present
      if (m /= 0) then
        ! Compute incident field on patches
        i = ld + 1
        i1 = n - 1
        do is = 1, m
          i = i - 1
          i1 = i1 + 2
          i2 = i1 + 1
          arg = -tp * (wx*x(i) + wy*y(i) + wz*z(i))
          tt1 = dcmplx(cos(arg), sin(arg)) * salp(i) * reta
          e(i2) = (qx*t1x(i) + qy*t1y(i) + qz*t1z(i)) * tt1
          e(i1) = (qx*t2x(i) + qy*t2y(i) + qz*t2z(i)) * tt1
        end do

        ! Add ground reflection contribution for patches
        if (ksymp /= 1) then
          tt1 = (qy*cph - qx*sph) * (rrv - rrh)
          cx = -(rrh*qx - tt1*sph)
          cy = -(rrh*qy + tt1*cph)
          cz = rrh * qz
          i = ld + 1
          i1 = n - 1
          do is = 1, m
            i = i - 1
            i1 = i1 + 2
            i2 = i1 + 1
            arg = -tp * (wx*x(i) + wy*y(i) - wz*z(i))
            tt1 = dcmplx(cos(arg), sin(arg)) * salp(i) * reta
            e(i2) = e(i2) + (cx*t1x(i) + cy*t1y(i) + cz*t1z(i)) * tt1
            e(i1) = e(i1) + (cx*t2x(i) + cy*t2y(i) + cz*t2z(i)) * tt1
          end do
        end if
      end if

    else
      !
      ! Label 13: ELLIPTIC POLARIZATION (IPR = 2 or 3)
      !
      tt1 = -(0.0d0, 1.0d0) * p6
      if (ipr == 3) tt1 = -tt1

      ! MODERNIZATION: Eliminated GOTO 16 by inverting condition
      if (n /= 0) then
        ! Compute incident field on wire segments
        cx = px + tt1*qx
        cy = py + tt1*qy
        cz = pz + tt1*qz
        do i = 1, n
          arg = -tp * (wx*x(i) + wy*y(i) + wz*z(i))
          e(i) = -(cx*cab(i) + cy*sab(i) + cz*salp(i)) * dcmplx(cos(arg), sin(arg))
        end do

        ! Add ground reflection contribution
        ! MODERNIZATION: Eliminated GOTO 16
        if (ksymp /= 1) then
          tt2 = (cy*cph - cx*sph) * (rrh - rrv)
          cx = rrv*cx - tt2*sph
          cy = rrv*cy + tt2*cph
          cz = -rrv*cz
          do i = 1, n
            arg = -tp * (wx*x(i) + wy*y(i) - wz*z(i))
            e(i) = e(i) - (cx*cab(i) + cy*sab(i) + cz*salp(i)) * &
                 dcmplx(cos(arg), sin(arg))
          end do
        end if
      end if

      ! Label 16: Process patches if present
      if (m /= 0) then
        ! Compute incident field on patches
        cx = qx - tt1*px
        cy = qy - tt1*py
        cz = qz - tt1*pz
        i = ld + 1
        i1 = n - 1
        do is = 1, m
          i = i - 1
          i1 = i1 + 2
          i2 = i1 + 1
          arg = -tp * (wx*x(i) + wy*y(i) + wz*z(i))
          tt2 = dcmplx(cos(arg), sin(arg)) * salp(i) * reta
          e(i2) = (cx*t1x(i) + cy*t1y(i) + cz*t1z(i)) * tt2
          e(i1) = (cx*t2x(i) + cy*t2y(i) + cz*t2z(i)) * tt2
        end do

        ! Add ground reflection contribution for patches
        if (ksymp /= 1) then
          tt1 = (cy*cph - cx*sph) * (rrv - rrh)
          cx = -(rrh*cx - tt1*sph)
          cy = -(rrh*cy + tt1*cph)
          cz = rrh * cz
          i = ld + 1
          i1 = n - 1
          do is = 1, m
            i = i - 1
            i1 = i1 + 2
            i2 = i1 + 1
            arg = -tp * (wx*x(i) + wy*y(i) - wz*z(i))
            tt1 = dcmplx(cos(arg), sin(arg)) * salp(i) * reta
            e(i2) = e(i2) + (cx*t1x(i) + cy*t1y(i) + cz*t1z(i)) * tt1
            e(i1) = e(i1) + (cx*t2x(i) + cy*t2y(i) + cz*t2z(i)) * tt1
          end do
        end if
      end if

    end if  ! IPR <= 1 or IPR > 1 (linear vs elliptic polarization)

  end if  ! Main IPR branching

  return
end subroutine etmns
