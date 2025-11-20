! =============================================================================
! nec2d_simple - Simple Helper Routines
! =============================================================================
! Purpose: Basic utility functions and calculations
! Contains: FACIO, TEST, CABC, LTSOLV, LUNSCR
! =============================================================================
subroutine facio (a,nrow,nop,ip,iu1,iu2,iu3,iu4)
! facio controls i/o for out-of-core factorization
  implicit real*8(a-h,o-z)
  complex*16 a
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
    icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  dimension a(nrow,1), ip(nrow)
  real*8 t1,t2

  it=2*npsym*nrow
  nbm=nblsym-1
  i1=1
  i2=it
  i3=i2+1
  i4=2*it
  time=0.
  rewind iu1
  rewind iu2

  do kk = 1, nop
    ka=(kk-1)*nrow+1
    ifile3=iu1
    ifile4=iu3

    do ixblk1 = 1, nbm
      rewind iu3
      rewind iu4
      call blckin (a,ifile3,i1,i2,1,17)
      ixbp=ixblk1+1

      do ixblk2 = ixbp, nblsym
        call blckin (a,ifile3,i3,i4,1,18)
        call cpusec (t1)
        call lfactr (a,nrow,ixblk1,ixblk2,ip(ka))
        call cpusec (t2)
        time=time+t2-t1
        if (ixblk2 == ixbp) call blckot (a,iu2,i1,i2,1,19)
        if (ixblk1 == nbm .and. ixblk2 == nblsym) ifile4=iu2
        call blckot (a,ifile4,i3,i4,1,20)
      end do

      ifile3=iu3
      ifile4=iu4
      ! eliminated goto - swap file indices if ixblk1 is odd
      if ((ixblk1/2)*2 /= ixblk1) then
        ifile3=iu4
        ifile4=iu3
      end if
    end do
  end do

  rewind iu1
  rewind iu2
  rewind iu3
  rewind iu4
  write(*,4) time
  return

4 format (35h cp time taken for factorization = ,1p,e12.5)
end subroutine facio

subroutine test (f1r,f2r,tr,f1i,f2i,ti,dmin)
! test for convergence in numerical integration
  implicit real*8(a-h,o-z)

  den=abs(f2r)
  tr=abs(f2i)
  if (den < tr) den=tr
  if (den < dmin) den=dmin

  ! eliminated goto - handle zero denominator case
  if (den < 1.d-37) then
    tr=0.
    ti=0.
  else
    tr=abs((f1r-f2r)/den)
    ti=abs((f1i-f2i)/den)
  end if

  return
end subroutine test

subroutine cabc (curx)
! cabc computes coefficients of the constant (a), sine (b), and
! cosine (c) terms in the current interpolation functions for the
! current vector cur.
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  implicit real*8(a-h,o-z)
  complex*16 cur,curx,vqds,curd,ccj,vsant,vqd,cs1,cs2
  common /data/ x(maxseg),y(maxseg),z(maxseg),si(maxseg),bi(maxseg), &
    alp(maxseg),bet(maxseg),wlam,icon1(2*maxseg),icon2(2*maxseg), &
    itag(2*maxseg),iconx(maxseg),ld,n1,n2,n,np,m1,m2,m,mp,ipsym
  common /crnt/ air(maxseg),aii(maxseg),bir(maxseg),bii(maxseg), &
    cir(maxseg),cii(maxseg),cur(3*maxseg)
  common /segj/ ax(jmax),bx(jmax),cx(jmax),jco(jmax), &
    jsno,iscon(50),nscon,ipcon(10),npcon
  common /vsorc/ vqd(nsmax),vsant(nsmax),vqds(nsmax),ivqd(nsmax), &
    isant(nsmax),iqds(nsmax),nvqd,nsant,nqds
  common /angl/ salp(maxseg)
  dimension t1x(1), t1y(1), t1z(1), t2x(1), t2y(1), t2z(1)
  dimension curx(1), ccjx(2)
  equivalence (t1x,si), (t1y,alp), (t1z,bet), (t2x,icon1), (t2y,icon2), (t2z,itag)
  equivalence (ccj,ccjx)
  data tp/6.283185308d+0/,ccjx/0.,-0.01666666667d+0/

  ! eliminated goto - skip wire processing if n=0
  if (n /= 0) then
    do i = 1, n
      air(i)=0.
      aii(i)=0.
      bir(i)=0.
      bii(i)=0.
      cir(i)=0.
      cii(i)=0.
    end do

    do i = 1, n
      ar=dreal(curx(i))
      ai=dimag(curx(i))
      call tbf (i,1)
      do jx = 1, jsno
        j=jco(jx)
        air(j)=air(j)+ax(jx)*ar
        aii(j)=aii(j)+ax(jx)*ai
        bir(j)=bir(j)+bx(jx)*ar
        bii(j)=bii(j)+bx(jx)*ai
        cir(j)=cir(j)+cx(jx)*ar
        cii(j)=cii(j)+cx(jx)*ai
      end do
    end do

    ! eliminated goto - skip qds processing if nqds=0
    if (nqds /= 0) then
      do is = 1, nqds
        i=iqds(is)
        jx=icon1(i)
        icon1(i)=0
        call tbf (i,0)
        icon1(i)=jx
        sh=si(i)*.5
        curd=ccj*vqds(is)/((log(2.*sh/bi(i))-1.)* &
          (bx(jsno)*cos(tp*sh)+cx(jsno)*sin(tp*sh))*wlam)
        ar=dreal(curd)
        ai=dimag(curd)
        do jx = 1, jsno
          j=jco(jx)
          air(j)=air(j)+ax(jx)*ar
          aii(j)=aii(j)+ax(jx)*ai
          bir(j)=bir(j)+bx(jx)*ar
          bii(j)=bii(j)+bx(jx)*ai
          cir(j)=cir(j)+cx(jx)*ar
          cii(j)=cii(j)+cx(jx)*ai
        end do
      end do
    end if

    do i = 1, n
      curx(i)=dcmplx(air(i)+cir(i),aii(i)+cii(i))
    end do
  end if

  if (m == 0) return

  ! convert surface currents from t1,t2 components to x,y,z components
  k=ld-m
  jco1=n+2*m+1
  jco2=jco1+m

  do i = 1, m
    k=k+1
    jco1=jco1-2
    jco2=jco2-3
    cs1=curx(jco1)
    cs2=curx(jco1+1)
    curx(jco2)=cs1*t1x(k)+cs2*t2x(k)
    curx(jco2+1)=cs1*t1y(k)+cs2*t2y(k)
    curx(jco2+2)=cs1*t1z(k)+cs2*t2z(k)
  end do

  return
end subroutine cabc

subroutine ltsolv (a,nrow,ix,b,neq,nrh,ifl1,ifl2)
! ltsolv solves the matrix eq. y(r)*lu(t)=b(r) where (r) denotes row
! vector and lu(t) denotes the lu decomposition of the transpose of
! the original coefficient matrix.  the lu(t) decomposition is
! stored on tape 5 in blocks in ascending order and on file 3 in
! blocks of descending order.
  parameter (maxseg=3000, maxmat=3000)
  parameter (loadmx=maxseg/10)
  parameter (nsmax=120)
  parameter (netmx=240)
  parameter (jmax=60)
  parameter (iresrv=maxmat**2)
  implicit real*8(a-h,o-z)
  complex*16 a,b,y,sum
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
    icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  common /scratm/ y(2*maxseg)
  dimension a(nrow,nrow), b(neq,nrh), ix(neq)

  ! forward substitution
  i2=2*npsym*nrow

  do ixblk1 = 1, nblsym
    call blckin (a,ifl1,1,i2,1,121)
    k2=npsym
    if (ixblk1 == nblsym) k2=nlsym
    jst=(ixblk1-1)*npsym

    do ic = 1, nrh
      j=jst

      do k = 1, k2
        jm1=j
        j=j+1
        sum=(0.,0.)

        ! eliminated goto - skip loop if jm1 < 1
        if (jm1 >= 1) then
          do i = 1, jm1
            sum=sum+a(i,k)*b(i,ic)
          end do
        end if

        b(j,ic)=(b(j,ic)-sum)/a(j,k)
      end do
    end do
  end do

  ! backward substitution
  jst=nrow+1

  do ixblk1 = 1, nblsym
    call blckin (a,ifl2,1,i2,1,122)
    k2=npsym
    if (ixblk1 == 1) k2=nlsym

    do ic = 1, nrh
      kp=k2+1
      j=jst

      do k = 1, k2
        kp=kp-1
        jp1=j
        j=j-1
        sum=(0.,0.)

        ! eliminated goto - skip loop if nrow < jp1
        if (nrow >= jp1) then
          do i = jp1, nrow
            sum=sum+a(i,kp)*b(i,ic)
          end do
        end if

        b(j,ic)=b(j,ic)-sum
      end do
    end do

    jst=jst-k2
  end do

  ! unscramble solution
  do ic = 1, nrh
    do i = 1, nrow
      ixi=ix(i)
      y(ixi)=b(i,ic)
    end do

    do i = 1, nrow
      b(i,ic)=y(i)
    end do
  end do

  return
end subroutine ltsolv

subroutine lunscr (a,nrow,nop,ix,ip,iu2,iu3,iu4)
! s/r which unscrambles, scrambled factored matrix
  implicit real*8(a-h,o-z)
  complex*16 a,temp
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
    icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  dimension a(nrow,1), ip(nrow), ix(nrow)

  i1=1
  i2=2*npsym*nrow
  nm1=nrow-1
  rewind iu2
  rewind iu3
  rewind iu4

  do kk = 1, nop
    ka=(kk-1)*nrow

    do ixblk1 = 1, nblsym
      call blckin (a,iu2,i1,i2,1,121)
      k1=(ixblk1-1)*npsym+2

      ! eliminated goto - skip loops if nm1 < k1
      if (nm1 >= k1) then
        j2=0

        do k = k1, nm1
          if (j2 < npsym) j2=j2+1
          ipk=ip(k+ka)

          do j = 1, j2
            temp=a(k,j)
            a(k,j)=a(ipk,j)
            a(ipk,j)=temp
          end do
        end do
      end if

      call blckot (a,iu3,i1,i2,1,122)
    end do

    do ixblk1 = 1, nblsym
      backspace iu3
      if (ixblk1 /= 1) backspace iu3
      call blckin (a,iu3,i1,i2,1,123)
      call blckot (a,iu4,i1,i2,1,124)
    end do

    do i = 1, nrow
      ix(i+ka)=i
    end do

    do i = 1, nrow
      ipi=ip(i+ka)
      ixt=ix(i+ka)
      ix(i+ka)=ix(ipi+ka)
      ix(ipi+ka)=ixt
    end do

    ! eliminated goto - skip forward skip if nop = 1
    if (nop /= 1) then
      nb1=nblsym-1
      ! skip nb1 logical records forward
      do ixblk1 = 1, nb1
        call blckin (a,iu3,i1,i2,1,125)
      end do
    end if
  end do

  rewind iu2
  rewind iu3
  rewind iu4

  return
end subroutine lunscr
