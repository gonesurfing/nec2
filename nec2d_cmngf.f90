! =============================================================================
! nec2d_cmngf - Matrix NGF Filling
! =============================================================================
! Purpose: Fill interaction matrices B, C, and D for NGF solution
! Contains: CMNGF
! GOTOs eliminated: 38
! =============================================================================
subroutine cmngf (cb,cc,cd,nb,nc,nd,rkhx,iexkx)
  use nec2d_params
  use nec2d_commons, only: &
    ! /DATA/ - geometry and segment data (22 variables)
    x, y, z, si, bi, alp, bet, wlam, icon1, icon2, itag, iconx, &
    ld, n1, n2, n, np, m1, m2, m, mp, ipsym, &
    ! /ZLOAD/ - load impedances (3 variables)
    zarray, nload, nlodf, &
    ! /SEGJ/ - segment junction data (9 variables)
    ax, bx, cx, jco, jsno, iscon, nscon, ipcon, npcon, &
    ! /DATAJ/ - data for junction calculations (24 variables)
    s_j, b_j, xj, yj, zj, cabj, sabj, salpj, &
    exk, eyk, ezk, exs, eys, ezs, exc, eyc, ezc, &
    rkh, ind1, indd1, ind2, indd2, iexk, ipgnd, &
    ! /MATPAR/ - matrix parameters (15 variables)
    icase, nbloks, npblk, nlast, nblsym, npsym, nlsym, imat, &
    icasx, nbbx, npbx, nlbx, nbbl, npbl, nlbl
! ***
!     DOUBLE PRECISION 6/4/85
!     CMNGF FILLS INTERACTION MATRICIES B, C, AND D FOR N.G.F. SOLUTION

  implicit real*8(a-h,o-z)

  complex*16 cb,cc,cd
  dimension cb(nb,1), cc(nc,1), cd(nd,1)

  rkh=rkhx
  iexk=iexkx
  m1eq=2*m1
  m2eq=m1eq+1
  meq=2*m
  neqp=nd-npcon*2
  neqs=neqp-nscon
  neqsp=neqs+nc
  neqn=nc+n-n1
  itx=1
  if (nscon.gt.0) itx=2

  ! Initialize matrices and rewind files based on ICASX
  if (icasx.eq.1) then
    ! ICASX=1: Initialize all matrices
    do j=1,nd
      do i=1,nd
        cd(i,j)=(0.,0.)
      end do
      do i=1,nb
        cb(i,j)=(0.,0.)
        cc(i,j)=(0.,0.)
      end do
    end do
  else
    ! ICASX != 1: Rewind files
    rewind 12
    rewind 14
    rewind 15
    if (icasx.le.2) then
      ! ICASX=2: Also initialize matrices
      do j=1,nd
        do i=1,nd
          cd(i,j)=(0.,0.)
        end do
        do i=1,nb
          cb(i,j)=(0.,0.)
          cc(i,j)=(0.,0.)
        end do
      end do
    end if
  end if

  ist=n-n1+1
  it=npbx
  isv=-npbx

  ! ========================================================================
  ! LOOP THRU 24: FILLS B. FOR ICASX=1 OR 2 ALSO FILLS D(WW), D(WS)
  ! ========================================================================
  do iblk=1,nbbx
    isv=isv+npbx
    if (iblk.eq.nbbx) it=nlbx

    ! For ICASX >= 3: Zero out CB for this block
    if (icasx.ge.3) then
      do j=1,nd
        do i=1,it
          cb(i,j)=(0.,0.)
        end do
      end do
    end if

    i1=isv+1
    i2=isv+it
    in2=i2
    if (in2.gt.n1) in2=n1
    im1=i1-n1
    im2=i2-n1
    if (im1.lt.1) im1=1
    imx=1
    if (i1.le.n1) imx=n1-i1+2

    ! FILL B(WW),B(WS). FOR ICASX=1,2 FILL D(WW),D(WS)
    if (n2.le.n) then
      do j=n2,n
        call trio (j)

        ! Process JCO array
        do i=1,jsno
          jss=jco(i)
          if (jss.ge.n2) then
            ! SET JCO WHEN SOURCE IS NEW BASIS FUNCTION ON NEW SEGMENT
            jco(i)=jss-n1
          else
            ! SOURCE IS PORTION OF MODIFIED BASIS FUNCTION ON NEW SEGMENT
            jco(i)=neqs+iconx(jss)
          end if
        end do

        if (i1.le.in2) call cmww (j,i1,in2,cb,nb,cb,nb,0)
        if (im1.le.im2) call cmws (j,im1,im2,cb(imx,1),nb,cb,nb,0)

        if (icasx.le.2) then
          call cmww (j,n2,n,cd,nd,cd,nd,1)
          if (m2.le.m) call cmws (j,m2eq,meq,cd(1,ist),nd,cd,nd,1)

          ! LOADING IN D(WW)
          if (nload.ne.0) then
            ir=j-n1
            exk=zarray(j)
            do i=1,jsno
              jss=jco(i)
              cd(jss,ir)=cd(jss,ir)-(ax(i)+cx(i))*exk
            end do
          end if
        end if
      end do
    end if

    ! FILL B(WW)PRIME
    if (nscon.gt.0) then
      do i=1,nscon
        j=iscon(i)
        ! SOURCES ARE NEW OR MODIFIED BASIS FUNCTIONS ON OLD SEGMENTS WHICH
        ! CONNECT TO NEW SEGMENTS
        call trio (j)
        jss=0

        do ix=1,jsno
          ir=jco(ix)
          if (ir.ge.n2) then
            ir=ir-n1
          else
            ir=iconx(ir)
            if (ir.eq.0) cycle
            ir=neqs+ir
          end if
          jss=jss+1
          jco(jss)=ir
          ax(jss)=ax(ix)
          bx(jss)=bx(ix)
          cx(jss)=cx(ix)
        end do

        jsno=jss
        if (i1.le.in2) call cmww (j,i1,in2,cb,nb,cb,nb,0)
        if (im1.le.im2) call cmws (j,im1,im2,cb(imx,1),nb,cb,nb,0)

        ! SOURCE IS SINGULAR COMPONENT OF PATCH CURRENT THAT IS PART OF
        ! MODIFIED BASIS FUNCTION FOR OLD SEGMENT THAT CONNECTS TO A NEW
        ! SEGMENT ON END OPPOSITE PATCH.
        if (i1.le.in2) call cmsw (j,i,i1,in2,cb,cb,0,nb,-1)

        if (nlodf.ne.0) then
          jx=j-isv
          if (jx.ge.1.and.jx.le.it) then
            exk=zarray(j)
            do ix=1,jsno
              jss=jco(ix)
              cb(jx,jss)=cb(jx,jss)-(ax(ix)+cx(ix))*exk
            end do
          end if
        end if

        ! SOURCES ARE PORTIONS OF MODIFIED BASIS FUNCTION J ON OLD SEGMENTS
        ! EXCLUDING OLD SEGMENTS THAT DIRECTLY CONNECT TO NEW SEGMENTS.
        call tbf (j,1)
        jsx=jsno
        jsno=1
        ir=jco(1)
        jco(1)=neqs+i

        do ix=1,jsx
          if (ix.ne.1) then
            ir=jco(ix)
            ax(1)=ax(ix)
            bx(1)=bx(ix)
            cx(1)=cx(ix)
          end if

          if (ir.le.n1) then
            if (iconx(ir).eq.0) then
              if (i1.le.in2) call cmww (ir,i1,in2,cb,nb,cb,nb,0)
              if (im1.le.im2) call cmws (ir,im1,im2,cb(imx,1),nb,cb,nb,0)

              ! LOADING FOR B(WW)PRIME
              if (nlodf.ne.0) then
                jx=ir-isv
                if (jx.ge.1.and.jx.le.it) then
                  exk=zarray(ir)
                  jss=jco(1)
                  cb(jx,jss)=cb(jx,jss)-(ax(1)+cx(1))*exk
                end if
              end if
            end if
          end if
        end do
      end do
    end if

    ! FILL B(SS)PRIME TO SET OLD PATCH BASIS FUNCTIONS TO ZERO FOR
    ! PATCHES THAT CONNECT TO NEW SEGMENTS
    if (npcon.gt.0) then
      jss=neqp
      do i=1,npcon
        ix=ipcon(i)*2+n1-isv
        ir=ix-1
        jss=jss+1
        if (ir.gt.0.and.ir.le.it) cb(ir,jss)=(1.,0.)
        jss=jss+1
        if (ix.gt.0.and.ix.le.it) cb(ix,jss)=(1.,0.)
      end do
    end if

    ! FILL B(SW) AND B(SS)
    if (m2.le.m) then
      if (i1.le.in2) call cmsw (m2,m,i1,in2,cb(1,ist),cb,n1,nb,0)
      if (im1.le.im2) call cmss (m2,m,im1,im2,cb(imx,ist),nb,0)
    end if

    if (icasx.ne.1) then
      write (14) ((cb(i,j),i=1,it),j=1,nd)
    end if
  end do

  ! ========================================================================
  ! FILLING B COMPLETE. START ON C AND D
  ! ========================================================================
  it=npbl
  isv=-npbl

  do iblk=1,nbbl
    isv=isv+npbl
    isvv=isv+nc
    if (iblk.eq.nbbl) it=nlbl

    ! For ICASX >= 3: Zero out CC and CD for this block
    if (icasx.ge.3) then
      do j=1,it
        do i=1,nc
          cc(i,j)=(0.,0.)
        end do
        do i=1,nd
          cd(i,j)=(0.,0.)
        end do
      end do
    end if

    i1=isvv+1
    i2=isvv+it
    in1=i1-m1eq
    in2=i2-m1eq
    if (in2.gt.n) in2=n
    im1=i1-n
    im2=i2-n
    if (im1.lt.m2eq) im1=m2eq
    if (im2.gt.meq) im2=meq
    imx=1
    if (in1.le.in2) imx=neqn-i1+2

    ! SAME AS FIRST LOOP TO FILL D(WW) FOR ICASX GREATER THAN 2
    if (icasx.ge.3.and.n2.le.n) then
      do j=n2,n
        call trio (j)

        do i=1,jsno
          jss=jco(i)
          if (jss.ge.n2) then
            jco(i)=jss-n1
          else
            jco(i)=neqs+iconx(jss)
          end if
        end do

        if (in1.le.in2) call cmww (j,in1,in2,cd,nd,cd,nd,1)
        if (im1.le.im2) call cmws (j,im1,im2,cd(1,imx),nd,cd,nd,1)

        if (nload.ne.0) then
          ir=j-n1-isv
          if (ir.ge.1.and.ir.le.it) then
            exk=zarray(j)
            do i=1,jsno
              jss=jco(i)
              cd(jss,ir)=cd(jss,ir)-(ax(i)+cx(i))*exk
            end do
          end if
        end if
      end do
    end if

    ! FILL D(SW) AND D(SS)
    if (m2.le.m) then
      if (in1.le.in2) call cmsw (m2,m,in1,in2,cd(ist,1),cd,n1,nd,1)
      if (im1.le.im2) call cmss (m2,m,im1,im2,cd(ist,imx),nd,1)
    end if

    ! FILL C(WW),C(WS), D(WW)PRIME, AND D(WS)PRIME.
    if (n1.ge.1) then
      do j=1,n1
        call trio (j)

        if (nscon.gt.0) then
          do ix=1,jsno
            jss=jco(ix)
            if (jss.ge.n2) then
              jco(ix)=jss+m1eq
            else
              ir=iconx(jss)
              if (ir.ne.0) jco(ix)=neqsp+ir
            end if
          end do
        end if

        if (in1.le.in2) call cmww (j,in1,in2,cc,nc,cd,nd,itx)
        if (im1.le.im2) call cmws (j,im1,im2,cc(1,imx),nc,cd(1,imx),nd,itx)
      end do

      ! FILL C(WW)PRIME
      if (nscon.gt.0) then
        do ix=1,nscon
          ir=iscon(ix)
          jss=neqs+ix-isv
          if (jss.gt.0.and.jss.le.it) cc(ir,jss)=(1.,0.)
        end do
      end if
    end if

    ! FILL C(SS)PRIME
    if (npcon.gt.0) then
      jss=neqp-isv
      do i=1,npcon
        ix=ipcon(i)*2+n1
        ir=ix-1
        jss=jss+1
        if (jss.gt.0.and.jss.le.it) cc(ir,jss)=(1.,0.)
        jss=jss+1
        if (jss.gt.0.and.jss.le.it) cc(ix,jss)=(1.,0.)
      end do
    end if

    ! FILL C(SW) AND C(SS)
    if (m1.ge.1) then
      if (in1.le.in2) call cmsw (1,m1,in1,in2,cc(n2,1),cc,0,nc,1)
      if (im1.le.im2) call cmss (1,m1,im1,im2,cc(n2,imx),nc,1)
    end if

    if (icasx.ne.1) then
      write (12) ((cd(j,i),j=1,nd),i=1,it)
      write (15) ((cc(j,i),j=1,nc),i=1,it)
    end if
  end do

  if(icasx.eq.1)return
  rewind 12
  rewind 14
  rewind 15
  return
end subroutine cmngf
