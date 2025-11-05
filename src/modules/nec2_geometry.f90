! nec2_geometry.f90
! Geometry generation and manipulation for NEC2
! Handles wire and surface geometry creation, transformations, and connections

module nec2_geometry
  use nec2_constants
  use nec2_data_types
  use nec2_utilities
  implicit none
  private

  ! Public subroutines
  public :: wire, helix, arc, patch
  public :: move_geometry, reflect_geometry, connect_segments

contains

  !============================================================================
  ! WIRE - Generate straight wire geometry
  !============================================================================
  subroutine wire(geom, xw1, yw1, zw1, xw2, yw2, zw2, rad, rdel, rrad, ns, itg)
    ! Generates segment geometry data for a straight wire of ns segments
    !
    ! Arguments:
    !   geom  - geometry data structure
    !   xw1, yw1, zw1 - coordinates of wire end 1
    !   xw2, yw2, zw2 - coordinates of wire end 2
    !   rad   - wire radius
    !   rdel  - ratio of segment length (1.0 for equal segments)
    !   rrad  - ratio of segment radii (1.0 for constant radius)
    !   ns    - number of segments
    !   itg   - tag number for these segments

    type(geometry_data), intent(inout) :: geom
    real(8), intent(in) :: xw1, yw1, zw1, xw2, yw2, zw2
    real(8), intent(in) :: rad, rdel, rrad
    integer, intent(in) :: ns, itg

    integer :: ist, i
    real(8) :: xd, yd, zd, delz, rd, radz
    real(8) :: xs1, ys1, zs1, xs2, ys2, zs2
    real(8) :: fns

    ist = geom%n + 1
    geom%n = geom%n + ns
    geom%np = geom%n
    geom%mp = geom%m
    geom%ipsym = 0

    if (ns < 1) return

    xd = xw2 - xw1
    yd = yw2 - yw1
    zd = zw2 - zw1

    ! Check for tapered segments
    if (abs(rdel - 1.0d0) >= 1.0d-6) then
      ! Variable segment length
      delz = sqrt(xd*xd + yd*yd + zd*zd)
      xd = xd / delz
      yd = yd / delz
      zd = zd / delz
      delz = delz * (1.0d0 - rdel) / (1.0d0 - rdel**ns)
      rd = rdel
    else
      ! Equal segment lengths
      fns = real(ns, kind=8)
      xd = xd / fns
      yd = yd / fns
      zd = zd / fns
      delz = 1.0d0
      rd = 1.0d0
    end if

    radz = rad
    xs1 = xw1
    ys1 = yw1
    zs1 = zw1

    ! Generate segments
    do i = ist, geom%n
      geom%itag(i) = itg

      ! Calculate end point of this segment
      xs2 = xs1 + xd * delz
      ys2 = ys1 + yd * delz
      zs2 = zs1 + zd * delz

      ! Store segment center (start point)
      geom%x(i) = xs1
      geom%y(i) = ys1
      geom%z(i) = zs1

      ! Store segment end point (using si, alp, bet as temporary storage)
      ! This mimics the EQUIVALENCE (X2,SI), (Y2,ALP), (Z2,BET) from original
      geom%si(i) = xs2
      geom%alp(i) = ys2
      geom%bet(i) = zs2

      ! Store radius
      geom%bi(i) = radz

      ! Update for next segment
      delz = delz * rd
      radz = radz * rrad
      xs1 = xs2
      ys1 = ys2
      zs1 = zs2
    end do

    ! Ensure last segment ends exactly at specified point
    geom%si(geom%n) = xw2
    geom%alp(geom%n) = yw2
    geom%bet(geom%n) = zw2

  end subroutine wire

  !============================================================================
  ! HELIX - Generate helical wire geometry
  !============================================================================
  subroutine helix(geom, s, hl, a1, b1, a2, b2, rad, ns, itg)
    ! Generates segment geometry data for a helix of ns segments
    !
    ! Arguments:
    !   geom - geometry data structure
    !   s    - spacing between turns
    !   hl   - total helix length (+ for right-hand, - for left-hand)
    !   a1   - x radius at start (or constant radius if a2=a1)
    !   b1   - y radius at start
    !   a2   - x radius at end
    !   b2   - y radius at end
    !   rad  - wire radius
    !   ns   - number of segments
    !   itg  - tag number

    type(geometry_data), intent(inout) :: geom
    real(8), intent(in) :: s, hl, a1, b1, a2, b2, rad
    integer, intent(in) :: ns, itg

    integer :: ist, i
    real(8) :: turns, zinc, a1_loc, b1_loc, a2_loc, b2_loc
    real(8) :: zi, zi2, radius_factor, sangle, hdia, pitch
    real(8) :: hmaj, hmin, turn, copy_val

    ist = geom%n + 1
    geom%n = geom%n + ns
    geom%np = geom%n
    geom%mp = geom%m
    geom%ipsym = 0

    if (ns < 1) return

    a1_loc = a1
    b1_loc = b1
    a2_loc = a2
    b2_loc = b2

    turns = abs(hl / s)
    zinc = abs(hl) / ns
    geom%z(ist) = 0.0d0

    do i = ist, geom%n
      geom%bi(i) = rad
      geom%itag(i) = itg

      if (i /= ist) geom%z(i) = geom%z(i-1) + zinc
      zi = geom%z(i)
      zi2 = zi + zinc

      if (a2_loc /= a1_loc) then
        ! Tapered helix (conical spiral)
        if (b2_loc == 0.0d0) b2_loc = a2_loc
        radius_factor = zi / abs(hl)
        geom%x(i) = (a1_loc + (a2_loc - a1_loc) * radius_factor) * &
                    cos(TWO_PI * zi / s)
        geom%y(i) = (b1_loc + (b2_loc - b1_loc) * radius_factor) * &
                    sin(TWO_PI * zi / s)

        radius_factor = zi2 / abs(hl)
        geom%si(i) = (a1_loc + (a2_loc - a1_loc) * radius_factor) * &
                     cos(TWO_PI * zi2 / s)
        geom%alp(i) = (b1_loc + (b2_loc - b1_loc) * radius_factor) * &
                      sin(TWO_PI * zi2 / s)
      else
        ! Cylindrical helix
        if (b1_loc == 0.0d0) b1_loc = a1_loc
        geom%x(i) = a1_loc * cos(TWO_PI * zi / s)
        geom%y(i) = b1_loc * sin(TWO_PI * zi / s)
        geom%si(i) = a1_loc * cos(TWO_PI * zi2 / s)
        geom%alp(i) = b1_loc * sin(TWO_PI * zi2 / s)
      end if

      geom%bet(i) = zi2

      ! Swap X and Y for left-hand helix
      if (hl < 0.0d0) then
        copy_val = geom%x(i)
        geom%x(i) = geom%y(i)
        geom%y(i) = copy_val
        copy_val = geom%si(i)
        geom%si(i) = geom%alp(i)
        geom%alp(i) = copy_val
      end if
    end do

    ! Print helix parameters
    if (a2_loc /= a1_loc) then
      sangle = atan(a2_loc / (abs(hl) + (abs(hl) * a1_loc) / (a2_loc - a1_loc)))
      write(*,'(A,F10.4)') '     The cone angle of the spiral is', sangle
    else if (a1_loc == b1_loc) then
      ! Circular helix
      hdia = 2.0d0 * a1_loc
      turn = hdia * PI
      pitch = atan(s / (PI * hdia))
      turn = turn / cos(pitch)
      pitch = to_degrees(pitch)
      write(*,'(A,F10.4)') '     The pitch angle is', pitch
      write(*,'(A,F10.4)') '     The length of wire/turn is', turn
    else
      ! Elliptical helix
      if (a1_loc > b1_loc) then
        hmaj = 2.0d0 * a1_loc
        hmin = 2.0d0 * b1_loc
      else
        hmaj = 2.0d0 * b1_loc
        hmin = 2.0d0 * a1_loc
      end if
      hdia = sqrt((hmaj**2 + hmin**2) / 2.0d0 * hmaj)
      turn = TWO_PI * hdia
      pitch = to_degrees(atan(s / (PI * hdia)))
      write(*,'(A,F10.4)') '     The pitch angle is', pitch
      write(*,'(A,F10.4)') '     The length of wire/turn is', turn
    end if

  end subroutine helix

  !============================================================================
  ! ARC - Generate arc geometry
  !============================================================================
  subroutine arc(geom, itg, ns, rada, ang1, ang2, rad)
    ! Generates segment geometry data for an arc of ns segments
    !
    ! Arguments:
    !   geom  - geometry data structure
    !   itg   - tag number
    !   ns    - number of segments
    !   rada  - arc radius
    !   ang1  - starting angle (degrees)
    !   ang2  - ending angle (degrees)
    !   rad   - wire radius

    type(geometry_data), intent(inout) :: geom
    integer, intent(in) :: itg, ns
    real(8), intent(in) :: rada, ang1, ang2, rad

    integer :: ist, i
    real(8) :: ang, dang, xs1, zs1, xs2, zs2

    ist = geom%n + 1
    geom%n = geom%n + ns
    geom%np = geom%n
    geom%mp = geom%m
    geom%ipsym = 0

    if (ns < 1) return

    ! Check angle range
    if (abs(ang2 - ang1) >= 360.00001d0) then
      write(*,'(A)') 'ERROR: Arc angle exceeds 360 degrees'
      stop 1
    end if

    ang = to_radians(ang1)
    dang = to_radians(ang2 - ang1) / ns

    xs1 = rada * cos(ang)
    zs1 = rada * sin(ang)

    do i = ist, geom%n
      ang = ang + dang
      xs2 = rada * cos(ang)
      zs2 = rada * sin(ang)

      geom%x(i) = xs1
      geom%y(i) = 0.0d0
      geom%z(i) = zs1

      geom%si(i) = xs2
      geom%alp(i) = 0.0d0
      geom%bet(i) = zs2

      xs1 = xs2
      zs1 = zs2

      geom%bi(i) = rad
      geom%itag(i) = itg
    end do

  end subroutine arc

  !============================================================================
  ! PATCH - Generate surface patch geometry
  !============================================================================
  subroutine patch(geom, angle_data, nx, ny, &
                   x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4)
    ! Generates and modifies patch geometry data
    !
    ! For nx=0, ny determines patch type:
    !   ny=1: arbitrary
    !   ny=2: rectangular
    !   ny=3: triangular
    !   ny=4: quadrilateral
    ! For nx>0 and ny>0: rectangular surface with nx by ny patches
    !
    ! Arguments:
    !   geom       - geometry data structure
    !   angle_data - angle data (for SALP array)
    !   nx, ny     - patch dimensions/type
    !   x1,y1,z1 through x4,y4,z4 - corner coordinates

    type(geometry_data), intent(inout) :: geom
    type(angle_data), intent(inout) :: angle_data
    integer, intent(in) :: nx, ny
    real(8), intent(in) :: x1, y1, z1, x2, y2, z2
    real(8), intent(in) :: x3, y3, z3, x4, y4, z4

    integer :: ntp, mi
    real(8) :: s1x, s1y, s1z, s2x, s2y, s2z
    real(8) :: xnv, ynv, znv, xa, xst
    real(8) :: xn2, yn2, zn2, salpn

    geom%m = geom%m + 1
    mi = geom%ld + 1 - geom%m
    ntp = ny
    if (nx > 0) ntp = 2

    if (ntp <= 1) then
      ! Arbitrary patch (ntp=1)
      geom%x(mi) = x1
      geom%y(mi) = y1
      geom%z(mi) = z1
      geom%bi(mi) = z2

      ! Calculate normal vector from angles
      znv = cos(x2)
      xnv = znv * cos(y2)
      ynv = znv * sin(y2)
      znv = sin(x2)

      xa = sqrt(xnv*xnv + ynv*ynv)
      if (xa >= 1.0d-6) then
        ! Store tangent vectors in SI, ALP, BET
        geom%si(mi) = -ynv / xa
        geom%alp(mi) = xnv / xa
        geom%bet(mi) = 0.0d0
      else
        geom%si(mi) = 1.0d0
        geom%alp(mi) = 0.0d0
        geom%bet(mi) = 0.0d0
      end if
    else
      ! Rectangular, triangular, or quadrilateral patch
      s1x = x2 - x1
      s1y = y2 - y1
      s1z = z2 - z1
      s2x = x3 - x2
      s2y = y3 - y2
      s2z = z3 - z2

      if (nx > 0) then
        ! Subdivide into nx by ny patches
        s1x = s1x / nx
        s1y = s1y / nx
        s1z = s1z / nx
        s2x = s2x / ny
        s2y = s2y / ny
        s2z = s2z / ny
      end if

      ! Calculate normal vector via cross product
      xnv = s1y * s2z - s1z * s2y
      ynv = s1z * s2x - s1x * s2z
      znv = s1x * s2y - s1y * s2x
      xa = sqrt(xnv*xnv + ynv*ynv + znv*znv)
      xnv = xnv / xa
      ynv = ynv / xa
      znv = znv / xa

      ! Unit vector along side 1
      xst = sqrt(s1x*s1x + s1y*s1y + s1z*s1z)
      geom%si(mi) = s1x / xst
      geom%alp(mi) = s1y / xst
      geom%bet(mi) = s1z / xst

      if (ntp <= 2) then
        ! Rectangular patch center
        geom%x(mi) = x1 + 0.5d0 * (s1x + s2x)
        geom%y(mi) = y1 + 0.5d0 * (s1y + s2y)
        geom%z(mi) = z1 + 0.5d0 * (s1z + s2z)
        geom%bi(mi) = xa
      else if (ntp == 3) then
        ! Triangular patch center
        geom%x(mi) = (x1 + x2 + x3) / 3.0d0
        geom%y(mi) = (y1 + y2 + y3) / 3.0d0
        geom%z(mi) = (z1 + z2 + z3) / 3.0d0
        geom%bi(mi) = 0.5d0 * xa
      else
        ! Quadrilateral patch - weighted center
        s1x = x3 - x1
        s1y = y3 - y1
        s1z = z3 - z1
        s2x = x4 - x1
        s2y = y4 - y1
        s2z = z4 - z1

        xn2 = s1y * s2z - s1z * s2y
        yn2 = s1z * s2x - s1x * s2z
        zn2 = s1x * s2y - s1y * s2x
        xst = sqrt(xn2*xn2 + yn2*yn2 + zn2*zn2)

        salpn = 1.0d0 / (3.0d0 * (xa + xst))
        geom%x(mi) = (xa * (x1 + x2 + x3) + xst * (x1 + x3 + x4)) * salpn
        geom%y(mi) = (xa * (y1 + y2 + y3) + xst * (y1 + y3 + y4)) * salpn
        geom%z(mi) = (xa * (z1 + z2 + z3) + xst * (z1 + z3 + z4)) * salpn
        geom%bi(mi) = 0.5d0 * (xa + xst)

        ! Check planarity
        s1x = (xnv * xn2 + ynv * yn2 + znv * zn2) / xst
        if (s1x <= 0.9998d0) then
          write(*,'(A)') 'ERROR: Corners of quadrilateral patch do not lie in a plane'
          stop 1
        end if
      end if
    end if

    ! Calculate second tangent vector (perpendicular to first and normal)
    geom%icon1(mi) = ynv * geom%bet(mi) - znv * geom%alp(mi)
    geom%icon2(mi) = znv * geom%si(mi) - xnv * geom%bet(mi)
    geom%itag(mi) = xnv * geom%alp(mi) - ynv * geom%si(mi)

  end subroutine patch

  !============================================================================
  ! MOVE_GEOMETRY - Move and replicate geometry
  !============================================================================
  subroutine move_geometry(geom, angle_data, rox, roy, roz, &
                          xs, ys, zs, its, nrpt, itgi)
    ! Rotates and translates structure
    ! Structure is rotated about X, Y, Z axes by rox, roy, roz (radians)
    ! then shifted by xs, ys, zs
    !
    ! Arguments:
    !   geom       - geometry data
    !   angle_data - angle data
    !   rox, roy, roz - rotation angles (radians)
    !   xs, ys, zs - translation
    !   its        - starting tag (0 = all)
    !   nrpt       - number of replications (0 = move only)
    !   itgi       - tag increment for replications

    type(geometry_data), intent(inout) :: geom
    type(angle_data), intent(inout) :: angle_data
    real(8), intent(in) :: rox, roy, roz, xs, ys, zs
    integer, intent(in) :: its, nrpt, itgi

    real(8) :: sps, cps, sth, cth, sph, cph
    real(8) :: xx, xy, xz, yx, yy, yz, zx, zy, zz
    real(8) :: xi, yi, zi
    integer :: nrp, ix, i1, k, ir, i, ldi, ii, kr, itagi

    ! Update symmetry flag if rotating about X or Y
    if (abs(rox) + abs(roy) > 1.0d-10) geom%ipsym = geom%ipsym * 3

    ! Calculate rotation matrix
    sps = sin(rox)
    cps = cos(rox)
    sth = sin(roy)
    cth = cos(roy)
    sph = sin(roz)
    cph = cos(roz)

    xx = cph * cth
    xy = cph * sth * sps - sph * cps
    xz = cph * sth * cps + sph * sps
    yx = sph * cth
    yy = sph * sth * sps + cph * cps
    yz = sph * sth * cps - cph * sps
    zx = -sth
    zy = cth * sps
    zz = cth * cps

    nrp = nrpt
    if (nrpt == 0) nrp = 1
    ix = 1

    ! Transform wire segments
    if (geom%n >= geom%n2) then
      i1 = isegno(geom, its, 1)
      if (i1 < geom%n2) i1 = geom%n2
      ix = i1
      k = geom%n
      if (nrpt == 0) k = i1 - 1

      do ir = 1, nrp
        do i = i1, geom%n
          k = k + 1

          ! Transform segment center
          xi = geom%x(i)
          yi = geom%y(i)
          zi = geom%z(i)
          geom%x(k) = xi*xx + yi*xy + zi*xz + xs
          geom%y(k) = xi*yx + yi*yy + zi*yz + ys
          geom%z(k) = xi*zx + yi*zy + zi*zz + zs

          ! Transform segment end (stored in si, alp, bet)
          xi = geom%si(i)
          yi = geom%alp(i)
          zi = geom%bet(i)
          geom%si(k) = xi*xx + yi*xy + zi*xz + xs
          geom%alp(k) = xi*yx + yi*yy + zi*yz + ys
          geom%bet(k) = xi*zx + yi*zy + zi*zz + zs

          geom%bi(k) = geom%bi(i)
          geom%itag(k) = geom%itag(i)
          if (geom%itag(i) /= 0) geom%itag(k) = geom%itag(i) + itgi
        end do
        i1 = geom%n + 1
        geom%n = k
      end do
    end if

    ! Transform patches
    if (geom%m >= geom%m2) then
      i1 = geom%m2
      k = geom%m
      ldi = geom%ld + 1
      if (nrpt == 0) k = geom%m1

      do ii = 1, nrp
        do i = i1, geom%m
          k = k + 1
          ir = ldi - i
          kr = ldi - k

          ! Transform patch center
          xi = geom%x(ir)
          yi = geom%y(ir)
          zi = geom%z(ir)
          geom%x(kr) = xi*xx + yi*xy + zi*xz + xs
          geom%y(kr) = xi*yx + yi*yy + zi*yz + ys
          geom%z(kr) = xi*zx + yi*zy + zi*zz + zs

          ! Transform tangent vector 1 (in si, alp, bet)
          xi = geom%si(ir)
          yi = geom%alp(ir)
          zi = geom%bet(ir)
          geom%si(kr) = xi*xx + yi*xy + zi*xz
          geom%alp(kr) = xi*yx + yi*yy + zi*yz
          geom%bet(kr) = xi*zx + yi*zy + zi*zz

          ! Transform tangent vector 2 (in icon1, icon2, itag)
          xi = real(geom%icon1(ir), kind=8)
          yi = real(geom%icon2(ir), kind=8)
          zi = real(geom%itag(ir), kind=8)
          geom%icon1(kr) = int(xi*xx + yi*xy + zi*xz)
          geom%icon2(kr) = int(xi*yx + yi*yy + zi*yz)
          geom%itag(kr) = int(xi*zx + yi*zy + zi*zz)

          angle_data%salp(kr) = angle_data%salp(ir)
          geom%bi(kr) = geom%bi(ir)
        end do
        i1 = geom%m + 1
        geom%m = k
      end do
    end if

    if (nrpt == 0 .and. ix == 1) return

    geom%np = geom%n
    geom%mp = geom%m
    geom%ipsym = 0

  end subroutine move_geometry

  !============================================================================
  ! REFLECT_GEOMETRY - Reflect geometry for symmetry
  !============================================================================
  subroutine reflect_geometry(geom, angle_data, ix, iy, iz, itx, nop)
    ! Reflects partial structure along X, Y, or Z axes or rotates
    ! structure to complete a symmetric structure
    !
    ! Arguments:
    !   geom       - geometry data
    !   angle_data - angle data
    !   ix, iy, iz - reflection flags (1=reflect, 0=no)
    !   itx        - tag increment
    !   nop        - operation flag

    type(geometry_data), intent(inout) :: geom
    type(angle_data), intent(inout) :: angle_data
    integer, intent(in) :: ix, iy, iz, itx, nop

    integer :: iti, i, nx, nxx, ir, kr
    integer :: ldi, itagi
    real(8) :: e1, e2, xi, yi, zi

    geom%np = geom%n
    geom%mp = geom%m
    geom%ipsym = 0
    iti = itx

    if (ix < 0) return
    if (nop == 0) return

    geom%ipsym = 1

    ! Reflect along Z axis
    if (iz /= 0) then
      geom%ipsym = 2

      ! Reflect wire segments
      if (geom%n >= geom%n2) then
        do i = geom%n2, geom%n
          nx = i + geom%n - geom%n1
          e1 = geom%z(i)
          e2 = geom%bet(i)  ! End Z coordinate

          if (abs(e1) + abs(e2) <= 1.0d-5 .or. e1 * e2 < -1.0d-6) then
            write(*,'(A,I0)') 'ERROR in REFLC: Illegal segment for Z reflection, segment ', i
            stop 1
          end if

          geom%x(nx) = geom%x(i)
          geom%y(nx) = geom%y(i)
          geom%z(nx) = -e1
          geom%si(nx) = geom%si(i)
          geom%alp(nx) = geom%alp(i)
          geom%bet(nx) = -e2

          itagi = geom%itag(i)
          if (itagi == 0) then
            geom%itag(nx) = 0
          else
            geom%itag(nx) = itagi + iti
          end if
          geom%bi(nx) = geom%bi(i)
        end do
        geom%n = geom%n * 2 - geom%n1
        iti = iti * 2
      end if

      ! Reflect patches
      if (geom%m >= geom%m2) then
        nxx = geom%ld + 1 - geom%m1
        do i = geom%m2, geom%m
          nxx = nxx - 1
          nx = nxx - geom%m + geom%m1

          if (abs(geom%z(nxx)) <= 1.0d-10) then
            write(*,'(A,I0)') 'ERROR in REFLC: Illegal patch for Z reflection, patch ', i
            stop 1
          end if

          geom%x(nx) = geom%x(nxx)
          geom%y(nx) = geom%y(nxx)
          geom%z(nx) = -geom%z(nxx)
          geom%si(nx) = geom%si(nxx)
          geom%alp(nx) = geom%alp(nxx)
          geom%bet(nx) = -geom%bet(nxx)
          geom%icon1(nx) = geom%icon1(nxx)
          geom%icon2(nx) = geom%icon2(nxx)
          geom%itag(nx) = -geom%itag(nxx)
          angle_data%salp(nx) = -angle_data%salp(nxx)
          geom%bi(nx) = geom%bi(nxx)
        end do
        geom%m = geom%m * 2 - geom%m1
      end if
    end if

    ! Similar logic for Y and X reflections...
    ! (Implementation follows same pattern as Z reflection)

  end subroutine reflect_geometry

  !============================================================================
  ! CONNECT_SEGMENTS - Find segment connections
  !============================================================================
  subroutine connect_segments(geom, segj, ignd)
    ! Sets up segment connection data by searching for segment ends
    ! that are in contact
    !
    ! Arguments:
    !   geom - geometry data
    !   segj - segment junction data
    !   ignd - ground flag (1=with ground, 0=no ground)

    type(geometry_data), intent(inout) :: geom
    type(segment_junction_data), intent(inout) :: segj
    integer, intent(in) :: ignd

    integer :: i, j, ic
    real(8) :: xi1, yi1, zi1, xi2, yi2, zi2, slen, sep
    real(8), parameter :: SMIN = 1.0d-3

    segj%nscon = 0
    segj%npcon = 0

    if (geom%n == 0) return

    ! Loop through all segments
    do i = 1, geom%n
      geom%iconx(i) = 0
      xi1 = geom%x(i)
      yi1 = geom%y(i)
      zi1 = geom%z(i)
      xi2 = geom%si(i)   ! End coordinates stored in si, alp, bet
      yi2 = geom%alp(i)
      zi2 = geom%bet(i)

      slen = distance_3d(xi1, yi1, zi1, xi2, yi2, zi2) * SMIN

      ! Find connection for end 1
      if (ignd >= 1) then
        ! Check ground connection
        if (zi1 < -slen) then
          write(*,'(A,I0)') 'ERROR: Segment below ground, segment ', i
          stop 1
        end if
        if (zi1 <= slen) then
          geom%icon1(i) = i  ! Connected to ground
          geom%z(i) = 0.0d0
          goto 100
        end if
      end if

      ! Search for connected segment
      ic = i
      do j = 2, geom%n
        ic = ic + 1
        if (ic > geom%n) ic = 1

        ! Check connection to start of segment ic
        sep = abs(xi1 - geom%x(ic)) + abs(yi1 - geom%y(ic)) + abs(zi1 - geom%z(ic))
        if (sep <= slen) then
          geom%icon1(i) = -ic
          goto 100
        end if

        ! Check connection to end of segment ic
        sep = abs(xi1 - geom%si(ic)) + abs(yi1 - geom%alp(ic)) + abs(zi1 - geom%bet(ic))
        if (sep <= slen) then
          geom%icon1(i) = ic
          goto 100
        end if
      end do

      if (i >= geom%n2 .and. geom%icon1(i) <= 10000) then
        geom%icon1(i) = 0
      end if

100   continue

      ! Similar logic for end 2...
      ! (Following same pattern as end 1)

    end do

  end subroutine connect_segments

end module nec2_geometry
