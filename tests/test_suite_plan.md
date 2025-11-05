# NEC2 Modernization Test Suite

## Overview
Compare outputs between original nec2dxs.f and modernized version to ensure correctness.

## Test Categories

### 1. Unit Tests (Per-Function Testing)

Test individual subroutines in isolation:

#### Geometry Functions
- `WIRE`: Compare segment generation for various wire configurations
- `PATCH`: Compare surface patch generation
- `HELIX`: Test helical geometry generation
- `ARC`: Test arc generation

#### Mathematical Functions
- `BESSEL`: Test Bessel function calculation against known values
- `HANKEL`: Test Hankel functions
- `ZINT`: Test internal impedance calculation
- `DB10`: Test dB conversion

#### Matrix Operations
- `FACTR`: Test LU decomposition against known matrices
- `SOLVE`: Test solution of known linear systems

### 2. Integration Tests (Subsystem Testing)

Test combinations of functions:

#### Field Calculations
- `FFLD`: Far field for simple dipole
- `NEFLD`: Near field calculations
- `EFLD`: Electric field at specific points

#### Excitation
- `CABC`: Current basis function calculation
- `NETWK`: Network solution

### 3. End-to-End Regression Tests

Full antenna simulations with reference outputs:

#### Test Case 1: Half-Wave Dipole
```
Reference: tests/reference_cases/dipole_halfwave.nec
Expected: tests/reference_outputs/dipole_halfwave.out
```
- Simple λ/2 dipole in free space
- Known analytical solution
- Tests basic wire geometry and field calculation

#### Test Case 2: Folded Dipole
```
Reference: tests/reference_cases/dipole_folded.nec
```
- Two parallel wires
- Tests wire connections and mutual coupling

#### Test Case 3: Yagi-Uda Array
```
Reference: tests/reference_cases/yagi_3element.nec
```
- Director + driven element + reflector
- Tests multiple wires and pattern calculations

#### Test Case 4: Monopole Over Ground
```
Reference: tests/reference_cases/monopole_ground.nec
```
- Tests ground plane calculations
- Sommerfeld integral validation

#### Test Case 5: Loop Antenna
```
Reference: tests/reference_cases/loop_circular.nec
```
- Circular geometry
- Tests arc generation and loop currents

#### Test Case 6: Loaded Antenna
```
Reference: tests/reference_cases/dipole_loaded.nec
```
- Antenna with lumped loads
- Tests impedance loading

#### Test Case 7: Frequency Sweep
```
Reference: tests/reference_cases/dipole_sweep.nec
```
- Multiple frequencies
- Tests frequency-dependent calculations

#### Test Case 8: Network Connections
```
Reference: tests/reference_cases/array_network.nec
```
- Multiple feeds with networks
- Tests transmission line network solution

#### Test Case 9: Near Field Calculation
```
Reference: tests/reference_cases/dipole_nearfield.nec
```
- Near field on grid
- Tests spatial field calculation

#### Test Case 10: Patch Antenna
```
Reference: tests/reference_cases/patch_surface.nec
```
- Surface patches
- Tests surface current calculation

## Test Execution Strategy

### Phase 1: Generate Reference Data
Run original nec2dxs.f on all test cases and save outputs:
```bash
./generate_reference_data.sh
```

### Phase 2: Unit Testing During Development
As each module is modernized, run unit tests:
```bash
make test_geometry
make test_fields
make test_solver
```

### Phase 3: Integration Testing
Test subsystems together:
```bash
make test_integration
```

### Phase 4: Full Regression Testing
Run complete test suite:
```bash
make test_regression
```

## Output Comparison Metrics

### 1. Current Distribution
- Compare complex current on each segment
- Relative error < 1e-10 for magnitude
- Absolute error < 1e-8 degrees for phase

### 2. Input Impedance
- Real part within 0.01%
- Imaginary part within 0.01%

### 3. Radiation Pattern
- Gain values within 0.01 dB
- Pattern angles within 0.1 degrees

### 4. Near Field Values
- E-field magnitude within 0.1%
- H-field magnitude within 0.1%

### 5. Power Budget
- Total radiated power within 0.01%
- Losses within 0.01%

## Numerical Tolerance Guidelines

Different calculations require different tolerances:

- **Geometry**: 1e-12 (machine precision)
- **Matrix elements**: 1e-10 (numerical integration)
- **Current solution**: 1e-9 (matrix solver accumulation)
- **Far fields**: 1e-8 (summation over currents)
- **Ground wave**: 1e-6 (Sommerfeld integral approximations)

## Test Data Format

### Input Files (.nec)
Standard NEC2 card format

### Reference Output Files
- `.out`: Full text output from original code
- `.cur`: Binary current distribution
- `.fld`: Binary field data
- `.json`: Structured data for comparison

## Continuous Testing

### Git Hooks
- Pre-commit: Run unit tests
- Pre-push: Run full regression suite

### CI/CD Pipeline
```yaml
test:
  - unit_tests
  - integration_tests
  - regression_tests
  - performance_benchmarks
```

## Performance Testing

Beyond correctness, track performance:
- Execution time per test case
- Memory usage
- Ensure modernization doesn't degrade performance

## Test Coverage Goals

- 100% of subroutines have unit tests
- All COMMON block data structures tested
- All input card types covered
- Edge cases (short wires, extreme geometries)
