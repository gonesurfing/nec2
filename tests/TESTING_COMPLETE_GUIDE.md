# Complete Testing Guide for NEC2 Modernization

## Overview

This guide provides comprehensive instructions for testing the modernized NEC2 code to ensure it produces numerically equivalent results to the original FORTRAN 77 implementation.

## Test Philosophy

The modernization effort maintains **strict numerical equivalence** with the original code. Our testing strategy ensures:

1. **Correctness**: All calculations produce identical results (within numerical precision)
2. **Completeness**: All features and functionality are preserved
3. **Performance**: Modernized code performs comparably to original
4. **Robustness**: Edge cases and error conditions handled properly

## Test Hierarchy

### Level 1: Unit Tests
Test individual functions and modules in isolation

### Level 2: Integration Tests
Test modules working together

### Level 3: End-to-End Tests
Full antenna simulations compared against reference data

### Level 4: Performance Tests
Execution time and memory usage comparisons

## Quick Start

### Complete Test Suite (Recommended for Final Validation)

Run all tests at once:

```bash
cd tests
make full_test
```

This executes:
1. Integration test (build verification)
2. Module unit tests (all 12 modules)
3. End-to-end comparison (vs. original code)

### Individual Test Levels

#### 1. Integration Test (Build + Basic Execution)

```bash
cd tests
make integration
```

**What it tests:**
- All modules compile successfully
- Main program links correctly
- Basic execution doesn't crash
- Module files created properly

**Expected output:**
```
✓ Build successful
✓ Executable created
✓ Execution successful
✓ Output appears valid
✓ All 12 module files created
✓ All 13 object files created
```

#### 2. Unit Tests - Original Functions

```bash
cd tests
make unit_tests
```

**What it tests:**
- Basic mathematical functions (DB10, ATGN2, CANG, ZINT)
- Tests against known analytical values
- Extracted from original code for baseline

#### 3. Unit Tests - Basic Modernized Modules

```bash
cd tests
make test_modules
```

**What it tests:**
- Constants module (PI, conversions, etc.)
- Utilities module (db10, atgn2, cang, distance_3d, etc.)
- Data types module (allocation, cleanup)

#### 4. Unit Tests - Comprehensive (All 12 Modules)

```bash
cd tests
make test_all
```

**What it tests:**
- All 12 modules comprehensively
- Constants: PI, conversions, wavelength calculations
- Data types: allocation, initialization, cleanup
- Utilities: all mathematical functions
- Geometry: wire(), helix(), arc() generation
- (Other modules tested via end-to-end)

**Expected output:**
```
Testing Module: nec2_constants
  ✓ PI value correct
  ✓ TWO_PI = 2*PI
  ✓ DEG_TO_RAD conversion
  ...
Testing Module: nec2_geometry
  ✓ wire: created 11 segments
  ✓ wire: coordinates correct
  ...
✓✓✓ ALL TESTS PASSED ✓✓✓
```

#### 5. End-to-End Test (Complete Simulation Comparison)

```bash
cd tests
make end_to_end
```

**What it tests:**
- Builds both original and modernized code
- Runs all test cases through both versions
- Compares outputs numerically
- Benchmarks performance

**Test cases:**
1. `dipole_halfwave.nec` - Basic λ/2 dipole
2. `dipole_folded.nec` - Folded dipole (wire connections)
3. `monopole_ground.nec` - Ground plane effects
4. `dipole_loaded.nec` - Impedance loading

**Expected output:**
```
========================================
Step 1: Building Original Code
✓ Original code compiled successfully

Step 2: Building Modernized Code
✓ Modernized code compiled successfully

Step 3: Generating Reference Outputs
  ✓ Generated reference output

Step 4: Running Modernized Code
  ✓ Generated new output

Step 5: Comparing Outputs
  ✓ Outputs identical

Step 6: Performance Comparison
  Original:   0:01.23 elapsed, 45678 KB
  Modernized: 0:01.25 elapsed, 46234 KB

✓✓✓ ALL TESTS PASSED ✓✓✓
```

## Test Case Details

### Test Case 1: Half-Wave Dipole (dipole_halfwave.nec)

**Purpose:** Baseline validation
- Simple λ/2 dipole in free space
- Known analytical solution
- Tests basic wire geometry and field calculation

**Key outputs to verify:**
- Input impedance ~73 + j42.5 ohms at resonance
- Maximum gain ~2.15 dBi
- Current distribution: sinusoidal

**Tolerance:** 1e-8 relative error

### Test Case 2: Folded Dipole (dipole_folded.nec)

**Purpose:** Test wire connections
- Two parallel wires
- Tests mutual coupling
- Segment connection detection

**Key outputs:**
- Input impedance ~300 ohms (4× regular dipole)
- Similar pattern to regular dipole

**Tolerance:** 1e-8 relative error

### Test Case 3: Monopole Over Ground (monopole_ground.nec)

**Purpose:** Ground plane calculations
- Tests Sommerfeld integrals
- Norton approximation
- Image theory

**Key outputs:**
- Half the impedance of dipole
- Pattern hemisphere (not full sphere)

**Tolerance:** 1e-6 (Sommerfeld approximations less precise)

### Test Case 4: Loaded Dipole (dipole_loaded.nec)

**Purpose:** Impedance loading
- Lumped loads on segments
- Tests network solution
- Modified current distribution

**Key outputs:**
- Changed input impedance
- Modified current taper

**Tolerance:** 1e-8 relative error

## Numerical Tolerances

Different calculations have different expected accuracies:

| Calculation Type | Tolerance | Reason |
|-----------------|-----------|--------|
| Geometry coordinates | 1e-12 | Machine precision |
| Matrix elements | 1e-10 | Numerical integration |
| Current solution | 1e-9 | LU solver accumulation |
| Far fields | 1e-8 | Summation over segments |
| Ground wave (Sommerfeld) | 1e-6 | Integral approximations |
| Pattern gain | 0.01 dB | Pattern integration |
| Input impedance | 0.01% | Network solution |

## Output Comparison Details

The `compare_outputs.py` script extracts and compares:

### 1. Current Distribution
- Complex current (magnitude + phase) on each segment
- Location: After "CURRENT (AMPS)" in output
- Format: Segment number, real part, imaginary part

### 2. Input Impedance
- Real and imaginary parts at feed
- Location: "ANTENNA INPUT PARAMETERS" section
- Format: Impedance (ohms), VSWR, reflection coefficient

### 3. Radiation Pattern
- Gain vs. angle (theta, phi)
- Location: "RADIATION PATTERNS" section
- Format: Angle, vertical gain, horizontal gain, total gain

### 4. Power Budget
- Radiated power, input power, losses
- Location: "POWER BUDGET" section
- Used for energy conservation checks

## Troubleshooting Test Failures

### Build Failures

**Problem:** Modules don't compile

**Solution:**
1. Check compiler version: `gfortran --version` (need 4.8+)
2. Verify module dependency order in Makefile
3. Check for syntax errors in modules
4. Ensure `.mod` files are in obj/ directory

### Numerical Differences

**Problem:** Outputs differ beyond tolerance

**Possible causes:**

1. **Formatting differences** (not actual numerical difference)
   - Solution: Check if diff only shows spacing/format
   - Tool: `diff -w -B` ignores whitespace

2. **Compiler optimization differences**
   - Solution: Use same flags (-O2) for both
   - Check: Compare with -O0 (no optimization)

3. **Actual algorithm change**
   - Solution: Review recent code changes
   - Check: Step through calculation manually
   - Verify: COMMON block data mapped correctly

4. **Uninitialized variables**
   - Solution: Add `-fcheck=all` compiler flag
   - Modern code uses explicit initialization

5. **Array indexing differences**
   - Solution: Fortran is 1-indexed, verify all loops
   - Check: Array bounds with `-fbounds-check`

### Performance Degradation

**Problem:** Modernized code slower than original

**Acceptable:** ±10% difference
**Concerning:** >20% slower

**Possible causes:**

1. **Compiler flags differ**
   - Solution: Use same optimization level

2. **Excessive allocations**
   - Solution: Profile with `gprof` or `valgrind`
   - Move allocations outside loops

3. **Cache inefficiency**
   - Solution: Check array access patterns
   - Column-major (Fortran native) vs row-major

4. **Debug flags enabled**
   - Solution: Remove `-fcheck=all` for production

## Adding New Test Cases

### 1. Create NEC Input File

Create `tests/reference_cases/your_test.nec`:

```
CM Your test description
CE
GW 1 21 0. 0. -.25 0. 0. .25 .001
GE 0
FR 0 1 0 0 299.8 0
EX 0 1 11 0 1. 0.
RP 0 1 361 1000 90. 0. 0. 1.
EN
```

### 2. Regenerate Reference Data

```bash
cd tests
make reference
```

This runs original code on ALL .nec files in reference_cases/

### 3. Run New Test

```bash
make test
```

Or for just your test:
```bash
make compare CASE=your_test
```

### 4. Verify Results

Check `test_results.json` for detailed comparison metrics.

## Continuous Integration

### Pre-commit Hook

Recommended `.git/hooks/pre-commit`:

```bash
#!/bin/bash
cd tests && make test_all
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

Make executable: `chmod +x .git/hooks/pre-commit`

### Pre-push Hook

Recommended `.git/hooks/pre-push`:

```bash
#!/bin/bash
cd tests && make end_to_end
if [ $? -ne 0 ]; then
    echo "End-to-end tests failed. Push aborted."
    exit 1
fi
```

## Test Coverage Goals

Current status:
- ✅ Constants module: 100% coverage
- ✅ Data types module: 100% coverage
- ✅ Utilities module: 100% coverage
- ✅ Geometry module: ~80% coverage (wire, helix, arc tested)
- ⬜ Current module: End-to-end only
- ⬜ Kernel module: End-to-end only
- ⬜ Matrix module: End-to-end only
- ⬜ Solver module: End-to-end only
- ⬜ Sommerfeld module: End-to-end only
- ⬜ Fields module: End-to-end only
- ⬜ Excitation module: End-to-end only
- ⬜ I/O module: End-to-end only

Future work:
- Add unit tests for remaining modules
- Test edge cases (very short wires, extreme geometries)
- Test all NEC card types
- Add more complex test cases (Yagi, loops, patches)

## Performance Benchmarking

### Running Benchmarks

```bash
cd tests
make benchmark
```

### Expected Performance

- Execution time: Within ±10% of original
- Memory usage: May increase ~5-10% (allocatable arrays overhead)
- Compilation time: Longer (more files)

### Profiling

To find performance bottlenecks:

```bash
# Compile with profiling
cd src
make clean
FFLAGS="-O2 -pg" make

# Run test case
./nec2 < ../tests/reference_cases/dipole_halfwave.nec

# Analyze profile
gprof nec2 gmon.out > profile.txt
less profile.txt
```

Look for functions taking >10% of runtime.

## Test Automation Scripts

All test scripts are in `tests/`:

- `generate_reference_data.sh` - Generate all reference outputs
- `test_integration.sh` - Build and basic execution test
- `test_end_to_end.sh` - Complete end-to-end test suite
- `compare_outputs.py` - Numerical output comparison
- `run_test_workflow.sh` - Legacy workflow script

## Final Validation Checklist

Before declaring modernization complete:

- [ ] All modules compile without warnings
- [ ] `make integration` passes
- [ ] `make test_all` passes (all unit tests)
- [ ] `make end_to_end` passes (all test cases identical)
- [ ] Performance within 10% of original
- [ ] Memory usage acceptable
- [ ] All NEC card types tested
- [ ] Documentation complete and accurate
- [ ] Code reviewed and cleaned up

## Questions?

See also:
- `README.md` - Quick start guide
- `test_suite_plan.md` - Detailed test plan
- `TESTING_WORKFLOW.txt` - Step-by-step workflow
- `../BUILD.md` - Build instructions
- `../STATUS.md` - Project status

## Summary of Make Targets

```bash
make help           # Show all available targets
make integration    # Quick build + execution test
make test_modules   # Basic module tests
make test_all       # Comprehensive module tests (all 12)
make end_to_end     # Full comparison vs. original
make full_test      # Run EVERYTHING
make reference      # Generate reference data
make benchmark      # Performance comparison
make clean          # Remove test outputs
```

## Recommended Test Sequence

For first-time testing:

```bash
# 1. Basic build test
make integration

# 2. Unit tests
make test_all

# 3. Full validation
make end_to_end
```

For ongoing development:

```bash
# Quick test during development
make test_all

# Full validation before commit
make full_test
```
