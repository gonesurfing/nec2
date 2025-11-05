# NEC2 Modernization Test Suite

This directory contains the test infrastructure for validating the modernization of nec2dxs.f.

## Quick Start

```bash
# 1. Compile the original code
cd ..
gfortran -O2 -o nec2dxs nec2dxs.f
cd tests

# 2. Generate reference data
make reference

# 3. After making changes, compile the new version
cd ..
# ... compile your modernized version as nec2dxs_new ...
cd tests

# 4. Run the complete test suite
./run_test_workflow.sh
```

## Directory Structure

```
tests/
├── reference_cases/      # Input .nec files for test cases
├── reference_outputs/    # Expected outputs from original code
├── new_outputs/          # Outputs from modernized code
├── generate_reference_data.sh  # Generate reference outputs
├── compare_outputs.py    # Python script to compare outputs
├── test_unit_functions.f90     # Unit tests for functions
├── run_test_workflow.sh  # Complete test workflow
├── Makefile             # Build and test automation
└── test_suite_plan.md   # Detailed test plan

```

## Test Categories

### 1. Unit Tests

Test individual functions in isolation:

```bash
make unit_tests
```

Tests mathematical and utility functions:
- DB10: dB conversion
- ATGN2: Arc tangent
- CANG: Complex angle
- ZINT: Internal impedance
- etc.

### 2. Integration Tests

Test complete antenna simulations and compare numerical outputs:

```bash
make test
```

Compares:
- Current distributions (segment by segment)
- Input impedances
- Radiation patterns
- Power budgets

### 3. Reference Test Cases

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

## Questions?

See `test_suite_plan.md` for detailed testing methodology.
