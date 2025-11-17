# Refactoring Plan for nec2dxs.f

## Overview
Refactor nec2dxs.f (fixed-form Fortran) into modules with minimal changes.

## Compiler Configuration
- Keep fixed form even with modules
- Makefile flags: `FFLAGS = -O0 -std=legacy -ffixed-form -ffixed-line-length-none`
- File naming: Create new module/source files with `.f` extension (not `.f90`)

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

## Incremental Commit Steps

### Baseline ✓
- [x] Tag current tree
- [x] Update Makefile to allow multiple objects but still build the monolith
- [x] No code moved yet
- Commit: 17b8600

### Step 1: Common Module ✓
- [x] Add `nec2_common.f` with includes and COMMONs
- [x] Add `use nec2_common` only in the main program unit to prove it builds
- [x] Build and commit
- [x] Fixed /GGRID/ COMMON block size warning
- Commits: e6d24e3, d650409

### Step 2: I/O Utilities ✓
- [x] Move UPCASE/PARSIT/READMN/READGM/PRNT/CPUSEC into `nec2_io` module
- [x] Move BLCKOT/GFIL/GFOUT/stopwtch into `nec2_io` module
- [x] Add `use nec2_io` to main program
- [x] Added /ANGL/ and /NGFNAM/ to nec2_common
- [x] Build and commit
- Commit: f1630c1

### Step 3: Geometry - COMMON Block Incompatibility Discovery ⚠️
- **MULTIPLE ATTEMPTS FAILED** - Discovered fundamental Fortran COMMON/module incompatibility
- **Issue**: When COMMON blocks are declared inside a MODULE and that module is USEd, local redeclaration of those COMMON blocks in subroutines causes compiler errors:
  - Error: "Symbol 'xyz' at (1) is USE associated from module 'nec2_common' and cannot occur in COMMON"
  - This prevents splitting code across multiple files when using modules

- **Root Cause**: Fortran 90+ modules make COMMON blocks "owned" by the module, preventing the traditional F77 practice of redeclaring COMMON blocks in each compilation unit

- **Solutions Attempted**:
  1. **COMMON blocks in module (Step 1-2)**: Works for single-file, fails for multi-file ❌
  2. **MODULE variables**: Requires rewriting all ~60 subroutines, too error-prone ❌
  3. **Parameters-only module**: Simple, works for multi-file ✓

### Step 1-2 (REVISED): Parameters-Only Approach ✓
- **SOLUTION**: Keep ONLY parameters in nec2_common module (not COMMON blocks)
- Each compilation unit declares its own COMMON blocks locally (standard F77 practice)
- This allows multi-file organization while avoiding USE/COMMON conflicts
- **Changes made**:
  - [x] nec2_common.f: Contains ONLY `INCLUDE 'NEC2DPAR.INC'` and `PARAMETER (IRESRV=MAXMAT**2)`
  - [x] nec2_io.f: Subroutines PARSIT, GFIL, GFOUT declare local COMMON blocks
  - [x] nec2dxs.f: Main program declares all needed COMMON blocks locally
- [x] Build successful, test output identical to baseline
- Commits: 19079ba, 67fa3dd

### Step 3: Geometry Module ✓
- **COMPLETED**: Successfully extracted geometry routines using parameters-only approach
- **Files created**: nec2_geometry.f already existed from previous session attempt
- **Changes made**:
  - [x] Removed 11 geometry subroutines from nec2dxs.f (1565 lines removed):
    * ARC, DATAGN, HELIX, LOAD, MOVE, PATCH, PCINT, REFLC, SBF, TBF, WIRE
  - [x] Each subroutine in nec2_geometry.f follows parameters-only pattern:
    * USE NEC2_COMMON for parameters only
    * Declares needed COMMON blocks locally
    * Original F77 code preserved unchanged
  - [x] Updated Makefile: Added nec2_geometry.o to OBJS
  - [x] File size reduced: nec2dxs.f from 9093 to 7528 lines
- [x] Build successful: make clean && make with no errors
- [x] Test successful: numerical results identical (only formatting differences)
- Commit: e557021

### Step 4: Greens Functions
- [ ] Move special-function helpers into `nec2_greens`
- [ ] Add `use nec2_greens` in callers (solver/fields)
- [ ] Build and commit

### Step 5: Solver
- [ ] Move FACTR…/FACGF…/CM* into `nec2_solve`
- [ ] Add `use nec2_solve` in callers and main
- [ ] Build and commit

### Step 6: Fields
- [ ] Move GWAVE/FFLD…/NFPAT… into `nec2_fields`
- [ ] Add `use nec2_fields` in callers
- [ ] Build and commit

### Step 7: Network
- [ ] Move NETWK/COUPLE/QDSRC… into `nec2_network`
- [ ] Add `use nec2_network` in callers
- [ ] Build and commit

### Step 8: Cleanup
- [ ] Remove redundant COMMON statements now covered by `nec2_common`
- [ ] Normalize implicit typing as needed
- [ ] Tighten Makefile flags
- [ ] Final commit

## Important Notes

- After each step, test for compiler errors and fix them if present
- After each successful step, make a commit to the git branch
- After each commit, stop and return the prompt to the user for evaluation
- Keep fixed-form formatting throughout
- Maintain minimal changes to preserve original code behavior
