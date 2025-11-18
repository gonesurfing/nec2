!***********************************************************************
!                           NEC2D_IO.F90
!***********************************************************************
!
!     Input/Output Subroutines for NEC2D - MODERNIZED
!
!     Phase 2 Modernization Complete:
!     ✓ Free-form Fortran 90 format  
!     ✓ All 20 GOTO statements eliminated
!     ✓ Modern DO...END DO loops (no statement labels)
!     ✓ Structured control flow
!     • Kept IMPLICIT REAL*8 for COMMON block compatibility
!     • Kept COMMON blocks (convert to modules in Phase 4)
!
!***********************************************************************

subroutine readgm(inunit,code,i1,i2,r1,r2,r3,r4,r5,r6,r7)
  ! READGM reads a geometry record and parses it.
  implicit real*8(a-h,o-z)
  character*(*) code
  dimension intval(2), reaval(7)

  call parsit(inunit,2,7,code,intval,reaval,ieof)

  if (ieof < 0) code = 'GE'
  i1 = intval(1)
  i2 = intval(2)
  r1 = reaval(1)
  r2 = reaval(2)
  r3 = reaval(3)
  r4 = reaval(4)
  r5 = reaval(5)
  r6 = reaval(6)
  r7 = reaval(7)

end subroutine readgm


subroutine readmn(inunit,code,i1,i2,i3,i4,f1,f2,f3,f4,f5,f6)
  ! READMN reads a control record and parses it.
  implicit real*8(a-h,o-z)
  character*(*) code
  dimension intval(4), reaval(6)

  call parsit(inunit,4,6,code,intval,reaval,ieof)

  if (ieof < 0) code = 'EN'
  i1 = intval(1)
  i2 = intval(2)
  i3 = intval(3)
  i4 = intval(4)
  f1 = reaval(1)
  f2 = reaval(2)
  f3 = reaval(3)
  f4 = reaval(4)
  f5 = reaval(5)
  f6 = reaval(6)

end subroutine readmn


subroutine parsit(inunit,maxint,maxrea,cmnd,intfld,reafld,ieof)
  ! PARSIT reads an input record and parses it.
  ! MODERNIZED: Eliminated 3 GOTOs (143, 175, 190)
  implicit real*8(a-h,o-z)
  character ngfnam*80
  common /ngfnam/ngfnam
  character cmnd*2, buffer*20, rec*80
  integer intfld(maxint)
  integer bgnfld(12), endfld(12), totcol, totfld
  logical fldtrm
  dimension reafld(maxrea)

  read(inunit, 8000, iostat=ieof) rec
  call upcase(rec, rec, totcol)

  ! Store opcode and clear field arrays
  cmnd = rec(1:2)
  do i = 1, maxint
    intfld(i) = 0
  end do
  do i = 1, maxrea
    reafld(i) = 0.0d0
  end do
  do i = 1, 12
    bgnfld(i) = 0
    endfld(i) = 0
  end do

  ! Find field boundaries
  totfld = 0
  fldtrm = .false.
  last = maxrea + maxint
  do j = 3, totcol
    k = ichar(rec(j:j))
    
    if (k == 33) then  ! End of line comment '!'
      if (fldtrm) endfld(totfld) = j - 1
      exit  ! ELIMINATED GO TO 5000
    else if (k == 32 .or. k == 44) then  ! Space or comma
      if (fldtrm) then
        endfld(totfld) = j - 1
        fldtrm = .false.
      end if
    else if (.not. fldtrm) then
      totfld = totfld + 1
      fldtrm = .true.
      bgnfld(totfld) = j
    end if
  end do

  if (fldtrm) endfld(totfld) = totcol

  ! Check field limits
  if ((cmnd == 'WG') .or. (cmnd == 'GF')) then
    ngfnam = 'NGF2D.NEC'
  end if

  if (totfld == 0) then
    return
  else if (totfld > last) then
    write(*,8001)
    write(*,8004) rec
    stop 'CARD ERROR'  ! ELIMINATED GO TO 9010
  end if

  j = min(totfld, maxint)

  ! Parse integers
  do i = 1, j
    length = endfld(i) - bgnfld(i) + 1
    buffer = rec(bgnfld(i):endfld(i))
    if (((cmnd == 'WG') .or. (cmnd == 'GF')) .and. &
        (buffer(1:1) /= '0') .and. (buffer(1:1) /= '1')) then
      ngfnam = rec(bgnfld(i):endfld(i))
      return
    end if
    ind = index(buffer(1:length), '.')
    if (ind > 0 .and. ind < length) then  ! ELIMINATED GO TO 9000
      write(*,8002) i
      write(*,8004) rec
      stop 'CARD ERROR'
    end if
    if (ind == length) length = length - 1
    read(buffer(1:length), *, err=9000) intfld(i)
  end do

  ! Parse reals  
  if (totfld > maxint) then
    j = maxint + 1
    do i = j, totfld
      length = endfld(i) - bgnfld(i) + 1
      buffer = rec(bgnfld(i):endfld(i))
      ind = index(buffer(1:length), '.')
      if (ind == 0) then
        inde = index(buffer(1:length), 'E')
        length = length + 1
        if (inde == 0) then
          buffer(length:length) = '.'
        else
          buffer = buffer(1:inde-1) // '.' // buffer(inde:length-1)
        end if
      end if
      read(buffer(1:length), *, err=9100) reafld(i-maxint)
    end do
  end if
  return

  ! Error handling
9000 write(*,8002) i
  write(*,8004) rec
  stop 'CARD ERROR'

9100 i = i - maxint
  write(*,8003) i
  write(*,8004) rec
  stop 'CARD ERROR'

8000 format (a80)
8001 format (//,' ***** CARD ERROR - TOO MANY FIELDS IN RECORD')
8002 format (//,' ***** CARD ERROR - INVALID NUMBER AT INTEGER POSITION ',i1)
8003 format (//,' ***** CARD ERROR - INVALID NUMBER AT REAL POSITION ',i1)
8004 format (' ***** TEXT -->  ',a80)

end subroutine parsit


subroutine upcase(intext, outtxt, length)
  ! UPCASE converts text to upper case.
  implicit real*8(a-h,o-z)
  character*(*) intext, outtxt

  length = len(intext)
  do i = 1, length
    j = ichar(intext(i:i))
    if (j >= 96) j = j - 32
    outtxt(i:i) = char(j)
  end do

end subroutine upcase


subroutine prnt(in1,in2,in3,fl1,fl2,fl3,fl4,fl5,fl6,ctype)
  ! PRNT prints impedance loading data.
  implicit real*8(a-h,o-z)
  character ctype*(*), cint(3)*5, cflt(6)*13

  do i = 1, 3
    cint(i) = '     '
  end do

  if (in1 == 0 .and. in2 == 0 .and. in3 == 0) then
    cint(1) = '  ALL'
  else
    if (in1 /= 0) write(cint(1),90) in1
    if (in2 /= 0) write(cint(2),90) in2
    if (in3 /= 0) write(cint(3),90) in3
  end if

  do i = 1, 6
    cflt(i) = '     '
  end do

  if (abs(fl1) > 1.e-30) write(cflt(1),91) fl1
  if (abs(fl2) > 1.e-30) write(cflt(2),91) fl2
  if (abs(fl3) > 1.e-30) write(cflt(3),91) fl3
  if (abs(fl4) > 1.e-30) write(cflt(4),91) fl4
  if (abs(fl5) > 1.e-30) write(cflt(5),91) fl5
  if (abs(fl6) > 1.e-30) write(cflt(6),91) fl6
  write(*,92) (cint(i),i=1,3), (cflt(i),i=1,6), ctype

90 format(i5)
91 format(1p,e13.4)
92 format(/,3x,3a,3x,6a,3x,a)

end subroutine prnt


subroutine gfil(iprt)
  ! GFIL reads the N.G.F. file.
  ! MODERNIZED: Eliminated 8 GOTOs (30/31, 337, 358, 385/388, 390, 395, 402, 412)
  implicit real*8(a-h,o-z)
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  complex*16 cm,ssx,zrati,zrati2,t1,zarray,ar1,ar2,ar3,epscf,frati
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /cmb/ cm(iresrv)
  common /angl/ salp(maxseg)
  common /gnd/zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl, &
    ksymp,ifar,iperf
  common /ggrid/ ar1(11,10,4),ar2(17,5,4),ar3(9,8,4),epscf,dxa(3),dya(3), &
    xsa(3),ysa(3),nxa(3),nya(3)
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
    icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  common /smat/ ssx(16,16)
  common /zload/ zarray(maxseg),nload,nlodf
  common/save/epsr,sig,scrwlt,scrwrt,fmhz,ip(2*maxseg),kcom
  common/csave/com(19,5)
  character ngfnam*80
  common /ngfnam/ngfnam
  dimension t2x(1),t2y(1),t2z(1)
  equivalence (t2x,icon1),(t2y,icon2),(t2z,itag)
  data igfl/20/
  logical file_exists

  ! Check file exists (ELIMINATED GO TO 30/31)
  inquire(file=ngfnam, exist=file_exists)
  if (.not. file_exists) then
    write(*,*) 'ERROR: Cannot open NGF file'
    stop
  end if
  open(unit=igfl,file=ngfnam,form='UNFORMATTED',status='OLD')
  rewind igfl

  read (igfl) n1,np,m1,mp,wlam,fmhz,ipsym,ksymp,iperf,nradl,epsr,sig, &
              scrwlt,scrwrt,nlodf,kcom
  n = n1
  m = m1
  n2 = n1 + 1
  m2 = m1 + 1

  ! Read segment data (ELIMINATED GO TO 2)
  if (n1 > 0) then
    read (igfl) (x(i),i=1,n1),(y(i),i=1,n1),(z(i),i=1,n1)
    read (igfl) (si(i),i=1,n1),(bi(i),i=1,n1),(alp(i),i=1,n1)
    read (igfl) (bet(i),i=1,n1),(salp(i),i=1,n1)
    read (igfl) (icon1(i),i=1,n1),(icon2(i),i=1,n1)
    read (igfl) (itag(i),i=1,n1)
    if (nlodf /= 0) read (igfl) (zarray(i),i=1,n1)
    do i = 1, n1
      xi = x(i)*wlam
      yi = y(i)*wlam
      zi = z(i)*wlam
      dx = si(i)*0.5d0*wlam
      x(i) = xi - alp(i)*dx
      y(i) = yi - bet(i)*dx
      z(i) = zi - salp(i)*dx
      si(i) = xi + alp(i)*dx
      alp(i) = yi + bet(i)*dx
      bet(i) = zi + salp(i)*dx
      bi(i) = bi(i)*wlam
    end do
  end if

  ! Read patch data (ELIMINATED GO TO 4)
  if (m1 > 0) then
    j = ld - m1 + 1
    read (igfl) (x(i),i=j,ld),(y(i),i=j,ld),(z(i),i=j,ld)
    read (igfl) (si(i),i=j,ld),(bi(i),i=j,ld),(alp(i),i=j,ld)
    read (igfl) (bet(i),i=j,ld),(salp(i),i=j,ld)
    read (igfl) (t2x(i),i=j,ld),(t2y(i),i=j,ld)
    read (igfl) (t2z(i),i=j,ld)
    dx = wlam*wlam
    do i = j, ld
      x(i) = x(i)*wlam
      y(i) = y(i)*wlam
      z(i) = z(i)*wlam
      bi(i) = bi(i)*dx
    end do
  end if

  read (igfl) icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat
  if (iperf == 2) read (igfl) ar1,ar2,ar3,epscf,dxa,dya,xsa,ysa,nxa,nya
  neq = n1 + 2*m1
  npeq = np + 2*mp
  nop = neq/npeq
  if (nop > 1) read (igfl) ((ssx(i,j),i=1,nop),j=1,nop)
  read (igfl) (ip(i),i=1,neq),com

  ! Read matrix (ELIMINATED GO TO 5/10 and computed GO TO)
  if (icase <= 2) then
    iout = neq*npeq
    read (igfl) (cm(i),i=1,iout)
  else
    rewind 13
    if (icase == 4) then
      iout = npeq*npeq
      do k = 1, nop
        read (igfl) (cm(j),j=1,iout)
        write (13) (cm(j),j=1,iout)
      end do
    else
      iout = npsym*npeq*2
      nbl2 = 2*nblsym
      do iop = 1, nop
        do i = 1, nbl2
          call blckin(cm,igfl,1,iout,1,206)
          call blckot(cm,13,1,iout,1,205)
        end do
      end do
    end if
    rewind 13
  end if

  rewind igfl

  ! Write heading
  write(*,16)
  write(*,14)
  write(*,14)
  write(*,17)
  write(*,18) n1, m1
  if (nop > 1) write(*,19) nop
  write(*,20) imat, icase

  ! (ELIMINATED GO TO 11)
  if (icase >= 3) then
    nbl2 = neq*npeq
    write(*,21) nbl2
  end if

  write(*,22) fmhz
  if (ksymp == 2 .and. iperf == 1) write(*,23)
  if (ksymp == 2 .and. iperf == 0) write(*,27)
  if (ksymp == 2 .and. iperf == 2) write(*,28)
  if (ksymp == 2 .and. iperf /= 1) write(*,24) epsr, sig
  write(*,17)

  do j = 1, kcom
    write(*,15) (com(i,j),i=1,19)
  end do

  write(*,17)
  write(*,14)
  write(*,14)
  write(*,16)

  if (iprt == 0) return

  write(*,25)
  do i = 1, n1
    write(*,26) i,x(i),y(i),z(i),si(i),alp(i),bet(i)
  end do

14 format (5x,50h**************************************************, &
           34h**********************************)
15 format (5x,3h** ,19a4,3h **)
16 format (////)
17 format (5x,2h**,80x,2h**)
18 format (5x,29h** numerical green'S FUNCTION,53X,2H**,/, &
           5x,17h** no. segments =,i4,10x,13hno. patches =,i4,34x,2h**)
19 format (5x,27h** no. symmetric sections =,i4,51x,2h**)
20 format (5x,34h** n.g.f. matrix -  core storage =,i7, &
           23h complex numbers,  case,i2,16x,2h**)
21 format (5x,2h**,19x,13hmatrix size =,i7,16h complex numbers,25x,2h**)
22 format (5x,14h** frequency =,1p,e12.5,5h mhz.,51x,2h**)
23 format (5x,17h** perfect ground,65x,2h**)
24 format (5x,44h** ground parameters - dielectric constant =,1p, &
           e12.5,26x,2h**,/,5x,2h**,21x,14hconductivity =,e12.5, &
           8h mhos/m.,25x,2h**)
25 format (39x,31hnumerical green'S FUNCTION DATA,/, &
           41x,27hcoordinates of segment ends,/,51x,8h(meters),/, &
           5x,4hseg.,11x,19h- - - end one - - -,26x, &
           19h- - - end two - - -,/,6x,3hno.,6x,1hx,14x,1hy,14x,1hz, &
           14x,1hx,14x,1hy,14x,1hz)
26 format (1x,i7,1p,6e15.6)
27 format (5x,55h** finite ground.  reflection coefficient approximation, &
           27x,2h**)
28 format (5x,38h** finite ground.  sommerfeld solution,44x,2h**)

end subroutine gfil


subroutine gfout
  ! GFOUT writes the N.G.F. file.
  ! MODERNIZED: Eliminated 8 GOTOs (500/507, 525/528, 529/536, 539/547)
  implicit real*8(a-h,o-z)
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  complex*16 cm,ssx,zrati,zrati2,t1,zarray,ar1,ar2,ar3,epscf,frati
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /cmb/ cm(iresrv)
  common /angl/ salp(maxseg)
  common /gnd/zrati,zrati2,frati,t1,t2,cl,ch,scrwl,scrwr,nradl, &
    ksymp,ifar,iperf
  common /ggrid/ ar1(11,10,4),ar2(17,5,4),ar3(9,8,4),epscf,dxa(3),dya(3), &
    xsa(3),ysa(3),nxa(3),nya(3)
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
    icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  common /smat/ ssx(16,16)
  common /zload/ zarray(maxseg),nload,nlodf
  common/save/epsr,sig,scrwlt,scrwrt,fmhz,ip(2*maxseg),kcom
  common/csave/com(19,5)
  character ngfnam*80
  common /ngfnam/ngfnam
  dimension t2x(1),t2y(1),t2z(1)
  equivalence (t2x,icon1),(t2y,icon2),(t2z,itag)
  data igfl/20/

  open(unit=igfl,file=ngfnam,form='UNFORMATTED',status='UNKNOWN')
  neq = n + 2*m
  npeq = np + 2*mp
  nop = neq/npeq
  write (igfl) n,np,m,mp,wlam,fmhz,ipsym,ksymp,iperf,nradl,epsr, &
               sig,scrwlt,scrwrt,nload,kcom

  ! Write segment data (ELIMINATED GO TO 1)
  if (n > 0) then
    write (igfl) (x(i),i=1,n),(y(i),i=1,n),(z(i),i=1,n)
    write (igfl) (si(i),i=1,n),(bi(i),i=1,n),(alp(i),i=1,n)
    write (igfl) (bet(i),i=1,n),(salp(i),i=1,n)
    write (igfl) (icon1(i),i=1,n),(icon2(i),i=1,n)
    write (igfl) (itag(i),i=1,n)
    if (nload > 0) write (igfl) (zarray(i),i=1,n)
  end if

  ! Write patch data (ELIMINATED GO TO 2)
  if (m > 0) then
    j = ld - m + 1
    write (igfl) (x(i),i=j,ld),(y(i),i=j,ld),(z(i),i=j,ld)
    write (igfl) (si(i),i=j,ld),(bi(i),i=j,ld),(alp(i),i=j,ld)
    write (igfl) (bet(i),i=j,ld),(salp(i),i=j,ld)
    write (igfl) (t2x(i),i=j,ld),(t2y(i),i=j,ld)
    write (igfl) (t2z(i),i=j,ld)
  end if

  write (igfl) icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat
  if (iperf == 2) write (igfl) ar1,ar2,ar3,epscf,dxa,dya,xsa,ysa,nxa,nya
  if (nop > 1) write (igfl) ((ssx(i,j),i=1,nop),j=1,nop)
  write (igfl) (ip(i),i=1,neq),com

  ! Write matrix (ELIMINATED GO TO 3/12 and computed GO TO)
  if (icase <= 2) then
    iout = neq*npeq
    write (igfl) (cm(i),i=1,iout)
  else if (icase == 4) then
    rewind 13
    i = npeq*npeq
    do k = 1, nop
      read (13) (cm(j),j=1,i)
      write (igfl) (cm(j),j=1,i)
    end do
    rewind 13
  else
    rewind 13
    rewind 14
    if (icase /= 5) then
      iout = npblk*neq*2
      do i = 1, nbloks
        call blckin(cm,13,1,iout,1,201)
        call blckot(cm,igfl,1,iout,1,202)
      end do
      do i = 1, nbloks
        call blckin(cm,14,1,iout,1,203)
        call blckot(cm,igfl,1,iout,1,204)
      end do
    else
      iout = npsym*npeq*2
      do iop = 1, nop
        do i = 1, nblsym
          call blckin(cm,13,1,iout,1,205)
          call blckot(cm,igfl,1,iout,1,206)
        end do
        do i = 1, nblsym
          call blckin(cm,14,1,iout,1,207)
          call blckot(cm,igfl,1,iout,1,208)
        end do
      end do
    end if
    rewind 13
    rewind 14
  end if

  rewind igfl
  write(*,13) igfl, imat

13 format (///,44h ****numerical green'S FUNCTION FILE ON TAPE,I3, &
           5h****,/,5x,16hmatrix storage -,i7,16h complex numbers,///)

end subroutine gfout


subroutine blckot(ar,nunit,ix1,ix2,nblks,neof)
  ! blckot controls writing of matrix blocks.
  ! note: nblks and neof are intentionally unused here but kept for
  ! interface consistency with blckin (these subroutines were originally
  ! a single routine with an entry point)
  implicit real*8(a-h,o-z)
  complex*16 ar
  dimension ar(1)

  i1 = (ix1 + 1) / 2
  i2 = (ix2 + 1) / 2
  write (nunit) (ar(j),j=i1,i2)

end subroutine blckot


subroutine blckin(ar,nunit,ix1,ix2,nblks,neof)
  ! BLCKIN controls reading of matrix blocks.
  ! MODERNIZED: Converted from ENTRY to separate subroutine, eliminated label-sharing
  implicit real*8(a-h,o-z)
  complex*16 ar
  dimension ar(1)

  i1 = (ix1 + 1) / 2
  i2 = (ix2 + 1) / 2

  do i = 1, nblks
    read (nunit,end=3) (ar(j),j=i1,i2)
  end do
  return

3 write(*,4) nunit, nblks, neof
  if (neof /= 777) stop
  neof = 0

4 format (13h  eof on unit,i3,9h  nblks= ,i3,8h  neof= ,i5)

end subroutine blckin


subroutine reblk(b,bx,nb,nbx,n2c)
  ! REBLK reblocks array in N.G.F. solution.
  implicit real*8(a-h,o-z)
  complex*16 b,bx
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
    icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  dimension b(nb,1), bx(nbx,1)

  rewind 16
  nib = 0
  npb = npbl

  do ib = 1, nbbl
    if (ib == nbbl) npb = nlbl
    rewind 14
    nix = 0
    npx = npbx

    do ibx = 1, nbbx
      if (ibx == nbbx) npx = nlbx
      read (14) ((bx(i,j),i=1,npx),j=1,n2c)
      do i = 1, npx
        ix = i + nix
        do j = 1, npb
          b(ix,j) = bx(i,j+nib)
        end do
      end do
      nix = nix + npbx
    end do

    write (16) ((b(i,j),i=1,nb),j=1,npb)
    nib = nib + npbl
  end do

  rewind 14
  rewind 16

end subroutine reblk
