! =============================================================================
! nec2d_solver - Matrix Solution Routines
! =============================================================================
! Purpose: Matrix partitioning, factorization, and solution
! Contains: FBLOCK, SOLGF, SOLVES
! GOTOs eliminated: 14
! =============================================================================
subroutine fblock (nrow,ncol,imax,irngf,ipsym)
! ============================================================================
! Modernized from: nec2dxs_integrated.f, lines 1763-1869
! GOTOs eliminated: 14 (converted to structured IF/THEN/ELSE control flow)
! Changes:
!   - Converted to free-form Fortran 90
!   - Eliminated all GOTO statements using structured control flow
!   - Improved logical flow with nested IF/ELSE blocks
!   - Error GOTOs (12,13) converted to inline error handling
!   - Conditional jumps converted to IF/THEN/ELSE structures
! ============================================================================
! FBLOCK SETS PARAMETERS FOR OUT-OF-CORE SOLUTION FOR THE PRIMARY MATRIX (A)
!
  use nec2d_params
  implicit real*8(a-h,o-z)

  complex*16 ssx,deter
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat,icasx, &
                  nbbx,npbx,nlbx,nbbl,npbl,nlbl
  common /smat/ ssx(16,16)

  logical :: need_symmetry_setup

  imx1=imax-irngf
  need_symmetry_setup = .false.

  ! Original GOTO 2 (line 1776) eliminated: restructured as IF/ELSE block
  if (nrow*ncol <= imx1) then
    ! Matrix fits in core - simple case
    nbloks=1
    npblk=nrow
    nlast=nrow
    imat=nrow*ncol
    ! Original GOTO 1 (line 1781) eliminated: restructured as IF/ELSE
    if (nrow == ncol) then
      icase=1
      return  ! Early return for symmetric in-core case
    else
      ! Label 1: Non-symmetric in-core case
      icase=2
      ! Original GOTO 5 (line 1785) eliminated: set flag to continue to symmetry setup
      need_symmetry_setup = .true.
    end if
  else
    ! Label 2: Matrix doesn't fit in core - out-of-core solution needed
    ! Original GOTO 3 (line 1786) eliminated: restructured as IF/ELSE
    if (nrow == ncol) then
      ! Symmetric matrix out-of-core partitioning
      icase=3
      npblk=imax/(2*ncol)
      npsym=imx1/ncol
      if (npsym < npblk) npblk=npsym
      ! Original GOTO 12 (line 1791) eliminated: structured error check
      if (npblk < 1) then
        ! Label 12: Error - insufficient storage
        write(*,17) nrow,ncol
        stop
      end if
      nbloks=(nrow-1)/npblk
      nlast=nrow-nbloks*npblk
      nbloks=nbloks+1
      nblsym=nbloks
      npsym=npblk
      nlsym=nlast
      imat=npblk*ncol
      write(*,14) nbloks,npblk,nlast
      ! Original GOTO 11 (line 1800) eliminated: direct RETURN
      return  ! Early return for symmetric out-of-core case
    else
      ! Label 3: Non-symmetric matrix out-of-core partitioning
      npblk=imax/ncol
      ! Original GOTO 12 (line 1802) eliminated: structured error check
      if (npblk < 1) then
        ! Label 12: Error - insufficient storage
        write(*,17) nrow,ncol
        stop
      end if
      if (npblk > nrow) npblk=nrow
      nbloks=(nrow-1)/npblk
      nlast=nrow-nbloks*npblk
      nbloks=nbloks+1
      write(*,14) nbloks,npblk,nlast
      ! Original GOTO 4 (line 1808) eliminated: restructured as IF/ELSE
      if (nrow*nrow <= imx1) then
        ! Label 4: Submatrices fit in core
        icase=4
        nblsym=1
        npsym=nrow
        nlsym=nrow
        imat=nrow*nrow
        write(*,15)
        ! Original GOTO 5 (line 1815) eliminated: set flag to continue to symmetry setup
        need_symmetry_setup = .true.
      else
        ! Submatrix partitioning needed
        icase=5
        npsym=imax/(2*nrow)
        nblsym=imx1/nrow
        if (nblsym < npsym) npsym=nblsym
        ! Original GOTO 12 (line 1820) eliminated: structured error check
        if (npsym < 1) then
          ! Label 12: Error - insufficient storage
          write(*,17) nrow,ncol
          stop
        end if
        nblsym=(nrow-1)/npsym
        nlsym=nrow-nblsym*npsym
        nblsym=nblsym+1
        write(*,16) nblsym,npsym,nlsym
        imat=npsym*nrow
        ! Fall through to symmetry setup (ICASE=5 always needs it)
        need_symmetry_setup = .true.
      end if
    end if
  end if

  ! Only execute symmetry setup for cases that need it (ICASE 2, 4, 5)
  if (need_symmetry_setup) then
    ! Label 5: Symmetry setup section
    nop=ncol/nrow
    ! Original GOTO 13 (line 1827) eliminated: structured error check
    if (nop*nrow /= ncol) then
      ! Label 13: Symmetry error
      write(*,18) nrow,ncol
      stop
    end if

    ! Original GOTO 7 (line 1828) eliminated: restructured as IF/ELSE
    if (ipsym > 0) then
      ! Label 7: SET UP SSX MATRIX FOR PLANE SYMMETRY
      kk=1
      ssx(1,1)=(1.,0.)
      ! Original GOTO 8 (line 1844) eliminated: structured error check
      if ((nop /= 2) .and. (nop /= 4) .and. (nop /= 8)) then
        stop
      end if
      ! Label 8: Continue plane symmetry setup
      ka=nop/2
      if (nop == 8) ka=3
      do k=1,ka
        do i=1,kk
          do j=1,kk
            deter=ssx(i,j)
            ssx(i,j+kk)=deter
            ssx(i+kk,j+kk)=-deter
            ssx(i+kk,j)=deter
          end do
        end do
        kk=kk*2
      end do
    else
      ! SET UP SSX MATRIX FOR ROTATIONAL SYMMETRY
      phaz=6.2831853072d+0/nop
      do i=2,nop
        do j=i,nop
          arg=phaz*dfloat(i-1)*dfloat(j-1)
          ssx(i,j)=dcmplx(cos(arg),sin(arg))
          ssx(j,i)=ssx(i,j)
        end do
      end do
      ! Original GOTO 11 (line 1838) eliminated: fall through to return
    end if
  end if

  ! Label 11: Normal return point
  return

14 format (//35h matrix file storage -  no. blocks=,i5, &
           19h columns per block=,i5,23h columns in last block=,i5)
15 format (25h submatricies fit in core)
16 format (38h submatrix partitioning -  no. blocks=,i5, &
           19h columns per block=,i5,23h columns in last block=,i5)
17 format (40h error - insufficient storage for matrix,2i5)
18 format (28h symmetry error - nrow,ncol=,2i5)

end subroutine fblock


!===============================================================================
! SOLGF - Solve for current in Numerical Green's Function procedure
!===============================================================================
! Modernized from: nec2dxs_integrated.f, lines 4120-4240
! Modernization: Tier 2 - Free-form F90, eliminate 10 GOTOs, keep IMPLICIT/COMMON
!
! GOTO eliminations:
!   1. Line 4137: IF (N2C.GT.0) GO TO 1 → IF-THEN-ELSE structure
!   2. Line 4140: GO TO 22 → Removed (end of THEN block)
!   3. Line 4141: IF (N1.EQ.N.OR.M1.EQ.0) GO TO 5 → IF-THEN for conditional skip
!   4. Line 4156: IF (NEQS.EQ.0) GO TO 7 → IF-THEN for conditional skip
!   5. Line 4180: IF (ICASX.GT.1) GO TO 11 → IF-THEN-ELSE structure
!   6. Line 4182: GO TO 13 → Removed (end of THEN block)
!   7. Line 4183: IF (ICASX.EQ.4) GO TO 12 → Nested IF-THEN-ELSE
!   8. Line 4188: GO TO 13 → Removed (end of THEN block)
!   9. Line 4221: IF (N1.EQ.N.OR.M1.EQ.0) GO TO 20 → IF-THEN for conditional skip
!  10. Line 4233: IF (NSCON.EQ.0) GO TO 22 → IF-THEN for conditional execution
!===============================================================================
subroutine solgf (a,b,c,d,xy,ip,np,n1,n,mp,m1,m,n1c,n2c,n2cz)
  ! DOUBLE PRECISION 6/4/85
  !
  use nec2d_params
  implicit real*8(a-h,o-z)
  ! SOLVE FOR CURRENT IN N.G.F. PROCEDURE
  complex*16 a,b,c,d,sum,xy,y
  common /scratm/ y(2*maxseg)
  common /segj/ ax(jmax),bx(jmax),cx(jmax),jco(jmax), &
    jsno,iscon(50),nscon,ipcon(10),npcon
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat, &
    icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  dimension a(1), b(n1c,1), c(n1c,1), d(n2cz,1), ip(1), xy(1)

  ifl=14
  if (icasx.gt.0) ifl=13

  ! GOTO 1,2 eliminated: Restructured as IF-THEN-ELSE
  if (n2c.gt.0) then
    ! N.G.F. SOLUTION

    ! GOTO 3 eliminated: Conditional execution with IF-THEN
    if (n1.ne.n .and. m1.ne.0) then
      ! REORDER EXCITATION ARRAY
      n2=n1+1
      jj=n+1
      npm=n+2*m1
      do i=n2,npm
        y(i)=xy(i)
      end do
      j=n1
      do i=jj,npm
        j=j+1
        xy(j)=y(i)
      end do
      do i=n2,n
        j=j+1
        xy(j)=y(i)
      end do
    end if

    neqs=nscon+2*npcon

    ! GOTO 4 eliminated: Conditional execution with IF-THEN
    if (neqs.ne.0) then
      neq=n1c+n2c
      neqs=neq-neqs+1
      ! COMPUTE INV(A)E1
      do i=neqs,neq
        xy(i)=(0.,0.)
      end do
    end if

    call solves (a,ip,xy,n1c,1,np,n1,mp,m1,13,ifl)
    ni=0
    npb=npbl

    ! COMPUTE E2-C(INV(A)E1)
    do jj=1,nbbl
      if (jj.eq.nbbl) npb=nlbl
      if (icasx.gt.1) read (15) ((c(i,j),i=1,n1c),j=1,npb)
      ii=n1c+ni
      do i=1,npb
        sum=(0.,0.)
        do j=1,n1c
          sum=sum+c(j,i)*xy(j)
        end do
        j=ii+i
        xy(j)=xy(j)-sum
      end do
      ni=ni+npbl
    end do
    if (icasx.gt.1) rewind 15
    jj=n1c+1

    ! COMPUTE INV(D)(E2-C(INV(A)E1)) = I2
    ! GOTO 5,6,7,8 eliminated: Restructured as nested IF-THEN-ELSE
    if (icasx.le.1) then
      call solve (n2c,d,ip(jj),xy(jj),n2c)
    else
      if (icasx.ne.4) then
        ni=n2c*n2c
        read (11) (b(j,1),j=1,ni)
        rewind 11
        call solve (n2c,b,ip(jj),xy(jj),n2c)
      else
        nblsys=nblsym
        npsys=npsym
        nlsys=nlsym
        icass=icase
        nblsym=nbbl
        npsym=npbl
        nlsym=nlbl
        icase=3
        rewind 11
        rewind 16
        call ltsolv (b,n2c,ip(jj),xy(jj),n2c,1,11,16)
        rewind 11
        rewind 16
        nblsym=nblsys
        npsym=npsys
        nlsym=nlsys
        icase=icass
      end if
    end if

    ni=0
    npb=npbl

    ! COMPUTE INV(A)E1-(INV(A)B)I2 = I1
    do jj=1,nbbl
      if (jj.eq.nbbl) npb=nlbl
      if (icasx.gt.1) read (14) ((b(i,j),i=1,n1c),j=1,npb)
      ii=n1c+ni
      do i=1,n1c
        sum=(0.,0.)
        do j=1,npb
          jp=ii+j
          sum=sum+b(i,j)*xy(jp)
        end do
        xy(i)=xy(i)-sum
      end do
      ni=ni+npbl
    end do
    if (icasx.gt.1) rewind 14

    ! GOTO 9 eliminated: Conditional execution with IF-THEN
    if (n1.ne.n .and. m1.ne.0) then
      ! REORDER CURRENT ARRAY
      do i=n2,npm
        y(i)=xy(i)
      end do
      jj=n1c+1
      j=n1
      do i=jj,npm
        j=j+1
        xy(j)=y(i)
      end do
      do i=n2,n1c
        j=j+1
        xy(j)=y(i)
      end do
    end if

    ! GOTO 10 eliminated: Conditional execution with IF-THEN
    if (nscon.ne.0) then
      j=neqs-1
      do i=1,nscon
        j=j+1
        jj=iscon(i)
        xy(jj)=xy(j)
      end do
    end if

  else
    ! NORMAL SOLUTION. NOT N.G.F.
    call solves (a,ip,xy,n1c,1,np,n,mp,m,13,ifl)
  end if

  return
end subroutine solgf


! ============================================================================
! Modernized SOLVES subroutine - Tier 2 conversion to F90 free form
! Source: nec2dxs_integrated.f, lines 4241-4362
! GOTOs eliminated: 11
! Modernization: Replaced all GOTO statements with structured control flow
! ============================================================================
subroutine solves (a,ip,b,neq,nrh,np,n,mp,m,ifl1,ifl2)
  use nec2d_params
  implicit real*8(a-h,o-z)
!
! SUBROUTINE SOLVES, FOR SYMMETRIC STRUCTURES, HANDLES THE
! TRANSFORMATION OF THE RIGHT HAND SIDE VECTOR AND SOLUTION OF THE
! MATRIX EQ.
!
  complex*16 a,b,y,sum,ssx
  common /smat/ ssx(16,16)
  common /scratm/ y(2*maxseg)
  common /matpar/ icase,nbloks,npblk,nlast,nblsym,npsym,nlsym,imat,&
    icasx,nbbx,npbx,nlbx,nbbl,npbl,nlbl
  dimension a(1), ip(1), b(neq,nrh)

  npeq=np+2*mp
  nop=neq/npeq
  fnop=nop
  fnorm=1./fnop
  nrow=neq
  if (icase.gt.3) nrow=npeq

  ! GOTO 1 eliminated: IF (NOP.EQ.1) GO TO 11 (line 4265)
  ! Replaced with IF-ELSE to skip forward transformation when NOP=1
  if (nop.ne.1) then
    do ic=1,nrh
      ! GOTO 2 eliminated: IF (N.EQ.0.OR.M.EQ.0) GO TO 6 (line 4267)
      ! Replaced with IF-ELSE to conditionally execute reordering
      if (n.ne.0 .and. m.ne.0) then
        do i=1,neq
          y(i)=b(i,ic)
        end do
        kk=2*mp
        ia=np
        ib=n
        j=np
        do k=1,nop
          ! GOTO 3 eliminated: IF (K.EQ.1) GO TO 3 (line 4275)
          ! GOTO 4 eliminated: IF (K.EQ.NOP) GO TO 5 (line 4280)
          ! Replaced with IF-ELSE to handle first/last iterations differently
          if (k.ne.1) then
            do i=1,np
              ia=ia+1
              j=j+1
              b(j,ic)=y(ia)
            end do
          end if
          if (k.ne.nop) then
            do i=1,kk
              ib=ib+1
              j=j+1
              b(j,ic)=y(ib)
            end do
          end if
        end do
      end if

      ! TRANSFORM MATRIX EQ. RHS VECTOR ACCORDING TO SYMMETRY MODES
      ! (label 6 in original code)
      do i=1,npeq
        do k=1,nop
          ia=i+(k-1)*npeq
          y(k)=b(ia,ic)
        end do
        sum=y(1)
        do k=2,nop
          sum=sum+y(k)
        end do
        b(i,ic)=sum*fnorm
        do k=2,nop
          ia=i+(k-1)*npeq
          sum=y(1)
          do j=2,nop
            sum=sum+y(j)*dconjg(ssx(k,j))
          end do
          b(ia,ic)=sum*fnorm
        end do
      end do
    end do
  end if

  ! GOTO 5 eliminated: IF (ICASE.LT.3) GO TO 12 (line 4303)
  ! Replaced with IF-ELSE to conditionally rewind files
  ! (label 11 in original code)
  if (icase.ge.3) then
    rewind ifl1
    rewind ifl2
  end if

  ! SOLVE EACH MODE EQUATION
  ! (label 12 in original code)
  do kk=1,nop
    ia=(kk-1)*npeq+1
    ib=ia
    ! GOTO 6 eliminated: IF (ICASE.NE.4) GO TO 13 (line 4312)
    ! Replaced with IF-ELSE to conditionally read matrix
    if (icase.eq.4) then
      i=npeq*npeq
      read (ifl1) (a(j),j=1,i)
      ib=1
    end if
    ! (label 13 in original code)
    ! GOTO 7 eliminated: IF (ICASE.EQ.3.OR.ICASE.EQ.5) GO TO 15 (line 4316)
    ! GOTO 8 eliminated: GO TO 16 (line 4319)
    ! Replaced with IF-ELSE-IF to select appropriate solver
    if (icase.eq.3 .or. icase.eq.5) then
      ! (label 15 in original code)
      call ltsolv (a,npeq,ip(ia),b(ia,1),neq,nrh,ifl1,ifl2)
    else
      do ic=1,nrh
        call solve (npeq,a(ib),ip(ia),b(ia,ic),nrow)
      end do
    end if
    ! (label 16 in original code)
  end do

  if (nop.eq.1) return

  ! INVERSE TRANSFORM THE MODE SOLUTIONS
  do ic=1,nrh
    do i=1,npeq
      do k=1,nop
        ia=i+(k-1)*npeq
        y(k)=b(ia,ic)
      end do
      sum=y(1)
      do k=2,nop
        sum=sum+y(k)
      end do
      b(i,ic)=sum
      do k=2,nop
        ia=i+(k-1)*npeq
        sum=y(1)
        do j=2,nop
          sum=sum+y(j)*ssx(k,j)
        end do
        b(ia,ic)=sum
      end do
    end do

    ! GOTO 9 eliminated: IF (N.EQ.0.OR.M.EQ.0) GO TO 26 (line 4341)
    ! Replaced with IF-ELSE to conditionally execute inverse reordering
    if (n.ne.0 .and. m.ne.0) then
      do i=1,neq
        y(i)=b(i,ic)
      end do
      kk=2*mp
      ia=np
      ib=n
      j=np
      do k=1,nop
        ! GOTO 10 eliminated: IF (K.EQ.1) GO TO 23 (line 4349)
        ! GOTO 11 eliminated: IF (K.EQ.NOP) GO TO 25 (line 4354)
        ! Replaced with IF-ELSE to handle first/last iterations differently
        if (k.ne.1) then
          do i=1,np
            ia=ia+1
            j=j+1
            b(ia,ic)=y(j)
          end do
        end if
        if (k.ne.nop) then
          do i=1,kk
            ib=ib+1
            j=j+1
            b(ib,ic)=y(j)
          end do
        end if
      end do
    end if
    ! (label 26 in original code)
  end do

  return
end subroutine solves
