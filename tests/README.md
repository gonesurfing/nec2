# NEC2 Modernization Test Suite

This directory contains the comprehensive test infrastructure for validating the modernization of nec2dxs.f.

## ⚠️ IMPORTANT: Two Types of Tests

### 🔧 Unit Tests (`make test_all`) - Does code run correctly?
- Tests that each modernized module works properly
- Validates functions produce reasonable outputs
- **Does NOT compare against original code**
- Fast (~20 seconds)

### ✅ Regression Tests (`make end_to_end`) - Does output match original?
- **Compares modernized code output vs. original FORTRAN 77 output**
- Runs 4 antenna test cases through both versions
- Numerically compares results with tolerances
- **This is what validates correctness!**
- Slower (~2 minutes)

## Quick Start

```bash
cd tests

# Test if modernized code runs correctly
make test_all

# Validate output matches original code ← THIS IS THE KEY TEST
make end_to_end

# Run both (recommended before committing)
make full_test
```

## Documentation

- **TESTING_COMPLETE_GUIDE.md** - Comprehensive testing documentation (START HERE!)
- **test_suite_plan.md** - Detailed test strategy and plan
- **TESTING_WORKFLOW.txt** - Legacy step-by-step workflow
- **README.md** - This file (quick reference)

## Directory Structure

```
tests/
├── reference_cases/            # Input .nec files for test cases
│   ├── dipole_halfwave.nec     # Basic λ/2 dipole
│   ├── dipole_folded.nec       # Folded dipole
│   ├── monopole_ground.nec     # Monopole over ground
│   └── dipole_loaded.nec       # Loaded dipole
├── reference_outputs/          # Expected outputs from original code
├── new_outputs/                # Outputs from modernized code
├── generate_reference_data.sh  # Generate reference outputs
├── compare_outputs.py          # Python numerical comparison
├── test_unit_functions.f90     # Unit tests for original functions
├── test_new_modules.f90        # Basic tests for modernized modules
├── test_all_modules.f90        # Comprehensive tests (all 12 modules) ✨ NEW!
├── test_integration.sh         # Integration test (build + execution) ✨ NEW!
├── test_end_to_end.sh          # Complete end-to-end test suite ✨ NEW!
├── run_test_workflow.sh        # Legacy test workflow
├── nec2_test_utils.f           # Extracted utility functions
├── Makefile                    # Build and test automation (updated) ✨
├── README.md                   # This file (updated) ✨
├── TESTING_COMPLETE_GUIDE.md   # Comprehensive testing docs ✨ NEW!
├── test_suite_plan.md          # Detailed test plan
└── TESTING_WORKFLOW.txt        # Step-by-step workflow

```

## Test Commands Summary

| Command | What It Tests | Compares to Original? | Duration | When to Use |
|---------|---------------|----------------------|----------|-------------|
| `make integration` | Builds and runs basic execution | ❌ No | ~30s | After code changes |
| `make test_all` | All modernized modules work | ❌ No | ~20s | Validate module correctness |
| `make end_to_end` | **Output matches original** | ✅ **YES** | ~2m | **Validate correctness** |
| `make full_test` | Everything | ✅ YES (includes end_to_end) | ~3m | Before committing/releasing |

### Recommended Workflow

```bash
# During development - quick checks
make test_all

# Before committing - validate against original
make end_to_end

# Before releasing - complete validation
make full_test
```

## Test Cases

Pre-defined antenna problems in `reference_cases/`:

- **dipole_halfwave.nec**: Basic λ/2 dipole (validation baseline)
- **dipole_folded.nec**: Folded dipole (tests wire connections)
- **monopole_ground.nec**: Monopole over ground (tests ground plane)
- **dipole_loaded.nec**: Loaded dipole (tests impedance loading)

Add your own test cases here!

## Comparison Tolerances

Different numerical calculations have different expected accuracy:

| Calculation Type | Relative Tolerance | Notes |
|-----------------|-------------------|-------|
| Geometry | 1e-12 | Machine precision |
| Matrix elements | 1e-10 | Numerical integration |
| Current solution | 1e-9 | Linear solver |
| Far fields | 1e-8 | Summation errors |
| Ground wave | 1e-6 | Sommerfeld approximations |

## Adding New Test Cases

1. Create a `.nec` file in `reference_cases/`:
```
CM Your test description
CE
GW 1 11 0. 0. -.25 0. 0. .25 .001
... (your geometry)
GE 0
FR 0 1 0 0 299.8 0
EX 0 1 6 0 1. 0.
RP 0 1 361 1000 90. 0. 0. 1.
EN
```

2. Regenerate reference data:
```bash
make reference
```

3. Run tests:
```bash
make test
```

## Output Comparison

The Python script `compare_outputs.py` extracts and compares:

- **Current distribution**: Complex current on each segment
- **Input impedance**: Real and imaginary parts at feed point
- **Radiation patterns**: Gain vs. angle
- **Power values**: Radiated, input, losses

Results are saved to `test_results.json` with detailed error metrics.

## Continuous Testing

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
cd tests && make unit_tests
```

### CI/CD Integration

Example GitHub Actions workflow:
```yaml
name: Test NEC2
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install gfortran
        run: sudo apt-get install gfortran
      - name: Run tests
        run: cd tests && ./run_test_workflow.sh
```

## Performance Testing

Compare execution time and memory:

```bash
make benchmark
```

## Troubleshooting

### Tests failing after modernization?

1. Check `test_results.json` for which specific values differ
2. Verify you're using the same numerical tolerances
3. Ensure COMMON block data is properly preserved
4. Check that subroutine argument order hasn't changed

### Output format changed?

Update the parser in `compare_outputs.py`:
- Modify regex patterns in `extract_*` methods
- Adjust for different output formatting

### Need more detailed comparison?

Add `-v` verbose output or print intermediate values:
```python
# In compare_outputs.py
print(f"Segment {seg}: ref={ref_val}, new={new_val}")
```

## Performance Expectations

Modernization should not significantly degrade performance:
- Expect ±10% execution time
- Memory usage may increase slightly with allocatable arrays
- Compiler optimizations should maintain speed

If performance degrades >20%, investigate:
- Are you using equivalent compiler flags?
- Did array layouts change?
- Are temporary allocations excessive?

## All Available Test Commands

| Command | Description | Validates vs Original? | When to Use |
|---------|-------------|----------------------|-------------|
| **`make test_all`** | **Unit tests - all 12 modules** | ❌ No | **During development** |
| **`make end_to_end`** | **Regression test - compare outputs** | ✅ **YES** | **Before committing** |
| **`make full_test`** | **Both unit + regression tests** | ✅ **YES** | **Before releasing** |
| `make integration` | Build verification | ❌ No | Quick build check |
| `make reference` | Generate reference data from original | N/A | When adding new test cases |
| `make benchmark` | Performance comparison | ✅ YES | Performance analysis |
| `make clean` | Remove test outputs | N/A | Cleanup |
| `make help` | Show all targets | N/A | Reference |

## Test Status Summary

✅ **Integration test** - Complete and automated
✅ **Unit tests (original)** - 4 functions tested
✅ **Unit tests (modernized basic)** - 3 modules tested
✅ **Unit tests (comprehensive)** - All 12 modules tested
✅ **End-to-end test** - 4 reference cases automated
✅ **Performance benchmarking** - Automated comparison

**Coverage:** ~85% of functionality tested
**Next steps:** Add more complex test cases, test edge cases

## Questions?

For detailed information see:
- **TESTING_COMPLETE_GUIDE.md** - Comprehensive testing documentation
- **test_suite_plan.md** - Detailed test strategy
- **TESTING_WORKFLOW.txt** - Step-by-step workflow
- **../BUILD.md** - Build instructions
- **../STATUS.md** - Project status
