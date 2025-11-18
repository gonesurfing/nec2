# Refactoring Plan for nec2dxs.f

## Current Status: REFACTORING COMPLETE ✅

**Completed modules (7):**
- ✅ nec2_common.f (parameters only, 19 lines)
- ✅ nec2_io.f (I/O utilities, 8 subroutines, 869 lines)
- ✅ nec2_geometry.f (geometry + helpers, 14 subroutines, 2094 lines)
- ✅ nec2_greens.f (Green's functions + integration, 18 subroutines, 1436 lines)
- ✅ nec2_solve.f (solver + helpers, 19 subroutines, 1908 lines)
- ✅ nec2_fields.f (fields + helpers, 15 subroutines, 1866 lines)
- ✅ nec2_network.f (network/coupling, 4 subroutines, 632 lines)
- ✅ nec2dxs.f (main program ONLY, 1230 lines, **87.6% reduction**)

**Total:** 78 subroutines extracted from 9925-line monolith into 7 specialized modules

**Build:** `nec2_common.o nec2_io.o nec2_geometry.o nec2_greens.o nec2_solve.o nec2_fields.o nec2_network.o nec2dxs.o` → `nec2dxs`

**Achievement:** Clean modular architecture preserving F77 semantics with minimal code changes

---

## Overview
Refactor nec2dxs.f (fixed-form Fortran) into modules with minimal changes.

## Compiler Configuration
- Keep fixed form even with modules
- Makefile flags: `FFLAGS = -O0 -std=legacy -ffixed-form -ffixed-line-length-none`
- File naming: Create new module/source files with `.f` extension (not `.f90`)
## CRITICAL: COMMON Block/Module Incompatibility Issue & Resolution

### The Problem (Discovered in Step 3 attempts)

When refactoring Fortran 77 code that uses COMMON blocks into Fortran 90+ modules, a fundamental incompatibility arises:

**Traditional F77 approach:**
- COMMON blocks are declared locally in each compilation unit that needs them
- The linker resolves COMMON blocks across different files
- Multiple files can declare the same COMMON block independently

**F90+ MODULE approach that FAILS:**
```fortran
MODULE NEC2_COMMON
  COMMON /DATA/ X(MAXSEG), Y(MAXSEG), ...  ! Declared in module
END MODULE

SUBROUTINE DATAGN
  USE NEC2_COMMON                          ! Brings in /DATA/ COMMON
  COMMON /DATA/ X(MAXSEG), Y(MAXSEG), ... ! ❌ COMPILER ERROR!
  ! Error: Symbol 'X' at (1) is USE associated from module 'nec2_common'
  !        and cannot occur in COMMON
END SUBROUTINE
```

**Root cause:** When a COMMON block is declared inside a MODULE, Fortran 90+ makes that COMMON block "owned" by the module. Any USE of that module brings those symbols into scope as USE-associated entities, which cannot be redeclared in a local COMMON block.

### Solutions Considered

1. **COMMON blocks in module** ❌
   - Works for single-file organization
   - Fails when splitting code across multiple files (Step 3)
   - Requires removing all local COMMON declarations (too invasive)

2. **Convert COMMON to MODULE variables** ❌
   - Would require rewriting ~60 subroutines
   - High risk of introducing bugs
   - Changes code semantics significantly

3. **Parameters-only module** ✅ **CHOSEN SOLUTION**
   - Keep ONLY parameter definitions in nec2_common module
   - Each .f file declares its own COMMON blocks locally (standard F77 practice)
   - No USE/COMMON conflicts
   - Minimal code changes
   - Preserves F77 semantics perfectly

### The Working Pattern

**nec2_common.f** (parameters only):
```fortran
MODULE NEC2_COMMON
  INCLUDE 'NEC2DPAR.INC'           ! MAXSEG, MAXMAT, etc.
  PARAMETER (IRESRV=MAXMAT**2)
  IMPLICIT REAL*8(A-H,O-Z)
  ! NO COMMON BLOCKS HERE!
END MODULE NEC2_COMMON
```

**nec2_geometry.f** (and all other module files):
```fortran
MODULE NEC2_GEOMETRY
END MODULE NEC2_GEOMETRY

SUBROUTINE DATAGN
  USE NEC2_COMMON                  ! Only brings in parameters
  IMPLICIT REAL*8(A-H,O-Z)

  ! Declare COMMON blocks locally (no conflict!)
  COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),...
  COMMON /ANGL/ SALP(MAXSEG)

  ! Original code unchanged...
END SUBROUTINE
```

**Key insight:** By keeping the module interface minimal (parameters only), we can organize code into multiple files while preserving traditional F77 COMMON block behavior.

## Proposed Module Layout
## Implementation Progress

### ✅ COMPLETED STEPS

#### Step 1: Common Module (Parameters Only) ✓
**Initial attempt (e6d24e3, d650409):**
- Created `nec2_common.f` with INCLUDE and COMMON blocks
- Fixed /GGRID/ COMMON block size warning
- Built successfully with main program only

**Revised after COMMON block issue discovery (19079ba, 67fa3dd):**
- **CRITICAL FIX**: Removed all COMMON blocks from nec2_common.f
- Now contains ONLY parameters: `INCLUDE 'NEC2DPAR.INC'` and `PARAMETER (IRESRV=MAXMAT**2)`
- This is the key to enabling multi-file organization
- Added test output files to .gitignore

**Result:** nec2_common.f is now a pure parameters-only module

---

#### Step 2: I/O Utilities Module (f1630c1) ✓
- Created `nec2_io.f` with 8 subroutines:
  * UPCASE, PARSIT, READMN, READGM, PRNT, CPUSEC
  * BLCKOT, GFIL, GFOUT, stopwatch helpers
- Each subroutine follows parameters-only pattern:
  * `USE NEC2_COMMON` for parameters
  * Declares needed COMMON blocks locally
- Main program USEs nec2_io module
- Build and test successful

**Result:** nec2_io.f extracted and working

---

#### Step 3: Geometry Module (e557021, 78d120e) ✓
**Discovery phase:** Multiple failed attempts revealed COMMON/module incompatibility
- Error: "Symbol at (1) is USE associated and cannot occur in COMMON"
- This blocked multi-file splitting when COMMON blocks were in modules

**Solution:** Apply parameters-only pattern consistently across all files

**Implementation:**
- Created `nec2_geometry.f` with 11 subroutines (1582 lines):
  * ARC, DATAGN, HELIX, LOAD, MOVE, PATCH, PCINT, REFLC, SBF, TBF, WIRE
- Removed those subroutines from nec2dxs.f (1565 lines removed)
- Each subroutine uses `USE NEC2_COMMON` for parameters only
- Each subroutine declares its own COMMON blocks locally
- Updated Makefile: `OBJS = nec2_common.o nec2_io.o nec2_geometry.o nec2dxs.o`
- File size: nec2dxs.f reduced from 9925 → 9093 → 7528 lines

**Testing:**
- Build: ✅ `make clean && make` successful
- Functionality: ✅ Numerical results identical to baseline
- Only minor formatting differences in output (leading zeros)

**Result:** nec2_geometry.f extracted and working; parameters-only pattern validated

---

#### Step 4: Green's Functions Module (494cef5) ✓
**Implementation:**
- Created `nec2_greens.f` with 12 special function/quadrature subroutines (1029 lines):
  * SOM2D - Sommerfeld integral grid generation
  * BESSEL, HANKEL - Bessel and Hankel special functions
  * ETMNS - Electric field incident calculation
  * GF, GH, GX, GXX - Green's function components
  * HFK, HINTG, HSFLX, INTX - Integration kernels for field calculations
- Removed these subroutines from nec2dxs.f (1011 lines removed)
- Each subroutine uses `USE NEC2_COMMON` for parameters only
- Each subroutine declares its own COMMON blocks locally (/EVLCOM/, /GGRID/)
- Removed redundant `INCLUDE 'NEC2DPAR.INC'` (already in NEC2_COMMON)
- Updated Makefile: `OBJS = nec2_common.o nec2_io.o nec2_geometry.o nec2_greens.o nec2dxs.o`
- File size: nec2dxs.f reduced from 7528 → 6517 lines

**Testing:**
- Build: ✅ `make clean && make` successful
- Functionality: ✅ Numerical results identical to Step 3
- Output: 247 lines, power budget values match exactly

**Result:** nec2_greens.f extracted and working

---

#### Step 5: Solver Module (005a9c1) ✓
**Implementation:**
- Created `nec2_solve.f` with 17 matrix/solver subroutines (1729 lines):
  * Matrix fill: CMNGF, CMSET, CMSS, CMSW, CMWS, CMWW (813 lines)
  * Factorization: FACTR, FACTRS, FACGF, LFACTR (381 lines)
  * Solvers: SOLVE, SOLVES, LTSOLV, LUNSCR (308 lines)
  * Blocking: FBLOCK, FBNGF, REBLK (215 lines)
- Removed these subroutines from nec2dxs.f (1717 lines removed)
- Most subroutines use `USE NEC2_COMMON` for parameters
- **Exception**: FBNGF has IRESRV as argument → conflicts with PARAMETER IRESRV
  * Solution: FBNGF does NOT use NEC2_COMMON (includes its own declarations)
- Updated Makefile: `OBJS = ... nec2_greens.o nec2_solve.o nec2dxs.o`
- File size: nec2dxs.f reduced from 6517 → 4800 lines

**Testing:**
- Build: ✅ `make clean && make` successful
- Functionality: ✅ Output identical to Step 4
- Power budget values match exactly

**Result:** nec2_solve.f extracted and working

---

#### Step 6: Fields Module (7316140) ✓
**Implementation:**
- Created `nec2_fields.f` with 11 field calculation subroutines (1371 lines):
  * Far field: FFLD, FFLDS, NFPAT, RDPAT (629 lines)
  * Near field: NEFLD, NHFLD (237 lines)
  * Ground/surface: GWAVE, SFLDS, HSFLD (311 lines)
  * Evaluation: EVLUA, UNERE (182 lines)
- Removed these subroutines from nec2dxs.f (1359 lines removed)
- All subroutines use `USE NEC2_COMMON` for parameters
- Each subroutine declares its own COMMON blocks locally
- Updated Makefile: `OBJS = ... nec2_fields.o nec2dxs.o`
- File size: nec2dxs.f reduced from 4800 → 3441 lines (65% total reduction)

**Testing:**
- Build: ✅ `make clean && make` successful
- Functionality: ✅ Numerical results identical to Step 5 (only timing differs)
- Power budget values match exactly

**Result:** nec2_fields.f extracted and working

---

#### Step 7: Network Module (3074d26, bf7779c) ✓
**Implementation:**
- Created `nec2_network.f` with 4 network/coupling subroutines (632 lines):
  * NETWK - Network analysis and impedance loading (335 lines)
  * COUPLE - Mutual coupling calculation (75 lines)
  * QDSRC - Quadrilateral patch current source (129 lines)
  * CABC - Cable/transmission line loading (87 lines)
- Removed these subroutines from nec2dxs.f (626 lines removed)
- All subroutines use `USE NEC2_COMMON` for parameters
- Each declares needed COMMON blocks locally (/NETCX/, /DATA/, /CRNT/, etc.)
- Updated Makefile: `OBJS = ... nec2_network.o nec2dxs.o`
- File size: nec2dxs.f reduced from 3441 → 2815 lines (72% total reduction)

**Remaining in nec2dxs.f (15 helper subroutines):**
- Integration: GSHANK, LAMBDA, ROM1, ROM2, SAOA, TEST
- Field helpers: EFLD, EKSC, EKSCX, GFLD
- Solver helpers: FACIO, SOLGF
- Geometry: CONECT, INTRP, TRIO

**Testing:**
- Build: ✅ `make clean && make` successful
- Functionality: ✅ Numerical results identical (only timing differs)
- Power budget values match exactly

**Result:** nec2_network.f extracted; main refactoring complete

---

#### Step 8: Final Cleanup - Distribute Helpers (0a15dbb) ✓
**Implementation:**
Moved all 15 remaining helper subroutines to their logical modules:

**nec2_greens.f (+6 integration helpers, 402 lines):**
- GSHANK, LAMBDA, ROM1, ROM2, SAOA, TEST
- Romberg integration and convergence testing for Sommerfeld integrals

**nec2_fields.f (+4 field helpers, 493 lines):**
- EFLD - Electric field at observation point
- EKSC, EKSCX - Electric field kernel calculations
- GFLD - Ground field evaluation

**nec2_solve.f (+2 solver helpers, 179 lines):**
- FACIO - Out-of-core factorization I/O control
- SOLGF - Green's function solver

**nec2_geometry.f (+3 geometry helpers, 511 lines):**
- CONECT - Segment connectivity analysis
- INTRP - 4-point interpolation
- TRIO - Triangle geometry operations

**Final result:**
- nec2dxs.f: 9925 → 1230 lines (87.6% reduction)
- Main program is now ONLY control logic, no subroutines
- All 78 subroutines distributed across 7 specialized modules
- Build successful, output identical to Step 7

**REFACTORING COMPLETE** ✅

---
## Key Lessons Learned

### COMMON Block/Module Incompatibility
The most significant technical challenge in this refactoring was discovering that Fortran 90+ modules and traditional F77 COMMON blocks are fundamentally incompatible when splitting code across multiple files:

1. **The Issue:** COMMON blocks declared in a MODULE become USE-associated entities, preventing local redeclaration in subroutines
2. **The Solution:** Keep modules minimal - parameters only, NO COMMON blocks or variables
3. **The Pattern:** Each .f file declares its own COMMON blocks locally, just like traditional F77
4. **The Benefit:** Enables multi-file organization while preserving F77 semantics and minimizing code changes

### Working Pattern for All Module Files

```fortran
C     MODULE NEC2_<NAME>
      MODULE NEC2_<NAME>
      END MODULE NEC2_<NAME>

      SUBROUTINE <SUBNAME>(...)
      USE NEC2_COMMON              ! Parameters only
      IMPLICIT REAL*8(A-H,O-Z)

      ! Declare COMMON blocks locally (no conflicts!)
      COMMON /DATA/ X(MAXSEG), Y(MAXSEG), Z(MAXSEG), ...
      COMMON /.../ ...

      ! Original F77 code unchanged
      ...
      END
```

## Important Notes

- After each step, test for compiler errors and fix them if present
- After each successful step, make a commit to the git branch
- After each commit, stop and return the prompt to the user for evaluation
- Keep fixed-form formatting throughout
- Maintain minimal changes to preserve original code behavior
- **CRITICAL:** Never put COMMON blocks in nec2_common module - parameters only!
- Each new .f file must declare its own COMMON blocks locally