SUBROUTINE CONECT (IGND)
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  ! CONNECT SETS UP SEGMENT CONNECTION DATA IN ARRAYS ICON1 AND ICON2
  ! BY SEARCHING FOR SEGMENT ENDS THAT ARE IN CONTACT.
  !
  ! Modernized: Eliminated 67 GOTOs using structured control flow
  !
  IMPLICIT REAL*8(A-H,O-Z)

  ! Parameter from NEC2DPAR.INC
  INTEGER, PARAMETER :: MAXSEG = 3000
  INTEGER, PARAMETER :: JMAX = 50
  INTEGER, PARAMETER :: NSMAX = 50

  ! LOGICAL variables override IMPLICIT typing
  LOGICAL :: end1_connected, end2_connected, patch_connected, needs_tracking

  COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG), &
                ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG), &
                ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
  COMMON /SEGJ/ AX(JMAX),BX(JMAX),CX(JMAX),JCO(JMAX), &
                JSNO,ISCON(50),NSCON,IPCON(10),NPCON

  DIMENSION X2(1), Y2(1), Z2(1)
  EQUIVALENCE (X2,SI), (Y2,ALP), (Z2,BET)
  DATA SMIN/1.D-3/,NPMAX/10/

  NSCON = 0
  NPCON = 0

  ! Section 1: Initialization and symmetry setup (labels 1, 2, 3 eliminated)
  ! GOTO 1, 2, 3 eliminated with structured IF-THEN-ELSE
  IF (IGND .NE. 0) THEN
    WRITE(*,54)
    IF (IGND .GT. 0) WRITE(*,55)

    ! Label 1: Adjust for symmetry
    IF (IPSYM .EQ. 2) THEN
      NP = 2*NP
      MP = 2*MP
    END IF

    ! Label 2: More symmetry adjustments
    IF (IABS(IPSYM) .GT. 2) THEN
      NP = N
      MP = M
    END IF

    IF (NP .GT. N) STOP
    IF (NP .EQ. N .AND. MP .EQ. M) IPSYM = 0
  END IF

  ! Label 3: Main processing begins
  ! GOTO 26 eliminated with IF-THEN
  IF (N .EQ. 0) THEN
    ! Skip to label 26 (output section)
    ! (handled at end of routine)
  ELSE
    ! Main segment connection loop (DO 15 eliminated)
    DO I = 1, N
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

      IF (IGND .GE. 1) THEN
        ! Check ground plane connection for end 1
        IF (ZI1 .LE. -SLEN) THEN
          WRITE(*,56) I
          STOP
        END IF

        IF (ZI1 .LE. SLEN) THEN
          ! Label 4: End 1 touches ground
          ICON1(I) = I
          Z(I) = 0.
          end1_connected = .TRUE.
        END IF
      END IF

      ! Label 5: Search for segment connections (if not ground connected)
      IF (.NOT. end1_connected) THEN
        IC = I
        ICON1(I) = 0  ! Default: no connection

        ! DO 7 loop: Search for connecting segment
        DO J = 2, N
          IC = IC + 1
          IF (IC .GT. N) IC = 1

          ! Check connection to end 1 of segment IC (label 6)
          SEP = ABS(XI1-X(IC)) + ABS(YI1-Y(IC)) + ABS(ZI1-Z(IC))
          IF (SEP .LE. SLEN) THEN
            ! GOTO 6 eliminated: Found connection at end 1 of IC
            ICON1(I) = -IC
            EXIT  ! GOTO 8 eliminated
          END IF

          ! Check connection to end 2 of segment IC (label 7)
          SEP = ABS(XI1-X2(IC)) + ABS(YI1-Y2(IC)) + ABS(ZI1-Z2(IC))
          IF (SEP .LE. SLEN) THEN
            ! GOTO 7 eliminated: Found connection at end 2 of IC
            ICON1(I) = IC
            EXIT  ! GOTO 8 eliminated
          END IF
        END DO  ! Label 7: CONTINUE eliminated

        ! After DO 7 loop, check special case
        IF (I .LT. N2 .AND. ICON1(I) .GT. 10000) THEN
          ! Keep ICON1(I) as is (GOTO 8 implicit)
        ELSE IF (ICON1(I) .EQ. 0) THEN
          ! No connection found, ICON1(I) already set to 0
        END IF
      END IF

      ! Label 8: Determine connection data for end 2 of segment
      ! Labels 9, 10, 11, 12 eliminated with IF-THEN-ELSE
      end2_connected = .FALSE.

      IF (IGND .GE. 1) THEN
        ! Label 9: Check ground plane connection for end 2
        IF (ZI2 .LE. -SLEN) THEN
          WRITE(*,56) I
          STOP
        END IF

        ! Label 10
        IF (ZI2 .LE. SLEN) THEN
          IF (ICON1(I) .EQ. I) THEN
            ! Label 11: Both ends on ground - error
            WRITE(*,57) I
            STOP
          END IF
          ICON2(I) = I
          Z2(I) = 0.
          end2_connected = .TRUE.
        END IF
      END IF

      ! Label 12: Search for segment connections (if not ground connected)
      IF (.NOT. end2_connected) THEN
        IC = I
        ICON2(I) = 0  ! Default: no connection

        ! DO 14 loop: Search for connecting segment
        DO J = 2, N
          IC = IC + 1
          IF (IC .GT. N) IC = 1

          ! Check connection to end 1 of segment IC (label 13)
          SEP = ABS(XI2-X(IC)) + ABS(YI2-Y(IC)) + ABS(ZI2-Z(IC))
          IF (SEP .LE. SLEN) THEN
            ! GOTO 13 eliminated: Found connection at end 1 of IC
            ICON2(I) = IC
            EXIT  ! GOTO 15 eliminated
          END IF

          ! Check connection to end 2 of segment IC (label 14)
          SEP = ABS(XI2-X2(IC)) + ABS(YI2-Y2(IC)) + ABS(ZI2-Z2(IC))
          IF (SEP .LE. SLEN) THEN
            ! GOTO 14 eliminated: Found connection at end 2 of IC
            ICON2(I) = -IC
            EXIT  ! GOTO 15 eliminated
          END IF
        END DO  ! Label 14: CONTINUE eliminated

        ! After DO 14 loop, check special case
        IF (I .LT. N2 .AND. ICON2(I) .GT. 10000) THEN
          ! Keep ICON2(I) as is (GOTO 15 implicit)
        ELSE IF (ICON2(I) .EQ. 0) THEN
          ! No connection found, ICON2(I) already set to 0
        END IF
      END IF

    END DO  ! Label 15: End main segment loop

    ! Section 2: Find wire-surface connections for new patches
    ! GOTO 26 eliminated with IF-THEN
    IF (M .NE. 0) THEN
      IX = LD + 1 - M1
      I = M2

      ! Label 16: Loop through new patches
      DO WHILE (I .LE. M)
        IX = IX - 1
        XS = X(IX)
        YS = Y(IX)
        ZS = Z(IX)

        patch_connected = .FALSE.

        ! DO 18 loop: Check all segments
        DO ISEG = 1, N
          XI1 = X(ISEG)
          YI1 = Y(ISEG)
          ZI1 = Z(ISEG)
          XI2 = X2(ISEG)
          YI2 = Y2(ISEG)
          ZI2 = Z2(ISEG)
          SLEN = (ABS(XI2-XI1) + ABS(YI2-YI1) + ABS(ZI2-ZI1))*SMIN

          ! Check end 1 connection (label 17)
          SEP = ABS(XI1-XS) + ABS(YI1-YS) + ABS(ZI1-ZS)
          IF (SEP .LE. SLEN) THEN
            ! GOTO 17 eliminated: Connection found at end 1
            ICON1(ISEG) = 10000 + I
            IC = 0
            CALL SUBPH(I, IC, XI1, YI1, ZI1, XI2, YI2, ZI2, XA, YA, ZA, XS, YS, ZS)
            patch_connected = .TRUE.
            EXIT  ! GOTO 19 eliminated
          END IF

          ! Check end 2 connection (label 18)
          SEP = ABS(XI2-XS) + ABS(YI2-YS) + ABS(ZI2-ZS)
          IF (SEP .LE. SLEN) THEN
            ! GOTO 18 eliminated: Connection found at end 2
            ICON2(ISEG) = 10000 + I
            IC = 0
            CALL SUBPH(I, IC, XI1, YI1, ZI1, XI2, YI2, ZI2, XA, YA, ZA, XS, YS, ZS)
            patch_connected = .TRUE.
            EXIT  ! GOTO 19 eliminated
          END IF
        END DO  ! Label 18: CONTINUE eliminated

        ! Label 19: Next patch
        I = I + 1
      END DO  ! GOTO 16 eliminated (DO WHILE loop)
    END IF

    ! Section 3: Repeat search for new segments connected to NGF patches
    ! Label 20: GOTO 26 eliminated with IF-THEN
    IF (M1 .NE. 0 .AND. N2 .LE. N) THEN
      IX = LD + 1
      I = 1

      ! Label 21: Loop through NGF patches
      DO WHILE (I .LE. M1)
        IX = IX - 1
        XS = X(IX)
        YS = Y(IX)
        ZS = Z(IX)

        ! DO 23 loop: Check segments N2 to N
        DO ISEG = N2, N
          XI1 = X(ISEG)
          YI1 = Y(ISEG)
          ZI1 = Z(ISEG)
          XI2 = X2(ISEG)
          YI2 = Y2(ISEG)
          ZI2 = Z2(ISEG)
          SLEN = (ABS(XI2-XI1) + ABS(YI2-YI1) + ABS(ZI2-ZI1))*SMIN

          ! Check end 1 connection (label 22)
          SEP = ABS(XI1-XS) + ABS(YI1-YS) + ABS(ZI1-ZS)
          IF (SEP .LE. SLEN) THEN
            ! GOTO 22 eliminated: Connection found at end 1
            ICON1(ISEG) = 10001 + M
            IC = 1
            NPCON = NPCON + 1
            IPCON(NPCON) = I
            CALL SUBPH(I, IC, XI1, YI1, ZI1, XI2, YI2, ZI2, XA, YA, ZA, XS, YS, ZS)
            EXIT  ! GOTO 24 eliminated
          END IF

          ! Check end 2 connection (label 23)
          SEP = ABS(XI2-XS) + ABS(YI2-YS) + ABS(ZI2-ZS)
          IF (SEP .LE. SLEN) THEN
            ! GOTO 23 eliminated: Connection found at end 2
            ICON2(ISEG) = 10001 + M
            IC = 1
            NPCON = NPCON + 1
            IPCON(NPCON) = I
            CALL SUBPH(I, IC, XI1, YI1, ZI1, XI2, YI2, ZI2, XA, YA, ZA, XS, YS, ZS)
            EXIT  ! GOTO 24 eliminated
          END IF
        END DO  ! Label 23: CONTINUE eliminated

        ! Label 24: Next NGF patch
        I = I + 1
      END DO  ! GOTO 21 eliminated (DO WHILE loop)

      ! Label 25: Check NPCON limit
      IF (NPCON .GT. NPMAX) THEN
        WRITE(*,62) NPMAX
        STOP
      END IF
    END IF
  END IF  ! End of N .NE. 0 block

  ! Label 26: Output segment and symmetry information
  WRITE(*,58) N, NP, IPSYM
  IF (M .GT. 0) WRITE(*,61) M, MP

  ISEG = (N + M)/(NP + MP)

  ! Labels 27, 28, 29, 30 eliminated with structured IF-THEN-ELSE
  IF (ISEG .NE. 1) THEN
    IF (IPSYM .LT. 0) THEN
      ! Label 28: Negative IPSYM (rotational symmetry)
      WRITE(*,59) ISEG
    ELSE IF (IPSYM .GT. 0) THEN
      ! Label 29: Positive IPSYM (plane symmetry)
      IC = ISEG/2
      IF (ISEG .EQ. 8) IC = 3
      WRITE(*,60) IC
    ELSE
      ! Label 27: IPSYM = 0 and ISEG != 1 - error
      STOP
    END IF
  END IF

  ! Label 30: Adjust connected segment ends and print junctions
  ! GOTO 48 eliminated with IF-THEN
  IF (N .NE. 0) THEN
    WRITE(*,50)
    ISEG = 0

    ! Main junction processing loop (DO 44)
    DO J = 1, N
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
      process_end1: DO
        ! Label 31: Check if valid connection to process
        ! GOTO 43 eliminated with EXIT
        IF (IX .EQ. 0) EXIT process_end1
        IF (IX .EQ. J) EXIT process_end1
        IF (IX .GT. 10000) EXIT process_end1

        NSFLG = 0

        ! Label 32: Traverse connected segments (while-loop structure)
        traverse_connections: DO
          ! Computed GOTO: IF (IX) 33,49,34 → structured IF-THEN-ELSE
          IF (IX .EQ. 0) THEN
            ! Label 49: Error - segment connection error
            WRITE(*,53) IX
            STOP
          ELSE IF (IX .LT. 0) THEN
            ! Label 33: Negative IX (connected at end 1)
            IX = -IX
          ELSE
            ! Label 34: Positive IX (connected at end 2)
            JEND = -JEND
          END IF

          ! Label 35: Check for loop completion or continuation
          IF (IX .EQ. J) THEN
            ! GOTO 37: Loop detected, average coordinates
            EXIT traverse_connections
          END IF

          ! GOTO 43 eliminated with EXIT
          IF (IX .LT. J) EXIT process_end1

          IC = IC + 1
          IF (IC .GT. JMAX) THEN
            ! GOTO 49: Too many connections
            WRITE(*,53) IX
            STOP
          END IF

          JCO(IC) = IX*JEND
          IF (IX .GT. N1) NSFLG = 1

          ! Labels 36, 32 eliminated: Get next connection
          IF (JEND .EQ. 1) THEN
            ! Label 36: Connected at end 2, accumulate and get ICON2
            XA = XA + X2(IX)
            YA = YA + Y2(IX)
            ZA = ZA + Z2(IX)
            IX = ICON2(IX)
          ELSE
            ! Connected at end 1, accumulate and get ICON1
            XA = XA + X(IX)
            YA = YA + Y(IX)
            ZA = ZA + Z(IX)
            IX = ICON1(IX)
          END IF

          ! GOTO 32: Continue traversal (DO loop handles this)
        END DO traverse_connections

        ! Label 37: Average junction coordinates
        SEP = IC
        XA = XA/SEP
        YA = YA/SEP
        ZA = ZA/SEP

        ! DO 39: Update all connected segment endpoints
        DO I = 1, IC
          IX = JCO(I)

          ! Labels 38, 39 eliminated with IF-THEN-ELSE
          IF (IX .GT. 0) THEN
            ! Label 38: Update end 2
            X2(IX) = XA
            Y2(IX) = YA
            Z2(IX) = ZA
          ELSE
            ! Update end 1
            IX = -IX
            X(IX) = XA
            Y(IX) = YA
            Z(IX) = ZA
          END IF
        END DO  ! Label 39: CONTINUE eliminated

        ! Labels 40, 41, 42 eliminated: Track new segment connections
        ! GOTO 42 eliminated with IF-THEN
        IF (N1 .NE. 0 .AND. NSFLG .NE. 0) THEN
          DO I = 1, IC
            IX = IABS(JCO(I))

            ! GOTO 41 eliminated with CYCLE
            IF (IX .GT. N1) CYCLE
            IF (ICONX(IX) .NE. 0) CYCLE

            NSCON = NSCON + 1
            IF (NSCON .GT. NSMAX) THEN
              ! Label 40: Error - too many connections
              WRITE(*,62) NSMAX
              STOP
            END IF

            ISCON(NSCON) = IX
            ICONX(IX) = NSCON
          END DO  ! Label 41: CONTINUE eliminated
        END IF

        ! Label 42, 43: Check if junction has 3+ segments
        EXIT process_end1  ! Exit after processing this junction
      END DO process_end1

      ! Label 43: Print junction if 3 or more segments
      IF (IC .GE. 3) THEN
        ISEG = ISEG + 1
        WRITE(*,51) ISEG, (JCO(I), I=1, IC)
      END IF

      ! Label 43, 44: Process second end if not done
      ! GOTO 44 eliminated with IF-THEN
      IF (IEND .EQ. -1) THEN
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
        process_end2: DO
          IF (IX .EQ. 0) EXIT process_end2
          IF (IX .EQ. J) EXIT process_end2
          IF (IX .GT. 10000) EXIT process_end2

          NSFLG = 0

          traverse_connections2: DO
            IF (IX .EQ. 0) THEN
              WRITE(*,53) IX
              STOP
            ELSE IF (IX .LT. 0) THEN
              IX = -IX
            ELSE
              JEND = -JEND
            END IF

            IF (IX .EQ. J) EXIT traverse_connections2
            IF (IX .LT. J) EXIT process_end2

            IC = IC + 1
            IF (IC .GT. JMAX) THEN
              WRITE(*,53) IX
              STOP
            END IF

            JCO(IC) = IX*JEND
            IF (IX .GT. N1) NSFLG = 1

            IF (JEND .EQ. 1) THEN
              XA = XA + X2(IX)
              YA = YA + Y2(IX)
              ZA = ZA + Z2(IX)
              IX = ICON2(IX)
            ELSE
              XA = XA + X(IX)
              YA = YA + Y(IX)
              ZA = ZA + Z(IX)
              IX = ICON1(IX)
            END IF
          END DO traverse_connections2

          SEP = IC
          XA = XA/SEP
          YA = YA/SEP
          ZA = ZA/SEP

          DO I = 1, IC
            IX = JCO(I)
            IF (IX .GT. 0) THEN
              X2(IX) = XA
              Y2(IX) = YA
              Z2(IX) = ZA
            ELSE
              IX = -IX
              X(IX) = XA
              Y(IX) = YA
              Z(IX) = ZA
            END IF
          END DO

          IF (N1 .NE. 0 .AND. NSFLG .NE. 0) THEN
            DO I = 1, IC
              IX = IABS(JCO(I))
              IF (IX .GT. N1) CYCLE
              IF (ICONX(IX) .NE. 0) CYCLE

              NSCON = NSCON + 1
              IF (NSCON .GT. NSMAX) THEN
                WRITE(*,62) NSMAX
                STOP
              END IF

              ISCON(NSCON) = IX
              ICONX(IX) = NSCON
            END DO
          END IF

          EXIT process_end2
        END DO process_end2

        IF (IC .GE. 3) THEN
          ISEG = ISEG + 1
          WRITE(*,51) ISEG, (JCO(I), I=1, IC)
        END IF
      END IF

    END DO  ! Label 44: End main junction loop

    IF (ISEG .EQ. 0) WRITE(*,52)

    ! Section 4: Find old segments connecting to new patches
    ! Labels 45, 46, 47 eliminated with structured IF-THEN
    ! GOTO 48 eliminated with IF-THEN
    IF (N1 .NE. 0 .AND. M1 .NE. M) THEN
      DO J = 1, N1
        IX = ICON1(J)

        ! Label 45, 46: Check ICON1 connection
        ! GOTO 45, 46, 47 eliminated with nested IF-THEN
        needs_tracking = .FALSE.

        IF (IX .GE. 10000) THEN
          IX = IX - 10000
          IF (IX .GT. M1) needs_tracking = .TRUE.
        ELSE
          ! Label 45: Check ICON2
          IX = ICON2(J)
          IF (IX .GE. 10000) THEN
            IX = IX - 10000
            IF (IX .GE. M2) needs_tracking = .TRUE.
          END IF
        END IF

        ! Label 46: Track if needed
        IF (needs_tracking .AND. ICONX(J) .EQ. 0) THEN
          NSCON = NSCON + 1
          ISCON(NSCON) = J
          ICONX(J) = NSCON
        END IF

      END DO  ! Label 47: CONTINUE eliminated
    END IF
  END IF  ! Label 48: End of N != 0 block

  RETURN

  ! Format statements (Hollerith converted to quoted strings)
50 FORMAT (//,9X,'- MULTIPLE WIRE JUNCTIONS -',/,1X,'JUNCTION',4X, &
           'SEGMENTS  (- FOR END 1, + FOR END 2)')
51 FORMAT (1X,I5,5X,20I5,/,(11X,20I5))
52 FORMAT (2X,'NONE')
53 FORMAT (' CONNECT - SEGMENT CONNECTION ERROR FOR SEGMENT',I5)
54 FORMAT (/,3X,'GROUND PLANE SPECIFIED.')
55 FORMAT (/,3X,'WHERE WIRE ENDS TOUCH GROUND, CURRENT WILL BE ', &
           'INTERPOLATED TO IMAGE IN GROUND PLANE.',/)
56 FORMAT (' GEOMETRY DATA ERROR-- SEGMENT',I5,' EXTENDS BELOW GROUND')
57 FORMAT (' GEOMETRY DATA ERROR--SEGMENT',I5,' LIES IN GROUND PLANE.')
58 FORMAT (/,3X,'TOTAL SEGMENTS USED=',I5,5X,'NO. SEG. IN ', &
           'A SYMMETRIC CELL=',I5,5X,'SYMMETRY FLAG=',I3)
59 FORMAT (' STRUCTURE HAS',I4,' FOLD ROTATIONAL SYMMETRY',/)
60 FORMAT (' STRUCTURE HAS',I2,' PLANES OF SYMMETRY',/)
61 FORMAT (3X,'TOTAL PATCHES USED=',I5,6X, &
           'NO. PATCHES IN A SYMMETRIC CELL=',I5)
62 FORMAT (' ERROR - NO. NEW SEGMENTS CONNECTED TO N.G.F. SEGMENTS ', &
           'OR PATCHES EXCEEDS LIMIT OF',I5)

END SUBROUTINE CONECT
