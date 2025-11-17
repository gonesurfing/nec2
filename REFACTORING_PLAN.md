# NEC2D Fortran Refactoring Plan

## Objective
Split the monolithic nec2dxs.f file (~10,000 lines, 83 routines) into modular Fortran 90 files to enable systematic incremental replacement and testing.

## Strategy
- **Minimal changes**: Keep original code largely intact, just add module wrappers and USE statements
- **Logical grouping**: Organize by functional area for easier testing
- **Incremental replacement**: Each module can be tested independently before replacing functionality
- **Frequent checkpoints**: Commit after each phase to prevent loss of progress

## Module Layout (14 modules + main program)

### Foundation Modules (Phase 1)

**1. nec2d_params.f90** - Parameter definitions
- Convert .INC files to module parameters
- MAXSEG, MAXMAT, LOADMX, NSMAX, NETMX, JMAX, etc.
- Source: NEC2D3000.INC, NEC2DPAR.INC

**2. nec2d_commons.f90** - Common block definitions
- All COMMON blocks converted to module variables
- Blocks: DATA, CMB, MATPAR, SAVE, CSAVE, CRNT, GND, ZLOAD, YPARM, SEGJ, VSORC, NETCX, FPAT, GGRID, GWAV, PLOT

### Low Dependency Modules (Phase 2)

**3. nec2d_utils.f90** - Utility functions (4 routines)
- ATGN2 - Arc tangent function
- CANG - Complex angle
- DB10 - Decibel conversion
- CPUSEC - CPU timing

**4. nec2d_io.f90** - Input/Output operations (9 routines)
- READGM - Read geometry commands
- READMN - Read main commands
- PARSIT - Parse input
- UPCASE - String uppercase conversion
- PRNT - Print output
- GFIL - Geometry file operations
- GFOUT - Geometry output
- BLCKOT - Block output
- REBLK - Reblock data

### Geometry Module (Phase 3)

**5. nec2d_geometry.f90** - Geometry generation (8 routines)
- DATAGN - Main geometry setup
- ARC - Arc geometry
- HELIX - Helix geometry
- PATCH - Surface patch
- WIRE - Wire geometry
- MOVE - Move/translate geometry
- REFLC - Reflect geometry
- CONECT - Analyze connectivity

### Critical Path Modules (Phase 4)

**6. nec2d_matrix.f90** - Matrix operations (7 routines)
- CMSET - Set up CM matrix
- CMSS - CM subsection operations
- CMSW - CM switch operations
- CMWS - CM write subsection
- CMWW - CM write write
- CMNGF - CM numerical Green's function
- FBLOCK - Block factorization setup
- FBNGF - Allocate memory for NGF

**7. nec2d_solver.f90** - Linear algebra solvers (9 routines)
- FACTR - Factor matrix
- FACTRS - Factor with symmetry
- FACGF - Factor Green's function
- FACIO - Factor I/O
- SOLVE - Solve linear system
- SOLVES - Solve with symmetry
- SOLGF - Solve Green's function
- LFACTR - LU factorization
- LTSOLV - LU solve
- LUNSCR - LU unscramble

### Field Calculation Modules (Phase 5)

**8. nec2d_sommerfeld.f90** - Sommerfeld/Ground wave (14 routines)
- SOM2D - Main Sommerfeld routine
- BESSEL - Bessel functions
- HANKEL - Hankel functions
- EVLUA - Evaluate functions
- GSHANK - Generalized Shanks transform
- LAMBDA - Lambda function
- ROM1 - Romberg integration 1D
- ROM2 - Romberg integration 2D
- SAOA - Sommerfeld attenuation
- TEST - Test convergence
- GF - Green's function
- GH - Green's function H
- GX - Green's function auxiliary
- GXX - Green's function auxiliary extended

**9. nec2d_kernels.f90** - Kernel functions (6 routines)
- EKSC - E-field kernel standard
- EKSCX - E-field kernel extended
- HFK - H-field kernel
- HSFLX - H-field surface flux
- HINTG - H-field integration
- GWAVE - Ground wave

**10. nec2d_basis.f90** - Basis/Integration functions (7 routines)
- TBF - Thin wire basis function
- SBF - Surface basis function
- PCINT - Patch current integration
- ETMNS - E-field thin wire near segment
- INTX - Integration auxiliary
- INTRP - Interpolation
- TRIO - Triangle operations

**11. nec2d_fields.f90** - Field calculations (8 routines)
- EFLD - Electric field
- NEFLD - Near electric field
- HSFLD - H-field surface
- NHFLD - Near H-field
- FFLD - Far field
- FFLDS - Far field at surface
- GFLD - Ground field
- SFLDS - Surface fields

**12. nec2d_excitation.f90** - Excitation & sources (6 routines)
- QDSRC - Quad source
- COUPLE - Coupling calculations
- NETWK - Network parameters
- CABC - Cable current
- LOAD - Load impedances
- UNERE - Unit electric field at receive

**13. nec2d_pattern.f90** - Radiation patterns (2 routines)
- NFPAT - Near field pattern
- RDPAT - Read pattern

**14. nec2d_isegno.f90** - Segment numbering (1 routine)
- ISEGNO - Segment number utility

### Main Program (Phase 6)

**15. nec2d_main.f90** - Main program
- Convert from PROGRAM to main routine
- Uses all above modules

## Implementation Phases

### Phase 1: Foundation (Checkpoint 1)
- Create nec2d_params.f90
- Create nec2d_commons.f90
- Test compilation
- **COMMIT: "Phase 1: Foundation modules (params and commons)"**

### Phase 2: Low Dependencies (Checkpoint 2)
- Create nec2d_utils.f90
- Create nec2d_io.f90
- Test compilation
- **COMMIT: "Phase 2: Utils and I/O modules"**

### Phase 3: Geometry (Checkpoint 3)
- Create nec2d_geometry.f90
- Test compilation
- **COMMIT: "Phase 3: Geometry module"**

### Phase 4: Solvers (Checkpoint 4)
- Create nec2d_matrix.f90
- Create nec2d_solver.f90
- Test compilation
- **COMMIT: "Phase 4: Matrix and solver modules"**

### Phase 5: Field Calculations (Checkpoint 5)
- Create nec2d_sommerfeld.f90
- Create nec2d_kernels.f90
- Create nec2d_basis.f90
- Create nec2d_fields.f90
- Create nec2d_excitation.f90
- Create nec2d_pattern.f90
- Create nec2d_isegno.f90
- Test compilation
- **COMMIT: "Phase 5: Field calculation modules"**

### Phase 6: Integration (Checkpoint 6)
- Create nec2d_main.f90
- Create Makefile
- Test full compilation and linking
- Run basic test case
- **COMMIT: "Phase 6: Main program and complete build system"**

## Testing Strategy

After each phase:
1. Compile all modules created so far
2. Check for syntax errors
3. Verify module dependencies
4. Document any issues

After Phase 6:
1. Build complete executable
2. Run simple antenna test case
3. Compare output with original nec2dxs
4. Document any differences

## Notes
- Original nec2dxs.f will be preserved
- All new files use .f90 extension for free-form Fortran
- IMPLICIT NONE will be added to all modules
- Common blocks will become module variables
- Original code logic remains unchanged
