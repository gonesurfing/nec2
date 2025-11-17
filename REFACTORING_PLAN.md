# Refactoring Plan for nec2dxs.f

## Overview
Refactor nec2dxs.f (fixed-form Fortran) into modules with minimal changes.

## Compiler Configuration
- Keep fixed form even with modules
- Makefile flags: `FFLAGS = -O0 -std=legacy -ffixed-form -ffixed-line-length-none`
- File naming: Create new module/source files with `.f` extension (not `.f90`)

## Proposed Module Layout

### nec2_common
Parameters from `NEC2D*.INC`; all COMMON blocks:
- `/DATA/`, `/SEGJ/`, `/CRNT/`, `/GND/`, `/GWAV/`, `/ZLOAD/`, `/VSORC/`, `/NETCX/`
- `/FPAT/`, `/GGRID/`, `/MATPAR/`, `/PLOT/`, `/SCRATM/`, `/CNTOUR/`, `/ANGL/`
- `/SMAT/`, `/TMH/`, `/TMI/`, `/EVLCOM/`, `/NGFNAM/`
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

### Step 3: Geometry ⚠️ REVERTED
- **ATTEMPT FAILED** - Extraction broke calculations catastrophically
- Issue: Moving geometry subroutines (ARC, DATAGN, HELIX, LOAD, MOVE, PATCH, PCINT, REFLC, SBF, TBF, WIRE) to separate module broke COMMON block data sharing
- Symptom: Impedance calculation dropped from 82.7+j46.3Ω to 0.042+j429Ω (~2000x error)
- Root cause: Complex interaction between USE statements and local COMMON blocks with EQUIVALENCE
- Decision: **Keep geometry subroutines in main nec2dxs.f file**
- Commits reverted: 75817e1, 546a016
- Branch reset to: e8c32f2 (Step 2 completion)

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
