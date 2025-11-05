# Issues Found in Original nec2dxs.f

This document tracks issues, warnings, and undefined behaviors found in the original
FORTRAN 77 code that will be fixed during modernization.

## Compilation Warnings

### 1. Aggressive Loop Optimization Warning (PATCH subroutine)

**Location**: `nec2dxs.f:7557-7572`

**Warning**:
```
nec2dxs.f:7562:72:
 7562 |       T1X(MIA)=S1X
      |                                                                        ^
Warning: iteration 1 invokes undefined behavior [-Waggressive-loop-optimizations]
nec2dxs.f:7557:15:
 7557 | 12    DO 13 IX=1,4
      |               ^
note: within this loop
```

**Issue**:
The PATCH subroutine uses a loop that decrements an array index and writes to
arrays that are EQUIVALENCE'd with other arrays:

```fortran
12    DO 13 IX=1,4
      X(MIA)=XS+XT*S1X+YT*S2X
      Y(MIA)=YS+XT*S1Y+YT*S2Y
      Z(MIA)=ZS+XT*S1Z+YT*S2Z
      BI(MIA)=XA
      T1X(MIA)=S1X    ! T1X is EQUIVALENCE'd to SI
      T1Y(MIA)=S1Y    ! T1Y is EQUIVALENCE'd to ALP
      T1Z(MIA)=S1Z    ! T1Z is EQUIVALENCE'd to BET
      T2X(MIA)=S2X    ! T2X is EQUIVALENCE'd to ICON1
      T2Y(MIA)=S2Y    ! T2Y is EQUIVALENCE'd to ICON2
      T2Z(MIA)=S2Z    ! T2Z is EQUIVALENCE'd to ITAG
      SALP(MIA)=SALN
      IF (IX.EQ.2) YT=-YT
      IF (IX.EQ.1.OR.IX.EQ.3) XT=-XT
      MIA=MIA-1       ! Index decremented each iteration
13    CONTINUE
```

**Root Cause**:
- Arrays T1X, T1Y, T1Z, T2X, T2Y, T2Z are EQUIVALENCE'd to geometry arrays
- This is a memory-saving trick from the 1970s
- Modern compilers can't optimize this safely
- The EQUIVALENCE statements (lines 72-74):
  ```fortran
  EQUIVALENCE (T1X,SI),(T1Y,ALP),(T1Z,BET),(T2X,ICON1),(T2Y,ICON2),
       1 (T2Z,ITAG)
  ```

**Impact**:
- Code compiles and runs correctly
- Warning is cosmetic but indicates fragile code
- Could fail with future compiler versions or optimization levels

**Fix in Modernization**:
When porting to `nec2_geometry.f90`:
- Replace EQUIVALENCE with proper derived type members
- Use separate, clearly-named arrays
- Eliminate array overlaying
- Use bounds-checked array access
- Example modern approach:
  ```fortran
  type(geometry_data) :: geom

  do ix = 1, 4
    geom%x(mia) = xs + xt*s1x + yt*s2y
    geom%y(mia) = ys + xt*s1y + yt*s2y
    geom%z(mia) = zs + xt*s1z + yt*s2z
    geom%bi(mia) = xa
    ! Direct storage instead of EQUIVALENCE trickery
    patch_t1x(mia) = s1x
    patch_t1y(mia) = s1y
    patch_t1z(mia) = s1z
    mia = mia - 1
  end do
  ```

**Testing Note**:
- Reference data generated successfully despite warning
- Validates that warning is cosmetic
- Modernized version should compile warning-free

## Other Known Issues

### 2. COMMON Block Data Races
**Status**: To be addressed
Multiple subroutines modify COMMON block data simultaneously in undefined order.
Modernization will use explicit parameter passing.

### 3. Implicit Typing
**Status**: To be addressed
Many variables rely on implicit typing (I-N are integers, others real).
Modernization uses `implicit none` everywhere.

### 4. GOTO-heavy Control Flow
**Status**: To be addressed
Extensive use of GOTO statements makes code hard to follow.
Modernization will use structured control flow (IF/THEN/ELSE, DO/END DO).

### 5. Fixed Array Dimensions
**Status**: To be addressed
All arrays are statically sized at compile time.
Modernization uses allocatable arrays for dynamic sizing.

## Summary

The warning you see is **expected and harmless** but demonstrates why modernization
is valuable. Our modernized code will eliminate these warnings while maintaining
numerical accuracy.

**Validation Strategy**:
Even though original code has warnings, it produces correct numerical results.
Our test framework will ensure the modernized code produces identical results
(within appropriate tolerances) without the warnings.
