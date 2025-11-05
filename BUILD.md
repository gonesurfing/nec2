# Building Modernized NEC2

## Quick Build

From the `src` directory:

```bash
cd src
make
```

This will:
1. Create the `obj/` directory for object files and module files
2. Compile all 12 modules in dependency order
3. Compile the main program
4. Link everything into the `nec2` executable

## Build Outputs

- **Executable**: `src/nec2`
- **Object files**: `src/obj/*.o`
- **Module files**: `src/obj/*.mod`

## Makefile Targets

- `make all` - Build the complete system (default)
- `make clean` - Remove object files and modules
- `make distclean` - Remove all build artifacts including executable
- `make test-compile` - Test compilation only
- `make help` - Show available targets

## Module Compilation Order

The Makefile compiles modules in the correct dependency order:

1. **nec2_constants** - Physical and mathematical constants
2. **nec2_data_types** - All derived types (replaces COMMON blocks)
3. **nec2_utilities** - Utility functions
4. **nec2_geometry** - Geometry generation
5. **nec2_current** - Current basis functions
6. **nec2_kernel** - Interaction kernels
7. **nec2_sommerfeld** - Ground wave calculations
8. **nec2_matrix** - Matrix assembly
9. **nec2_solver** - Linear algebra
10. **nec2_fields** - Field calculations
11. **nec2_excitation** - Sources and loading
12. **nec2_io** - Input/output operations
13. **nec2_main** - Main program (links all modules)

## Compiler Requirements

- **gfortran** 4.8 or later (tested with 7.x and later)
- Fortran 2008 standard support
- Recommended flags are already set in Makefile:
  - `-O2` - Optimization level 2
  - `-g` - Debug symbols
  - `-Wall -Wextra` - All warnings
  - `-pedantic` - Strict standard compliance
  - `-std=f2008` - Fortran 2008 standard
  - `-fall-intrinsics` - Allow all intrinsics
  - `-fbacktrace` - Backtrace on runtime errors

## Testing the Build

### Basic Compilation Test

```bash
cd src
make clean
make test-compile
```

### Run with Sample Input

```bash
cd src
./nec2 < ../tests/reference_cases/dipole_halfwave.nec
```

### Compare with Original

```bash
# Build original version
gfortran -o nec2_original nec2dxs.f

# Build modernized version
cd src
make

# Run both and compare
../nec2_original < ../tests/reference_cases/dipole_halfwave.nec > output_original.txt
./nec2 < ../tests/reference_cases/dipole_halfwave.nec > output_new.txt

# Compare outputs
diff output_original.txt output_new.txt
```

## Troubleshooting

### Module file not found

If you see errors like:
```
Cannot open module file 'nec2_constants.mod' for reading
```

This means modules are being compiled out of order. The Makefile should handle this automatically, but if you manually compile, ensure you follow the dependency order listed above.

### Compilation errors in modules

Each module has been designed to compile independently once its dependencies are compiled. If you encounter errors:

1. Ensure all prerequisite modules compiled successfully
2. Check that `.mod` files are in the `obj/` directory
3. Clean and rebuild: `make clean && make`

### Linking errors

If you get "undefined reference" errors during linking:

1. Ensure all object files are being linked
2. Check the linking command includes all modules
3. The Makefile automatically handles this

## Next Steps

Once built successfully:

1. Run the test suite (see `tests/README.md`)
2. Compare outputs with original code
3. Run your own NEC2 input files
4. Report any issues found

## Performance Notes

The modernized code should perform similarly to the original:

- Same algorithms and numerical methods
- Explicit interfaces allow better optimization
- Allocatable arrays reduce memory waste
- Module system improves maintainability without performance cost

## Memory Usage

The modernized version uses allocatable arrays instead of fixed-size arrays, which:

- Reduces memory footprint for small problems
- Allows larger problems (no compile-time limits)
- Prevents memory waste

## Debugging

For debugging builds, the Makefile already includes `-g` flag. For additional debugging:

```bash
# Edit Makefile to change FFLAGS:
FFLAGS = -O0 -g -Wall -Wextra -pedantic -std=f2008 -fall-intrinsics -fbacktrace -fcheck=all
```

This adds:
- `-O0` - No optimization (easier debugging)
- `-fcheck=all` - Runtime checks for bounds, pointers, etc.
