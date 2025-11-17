# NEC2D Fortran Refactoring Plan V2 (Fixed-Form .f Strategy)

## Objective
Split the monolithic nec2dxs.f file (~10,000 lines, 83 routines) into multiple manageable .f files to enable systematic incremental replacement and testing.

## Strategy (REVISED)
- **Minimal changes**: Keep original Fortran 77 fixed-form syntax intact
- **Split by function**: Organize routines by functional area into separate .f files
- **Preserve COMMON blocks**: Keep all COMMON/INCLUDE statements as-is
- **Fixed-form (.f)**: Use .f extension, compile with gfortran -ffixed-form
- **Incremental testing**: Each file can be compiled and tested independently
- **Frequent checkpoints**: Commit after creating each .f file

## File Layout (8-10 files)

### 1. **nec2d_io.f** - Input/Output operations (~500 lines, 9 routines)
- READGM, READMN, PARSIT, UPCASE - Input parsing
- PRNT - Print output
- GFIL, GFOUT - Numerical Green's Function file I/O
- BLCKOT, REBLK - Block I/O for out-of-core solutions

### 2. **nec2d_geom.f** - Geometry generation (~800 lines, 8 routines)
- DATAGN - Main geometry setup
- ARC, HELIX, PATCH, WIRE - Geometry primitives
- MOVE, REFLC - Geometry transformations
- CONECT - Connectivity analysis

### 3. **nec2d_matrix.f** - Matrix operations (~600 lines, 7 routines)
- CMSET, CMSS, CMSW, CMWS, CMWW - Matrix setup and manipulation
- CMNGF - Numerical Green's Function matrix
- FBLOCK, FBNGF - Block setup

### 4. **nec2d_solver.f** - Linear algebra solvers (~1000 lines, 9 routines)
- FACTR, FACTRS, FACGF, FACIO - Matrix factorization
- SOLVE, SOLVES, SOLGF - Solution routines
- LFACTR, LTSOLV, LUNSCR - LU decomposition

### 5. **nec2d_sommerfeld.f** - Sommerfeld integrals (~2000 lines, 14 routines)
- SOM2D - Main Sommerfeld routine
- BESSEL, HANKEL - Special functions
- EVLUA, GSHANK, LAMBDA, ROM1, ROM2, SAOA, TEST - Integration
- GF, GH, GX, GXX - Green's functions

### 6. **nec2d_fields.f** - Field calculations (~1500 lines, 20 routines)
- EFLD, NEFLD, HSFLD, NHFLD - Near field calculations
- FFLD, FFLDS - Far field calculations
- GFLD, SFLDS, GWAVE - Ground and surface fields
- EKSC, EKSCX, HFK, HSFLX, HINTG - Kernel functions
- TBF, SBF, PCINT, ETMNS, INTX, INTRP, TRIO - Basis functions

### 7. **nec2d_excite.f** - Excitation and sources (~400 lines, 6 routines)
- QDSRC - Quad source
- COUPLE, NETWK - Coupling and networks
- CABC, LOAD - Cable and loads
- UNERE - Unit field at receive

### 8. **nec2d_pattern.f** - Radiation patterns (~300 lines, 2 routines)
- NFPAT - Near field pattern
- RDPAT - Read pattern

### 9. **nec2d_utils.f** - Utility functions (~200 lines, 5 routines)
- ATGN2, CANG, DB10 - Math utilities
- CPUSEC, STOPWTCH - Timing
- ISEGNO - Segment lookup

### 10. **nec2d_main.f** - Main program (~3000 lines)
- Main program logic
- All COMMON block declarations
- Calls to all subroutines

## Keep As-Is
- **NEC2D3000.INC** (and other .INC files) - Parameter definitions
- **All COMMON blocks** - Declared in each file that needs them
- **INCLUDE statements** - Keep all original includes
- **IMPLICIT REAL*8** - Keep original type declarations
- **Fixed-form syntax** - No conversion to free-form

## Implementation Steps

### Step 1: Extract I/O routines
1. Copy READGM, READMN, PARSIT, UPCASE, PRNT, GFIL, GFOUT, BLCKOT, REBLK to nec2d_io.f
2. Include necessary COMMON blocks
3. Add INCLUDE 'NEC2DPAR.INC' at top
4. Test compile: `gfortran -c -ffixed-form nec2d_io.f`
5. **COMMIT: "Split I/O routines into nec2d_io.f"**

### Step 2: Extract geometry routines
1. Copy DATAGN, ARC, HELIX, PATCH, WIRE, MOVE, REFLC, CONECT to nec2d_geom.f
2. Include necessary COMMON blocks
3. Test compile: `gfortran -c -ffixed-form nec2d_geom.f`
4. **COMMIT: "Split geometry routines into nec2d_geom.f"**

### Step 3: Extract matrix routines
1. Copy matrix routines to nec2d_matrix.f
2. Test compile
3. **COMMIT: "Split matrix routines into nec2d_matrix.f"**

### Step 4: Extract solver routines
1. Copy solver routines to nec2d_solver.f
2. Test compile
3. **COMMIT: "Split solver routines into nec2d_solver.f"**

### Step 5: Extract Sommerfeld routines
1. Copy Sommerfeld routines to nec2d_sommerfeld.f
2. Test compile
3. **COMMIT: "Split Sommerfeld routines into nec2d_sommerfeld.f"**

### Step 6: Extract field routines
1. Copy field calculation routines to nec2d_fields.f
2. Test compile
3. **COMMIT: "Split field routines into nec2d_fields.f"**

### Step 7: Extract excitation routines
1. Copy excitation routines to nec2d_excite.f
2. Test compile
3. **COMMIT: "Split excitation routines into nec2d_excite.f"**

### Step 8: Extract pattern routines
1. Copy pattern routines to nec2d_pattern.f
2. Test compile
3. **COMMIT: "Split pattern routines into nec2d_pattern.f"**

### Step 9: Extract utility routines
1. Copy utility routines to nec2d_utils.f
2. Test compile
3. **COMMIT: "Split utility routines into nec2d_utils.f"**

### Step 10: Create main program
1. Extract main program to nec2d_main.f (keep all COMMON blocks)
2. Test compile
3. **COMMIT: "Split main program into nec2d_main.f"**

### Step 11: Create Makefile
1. Create Makefile to compile all .f files
2. Link all .o files into nec2d executable
3. **COMMIT: "Add Makefile for split build"**

### Step 12: Test complete build
1. `make clean && make`
2. Run test case
3. Compare output with original nec2dxs
4. **COMMIT: "Verify complete build and test"**

## Compilation

```makefile
FC = gfortran
FFLAGS = -O2 -ffixed-form

OBJS = nec2d_io.o nec2d_geom.o nec2d_matrix.o nec2d_solver.o \
       nec2d_sommerfeld.o nec2d_fields.o nec2d_excite.o \
       nec2d_pattern.o nec2d_utils.o nec2d_main.o

nec2d: $(OBJS)
	$(FC) $(FFLAGS) -o nec2d $(OBJS)

%.o: %.f
	$(FC) $(FFLAGS) -c $<

clean:
	rm -f *.o *.mod nec2d
```

## Benefits of This Approach

1. **Minimal code changes** - No syntax conversion required
2. **Easy to verify** - Can diff against original routines
3. **Incremental testing** - Each file compiles independently
4. **Preserves stability** - No risk of introducing bugs during conversion
5. **Easy to replace later** - Can modernize individual files as needed

## Notes

- Original nec2dxs.f will be preserved as reference
- All .f files use fixed-form Fortran 77 syntax
- COMMON blocks duplicated in each file that needs them
- No module system - uses traditional COMMON blocks
- This is a **refactoring** not a **rewrite**
