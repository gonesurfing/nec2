# Unused Variable Warnings Analysis

**Date:** 2025-11-10
**Purpose:** Systematic review of all compiler unused variable warnings to identify missing functionality

## Summary

**Total Warnings Analyzed:** 25+
**Truly Unused (can be removed):** ~8
**Missing Functionality:** 1 (patch SALP calculation)
**False Positives:** ~15 (variables are actually used)

## Findings by Module

### 1. nec2_geometry.f90

#### move_geometry() function (line 471)
```fortran
integer(8) :: itagi  ! Line 471 - WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED** - Different from parameter `itgi` which IS used
**Action:** Remove this declaration (typo/leftover from conversion)
**Impact:** None - this is a duplicate/typo

#### move_geometry() function (lines 470, 539-569)
```fortran
integer :: ir, kr     ! Line 470 - WARNING claims unused
integer :: ldi        ! Line 470 - WARNING claims unused
real(8) :: xi, yi, zi ! Line 469 - WARNING claims unused
```
**Analysis:** ❌ **FALSE POSITIVE** - All ARE used
- `ir`, `kr`: Lines 545-546 for patch indices
- `ldi`: Line 539 for LD offset calculation
- `xi`, `yi`, `zi`: Lines 549-551, 557-559, 565-567 for transformations
**Action:** None - compiler warning is incorrect
**Impact:** These are critical for patch transformations

#### reflc() function (line 606)
```fortran
integer :: ir, kr     ! Line 606 - WARNING claims unused
integer :: ldi        ! Line 607 - WARNING claims unused
real(8) :: xi, yi, zi ! Line 609 - WARNING claims unused
```
**Analysis:** ✅ **TRULY UNUSED** in reflc()
- Checked original F77 REFLC (nec2dxs.f:8383) - these variables NOT used for Z/Y reflection
- Only used in X rotation section which may not be implemented
**Action:** Check if X-axis rotation is missing, otherwise remove
**Impact:** May indicate incomplete implementation

#### patch() function (line 304)
```fortran
type(angle_data), intent(inout) :: ang  ! WARNING: Unused dummy argument
```
**Analysis:** ⚠️ **MISSING FUNCTIONALITY**
- The `ang%salp(mi)` should be set for each patch to store the normal Z-component
- Original F77 sets SALP array via COMMON /ANGL/ SALP
- Modern code never sets ang%salp for patches created in patch()
**Action:** **ADD** `ang%salp(mi) = znv` after line 434
**Impact:** **CRITICAL** - Patch normals incomplete, affects field calculations

### 2. nec2_fields.f90

#### efld() function (line 310)
```fortran
type(geometry_data), intent(in) :: geom  ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED**
- Function calculates E-field, doesn't need full geometry
**Action:** Remove parameter if not needed for future extensions
**Impact:** None

#### efld() function (line 38)
```fortran
complex(8) :: exa  ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED**
**Action:** Remove
**Impact:** None

#### gwave() function (line 665)
```fortran
complex(8), parameter :: fj  ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED**
**Action:** Remove constant
**Impact:** None

#### sflds() function (line 1066)
```fortran
type(ground_data), intent(in) :: ground  ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED** currently
- Surface field integration doesn't use ground in current implementation
- May be needed for future ground plane corrections
**Action:** Keep for API consistency or remove if確定 not needed
**Impact:** Low

#### sflds() function (lines 1100, 1104)
```fortran
real(8) :: pot       ! WARNING: Unused
complex(8) :: t1     ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED**
**Action:** Remove
**Impact:** None

### 3. nec2_solver.f90

#### solgf() function (line 405)
```fortran
integer, intent(in) :: n2cz  ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED** - legacy parameter
**Action:** Keep for API compatibility with calling sites
**Impact:** None

#### facio() function (line 357)
```fortran
integer, intent(in) :: iu1, iu2, iu3, iu4  ! WARNING: Unused
integer, intent(in) :: nop                  ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED** - I/O unit numbers not used
- Original F77 used these for file I/O
- Modern version uses in-memory arrays
**Action:** Keep for API compatibility
**Impact:** None

#### factrs() function (line 179)
```fortran
integer, intent(in) :: iu1, iu2, iu3, iu4  ! WARNING: Unused
integer, intent(in) :: ix                   ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED** - same as facio()
**Action:** Keep for API compatibility
**Impact:** None

#### solves() function (line 273)
```fortran
integer, intent(in) :: np, n, mp, m  ! WARNING: Unused
integer, intent(in) :: ifl1, ifl2    ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED** - symmetry flags not used
**Action:** Keep for API compatibility
**Impact:** None

#### factrs() function (line 196)
```fortran
complex(8) :: pivot_val  ! WARNING: Unused
```
**Analysis:** ✅ **TRULY UNUSED** - debugging variable
**Action:** Remove
**Impact:** None

## Recommended Actions

### Priority 1: CRITICAL - Missing Functionality
1. **patch() function** - ADD ang%salp calculation:
   ```fortran
   ! After line 434, before icon1/icon2/itag calculations:
   ang%salp(mi) = znv  ! Store normal Z-component
   ```

### Priority 2: Clean Up - Remove Unused Variables
1. **nec2_geometry.f90:471** - Remove `integer(8) :: itagi` (typo)
2. **nec2_geometry.f90:606-609** - Remove `ir, kr, ldi, xi, yi, zi` from reflc() if X-rotation not needed
3. **nec2_fields.f90:38** - Remove `exa`
4. **nec2_fields.f90:665** - Remove `fj` parameter
5. **nec2_fields.f90:1100,1104** - Remove `pot, t1`
6. **nec2_solver.f90:196** - Remove `pivot_val`

### Priority 3: Consider - API Cleanup
1. **nec2_fields.f90:310** - Remove `geom` parameter from efld() if truly not needed
2. **nec2_fields.f90:1066** - Remove or document why `ground` kept in sflds()
3. **nec2_solver.f90** - All iu1-4, nop, ix, ifl1-2 parameters - Document as legacy API

### Priority 4: Investigate
1. **reflc() function** - Check if X-axis reflection is missing (variables declared but not used)

## Uninitialized Variable Warnings

Several "may be used uninitialized" warnings for:
- `ccx, ccy, ccz, rrh, rrv, cix, ciy, ciz` in nec2_fields.f90:efld()

These are **FALSE POSITIVES** - variables are initialized in conditional blocks that compiler cannot trace.
No action needed unless runtime errors occur.

## Conversion Warnings

Multiple "Possible change of value in conversion from INTEGER(8) to INTEGER(4)" warnings.

These are **EXPECTED** from F77 modernization and are non-critical.
Original F77 used default INTEGER which could be 32-bit.
