! =============================================================================
! nec2d_matrix2 - Matrix Filling Routines
! =============================================================================
! Purpose: Interaction matrix computation and filling
! Contains: CMSET, CMSS, FBNGF
! GOTOs eliminated: 22
! =============================================================================
subroutine cmset(nrow,cm,rkhx,iexkx)
!
! cmset sets up the complex structure matrix in the array cm
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)
  complex*16 cm,zarray,zaj,exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc,ssx, &
             d,deter
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
                alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
                itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
                  icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  common /smat/ ssx(16,16)
  common /scratm/ d(2*maxseg)
  common /zload/ zarray(maxseg),nload,nlodf
  common /segj/ ax(jmax),bx(jmax),cx(jmax),jco(jmax), &
                jsno,iscon(50),nscon,ipcon(10),npcon
  common /dataj/ s,b,xj,yj,zj,cabj,sabj,salpj,exk,eyk,ezk,exs,eys, &
                 ezs,exc,eyc,ezc,rkh,ind1,indd1,ind2,indd2,iexk,ipgnd
  dimension cm(nrow,1)

  mp2=2*mp
  npeq=np+mp2
  neq=n+2*m
  nop=neq/npeq
  if (icase > 2) rewind 11
  rkh=rkhx
  iexk=iexkx
  iout=2*npblk*nrow
  it=npblk

  ! Cycle over matrix blocks
  do ixblk1=1,nbloks
    isv=(ixblk1-1)*npblk
    if (ixblk1 == nbloks) it=nlast
    do i=1,nrow
      do j=1,it
        cm(i,j)=(0.d0,0.d0)
      end do
    end do
    i1=isv+1
    i2=isv+it
    in2=i2
    if (in2 > np) in2=np
    im1=i1-np
    im2=i2-np
    if (im1 < 1) im1=1
    ist=1
    if (i1 <= np) ist=np-i1+2

    ! Wire source loop (only if N > 0)
    if (n /= 0) then
      do j=1,n
        call trio (j)
        do i=1,jsno
          ij=jco(i)
          jco(i)=((ij-1)/np)*mp2+ij
        end do
        if (i1 <= in2) call cmww (j,i1,in2,cm,nrow,cm,nrow,1)
        if (im1 <= im2) call cmws (j,im1,im2,cm(1,ist),nrow,cm,nrow,1)

        ! Matrix elements modified by loading
        if (nload /= 0 .and. j <= np) then
          ipr=j-isv
          if (ipr >= 1 .and. ipr <= it) then
            zaj=zarray(j)
            do i=1,jsno
              jss=jco(i)
              cm(jss,ipr)=cm(jss,ipr)-(ax(i)+cx(i))*zaj
            end do
          end if
        end if
      end do
    end if

    ! Matrix elements for patch current sources (only if M > 0)
    if (m /= 0) then
      jm1=1-mp
      jm2=0
      jst=1-mp2
      do i=1,nop
        jm1=jm1+mp
        jm2=jm2+mp
        jst=jst+npeq
        if (i1 <= in2) call cmsw (jm1,jm2,i1,in2,cm(jst,1),cm,0,nrow,1)
        if (im1 <= im2) call cmss (jm1,jm2,im1,im2,cm(jst,ist),nrow,1)
      end do
    end if

    ! Process based on ICASE value
    if (icase == 1) then
      ! ICASE==1: Skip to end of block loop (no additional processing)
      continue
    else if (icase == 2) then
      ! ICASE==2: Combine elements for symmetry modes
      do i=1,it
        do j=1,npeq
          do k=1,nop
            ka=j+(k-1)*npeq
            d(k)=cm(ka,i)
          end do
          deter=d(1)
          do kk=2,nop
            deter=deter+d(kk)
          end do
          cm(j,i)=deter
          do k=2,nop
            ka=j+(k-1)*npeq
            deter=d(1)
            do kk=2,nop
              deter=deter+d(kk)*ssx(k,kk)
            end do
            cm(ka,i)=deter
          end do
        end do
      end do
    else if (icase == 3) then
      ! ICASE==3: Combine elements for symmetry modes, then write block
      do i=1,it
        do j=1,npeq
          do k=1,nop
            ka=j+(k-1)*npeq
            d(k)=cm(ka,i)
          end do
          deter=d(1)
          do kk=2,nop
            deter=deter+d(kk)
          end do
          cm(j,i)=deter
          do k=2,nop
            ka=j+(k-1)*npeq
            deter=d(1)
            do kk=2,nop
              deter=deter+d(kk)*ssx(k,kk)
            end do
            cm(ka,i)=deter
          end do
        end do
      end do
      ! Write block for out-of-core cases
      call blckot (cm,11,1,iout,1,31)
    end if
  end do

  if (icase > 2) rewind 11

end subroutine cmset

subroutine cmss(j1,j2,im1,im2,cm,nrow,itrp)
!
! cmss computes matrix elements for surface-surface interactions
!
  include 'NEC2D3000.INC'
  implicit real*8(a-h,o-z)
  complex*16 g11,g12,g21,g22,cm,exk,eyk,ezk,exs,eys,ezs,exc,eyc,ezc
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
       alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
       itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /angl/ salp(maxseg)
  common /dataj/ s,b,xj,yj,zj,cabj,sabj,salpj,exk,eyk,ezk,exs,eys, &
       ezs,exc,eyc,ezc,rkh,ind1,indd1,ind2,indd2,iexk,ipgnd
  dimension cm(nrow,1)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1)
  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), &
       (t2z,itag)
  equivalence (t1xj,cabj), (t1yj,sabj), (t1zj,salpj), (t2xj,b), (t2yj,ind1), &
       (t2zj,ind2)

  ldp=ld+1
  i1=(im1+1)/2
  i2=(im2+1)/2
  icomp=i1*2-3
  ii1=-1
  if (icomp+2 < im1) ii1=-2

  ! Loop over observation patches
  do i=i1,i2
    il=ldp-i
    icomp=icomp+2
    ii1=ii1+2
    ii2=ii1+1
    t1xi=t1x(il)*salp(il)
    t1yi=t1y(il)*salp(il)
    t1zi=t1z(il)*salp(il)
    t2xi=t2x(il)*salp(il)
    t2yi=t2y(il)*salp(il)
    t2zi=t2z(il)*salp(il)
    xi=x(il)
    yi=y(il)
    zi=z(il)
    jj1=-1

    ! Loop over source patches
    do j=j1,j2
      jl=ldp-j
      jj1=jj1+2
      jj2=jj1+1
      s=bi(jl)
      xj=x(jl)
      yj=y(jl)
      zj=z(jl)
      t1xj=t1x(jl)
      t1yj=t1y(jl)
      t1zj=t1z(jl)
      t2xj=t2x(jl)
      t2yj=t2y(jl)
      t2zj=t2z(jl)
      call hintg (xi,yi,zi)
      g11=-(t2xi*exk+t2yi*eyk+t2zi*ezk)
      g12=-(t2xi*exs+t2yi*eys+t2zi*ezs)
      g21=-(t1xi*exk+t1yi*eyk+t1zi*ezk)
      g22=-(t1xi*exs+t1yi*eys+t1zi*ezs)

      ! Conditional adjustment for diagonal elements
      if (i == j) then
        g11=g11-0.5d0
        g22=g22+0.5d0
      end if

      ! Choose normal or transposed fill
      if (itrp == 0) then
        ! Normal fill
        if (icomp >= im1) then
          cm(ii1,jj1)=g11
          cm(ii1,jj2)=g12
        end if
        if (icomp < im2) then
          cm(ii2,jj1)=g21
          cm(ii2,jj2)=g22
        end if
      else
        ! Transposed fill
        if (icomp >= im1) then
          cm(jj1,ii1)=g11
          cm(jj2,ii1)=g12
        end if
        if (icomp < im2) then
          cm(jj1,ii2)=g21
          cm(jj2,ii2)=g22
        end if
      end if
    end do
  end do

end subroutine cmss

subroutine fbngf(neq,neq2,iresrv,ib11,ic11,id11,ix11)
!
! fbngf sets the blocking parameters for the b, c, and d arrays for
! out-of-core storage
!
  implicit real*8(a-h,o-z)
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat,icasx, &
                  nbbx,npbx,nlbx,nbbl,npbl,nlbl

  iresx = iresrv - imat
  nbln = neq * neq2
  ndln = neq2 * neq2
  nbcd = 2 * nbln + ndln

  ! Determine which storage strategy to use
  if (nbcd <= iresx) then
    ! Case 1: All arrays fit in available memory
    icasx = 1
    ib11 = imat + 1
    ! Set simple blocking parameters
    nbbx = 1
    npbx = neq
    nlbx = neq
    nbbl = 1
    npbl = neq2
    nlbl = neq2
  else if (icase >= 3 .and. nbcd <= iresrv .and. nbln <= iresx) then
    ! Case 2: Alternative memory allocation strategy
    icasx = 2
    ib11 = 1
    ! Set simple blocking parameters
    nbbx = 1
    npbx = neq
    nlbx = neq
    nbbl = 1
    npbl = neq2
    nlbl = neq2
  else
    ! Case 3: Need blocking strategy
    if (icase < 3) then
      ir = iresx
    else
      ir = iresrv
    end if

    icasx = 3
    if (ndln > ir) icasx = 4
    nbcd = 2 * neq + neq2
    npbl = ir / nbcd
    nlbl = ir / (2 * neq2)
    if (nlbl < npbl) npbl = nlbl

    if (icase >= 3) then
      nlbl = iresx / neq
      if (nlbl < npbl) npbl = nlbl
    end if

    ! Check if we have enough memory
    if (npbl < 1) then
      write(*,7) iresrv, imat, neq, neq2
      stop
    end if

    ! Calculate blocking parameters
    nbbl = (neq2 - 1) / npbl
    nlbl = neq2 - nbbl * npbl
    nbbl = nbbl + 1
    nbln = neq * npbl
    ir = ir - nbln
    npbx = ir / neq2
    if (npbx > neq) npbx = neq
    nbbx = (neq - 1) / npbx
    nlbx = neq - nbbx * npbx
    nbbx = nbbx + 1
    ib11 = 1
    if (icase < 3) ib11 = imat + 1
  end if

  ! Common exit - calculate final parameters and write output
  ic11 = ib11 + nbln
  id11 = ic11 + nbln
  ix11 = imat + 1
  write(*,11) neq2
  if (icasx == 1) return
  write(*,8) icasx
  write(*,9) nbbx, npbx, nlbx
  write(*,10) nbbl, npbl, nlbl

7 format (55h error - insufficient storage for interaction matricies, &
          24h  iresrv,imat,neq,neq2 =,4i5)
8 format (48h file storage for new matrix sections -  icasx =,i2)
9 format (19h b filled by rows -,15x,12hno. blocks =,i3,3x, &
          16hrows per block =,i3,3x,20hrows in last block =,i3)
10 format (32h b by columns, c and d by rows -,2x,12hno. blocks =,i3, &
           4x,15hr/c per block =,i3,4x,19hr/c in last block =,i3)
11 format (//,35h n.g.f. - number of new unknowns is,i4)

end subroutine fbngf
