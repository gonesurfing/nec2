! =============================================================================
! nec2d_matrix - Matrix Operations
! =============================================================================
! Purpose: Matrix setup and excitation routines
! Contains: FACTRS, COUPLE
! GOTOs eliminated: 9
! =============================================================================
subroutine factrs(np,nrow,a,ip,ix,iu1,iu2,iu3,iu4)
!
! factrs, for symmetric structure, transforms submatricies to form
! matricies of the symmetric modes and calls routine to factor
! matricies. if no symmetry, the routine is called to factor the
! complete matrix.
!
  implicit real*8(a-h,o-z)
  complex*16 a
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
       icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  dimension a(1), ip(nrow), ix(nrow)

  nop=nrow/np

  if (icase <= 2) then
    ! Simple factorization
    do kk = 1, nop
      ka=(kk-1)*np+1
      call factr(np,a(ka),ip(ka),nrow)
    end do
    return
  end if

  if (icase == 3) then
    ! Factor submatricies, or factor complete matrix if no symmetry exists
    call facio(a,nrow,nop,ix,iu1,iu2,iu3,iu4)
    call lunscr(a,nrow,nop,ip,ix,iu2,iu3,iu4)
    return
  end if

  ! ICASE > 3: Rewrite the matrices by columns on tape 13
  i2=2*npblk*nrow
  rewind iu2

  do k = 1, nop
    rewind iu1
    icols=npblk
    ir2=k*np
    ir1=ir2-np+1

    do l = 1, nbloks
      if (.not. (nbloks == 1 .and. k > 1)) then
        call blckin(a,iu1,1,i2,1,602)
      end if
      if (l == nbloks) icols=nlast

      irr1=ir1
      irr2=ir2
      do icoldx = 1, icols
        write(iu2) (a(i),i=irr1,irr2)
        irr1=irr1+nrow
        irr2=irr2+nrow
      end do
    end do
  end do

  rewind iu1
  rewind iu2

  if (icase /= 5) then
    ! ICASE == 4
    rewind iu3
    irr1=np*np

    do kk = 1, nop
      ir1=1-np
      ir2=0
      do i = 1, np
        ir1=ir1+np
        ir2=ir2+np
        read(iu2) (a(j),j=ir1,ir2)
      end do
      ka=(kk-1)*np+1
      call factr(np,a,ip(ka),np)
      write(iu3) (a(i),i=1,irr1)
    end do

    rewind iu2
    rewind iu3
  else
    ! ICASE == 5
    i2=2*npsym*np

    do kk = 1, nop
      j2=npsym
      do l = 1, nblsym
        if (l == nblsym) j2=nlsym
        ir1=1-np
        ir2=0
        do j = 1, j2
          ir1=ir1+np
          ir2=ir2+np
          read(iu2) (a(i),i=ir1,ir2)
        end do
        call blckot(a,iu1,1,i2,1,193)
      end do
    end do

    rewind iu1
    call facio(a,np,nop,ix,iu1,iu2,iu3,iu4)
    call lunscr(a,np,nop,ip,ix,iu2,iu3,iu4)
  end if

end subroutine factrs

subroutine couple(cur,wlam)
!
! couple computes the maximum coupling between pairs of segments.
!
  use nec2d_params
  implicit real*8(a-h,o-z)
  complex*16 y11a,y12a,cur,y11,y12,y22,yl,yin,zl,zin,rho,vqd,vsant,vqds
  common /yparm/ y11a(5),y12a(20),ncoup,icoup,nctag(5),ncseg(5)
  common /vsorc/ vqd(nsmax),vsant(nsmax),vqds(nsmax),ivqd(nsmax), &
       isant(nsmax),iqds(nsmax),nvqd,nsant,nqds
  dimension cur(1)

  if (nsant /= 1 .or. nvqd /= 0) return

  j=isegno(nctag(icoup+1),ncseg(icoup+1))
  if (j /= isant(1)) return

  icoup=icoup+1
  zin=vsant(1)
  y11a(icoup)=cur(j)*wlam/zin
  l1=(icoup-1)*(ncoup-1)

  do i = 1, ncoup
    if (i /= icoup) then
      k=isegno(nctag(i),ncseg(i))
      l1=l1+1
      y12a(l1)=cur(k)*wlam/zin
    end if
  end do

  if (icoup < ncoup) return

  write(*,6)
  npm1=ncoup-1

  do i = 1, npm1
    itt1=nctag(i)
    its1=ncseg(i)
    isg1=isegno(itt1,its1)
    l1=i+1

    do j = l1, ncoup
      itt2=nctag(j)
      its2=ncseg(j)
      isg2=isegno(itt2,its2)
      j1=j+(i-1)*npm1-1
      j2=i+(j-1)*npm1
      y11=y11a(i)
      y22=y11a(j)
      y12=0.5d0*(y12a(j1)+y12a(j2))
      yin=y12*y12
      dbc=abs(yin)
      c=dbc/(2.d0*dreal(y11)*dreal(y22)-dreal(yin))

      if (c >= 0.d0 .and. c <= 1.d0) then
        ! Valid coupling - compute maximum
        if (c < 0.01d0) then
          ! Small C approximation
          gmax=0.5d0*(c+0.25d0*c*c*c)
        else
          ! Standard formula
          gmax=(1.d0-sqrt(1.d0-c*c))/c
        end if

        rho=gmax*dconjg(yin)/dbc
        yl=((1.d0-rho)/(1.d0+rho)+1.d0)*dreal(y22)-y22
        zl=1.d0/yl
        yin=y11-yin/(y22+yl)
        zin=1.d0/yin
        dbc=db10(gmax)
        write(*,7) itt1,its1,isg1,itt2,its2,isg2,dbc,zl,zin
      else
        ! Error - coupling out of range
        write(*,8) itt1,its1,isg1,itt2,its2,isg2,c
      end if
    end do
  end do

6 format(///,36x,'- - - ISOLATION DATA - - -',//,6x,'- - COUPLING BETWEEN - -',8x, &
       'MAXIMUM',15x,'- - - FOR MAXIMUM COUPLING - - -', &
       /,12x,'SEG.',14x,'SEG.',3x,'COUPLING',4x,'LOAD IMPEDANCE (2ND SEG.)',7x, &
       'INPUT IMPEDANCE',/,2x,'TAG/SEG.',3x,'NO.',4x,'TAG/SEG.',3x,'NO.',6x, &
       '(DB)',8x,'REAL',9x,'IMAG.',9x,'REAL',9x,'IMAG.')
7 format(2(1x,i4,1x,i4,1x,i5,2x),f9.3,2x,1p,2(2x,e12.5,1x,e12.5))
8 format(2(1x,i4,1x,i4,1x,i5,2x),'**ERROR** COUPLING IS NOT BETWEEN 0 AND 1. (=', &
       1p,e12.5,')')

end subroutine couple
