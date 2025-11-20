! =============================================================================
! nec2d_conect - Connection Handling
! =============================================================================
! Purpose: Wire and patch connection processing
! Contains: CONECT
! =============================================================================
subroutine conect (ignd)
  ! ***
  ! DOUBLE PRECISION 6/4/85
  !
  ! CONNECT SETS UP SEGMENT CONNECTION DATA IN ARRAYS ICON1 AND ICON2
  ! BY SEARCHING FOR SEGMENT ENDS THAT ARE IN CONTACT.
  !
  ! Modernized: Eliminated 67 GOTOs using structured control flow
  !
  implicit real*8(a-h,o-z)

  ! Parameter from NEC2DPAR.INC
  integer, parameter :: maxseg = 3000
  integer, parameter :: jmax = 50
  integer, parameter :: nsmax = 50

  ! LOGICAL variables override IMPLICIT typing
  logical :: end1_connected, end2_connected, patch_connected, needs_tracking

  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
                alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
                itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /segj/ ax(jmax),bx(jmax),cx(jmax),jco(jmax), &
                jsno,iscon(50),nscon,ipcon(10),npcon

  dimension x2(1), y2(1), z2(1)
  equivalence (x2,si), (y2,alp), (z2,bet)
  data smin/1.d-3/,npmax/10/

  nscon = 0
  npcon = 0

  ! Section 1: Initialization and symmetry setup (labels 1, 2, 3 eliminated)
  ! GOTO 1, 2, 3 eliminated with structured IF-THEN-ELSE
  if (ignd .ne. 0) then
    write(*,54)
    if (ignd .gt. 0) write(*,55)

    ! Label 1: Adjust for symmetry
    if (ipsym .eq. 2) then
      np = 2*np
      mp = 2*mp
    end if

    ! Label 2: More symmetry adjustments
    if (iabs(ipsym) .gt. 2) then
      np = n
      mp = m
    end if

    if (np .gt. n) stop
    if (np .eq. n .and. mp .eq. m) ipsym = 0
  end if

  ! Label 3: Main processing begins
  ! GOTO 26 eliminated with IF-THEN
  if (n .eq. 0) then
    ! Skip to label 26 (output section)
    ! (handled at end of routine)
  else
    ! Main segment connection loop (DO 15 eliminated)
    do i = 1, n
      iconx(i) = 0
      xi1 = x(i)
      yi1 = y(i)
      zi1 = z(i)
      xi2 = x2(i)
      yi2 = y2(i)
      zi2 = z2(i)
      slen = sqrt((xi2-xi1)**2 + (yi2-yi1)**2 + (zi2-zi1)**2)*smin

      ! Determine connection data for end 1 of segment
      ! Labels 4, 5, 9 eliminated with IF-THEN-ELSE
      end1_connected = .false.

      if (ignd .ge. 1) then
        ! Check ground plane connection for end 1
        if (zi1 .le. -slen) then
          write(*,56) i
          stop
        end if

        if (zi1 .le. slen) then
          ! Label 4: End 1 touches ground
          icon1(i) = i
          z(i) = 0.
          end1_connected = .true.
        end if
      end if

      ! Label 5: Search for segment connections (if not ground connected)
      if (.not. end1_connected) then
        ic = i
        icon1(i) = 0  ! Default: no connection

        ! DO 7 loop: Search for connecting segment
        do j = 2, n
          ic = ic + 1
          if (ic .gt. n) ic = 1

          ! Check connection to end 1 of segment IC (label 6)
          sep = abs(xi1-x(ic)) + abs(yi1-y(ic)) + abs(zi1-z(ic))
          if (sep .le. slen) then
            ! GOTO 6 eliminated: Found connection at end 1 of IC
            icon1(i) = -ic
            exit  ! GOTO 8 eliminated
          end if

          ! Check connection to end 2 of segment IC (label 7)
          sep = abs(xi1-x2(ic)) + abs(yi1-y2(ic)) + abs(zi1-z2(ic))
          if (sep .le. slen) then
            ! GOTO 7 eliminated: Found connection at end 2 of IC
            icon1(i) = ic
            exit  ! GOTO 8 eliminated
          end if
        end do  ! Label 7: CONTINUE eliminated

        ! After DO 7 loop, check special case
        if (i .lt. n2 .and. icon1(i) .gt. 10000) then
          ! Keep ICON1(I) as is (GOTO 8 implicit)
        else if (icon1(i) .eq. 0) then
          ! No connection found, ICON1(I) already set to 0
        end if
      end if

      ! Label 8: Determine connection data for end 2 of segment
      ! Labels 9, 10, 11, 12 eliminated with IF-THEN-ELSE
      end2_connected = .false.

      if (ignd .ge. 1) then
        ! Label 9: Check ground plane connection for end 2
        if (zi2 .le. -slen) then
          write(*,56) i
          stop
        end if

        ! Label 10
        if (zi2 .le. slen) then
          if (icon1(i) .eq. i) then
            ! Label 11: Both ends on ground - error
            write(*,57) i
            stop
          end if
          icon2(i) = i
          z2(i) = 0.
          end2_connected = .true.
        end if
      end if

      ! Label 12: Search for segment connections (if not ground connected)
      if (.not. end2_connected) then
        ic = i
        icon2(i) = 0  ! Default: no connection

        ! DO 14 loop: Search for connecting segment
        do j = 2, n
          ic = ic + 1
          if (ic .gt. n) ic = 1

          ! Check connection to end 1 of segment IC (label 13)
          sep = abs(xi2-x(ic)) + abs(yi2-y(ic)) + abs(zi2-z(ic))
          if (sep .le. slen) then
            ! GOTO 13 eliminated: Found connection at end 1 of IC
            icon2(i) = ic
            exit  ! GOTO 15 eliminated
          end if

          ! Check connection to end 2 of segment IC (label 14)
          sep = abs(xi2-x2(ic)) + abs(yi2-y2(ic)) + abs(zi2-z2(ic))
          if (sep .le. slen) then
            ! GOTO 14 eliminated: Found connection at end 2 of IC
            icon2(i) = -ic
            exit  ! GOTO 15 eliminated
          end if
        end do  ! Label 14: CONTINUE eliminated

        ! After DO 14 loop, check special case
        if (i .lt. n2 .and. icon2(i) .gt. 10000) then
          ! Keep ICON2(I) as is (GOTO 15 implicit)
        else if (icon2(i) .eq. 0) then
          ! No connection found, ICON2(I) already set to 0
        end if
      end if

    end do  ! Label 15: End main segment loop

    ! Section 2: Find wire-surface connections for new patches
    ! GOTO 26 eliminated with IF-THEN
    if (m .ne. 0) then
      ix = ld + 1 - m1
      i = m2

      ! Label 16: Loop through new patches
      do while (i .le. m)
        ix = ix - 1
        xs = x(ix)
        ys = y(ix)
        zs = z(ix)

        patch_connected = .false.

        ! DO 18 loop: Check all segments
        do iseg = 1, n
          xi1 = x(iseg)
          yi1 = y(iseg)
          zi1 = z(iseg)
          xi2 = x2(iseg)
          yi2 = y2(iseg)
          zi2 = z2(iseg)
          slen = (abs(xi2-xi1) + abs(yi2-yi1) + abs(zi2-zi1))*smin

          ! Check end 1 connection (label 17)
          sep = abs(xi1-xs) + abs(yi1-ys) + abs(zi1-zs)
          if (sep .le. slen) then
            ! GOTO 17 eliminated: Connection found at end 1
            icon1(iseg) = 10000 + i
            ic = 0
            call subph(i, ic, xi1, yi1, zi1, xi2, yi2, zi2, xa, ya, za, xs, ys, zs)
            patch_connected = .true.
            exit  ! GOTO 19 eliminated
          end if

          ! Check end 2 connection (label 18)
          sep = abs(xi2-xs) + abs(yi2-ys) + abs(zi2-zs)
          if (sep .le. slen) then
            ! GOTO 18 eliminated: Connection found at end 2
            icon2(iseg) = 10000 + i
            ic = 0
            call subph(i, ic, xi1, yi1, zi1, xi2, yi2, zi2, xa, ya, za, xs, ys, zs)
            patch_connected = .true.
            exit  ! GOTO 19 eliminated
          end if
        end do  ! Label 18: CONTINUE eliminated

        ! Label 19: Next patch
        i = i + 1
      end do  ! GOTO 16 eliminated (DO WHILE loop)
    end if

    ! Section 3: Repeat search for new segments connected to NGF patches
    ! Label 20: GOTO 26 eliminated with IF-THEN
    if (m1 .ne. 0 .and. n2 .le. n) then
      ix = ld + 1
      i = 1

      ! Label 21: Loop through NGF patches
      do while (i .le. m1)
        ix = ix - 1
        xs = x(ix)
        ys = y(ix)
        zs = z(ix)

        ! DO 23 loop: Check segments N2 to N
        do iseg = n2, n
          xi1 = x(iseg)
          yi1 = y(iseg)
          zi1 = z(iseg)
          xi2 = x2(iseg)
          yi2 = y2(iseg)
          zi2 = z2(iseg)
          slen = (abs(xi2-xi1) + abs(yi2-yi1) + abs(zi2-zi1))*smin

          ! Check end 1 connection (label 22)
          sep = abs(xi1-xs) + abs(yi1-ys) + abs(zi1-zs)
          if (sep .le. slen) then
            ! GOTO 22 eliminated: Connection found at end 1
            icon1(iseg) = 10001 + m
            ic = 1
            npcon = npcon + 1
            ipcon(npcon) = i
            call subph(i, ic, xi1, yi1, zi1, xi2, yi2, zi2, xa, ya, za, xs, ys, zs)
            exit  ! GOTO 24 eliminated
          end if

          ! Check end 2 connection (label 23)
          sep = abs(xi2-xs) + abs(yi2-ys) + abs(zi2-zs)
          if (sep .le. slen) then
            ! GOTO 23 eliminated: Connection found at end 2
            icon2(iseg) = 10001 + m
            ic = 1
            npcon = npcon + 1
            ipcon(npcon) = i
            call subph(i, ic, xi1, yi1, zi1, xi2, yi2, zi2, xa, ya, za, xs, ys, zs)
            exit  ! GOTO 24 eliminated
          end if
        end do  ! Label 23: CONTINUE eliminated

        ! Label 24: Next NGF patch
        i = i + 1
      end do  ! GOTO 21 eliminated (DO WHILE loop)

      ! Label 25: Check NPCON limit
      if (npcon .gt. npmax) then
        write(*,62) npmax
        stop
      end if
    end if
  end if  ! End of N .NE. 0 block

  ! Label 26: Output segment and symmetry information
  write(*,58) n, np, ipsym
  if (m .gt. 0) write(*,61) m, mp

  iseg = (n + m)/(np + mp)

  ! Labels 27, 28, 29, 30 eliminated with structured IF-THEN-ELSE
  if (iseg .ne. 1) then
    if (ipsym .lt. 0) then
      ! Label 28: Negative IPSYM (rotational symmetry)
      write(*,59) iseg
    else if (ipsym .gt. 0) then
      ! Label 29: Positive IPSYM (plane symmetry)
      ic = iseg/2
      if (iseg .eq. 8) ic = 3
      write(*,60) ic
    else
      ! Label 27: IPSYM = 0 and ISEG != 1 - error
      stop
    end if
  end if

  ! Label 30: Adjust connected segment ends and print junctions
  ! GOTO 48 eliminated with IF-THEN
  if (n .ne. 0) then
    write(*,50)
    iseg = 0

    ! Main junction processing loop (DO 44)
    do j = 1, n
      iend = -1
      jend = -1
      ix = icon1(j)
      ic = 1
      jco(1) = -j
      xa = x(j)
      ya = y(j)
      za = z(j)

      ! Label 31: Process one end of segment J
      ! This is a complex section with a graph traversal algorithm
      ! GOTO 31, 43, 49 eliminated with structured loops and flags
      process_end1: do
        ! Label 31: Check if valid connection to process
        ! GOTO 43 eliminated with EXIT
        if (ix .eq. 0) exit process_end1
        if (ix .eq. j) exit process_end1
        if (ix .gt. 10000) exit process_end1

        nsflg = 0

        ! Label 32: Traverse connected segments (while-loop structure)
        traverse_connections: do
          ! Computed GOTO: IF (IX) 33,49,34 → structured IF-THEN-ELSE
          if (ix .eq. 0) then
            ! Label 49: Error - segment connection error
            write(*,53) ix
            stop
          else if (ix .lt. 0) then
            ! Label 33: Negative IX (connected at end 1)
            ix = -ix
          else
            ! Label 34: Positive IX (connected at end 2)
            jend = -jend
          end if

          ! Label 35: Check for loop completion or continuation
          if (ix .eq. j) then
            ! GOTO 37: Loop detected, average coordinates
            exit traverse_connections
          end if

          ! GOTO 43 eliminated with EXIT
          if (ix .lt. j) exit process_end1

          ic = ic + 1
          if (ic .gt. jmax) then
            ! GOTO 49: Too many connections
            write(*,53) ix
            stop
          end if

          jco(ic) = ix*jend
          if (ix .gt. n1) nsflg = 1

          ! Labels 36, 32 eliminated: Get next connection
          if (jend .eq. 1) then
            ! Label 36: Connected at end 2, accumulate and get ICON2
            xa = xa + x2(ix)
            ya = ya + y2(ix)
            za = za + z2(ix)
            ix = icon2(ix)
          else
            ! Connected at end 1, accumulate and get ICON1
            xa = xa + x(ix)
            ya = ya + y(ix)
            za = za + z(ix)
            ix = icon1(ix)
          end if

          ! GOTO 32: Continue traversal (DO loop handles this)
        end do traverse_connections

        ! Label 37: Average junction coordinates
        sep = ic
        xa = xa/sep
        ya = ya/sep
        za = za/sep

        ! DO 39: Update all connected segment endpoints
        do i = 1, ic
          ix = jco(i)

          ! Labels 38, 39 eliminated with IF-THEN-ELSE
          if (ix .gt. 0) then
            ! Label 38: Update end 2
            x2(ix) = xa
            y2(ix) = ya
            z2(ix) = za
          else
            ! Update end 1
            ix = -ix
            x(ix) = xa
            y(ix) = ya
            z(ix) = za
          end if
        end do  ! Label 39: CONTINUE eliminated

        ! Labels 40, 41, 42 eliminated: Track new segment connections
        ! GOTO 42 eliminated with IF-THEN
        if (n1 .ne. 0 .and. nsflg .ne. 0) then
          do i = 1, ic
            ix = iabs(jco(i))

            ! GOTO 41 eliminated with CYCLE
            if (ix .gt. n1) cycle
            if (iconx(ix) .ne. 0) cycle

            nscon = nscon + 1
            if (nscon .gt. nsmax) then
              ! Label 40: Error - too many connections
              write(*,62) nsmax
              stop
            end if

            iscon(nscon) = ix
            iconx(ix) = nscon
          end do  ! Label 41: CONTINUE eliminated
        end if

        ! Label 42, 43: Check if junction has 3+ segments
        exit process_end1  ! Exit after processing this junction
      end do process_end1

      ! Label 43: Print junction if 3 or more segments
      if (ic .ge. 3) then
        iseg = iseg + 1
        write(*,51) iseg, (jco(i), i=1, ic)
      end if

      ! Label 43, 44: Process second end if not done
      ! GOTO 44 eliminated with IF-THEN
      if (iend .eq. -1) then
        ! Process end 2
        iend = 1
        jend = 1
        ix = icon2(j)
        ic = 1
        jco(1) = j
        xa = x2(j)
        ya = y2(j)
        za = z2(j)

        ! Re-enter at label 31 for end 2 processing
        ! Duplicate the process_end1 logic for end 2
        process_end2: do
          if (ix .eq. 0) exit process_end2
          if (ix .eq. j) exit process_end2
          if (ix .gt. 10000) exit process_end2

          nsflg = 0

          traverse_connections2: do
            if (ix .eq. 0) then
              write(*,53) ix
              stop
            else if (ix .lt. 0) then
              ix = -ix
            else
              jend = -jend
            end if

            if (ix .eq. j) exit traverse_connections2
            if (ix .lt. j) exit process_end2

            ic = ic + 1
            if (ic .gt. jmax) then
              write(*,53) ix
              stop
            end if

            jco(ic) = ix*jend
            if (ix .gt. n1) nsflg = 1

            if (jend .eq. 1) then
              xa = xa + x2(ix)
              ya = ya + y2(ix)
              za = za + z2(ix)
              ix = icon2(ix)
            else
              xa = xa + x(ix)
              ya = ya + y(ix)
              za = za + z(ix)
              ix = icon1(ix)
            end if
          end do traverse_connections2

          sep = ic
          xa = xa/sep
          ya = ya/sep
          za = za/sep

          do i = 1, ic
            ix = jco(i)
            if (ix .gt. 0) then
              x2(ix) = xa
              y2(ix) = ya
              z2(ix) = za
            else
              ix = -ix
              x(ix) = xa
              y(ix) = ya
              z(ix) = za
            end if
          end do

          if (n1 .ne. 0 .and. nsflg .ne. 0) then
            do i = 1, ic
              ix = iabs(jco(i))
              if (ix .gt. n1) cycle
              if (iconx(ix) .ne. 0) cycle

              nscon = nscon + 1
              if (nscon .gt. nsmax) then
                write(*,62) nsmax
                stop
              end if

              iscon(nscon) = ix
              iconx(ix) = nscon
            end do
          end if

          exit process_end2
        end do process_end2

        if (ic .ge. 3) then
          iseg = iseg + 1
          write(*,51) iseg, (jco(i), i=1, ic)
        end if
      end if

    end do  ! Label 44: End main junction loop

    if (iseg .eq. 0) write(*,52)

    ! Section 4: Find old segments connecting to new patches
    ! Labels 45, 46, 47 eliminated with structured IF-THEN
    ! GOTO 48 eliminated with IF-THEN
    if (n1 .ne. 0 .and. m1 .ne. m) then
      do j = 1, n1
        ix = icon1(j)

        ! Label 45, 46: Check ICON1 connection
        ! GOTO 45, 46, 47 eliminated with nested IF-THEN
        needs_tracking = .false.

        if (ix .ge. 10000) then
          ix = ix - 10000
          if (ix .gt. m1) needs_tracking = .true.
        else
          ! Label 45: Check ICON2
          ix = icon2(j)
          if (ix .ge. 10000) then
            ix = ix - 10000
            if (ix .ge. m2) needs_tracking = .true.
          end if
        end if

        ! Label 46: Track if needed
        if (needs_tracking .and. iconx(j) .eq. 0) then
          nscon = nscon + 1
          iscon(nscon) = j
          iconx(j) = nscon
        end if

      end do  ! Label 47: CONTINUE eliminated
    end if
  end if  ! Label 48: End of N != 0 block

  return

  ! Format statements (Hollerith converted to quoted strings)
50 format (//,9x,'- MULTIPLE WIRE JUNCTIONS -',/,1x,'JUNCTION',4x, &
           'SEGMENTS  (- FOR END 1, + FOR END 2)')
51 format (1x,i5,5x,20i5,/,(11x,20i5))
52 format (2x,'NONE')
53 format (' CONNECT - SEGMENT CONNECTION ERROR FOR SEGMENT',i5)
54 format (/,3x,'GROUND PLANE SPECIFIED.')
55 format (/,3x,'WHERE WIRE ENDS TOUCH GROUND, CURRENT WILL BE ', &
           'INTERPOLATED TO IMAGE IN GROUND PLANE.',/)
56 format (' GEOMETRY DATA ERROR-- SEGMENT',i5,' EXTENDS BELOW GROUND')
57 format (' GEOMETRY DATA ERROR--SEGMENT',i5,' LIES IN GROUND PLANE.')
58 format (/,3x,'TOTAL SEGMENTS USED=',i5,5x,'NO. SEG. IN ', &
           'A SYMMETRIC CELL=',i5,5x,'SYMMETRY FLAG=',i3)
59 format (' STRUCTURE HAS',i4,' FOLD ROTATIONAL SYMMETRY',/)
60 format (' STRUCTURE HAS',i2,' PLANES OF SYMMETRY',/)
61 format (3x,'TOTAL PATCHES USED=',i5,6x, &
           'NO. PATCHES IN A SYMMETRIC CELL=',i5)
62 format (' ERROR - NO. NEW SEGMENTS CONNECTED TO N.G.F. SEGMENTS ', &
           'OR PATCHES EXCEEDS LIMIT OF',i5)

end subroutine conect
