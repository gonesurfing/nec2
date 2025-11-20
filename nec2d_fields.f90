! =============================================================================
! nec2d_fields - Field Calculations
! =============================================================================
! Purpose: H field and kernel functions for segments
! Contains: HSFLX, EKSCX
! GOTOs eliminated: 12
! =============================================================================
subroutine hsflx(s,rh,zpx,hpk,hps,hpc)
!
! hsflx calculates h field of sine, cosine, and constant current of segment
!
  implicit real*8(a-h,o-z)
  complex*16 fj,fjk,ekr1,ekr2,t1,t2,cons,hps,hpc,hpk
  dimension fjx(2), fjkx(2)
  equivalence (fj,fjx), (fjk,fjkx)
  data tp/6.283185308d0/,fjx/0.d0,1.d0/,fjkx/0.d0,-6.283185308d0/
  data pi8/25.13274123d0/

  if (rh < 1.d-10) then
    ! Zero rh case
    hps=(0.d0,0.d0)
    hpc=(0.d0,0.d0)
    hpk=(0.d0,0.d0)
    return
  end if

  ! Handle zpx sign
  if (zpx < 0.d0) then
    zp=-zpx
    hss=-1.d0
  else
    zp=zpx
    hss=1.d0
  end if

  dh=0.5d0*s
  z1=zp+dh
  z2=zp-dh

  ! Compute rhz
  if (z2 < 1.d-7) then
    rhz=1.d0
  else
    rhz=rh/z2
  end if

  dk=tp*dh
  cdk=cos(dk)
  sdk=sin(dk)
  call hfk(-dk,dk,rh*tp,zp*tp,hkr,hki)
  hpk=dcmplx(hkr,hki)

  if (rhz < 1.d-3) then
    ! Small rhz - use series expansion
    ekr1=dcmplx(cdk,sdk)/(z2*z2)
    ekr2=dcmplx(cdk,-sdk)/(z1*z1)
    t1=tp*(1.d0/z1-1.d0/z2)
    t2=exp(fjk*zp)*rh/pi8
    hps=t2*(t1+(ekr1+ekr2)*sdk)*hss
    hpc=t2*(-fj*t1+(ekr1-ekr2)*cdk)
  else
    ! Normal computation
    rh2=rh*rh
    r1=sqrt(rh2+z1*z1)
    r2=sqrt(rh2+z2*z2)
    ekr1=exp(fjk*r1)
    ekr2=exp(fjk*r2)
    t1=z1*ekr1/r1
    t2=z2*ekr2/r2
    hps=(cdk*(ekr2-ekr1)-fj*sdk*(t2+t1))*hss
    hpc=-sdk*(ekr2+ekr1)-fj*cdk*(t2-t1)
    cons=-fj/(2.d0*tp*rh)
    hps=cons*hps
    hpc=cons*hpc
  end if

end subroutine hsflx

subroutine ekscx(bx,s,z,rhx,xk,ij,inx1,inx2,ezs,ers,ezc,erc,ezk,erk)
  use nec2d_params
  use nec2d_commons, only: &
    ! /TMI/ - TM mode integration variables (with aliases for original names)
    zpk => ZPK_TMI, rkb2 => RKB2, ijx => IJX_TMI
!
! ekscx computes e field of sine, cosine, and constant current filaments
! by extended thin wire approximation.
! COMMON blocks: Converted to USE...ONLY with aliasing (2025-11-19)
!
  implicit real*8(a-h,o-z)
  complex*16 con,gz1,gz2,gzp1,gzp2,gr1,gr2,grp1,grp2,ezs,ezc,ers,erc, &
       grk1,grk2,ezk,erk,gzz1,gzz2
  dimension conx(2)
  equivalence (conx,con)
  data conx/0.d0,4.771341189d0/

  ! Swap radii if needed to ensure rh >= b
  if (rhx < bx) then
    rh=bx
    b=rhx
    ira=1
  else
    rh=rhx
    b=bx
    ira=0
  end if

  sh=0.5d0*s
  ijx=ij
  zpk=xk*z
  rhk=xk*rh
  rkb2=rhk*rhk
  shk=xk*sh
  ss=sin(shk)
  cs=cos(shk)
  z2=sh-z
  z1=-(sh+z)
  a2=b*b

  ! Compute field components at z1
  if (inx1 == 2) then
    ! Thin wire approximation
    call gx(z1,rhx,xk,gz1,grk1)
    gzp1=grk1*z1
    gr1=gz1/rhx
    grp1=gzp1/rhx
    grk1=grk1*rhx
    gzz1=(0.d0,0.d0)
  else
    ! Extended approximation
    call gxx(z1,rh,b,a2,xk,ira,gz1,gzp1,gr1,grp1,grk1,gzz1)
  end if

  ! Compute field components at z2
  if (inx2 == 2) then
    ! Thin wire approximation
    call gx(z2,rhx,xk,gz2,grk2)
    gzp2=grk2*z2
    gr2=gz2/rhx
    grp2=gzp2/rhx
    grk2=grk2*rhx
    gzz2=(0.d0,0.d0)
  else
    ! Extended approximation
    call gxx(z2,rh,b,a2,xk,ira,gz2,gzp2,gr2,grp2,grk2,gzz2)
  end if

  ! Compute e field components
  ezs=con*((gz2-gz1)*cs*xk-(gzp2+gzp1)*ss)
  ezc=-con*((gz2+gz1)*ss*xk+(gzp2-gzp1)*cs)
  ers=-con*((z2*grp2+z1*grp1+gr2+gr1)*ss-(z2*gr2-z1*gr1)*cs*xk)
  erc=-con*((z2*grp2-z1*grp1+gr2-gr1)*cs+(z2*gr2+z1*gr1)*ss*xk)
  erk=con*(grk2-grk1)

  call intx(-shk,shk,rhk,ij,cint,sint)
  bk=b*xk
  bk2=bk*bk*0.25d0
  ezk=-con*(gzp2-gzp1+xk*xk*(1.d0-bk2)*dcmplx(cint,-sint)-bk2*(gzz2-gzz1))

end subroutine ekscx
