# Placeholder Implementation Roadmap

## Overview

This document provides the implementation plan for migrating the 7 placeholder functions from the original nec2dxs.f to the modernized modules.

## Implementation Order (by Priority and Dependency)

### Phase 1: Kernel Functions (Foundation) - CRITICAL
These are used by other functions and should be implemented first.

#### 1. gx() - Simple, No Dependencies
**File:** `nec2_kernel.f90` (Line 324)
**Original:** `nec2dxs.f` (Lines 5428-5442, 15 lines)
**Complexity:** LOW
**Status:** Ready to implement
**Dependencies:** None

#### 2. gxx() - Moderate, No Dependencies
**File:** `nec2_kernel.f90` (Line 332)
**Original:** `nec2dxs.f` (Lines 5443-5487, 45 lines)
**Complexity:** MEDIUM
**Status:** Ready to implement
**Dependencies:** None

#### 3. intx() - Complex, Needs GF helper
**File:** `nec2_kernel.f90` (Line 439)
**Original:** `nec2dxs.f` (Lines 6065-6174, ~108 lines)
**Complexity:** HIGH
**Status:** ✅ COMPLETE (2025-11-06)
**Dependencies:** GF() (lines 4879-4901), TEST() (lines 9674-9694)
**Implementation:**
- Fixed signature (sgr, sgi now REAL not COMPLEX)
- Implemented full Romberg integration with adaptive step size
- Added gf_integrand() helper (~24 lines)
- Added test_convergence() helper (~21 lines)
**Features:**
- Variable interval width integration
- 3-point and 5-point Romberg schemes
- Automatic step size halving/doubling
- Near singularity handling for diagonal terms

### Phase 2: Field Functions - HIGH PRIORITY

#### 4. gfld() - Ground Field Calculation
**File:** `nec2_fields.f90` (Line 464)
**Original:** `nec2dxs.f` (Lines ~5000-5200, ~200 lines estimated)
**Complexity:** HIGH
**Status:** Needs location in original
**Dependencies:** May need Sommerfeld functions

#### 5. gwave() - Ground Wave Field
**File:** `nec2_fields.f90` (Line 483)
**Original:** `nec2dxs.f` (Lines ~5200-5300, ~100 lines estimated)
**Complexity:** MEDIUM
**Status:** Needs location in original
**Dependencies:** Calls evlua() from nec2_sommerfeld

#### 6. hsfld() - H Field from Surface
**File:** `nec2_fields.f90` (Line 503)
**Original:** `nec2dxs.f` (Lines ~5300-5450, ~150 lines estimated)
**Complexity:** MEDIUM-HIGH
**Status:** Needs location in original
**Dependencies:** Geometry calculations

### Phase 3: Integration - LOW PRIORITY

#### 7. rom2() - Alternative Romberg Integration
**File:** `nec2_sommerfeld.f90` (Line 461)
**Original:** `nec2dxs.f` (Lines ~7500-7600, ~100 lines estimated)
**Complexity:** MEDIUM
**Status:** Partially implemented, needs completion
**Dependencies:** None

## Helper Functions Needed

### GF() - Green's Function for INTX
**Original:** `nec2dxs.f` (Lines 6173-6220)
**Purpose:** Provides integrand values for INTX
**Action:** Create as internal subroutine or module-level helper

### TEST() - Convergence Test
**Original:** `nec2dxs.f` (Search for "SUBROUTINE TEST")
**Purpose:** Tests convergence for Romberg integration
**Action:** May already exist or need to create

## Implementation Steps (Per Function)

For each function, follow these steps:

### Step 1: Locate Original Code
```bash
grep -n "SUBROUTINE <NAME>" nec2dxs.f
```

### Step 2: Extract and Analyze
- Copy the original FORTRAN code
- Identify all COMMON block references
- Note any called subroutines
- Identify GOTO statements and control flow

### Step 3: Modernize
- Replace COMMON blocks with passed parameters (derived types)
- Convert to free-form Fortran
- Replace GOTOs with structured control flow where possible
- Add explicit intent declarations
- Use modern intrinsics (CMPLX -> cmplx with kind=8)

### Step 4: Test
- Add unit test to `tests/test_all_modules.f90`
- Verify against known values
- Test edge cases

## Current Implementation Status

| Function | Status | Lines | Complexity | Priority |
|----------|--------|-------|------------|----------|
| gx()     | ✅ DONE | 15    | LOW        | HIGH     |
| gxx()    | ✅ DONE | 45    | MEDIUM     | HIGH     |
| intx()   | ✅ DONE | 150+  | HIGH       | HIGH     |
| gfld()   | ⬜ TODO | ~200  | HIGH       | MEDIUM   |
| gwave()  | ⬜ TODO | ~100  | MEDIUM     | MEDIUM   |
| hsfld()  | ⬜ TODO | ~150  | MEDIUM     | MEDIUM   |
| rom2()   | 🟡 PARTIAL | ~100  | MEDIUM     | LOW      |

## Signature Corrections Needed

### intx() - WRONG in current stub
```fortran
! Current (WRONG):
subroutine intx(el1, el2, b, ij, sgr, sgi)
  complex(8), intent(out) :: sgr, sgi  ! WRONG - should be real(8)

! Correct (from original):
subroutine intx(el1, el2, b, ij, sgr, sgi)
  real(8), intent(out) :: sgr, sgi  ! CORRECT
```

## Quick Reference: Original Line Numbers

Based on searches:
- GX: 5428-5442
- GXX: 5443-5487
- INTX: 6065-6172
- GF (helper for INTX): 6173-6220
- GFLD: TBD - search for "SUBROUTINE GFLD"
- GWAVE: TBD - search for "SUBROUTINE GWAVE"
- HSFLD: TBD - search for "SUBROUTINE HSFLD"
- ROM2: TBD - search for "SUBROUTINE ROM2"

## Testing Strategy

After implementing each function:

1. **Unit Test**: Add to `tests/test_all_modules.f90`
   - Test with known inputs/outputs
   - Test edge cases (rh=0, etc.)

2. **Integration Test**: Run with test cases
   - Surface patches (needs gx, gxx, intx, hsfld)
   - Ground planes (needs gfld, gwave)

3. **Regression Test**: Compare with original
   - Use `tests/test_end_to_end.sh`
   - Verify numerical equivalence

## Next Actions

1. ✅ Create this roadmap document
2. ✅ Implement gx() (15 lines) - DONE 2025-11-06
3. ✅ Implement gxx() (45 lines) - DONE 2025-11-06
4. ✅ Implement intx() + GF() + TEST() helpers - DONE 2025-11-06
5. ⬜ Locate remaining functions in original (gfld, gwave, hsfld)
6. ⬜ Implement field functions (gfld, gwave, hsfld)
7. ⬜ Complete rom2()
8. ✅ Update STATUS.md and PLACEHOLDERS.md - DONE 2025-11-06
9. ⬜ Full testing after all implementations

## Estimated Effort

- **Phase 1 (Kernel):** 2-3 hours
- **Phase 2 (Fields):** 4-6 hours
- **Phase 3 (Integration):** 1-2 hours
- **Testing & Debug:** 2-4 hours
- **Total:** 9-15 hours of focused implementation work

## Notes

- Keep original FORTRAN comments where helpful
- Document any algorithmic changes
- Preserve numerical behavior exactly
- Test thoroughly - these are critical functions
