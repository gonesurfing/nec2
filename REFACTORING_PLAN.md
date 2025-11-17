# Refactoring Plan for nec2dxs.f

## Current Status: Steps 1-3 Complete ✓

**Completed modules:**
- ✅ nec2_common.f (parameters only)
- ✅ nec2_io.f (I/O utilities, 8 subroutines)
- ✅ nec2_geometry.f (geometry routines, 11 subroutines)
- 🔄 nec2dxs.f (main program, reduced from 9925 → 7528 lines)

**Build configuration:** `nec2_common.o nec2_io.o nec2_geometry.o nec2dxs.o` → `nec2dxs`

**Next step:** Step 4 - Extract Green's functions (nec2_greens.f)

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

### nec2_common (PARAMETERS ONLY)
**Contains ONLY parameter definitions, NOT COMMON blocks**:
- `INCLUDE 'NEC2DPAR.INC'` - MAXSEG, MAXMAT, LOADMX, NSMAX, NETMX, JMAX
- `PARAMETER (IRESRV=MAXMAT**2)`
- **Each .f file declares its own COMMON blocks locally** (standard Fortran 77 practice)
- Shared via `use nec2_common`

### nec2_io
I/O utilities and helpers:
- UPCASE, PARSIT
- READMN/READGM
- PRNT
- BLCKOT/GFOUT/GFIL
- CPUSEC/stopwatch helpers
- Main driver I/O helpers

### nec2_geometry
Geometry build/mutation routines:
- DATAGN
- REFLC
- WIRE, HELIX, PATCH, ARC
- MOVE
- LOAD
- PCINT
- SBF/TBF helpers

### nec2_greens
Special functions/quadrature for Green's functions:
- SOM2D
- BESSEL/HANKEL/GH/GF/GX/GXX
- ETMNS
- HSFLX/HFK/INTX/HINTG

### nec2_solve
Matrix build/factor routines:
- FACTR/FACTRS/SOLVE/SOLVES/LFACTR/LTSOLV/LUNSCR
- FACGF/FBLOCK/FBNGF/REBLK
- CM* helpers (CMNGF, CMSET, CMSS, CMSW, CMWS, CMWW)

### nec2_fields
Near/far field evaluation and reporting:
- GWAVE/FFLD/FFLDS/NFPAT/RDPAT
- NEFLD/NHFLD
- UNERE
- SFLDS/HSFLD/EVLUA

### nec2_network
Network and coupling routines:
- NETWK/COUPLE
- QDSRC
- GFOUT variants
- VSORC/NETCX/port-related helpers

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

### 📋 PENDING STEPS

#### Step 4: Green's Functions Module
- [ ] Create `nec2_greens.f` with special functions/quadrature routines:
  * SOM2D, BESSEL, HANKEL, GH, GF, GX, GXX
  * ETMNS, HSFLX, HFK, INTX, HINTG
- [ ] Follow parameters-only pattern (USE NEC2_COMMON, local COMMON blocks)
- [ ] Remove these subroutines from nec2dxs.f
- [ ] Update Makefile to add nec2_greens.o
- [ ] Build and test
- [ ] Commit

#### Step 5: Solver Module
- [ ] Create `nec2_solve.f` with matrix/solver routines:
  * FACTR, FACTRS, SOLVE, SOLVES, LFACTR, LTSOLV, LUNSCR
  * FACGF, FBLOCK, FBNGF, REBLK
  * CM* helpers: CMNGF, CMSET, CMSS, CMSW, CMWS, CMWW
- [ ] Follow parameters-only pattern
- [ ] Remove from nec2dxs.f
- [ ] Update Makefile
- [ ] Build and test
- [ ] Commit

#### Step 6: Fields Module
- [ ] Create `nec2_fields.f` with field calculation routines:
  * GWAVE, FFLD, FFLDS, NFPAT, RDPAT
  * NEFLD, NHFLD, UNERE
  * SFLDS, HSFLD, EVLUA
- [ ] Follow parameters-only pattern
- [ ] Remove from nec2dxs.f
- [ ] Update Makefile
- [ ] Build and test
- [ ] Commit

#### Step 7: Network Module
- [ ] Create `nec2_network.f` with network/coupling routines:
  * NETWK, COUPLE, QDSRC
  * GFOUT variants, VSORC, NETCX, port-related helpers
- [ ] Follow parameters-only pattern
- [ ] Remove from nec2dxs.f
- [ ] Update Makefile
- [ ] Build and test
- [ ] Commit

#### Step 8: Final Cleanup
- [ ] Review all COMMON declarations for consistency
- [ ] Check IMPLICIT typing declarations
- [ ] Consider tightening Makefile flags (if appropriate)
- [ ] Final documentation update
- [ ] Final commit

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
