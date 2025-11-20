! =============================================================================
! nec2d_conect - Connection Handling
! =============================================================================
! Purpose: Wire and patch connection processing
! Contains: CONECT
! =============================================================================
subroutine CONECT (IGND)
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  ! CONNECT SETS UP SEGMENT CONNECTION DATA IN ARRAYS ICON1 AND ICON2
  ! BY SEARCHING FOR SEGMENT ENDS THAT ARE IN CONTACT.
  !
  ! Modernized: Eliminated 67 GOTOs using structured control flow
  !
  implicit real*8(A-H,O-Z)

  ! Parameter from NEC2DPAR.INC
  integer, parameter :: MAXSEG = 3000
  integer, parameter :: JMAX = 50
  integer, parameter :: NSMAX = 50

  ! LOGICAL variables override IMPLICIT typing
  logical :: end1_connected, end2_connected, patch_connected, needs_tracking

  common /data/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
                ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
                ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  common /SEGJ/ AX(JMAX),BX(JMAX),CX(JMAX),JCO(JMAX), &
                JSNO,ISCON(50),NSCON,IPCON(10),NPCON

  dimension X2(1), Y2(1), Z2(1)
  equivalence (X2,SI), (Y2,ALP), (Z2,BET)
  data SMIN/1.D-3/,NPMAX/10/

  NSCON = 0
  NPCON = 0

  ! Section 1: Initialization and symmetry setup (labels 1, 2, 3 eliminated)
  ! GOTO 1, 2, 3 eliminated with structured IF-THEN-ELSE
  if (IGND .NE. 0) then
    write(*,54)
    if (IGND .GT. 0) write(*,55)

    ! Label 1: Adjust for symmetry
    if (IPSYM .EQ. 2) then
      NP = 2*NP
      MP = 2*MP
    end if

    ! Label 2: More symmetry adjustments
    if (IABS(IPSYM) .GT. 2) then
      NP = N
      MP = M
    end if

    if (NP .GT. N) stop
    if (NP .EQ. N .AND. MP .EQ. M) IPSYM = 0
  end if

  ! Label 3: Main processing begins
  ! GOTO 26 eliminated with IF-THEN
  if (N .EQ. 0) then
    ! Skip to label 26 (output section)
    ! (handled at end of routine)
  else
    ! Main segment connection loop (DO 15 eliminated)
    do I = 1, N
      ICONX(I) = 0
      XI1 = X(I)
      YI1 = Y(I)
      ZI1 = Z(I)
      XI2 = X2(I)
      YI2 = Y2(I)
      ZI2 = Z2(I)
      SLEN = SQRT((XI2-XI1)**2 + (YI2-YI1)**2 + (ZI2-ZI1)**2)*SMIN

      ! Determine connection data for end 1 of segment
      ! Labels 4, 5, 9 eliminated with IF-THEN-ELSE
      end1_connected = .FALSE.

      if (IGND .GE. 1) then
        ! Check ground plane connection for end 1
        if (ZI1 .LE. -SLEN) then
          write(*,56) I
          stop
        end if

        if (ZI1 .LE. SLEN) then
          ! Label 4: End 1 touches ground
          ICON1(I) = I
          Z(I) = 0.
          end1_connected = .TRUE.
        end if
      end if

      ! Label 5: Search for segment connections (if not ground connected)
      if (.NOT. end1_connected) then
        IC = I
        ICON1(I) = 0  ! Default: no connection

        ! DO 7 loop: Search for connecting segment
        do J = 2, N
          IC = IC + 1
          if (IC .GT. N) IC = 1

          ! Check connection to end 1 of segment IC (label 6)
          SEP = ABS(XI1-X(IC)) + ABS(YI1-Y(IC)) + ABS(ZI1-Z(IC))
          if (SEP .LE. SLEN) then
            ! GOTO 6 eliminated: Found connection at end 1 of IC
            ICON1(I) = -IC
            exit  ! GOTO 8 eliminated
          end if

          ! Check connection to end 2 of segment IC (label 7)
          SEP = ABS(XI1-X2(IC)) + ABS(YI1-Y2(IC)) + ABS(ZI1-Z2(IC))
          if (SEP .LE. SLEN) then
            ! GOTO 7 eliminated: Found connection at end 2 of IC
            ICON1(I) = IC
            exit  ! GOTO 8 eliminated
          end if
        end do  ! Label 7: CONTINUE eliminated

        ! After DO 7 loop, check special case
        if (I .LT. N2 .AND. ICON1(I) .GT. 10000) then
          ! Keep ICON1(I) as is (GOTO 8 implicit)
        else if (ICON1(I) .EQ. 0) then
          ! No connection found, ICON1(I) already set to 0
        end if
      end if

      ! Label 8: Determine connection data for end 2 of segment
      ! Labels 9, 10, 11, 12 eliminated with IF-THEN-ELSE
      end2_connected = .FALSE.

      if (IGND .GE. 1) then
        ! Label 9: Check ground plane connection for end 2
        if (ZI2 .LE. -SLEN) then
          write(*,56) I
          stop
        end if

        ! Label 10
        if (ZI2 .LE. SLEN) then
          if (ICON1(I) .EQ. I) then
            ! Label 11: Both ends on ground - error
            write(*,57) I
            stop
          end if
          ICON2(I) = I
          Z2(I) = 0.
          end2_connected = .TRUE.
        end if
      end if

      ! Label 12: Search for segment connections (if not ground connected)
      if (.NOT. end2_connected) then
        IC = I
        ICON2(I) = 0  ! Default: no connection

        ! DO 14 loop: Search for connecting segment
        do J = 2, N
          IC = IC + 1
          if (IC .GT. N) IC = 1

          ! Check connection to end 1 of segment IC (label 13)
          SEP = ABS(XI2-X(IC)) + ABS(YI2-Y(IC)) + ABS(ZI2-Z(IC))
          if (SEP .LE. SLEN) then
            ! GOTO 13 eliminated: Found connection at end 1 of IC
            ICON2(I) = IC
            exit  ! GOTO 15 eliminated
          end if

          ! Check connection to end 2 of segment IC (label 14)
          SEP = ABS(XI2-X2(IC)) + ABS(YI2-Y2(IC)) + ABS(ZI2-Z2(IC))
          if (SEP .LE. SLEN) then
            ! GOTO 14 eliminated: Found connection at end 2 of IC
            ICON2(I) = -IC
            exit  ! GOTO 15 eliminated
          end if
        end do  ! Label 14: CONTINUE eliminated

        ! After DO 14 loop, check special case
        if (I .LT. N2 .AND. ICON2(I) .GT. 10000) then
          ! Keep ICON2(I) as is (GOTO 15 implicit)
        else if (ICON2(I) .EQ. 0) then
          ! No connection found, ICON2(I) already set to 0
        end if
      end if

    end do  ! Label 15: End main segment loop

    ! Section 2: Find wire-surface connections for new patches
    ! GOTO 26 eliminated with IF-THEN
    if (M .NE. 0) then
      IX = LD + 1 - M1
      I = M2

      ! Label 16: Loop through new patches
      do while (I .LE. M)
        IX = IX - 1
        XS = X(IX)
        YS = Y(IX)
        ZS = Z(IX)

        patch_connected = .FALSE.

        ! DO 18 loop: Check all segments
        do ISEG = 1, N
          XI1 = X(ISEG)
          YI1 = Y(ISEG)
          ZI1 = Z(ISEG)
          XI2 = X2(ISEG)
          YI2 = Y2(ISEG)
          ZI2 = Z2(ISEG)
          SLEN = (ABS(XI2-XI1) + ABS(YI2-YI1) + ABS(ZI2-ZI1))*SMIN

          ! Check end 1 connection (label 17)
          SEP = ABS(XI1-XS) + ABS(YI1-YS) + ABS(ZI1-ZS)
          if (SEP .LE. SLEN) then
            ! GOTO 17 eliminated: Connection found at end 1
            ICON1(ISEG) = 10000 + I
            IC = 0
            call SUBPH(I, IC, XI1, YI1, ZI1, XI2, YI2, ZI2, XA, YA, ZA, XS, YS, ZS)
            patch_connected = .TRUE.
            exit  ! GOTO 19 eliminated
          end if

          ! Check end 2 connection (label 18)
          SEP = ABS(XI2-XS) + ABS(YI2-YS) + ABS(ZI2-ZS)
          if (SEP .LE. SLEN) then
            ! GOTO 18 eliminated: Connection found at end 2
            ICON2(ISEG) = 10000 + I
            IC = 0
            call SUBPH(I, IC, XI1, YI1, ZI1, XI2, YI2, ZI2, XA, YA, ZA, XS, YS, ZS)
            patch_connected = .TRUE.
            exit  ! GOTO 19 eliminated
          end if
        end do  ! Label 18: CONTINUE eliminated

        ! Label 19: Next patch
        I = I + 1
      end do  ! GOTO 16 eliminated (DO WHILE loop)
    end if

    ! Section 3: Repeat search for new segments connected to NGF patches
    ! Label 20: GOTO 26 eliminated with IF-THEN
    if (M1 .NE. 0 .AND. N2 .LE. N) then
      IX = LD + 1
      I = 1

      ! Label 21: Loop through NGF patches
      do while (I .LE. M1)
        IX = IX - 1
        XS = X(IX)
        YS = Y(IX)
        ZS = Z(IX)

        ! DO 23 loop: Check segments N2 to N
        do ISEG = N2, N
          XI1 = X(ISEG)
          YI1 = Y(ISEG)
          ZI1 = Z(ISEG)
          XI2 = X2(ISEG)
          YI2 = Y2(ISEG)
          ZI2 = Z2(ISEG)
          SLEN = (ABS(XI2-XI1) + ABS(YI2-YI1) + ABS(ZI2-ZI1))*SMIN

          ! Check end 1 connection (label 22)
          SEP = ABS(XI1-XS) + ABS(YI1-YS) + ABS(ZI1-ZS)
          if (SEP .LE. SLEN) then
            ! GOTO 22 eliminated: Connection found at end 1
            ICON1(ISEG) = 10001 + M
            IC = 1
            NPCON = NPCON + 1
            IPCON(NPCON) = I
            call SUBPH(I, IC, XI1, YI1, ZI1, XI2, YI2, ZI2, XA, YA, ZA, XS, YS, ZS)
            exit  ! GOTO 24 eliminated
          end if

          ! Check end 2 connection (label 23)
          SEP = ABS(XI2-XS) + ABS(YI2-YS) + ABS(ZI2-ZS)
          if (SEP .LE. SLEN) then
            ! GOTO 23 eliminated: Connection found at end 2
            ICON2(ISEG) = 10001 + M
            IC = 1
            NPCON = NPCON + 1
            IPCON(NPCON) = I
            call SUBPH(I, IC, XI1, YI1, ZI1, XI2, YI2, ZI2, XA, YA, ZA, XS, YS, ZS)
            exit  ! GOTO 24 eliminated
          end if
        end do  ! Label 23: CONTINUE eliminated

        ! Label 24: Next NGF patch
        I = I + 1
      end do  ! GOTO 21 eliminated (DO WHILE loop)

      ! Label 25: Check NPCON limit
      if (NPCON .GT. NPMAX) then
        write(*,62) NPMAX
        stop
      end if
    end if
  end if  ! End of N .NE. 0 block

  ! Label 26: Output segment and symmetry information
  write(*,58) N, NP, IPSYM
  if (M .GT. 0) write(*,61) M, MP

  ISEG = (N + M)/(NP + MP)

  ! Labels 27, 28, 29, 30 eliminated with structured IF-THEN-ELSE
  if (ISEG .NE. 1) then
    if (IPSYM .LT. 0) then
      ! Label 28: Negative IPSYM (rotational symmetry)
      write(*,59) ISEG
    else if (IPSYM .GT. 0) then
      ! Label 29: Positive IPSYM (plane symmetry)
      IC = ISEG/2
      if (ISEG .EQ. 8) IC = 3
      write(*,60) IC
    else
      ! Label 27: IPSYM = 0 and ISEG != 1 - error
      stop
    end if
  end if

  ! Label 30: Adjust connected segment ends and print junctions
  ! GOTO 48 eliminated with IF-THEN
  if (N .NE. 0) then
    write(*,50)
    ISEG = 0

    ! Main junction processing loop (DO 44)
    do J = 1, N
      IEND = -1
      JEND = -1
      IX = ICON1(J)
      IC = 1
      JCO(1) = -J
      XA = X(J)
      YA = Y(J)
      ZA = Z(J)

      ! Label 31: Process one end of segment J
      ! This is a complex section with a graph traversal algorithm
      ! GOTO 31, 43, 49 eliminated with structured loops and flags
      process_end1: do
        ! Label 31: Check if valid connection to process
        ! GOTO 43 eliminated with EXIT
        if (IX .EQ. 0) exit process_end1
        if (IX .EQ. J) exit process_end1
        if (IX .GT. 10000) exit process_end1

        NSFLG = 0

        ! Label 32: Traverse connected segments (while-loop structure)
        traverse_connections: do
          ! Computed GOTO: IF (IX) 33,49,34 → structured IF-THEN-ELSE
          if (IX .EQ. 0) then
            ! Label 49: Error - segment connection error
            write(*,53) IX
            stop
          else if (IX .LT. 0) then
            ! Label 33: Negative IX (connected at end 1)
            IX = -IX
          else
            ! Label 34: Positive IX (connected at end 2)
            JEND = -JEND
          end if

          ! Label 35: Check for loop completion or continuation
          if (IX .EQ. J) then
            ! GOTO 37: Loop detected, average coordinates
            exit traverse_connections
          end if

          ! GOTO 43 eliminated with EXIT
          if (IX .LT. J) exit process_end1

          IC = IC + 1
          if (IC .GT. JMAX) then
            ! GOTO 49: Too many connections
            write(*,53) IX
            stop
          end if

          JCO(IC) = IX*JEND
          if (IX .GT. N1) NSFLG = 1

          ! Labels 36, 32 eliminated: Get next connection
          if (JEND .EQ. 1) then
            ! Label 36: Connected at end 2, accumulate and get ICON2
            XA = XA + X2(IX)
            YA = YA + Y2(IX)
            ZA = ZA + Z2(IX)
            IX = ICON2(IX)
          else
            ! Connected at end 1, accumulate and get ICON1
            XA = XA + X(IX)
            YA = YA + Y(IX)
            ZA = ZA + Z(IX)
            IX = ICON1(IX)
          end if

          ! GOTO 32: Continue traversal (DO loop handles this)
        end do traverse_connections

        ! Label 37: Average junction coordinates
        SEP = IC
        XA = XA/SEP
        YA = YA/SEP
        ZA = ZA/SEP

        ! DO 39: Update all connected segment endpoints
        do I = 1, IC
          IX = JCO(I)

          ! Labels 38, 39 eliminated with IF-THEN-ELSE
          if (IX .GT. 0) then
            ! Label 38: Update end 2
            X2(IX) = XA
            Y2(IX) = YA
            Z2(IX) = ZA
          else
            ! Update end 1
            IX = -IX
            X(IX) = XA
            Y(IX) = YA
            Z(IX) = ZA
          end if
        end do  ! Label 39: CONTINUE eliminated

        ! Labels 40, 41, 42 eliminated: Track new segment connections
        ! GOTO 42 eliminated with IF-THEN
        if (N1 .NE. 0 .AND. NSFLG .NE. 0) then
          do I = 1, IC
            IX = IABS(JCO(I))

            ! GOTO 41 eliminated with CYCLE
            if (IX .GT. N1) cycle
            if (ICONX(IX) .NE. 0) cycle

            NSCON = NSCON + 1
            if (NSCON .GT. NSMAX) then
              ! Label 40: Error - too many connections
              write(*,62) NSMAX
              stop
            end if

            ISCON(NSCON) = IX
            ICONX(IX) = NSCON
          end do  ! Label 41: CONTINUE eliminated
        end if

        ! Label 42, 43: Check if junction has 3+ segments
        exit process_end1  ! Exit after processing this junction
      end do process_end1

      ! Label 43: Print junction if 3 or more segments
      if (IC .GE. 3) then
        ISEG = ISEG + 1
        write(*,51) ISEG, (JCO(I), I=1, IC)
      end if

      ! Label 43, 44: Process second end if not done
      ! GOTO 44 eliminated with IF-THEN
      if (IEND .EQ. -1) then
        ! Process end 2
        IEND = 1
        JEND = 1
        IX = ICON2(J)
        IC = 1
        JCO(1) = J
        XA = X2(J)
        YA = Y2(J)
        ZA = Z2(J)

        ! Re-enter at label 31 for end 2 processing
        ! Duplicate the process_end1 logic for end 2
        process_end2: do
          if (IX .EQ. 0) exit process_end2
          if (IX .EQ. J) exit process_end2
          if (IX .GT. 10000) exit process_end2

          NSFLG = 0

          traverse_connections2: do
            if (IX .EQ. 0) then
              write(*,53) IX
              stop
            else if (IX .LT. 0) then
              IX = -IX
            else
              JEND = -JEND
            end if

            if (IX .EQ. J) exit traverse_connections2
            if (IX .LT. J) exit process_end2

            IC = IC + 1
            if (IC .GT. JMAX) then
              write(*,53) IX
              stop
            end if

            JCO(IC) = IX*JEND
            if (IX .GT. N1) NSFLG = 1

            if (JEND .EQ. 1) then
              XA = XA + X2(IX)
              YA = YA + Y2(IX)
              ZA = ZA + Z2(IX)
              IX = ICON2(IX)
            else
              XA = XA + X(IX)
              YA = YA + Y(IX)
              ZA = ZA + Z(IX)
              IX = ICON1(IX)
            end if
          end do traverse_connections2

          SEP = IC
          XA = XA/SEP
          YA = YA/SEP
          ZA = ZA/SEP

          do I = 1, IC
            IX = JCO(I)
            if (IX .GT. 0) then
              X2(IX) = XA
              Y2(IX) = YA
              Z2(IX) = ZA
            else
              IX = -IX
              X(IX) = XA
              Y(IX) = YA
              Z(IX) = ZA
            end if
          end do

          if (N1 .NE. 0 .AND. NSFLG .NE. 0) then
            do I = 1, IC
              IX = IABS(JCO(I))
              if (IX .GT. N1) cycle
              if (ICONX(IX) .NE. 0) cycle

              NSCON = NSCON + 1
              if (NSCON .GT. NSMAX) then
                write(*,62) NSMAX
                stop
              end if

              ISCON(NSCON) = IX
              ICONX(IX) = NSCON
            end do
          end if

          exit process_end2
        end do process_end2

        if (IC .GE. 3) then
          ISEG = ISEG + 1
          write(*,51) ISEG, (JCO(I), I=1, IC)
        end if
      end if

    end do  ! Label 44: End main junction loop

    if (ISEG .EQ. 0) write(*,52)

    ! Section 4: Find old segments connecting to new patches
    ! Labels 45, 46, 47 eliminated with structured IF-THEN
    ! GOTO 48 eliminated with IF-THEN
    if (N1 .NE. 0 .AND. M1 .NE. M) then
      do J = 1, N1
        IX = ICON1(J)

        ! Label 45, 46: Check ICON1 connection
        ! GOTO 45, 46, 47 eliminated with nested IF-THEN
        needs_tracking = .FALSE.

        if (IX .GE. 10000) then
          IX = IX - 10000
          if (IX .GT. M1) needs_tracking = .TRUE.
        else
          ! Label 45: Check ICON2
          IX = ICON2(J)
          if (IX .GE. 10000) then
            IX = IX - 10000
            if (IX .GE. M2) needs_tracking = .TRUE.
          end if
        end if

        ! Label 46: Track if needed
        if (needs_tracking .AND. ICONX(J) .EQ. 0) then
          NSCON = NSCON + 1
          ISCON(NSCON) = J
          ICONX(J) = NSCON
        end if

      end do  ! Label 47: CONTINUE eliminated
    end if
  end if  ! Label 48: End of N != 0 block

  return

  ! Format statements (Hollerith converted to quoted strings)
50 format (//,9X,'- MULTIPLE WIRE JUNCTIONS -',/,1X,'JUNCTION',4X, &
           'SEGMENTS  (- FOR END 1, + FOR END 2)')
51 format (1X,I5,5X,20I5,/,(11X,20I5))
52 format (2X,'NONE')
53 format (' CONNECT - SEGMENT CONNECTION ERROR FOR SEGMENT',I5)
54 format (/,3X,'GROUND PLANE SPECIFIED.')
55 format (/,3X,'WHERE WIRE ENDS TOUCH GROUND, CURRENT WILL BE ', &
           'INTERPOLATED TO IMAGE IN GROUND PLANE.',/)
56 format (' GEOMETRY DATA ERROR-- SEGMENT',I5,' EXTENDS BELOW GROUND')
57 format (' GEOMETRY DATA ERROR--SEGMENT',I5,' LIES IN GROUND PLANE.')
58 format (/,3X,'TOTAL SEGMENTS USED=',I5,5X,'NO. SEG. IN ', &
           'A SYMMETRIC CELL=',I5,5X,'SYMMETRY FLAG=',I3)
59 format (' STRUCTURE HAS',I4,' FOLD ROTATIONAL SYMMETRY',/)
60 format (' STRUCTURE HAS',I2,' PLANES OF SYMMETRY',/)
61 format (3X,'TOTAL PATCHES USED=',I5,6X, &
           'NO. PATCHES IN A SYMMETRIC CELL=',I5)
62 format (' ERROR - NO. NEW SEGMENTS CONNECTED TO N.G.F. SEGMENTS ', &
           'OR PATCHES EXCEEDS LIMIT OF',I5)

end subroutine CONECT
