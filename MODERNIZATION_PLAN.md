# NEC2 Modernization Plan

## Executive Summary

This document outlines the strategy for modernizing the 10,000-line `nec2dxs.f` FORTRAN 77 file into a maintainable, modular, modern Fortran codebase with comprehensive testing.

## Current State

- **File**: nec2dxs.f (~10,000 lines, ~265 KB)
- **Language**: FORTRAN 77 with fixed-form source
- **Structure**: Main program + 90+ subroutines in single file
- **Data Sharing**: 188 COMMON block declarations
- **Arrays**: Fixed-size arrays defined by parameters

## Modernization Goals

1. **Modularity**: Break into logical, focused modules
2. **Maintainability**: Modern Fortran 90/95+ features
3. **Safety**: Strong typing, intent declarations, allocatable arrays
4. **Testing**: Comprehensive test suite ensuring correctness
5. **Performance**: Maintain or improve execution speed
6. **Compatibility**: Preserve numerical results

## Module Structure

### Core Modules (12 files)

```
src/modules/
├── nec2_data_types.f90      - Derived types replacing COMMON blocks
├── nec2_constants.f90        - Physical and numerical constants
├── nec2_geometry.f90         - Geometry generation (WIRE, PATCH, HELIX, ARC)
├── nec2_matrix.f90           - Matrix assembly and operations
├── nec2_solver.f90           - Linear algebra solvers
├── nec2_fields.f90           - Field calculations (far/near)
├── nec2_sommerfeld.f90       - Ground wave calculations
├── nec2_excitation.f90       - Sources and networks
├── nec2_current.f90          - Current basis functions
├── nec2_kernel.f90           - Interaction kernels
├── nec2_greens.f90           - Green's functions
├── nec2_io.f90               - Input/output operations
└── nec2_utilities.f90        - Utility functions
```

### Subroutine Distribution

| Module | Key Subroutines | Lines (est.) |
|--------|----------------|--------------|
| geometry | DATAGN, WIRE, PATCH, HELIX, ARC, MOVE, REFLC, CONECT | ~800 |
| matrix | CMSET, CMSS, CMSW, CMWS, CMWW, CMNGF, FBLOCK | ~900 |
| solver | FACTR, SOLVE, FACTRS, SOLVES, FACIO, LFACTR, SOLGF | ~700 |
| fields | FFLD, EFLD, NEFLD, NHFLD, GFLD, HSFLD, SFLDS, GWAVE | ~900 |
| sommerfeld | SOM2D, EVLUA, SAOA, GSHANK, ROM1, ROM2, LAMBDA | ~600 |
| excitation | QDSRC, CABC, NETWK, COUPLE, LOAD, ETMNS, INTRP | ~700 |
| current | TBF, SBF, TRIO, HFK, HINTG, HSFLX | ~500 |
| kernel | EKSC, EKSCX, PCINT | ~400 |
| greens | GF, GH, GX, GXX, FACGF, FBNGF, GFIL, REBLK | ~600 |
| io | READGM, READMN, PARSIT, PRNT, GFOUT, RDPAT, NFPAT | ~800 |
| utilities | DB10, CANG, ATGN2, ISEGNO, TEST, UPCASE, CPUSEC | ~300 |
| data_types | Type definitions | ~200 |

## Data Structure Modernization

### COMMON Block Replacement

Replace 188 COMMON declarations with derived types:

```fortran
! Old: COMMON blocks
COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),...

! New: Derived types
type :: geometry_data
  real(8), allocatable :: x(:), y(:), z(:)
  real(8), allocatable :: si(:), bi(:)
  ...
end type
```

### Key Type Definitions

- `geometry_data`: Wire/patch geometry
- `ground_data`: Ground plane parameters
- `current_data`: Current coefficients
- `excitation_data`: Sources and networks
- `field_data`: Field calculation results
- `matrix_data`: Impedance matrix

## Language Modernization

### Fortran 77 → Fortran 90/95+

| Old Feature | New Feature | Benefit |
|-------------|-------------|---------|
| Fixed-form | Free-form | Readable code |
| COMMON blocks | Modules, derived types | Encapsulation |
| Fixed arrays | Allocatable arrays | Dynamic sizing |
| Implicit typing | Implicit None | Type safety |
| No interfaces | Explicit interfaces | Compile-time checks |
| GOTO statements | Structured control flow | Clarity |
| No intent | Intent(in/out/inout) | Safety |
| External | Module procedures | Namespace |

## Testing Strategy

### Three-Tier Testing Approach

```
1. Unit Tests
   ├─ Test individual functions
   ├─ Mathematical functions (DB10, ATGN2, ZINT)
   └─ Utility functions (ISEGNO, UPCASE)

2. Integration Tests
   ├─ Test module combinations
   ├─ Compare old vs. new implementations
   └─ Module-by-module validation

3. Regression Tests
   ├─ Full antenna simulations
   ├─ Compare complete outputs
   └─ Reference test cases
```

### Test Infrastructure (tests/)

- **generate_reference_data.sh**: Create known-good outputs
- **compare_outputs.py**: Numerical comparison with tolerances
- **test_unit_functions.f90**: Unit test framework
- **test_module_template.f90**: Template for module tests
- **run_test_workflow.sh**: Automated test execution
- **Makefile**: Build and test automation

### Reference Test Cases

Pre-defined antenna problems covering key features:

1. **dipole_halfwave.nec**: Basic λ/2 dipole (baseline validation)
2. **dipole_folded.nec**: Wire connections and coupling
3. **monopole_ground.nec**: Ground plane calculations
4. **dipole_loaded.nec**: Impedance loading
5. (More cases in tests/reference_cases/)

### Numerical Tolerances

Different calculations have different expected accuracy:

- Geometry: 1×10⁻¹² (machine precision)
- Matrix elements: 1×10⁻¹⁰ (numerical integration)
- Current solution: 1×10⁻⁹ (linear solver)
- Far fields: 1×10⁻⁸ (summation errors)
- Ground wave: 1×10⁻⁶ (Sommerfeld approximations)

### Comparison Metrics

- Current magnitude: relative error < 1×10⁻⁹
- Current phase: absolute error < 1×10⁻⁸ degrees
- Input impedance: relative error < 0.01%
- Radiation pattern: gain error < 0.01 dB
- Power budget: relative error < 0.01%

## Migration Phases

### Phase 1: Infrastructure (Week 1)

- [x] Create test directory structure
- [x] Write test framework scripts
- [x] Generate reference data
- [ ] Create nec2_data_types.f90
- [ ] Create nec2_constants.f90

### Phase 2: Utilities & Math (Week 1-2)

- [ ] Modernize nec2_utilities.f90
  - DB10, ATGN2, CANG, ISEGNO, etc.
- [ ] Write unit tests
- [ ] Validate against original

### Phase 3: Core Modules (Weeks 2-4)

In order of dependency:

1. [ ] nec2_geometry.f90 (geometry generation)
2. [ ] nec2_current.f90 (basis functions)
3. [ ] nec2_kernel.f90 (interaction kernels)
4. [ ] nec2_greens.f90 (Green's functions)
5. [ ] nec2_matrix.f90 (matrix assembly)
6. [ ] nec2_solver.f90 (linear algebra)

Test each module before proceeding.

### Phase 4: Physics Modules (Weeks 4-6)

1. [ ] nec2_sommerfeld.f90 (ground wave)
2. [ ] nec2_fields.f90 (field calculations)
3. [ ] nec2_excitation.f90 (sources/networks)

### Phase 5: I/O & Integration (Week 6-7)

1. [ ] nec2_io.f90 (input/output)
2. [ ] nec2_main.f90 (main program)
3. [ ] Full integration testing

### Phase 6: Validation & Optimization (Week 7-8)

1. [ ] Complete regression test suite
2. [ ] Performance benchmarking
3. [ ] Documentation
4. [ ] Code review

## Quality Assurance

### Continuous Testing

- Run unit tests after each function modernization
- Run integration tests after each module completion
- Run full regression suite before commits

### Performance Targets

- Execution time: within ±20% of original
- Memory usage: reasonable increase for dynamic allocation
- Numerical accuracy: maintain all tolerances

### Code Quality

- All modules use `implicit none`
- All procedures have explicit interfaces
- All arguments have intent declarations
- Meaningful variable names
- Inline documentation for complex algorithms

## Risk Mitigation

### Numerical Risks

**Risk**: Floating-point arithmetic changes
**Mitigation**: Comprehensive regression testing with tight tolerances

**Risk**: Complex arithmetic differences
**Mitigation**: Use same DCMPLX, validate phase angles

**Risk**: Sommerfeld integrals sensitive
**Mitigation**: Preserve integration algorithms exactly, test ground cases

### Performance Risks

**Risk**: Dynamic allocation overhead
**Mitigation**: Profile and optimize hot paths

**Risk**: Module boundaries add overhead
**Mitigation**: Use inline for small functions, compiler optimization

### Integration Risks

**Risk**: COMMON block data dependencies
**Mitigation**: Map all data flows, test each module in isolation

**Risk**: Hidden state in original code
**Mitigation**: Careful code review, make all state explicit

## Success Criteria

1. ✓ All regression tests pass with tolerances met
2. ✓ Performance within acceptable range (±20%)
3. ✓ All modules independently testable
4. ✓ No COMMON blocks remain
5. ✓ All code uses modern Fortran features
6. ✓ Comprehensive test coverage (>90% of subroutines)
7. ✓ Documentation complete

## Tools & Environment

- **Compiler**: gfortran 4.4+ (or ifort, nagfor)
- **Testing**: Python 3.6+ (for output comparison)
- **Build**: Make or CMake
- **Version Control**: Git
- **Platform**: Linux/Unix (portable to Windows)

## Resources

- **Tests Directory**: `/home/user/nec2/tests/`
- **Test Plan**: `tests/test_suite_plan.md`
- **Test README**: `tests/README.md`
- **Workflow**: `tests/TESTING_WORKFLOW.txt`

## Getting Started

```bash
# 1. Set up testing infrastructure
cd /home/user/nec2/tests
./generate_reference_data.sh

# 2. Start with utilities module
cd ..
# Create src/modules/nec2_utilities.f90
# Port DB10, ATGN2, etc.

# 3. Test as you go
cd tests
make unit_tests

# 4. Continue with next module
# ...

# 5. Full validation
./run_test_workflow.sh
```

## Questions & Support

- See `tests/README.md` for detailed testing instructions
- See `tests/TESTING_WORKFLOW.txt` for step-by-step guide
- Review `tests/test_module_template.f90` for examples

## Timeline

**Total Estimated Time**: 6-8 weeks for complete modernization

- Week 1: Infrastructure & utilities
- Weeks 2-4: Core computational modules
- Weeks 4-6: Physics modules
- Weeks 6-7: I/O & integration
- Week 7-8: Validation & documentation

**Incremental Value**: Each completed module provides immediate benefit in maintainability and testability.
