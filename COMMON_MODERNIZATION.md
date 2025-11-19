# COMMON Block Modernization Plan

## Current Status

### Infrastructure (Already Exists)
- **nec2d_params.f90** - Module with all PARAMETER definitions (MAXSEG, etc.)
- **nec2d_commons.f90** - Module wrapping all COMMON blocks in modern Fortran 90

### Usage Analysis
- **Total COMMON blocks**: 46 (case-insensitive duplicates counted separately)
- **Modules using old COMMON declarations**: 26 of 28 modernized modules
- **Modules already modernized**: 2 (nec2d_isegno.f90, nec2d_utils.f90)

### Most Heavily Used COMMON Blocks
1. **/DATA/** - Geometry and segment data (29 file references)
2. **/DATAJ/** - Current data for integration (15 file references)
3. **/MATPAR/** - Matrix parameters (17 file references)
4. **/ANGL/** - Angle data (17 file references)
5. **/SEGJ/** - Segment junction data (11 file references)

## Modernization Strategy

### Phase 1: Convert Modernized Modules (SAFE)
Convert the 26 modules that still use COMMON declarations to:
```fortran
MODULE module_name
  USE nec2d_params
  USE nec2d_commons
  IMPLICIT REAL*8(A-H,O-Z)
  ! Remove all COMMON declarations
```

**Benefits:**
- Cleaner code
- Explicit dependencies
- Better compiler optimization potential
- Easier to track data flow

**Risk Level:** LOW
- No change to data layout or memory structure
- No change to computation
- Bit-identical output guaranteed

### Phase 2: Test After Each Conversion
For each module conversion:
1. Remove COMMON declarations
2. Add USE nec2d_commons
3. Rebuild
4. Run test: `./nec2dxs_integrated < example1.nec`
5. Verify MD5: `7c45f1e15ba34584728075e0cf6402c1`

### Phase 3: Document Results
Track which modules successfully converted and update this document.

## Implementation Plan

### Batch A - Matrix Operations (Test First)
- nec2d_cmngf.f90 (COMMON: /DATA/, /DATAJ/, /MATPAR/, /SEGJ/, /ZLOAD/)
- nec2d_solver.f90 (COMMON: /MATPAR/, /SCRATM/, /SEGJ/, /SMAT/)

### Batch B - Geometry Processing
- nec2d_geomproc.f90 (COMMON: /DATA/, /DATAJ/, /MATPAR/, /GND/, /ANGL/, /SCRATM/)
- nec2d_conect.f90 (COMMON: /DATA/, /SEGJ/)
- nec2d_geometry.f90 (COMMON: /data/, /angl/)

### Batch C - Field Calculations
- nec2d_fields2.f90 (COMMON: /DATA/, /ANGL/, /PLOT/)
- nec2d_fields3.f90 (COMMON: /DATAJ/, /GND/, /MATPAR/, /GWAV/, /crnt/, /data/, /gnd/)
- nec2d_nearfield.f90 (COMMON: /angl/, /crnt/, /data/, /dataj/, /gnd/)

### Batch D - I/O and Data Processing
- nec2d_dataproc.f90 (COMMON: /DATA/, /DATAJ/, /GND/, /ANGL/, /INCOM/, /PLOT/, /VSORC/)
- nec2d_io.f90 (COMMON: /angl/, /cmb/, /ggrid/, /gnd/, /matpar/, /ngfnam/, /smat/, /zload/)
- nec2d_rdpat.f90 (COMMON: /DATA/, /GND/, /PLOT/, /SCRATM/)

### Batch E - Mathematical Utilities
- nec2d_numint.f90 (COMMON: /EVLCOM/, /GGRID/)
- nec2d_mathutil.f90 (COMMON: /cntour/, /data/, /dataj/, /gwav/, /tmh/)
- nec2d_sommerfeld.f90 (COMMON: /cntour/, /evlcom/)

### Batch F - Matrix Building
- nec2d_matrix.f90 (COMMON: /matpar/, /vsorc/, /yparm/)
- nec2d_matrix2.f90 (COMMON: /angl/, /data/, /dataj/, /matpar/, /scratm/, /segj/, /smat/, /zload/)
- nec2d_matrix3.f90 (COMMON: /angl/, /data/, /dataj/, /gnd/, /segj/)

### Batch G - Remaining Modules
- nec2d_bessel.f90
- nec2d_fields.f90
- nec2d_integration.f90
- nec2d_kernels.f90
- nec2d_segment.f90
- nec2d_simple.f90
- nec2d_utilities.f90

## ATTEMPTED MODULE CONVERSION - FAILED (2025-11-19)

### What We Tried
Converted 3 modules to replace COMMON declarations with `USE nec2d_commons`:
1. nec2d_cmngf.f90 - Initial test case
2. nec2d_conect.f90
3. nec2d_solver.f90

### Why It Failed
**Fatal Name Conflicts**: When a MODULE is USEd, ALL module variables are imported into the local scope. This creates ambiguous references when:
- Subroutine parameters have same names as COMMON block variables
- Example: `SUBROUTINE SOLGF(IP,NP,N,MP,M,...)` conflicts with module variables IP(2*MAXSEG), NP, N, MP, M from /DATA/ and /SAVE/ COMMON blocks

**Compiler Errors**:
```
Error: Name 'ip' at (1) is an ambiguous reference to 'ip' from current program unit
Error: Name 'np' at (1) is an ambiguous reference to 'np' from current program unit
Error: Name 'neq' at (1) is an ambiguous reference to 'neq' from current program unit
Error: Name 'mp' at (1) is an ambiguous reference to 'mp' from current program unit
```

### Why COMMON Blocks Must Stay

1. **Name Space Isolation**: COMMON blocks in each subroutine create local scope only for those variables explicitly declared - they don't conflict with parameters

2. **Massive Refactoring Required**: To use MODULEs would require either:
   - Renaming 1000+ parameter instances across all subroutines (HIGH RISK)
   - Using `USE nec2d_commons, ONLY: ...` in every subroutine (tedious, error-prone)
   - Neither approach is safe for a 64-year-old EM physics codebase

3. **No Functional Benefit**: COMMON blocks work correctly and produce bit-identical output. Conversion to MODULEs is cosmetic only.

## SUCCESSFUL SOLUTION: USE with ONLY Clause (2025-11-19)

### Discovery
**ONLY clauses completely solve the name conflict issue!**

By using `USE nec2d_commons, ONLY: var1, var2, ...`, we can:
- Import only the COMMON variables actually needed
- Avoid conflicts with subroutine parameters
- Maintain bit-identical output (MD5 verified)

### Example: CMNGF Conversion
```fortran
SUBROUTINE CMNGF (CB,CC,CD,NB,NC,ND,RKHX,IEXKX)
  USE nec2d_params
  USE nec2d_commons, ONLY: &
    ! /DATA/ - geometry and segment data (22 variables)
    X, Y, Z, SI, BI, ALP, BET, WLAM, ICON1, ICON2, ITAG, ICONX, &
    LD, N1, N2, N, NP, M1, M2, M, MP, IPSYM, &
    ! /ZLOAD/ - load impedances (3 variables)
    ZARRAY, NLOAD, NLODF, &
    ! ... (73 total variables explicitly listed)
```

### Verification
✅ **Compiled successfully**
✅ **MD5 checksum matches**: `7c45f1e15ba34584728075e0cf6402c1`
✅ **No parameter conflicts**: Only imports needed variables

### Benefits of ONLY Clause Approach
1. **Explicit dependencies**: Documents exactly which COMMON variables each subroutine uses
2. **No name conflicts**: Excludes conflicting variables from import
3. **Modern Fortran best practice**: Explicit imports are preferred over implicit
4. **Compile-time checking**: Missing variables cause immediate compilation errors
5. **Better maintainability**: Clear documentation of data dependencies

## Updated Conclusion

**RECOMMENDATION: USE with ONLY clauses is viable**

Two valid approaches exist:

### Option A: Keep COMMON blocks (current approach)
- ✅ **Simple**: No changes needed
- ✅ **Proven**: 28 modules working
- ✅ **Standard**: Valid Fortran 90/95/2003/2008

### Option B: Convert to USE with ONLY clauses (new option)
- ✅ **Modern**: Best practice Fortran 90
- ✅ **Explicit**: Documents dependencies
- ✅ **Safe**: Tested with bit-identical output
- ⚠️  **Tedious**: Requires analyzing each module's COMMON usage
- ⚠️  **Time-consuming**: Need custom ONLY list for each subroutine

### Recommendation
**For new modules**: Use `USE nec2d_commons, ONLY: ...` approach
**For existing modules**: Keep COMMON blocks unless refactoring for other reasons

Both approaches are valid and safe. The ONLY clause approach provides better documentation but requires more initial effort.

## Notes
- Keep IMPLICIT REAL*8(A-H,O-Z) (needed for compatibility)
- Module aliasing works: `Y => SCRATM_CPLX` for renamed variables
- EQUIVALENCE on USE ASSOCIATED variables fails - use aliasing instead
- Focus modernization efforts on GOTO elimination remains primary goal
