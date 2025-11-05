# First Tasks: Getting Started with Modernization

## Immediate Action Items

### Task 1: Verify Original Code (5 minutes)

```bash
cd /home/user/nec2

# Compile original
gfortran -O2 -std=legacy -o nec2dxs nec2dxs.f

# Test it works
echo "CM Test" | ./nec2dxs
```

### Task 2: Generate Reference Data (10 minutes)

```bash
cd tests

# Generate golden reference outputs
./generate_reference_data.sh

# Verify reference data was created
ls -lh reference_outputs/
```

### Task 3: Create Constants Module (30 minutes)

**File**: `src/modules/nec2_constants.f90` ✓ (CREATED)

This module:
- Has no dependencies on other modules
- Extracts all DATA and PARAMETER statements
- Provides clean constants for other modules
- Includes helper functions for common conversions

**To compile and test:**

```bash
cd /home/user/nec2

# Create directory structure
mkdir -p src/modules

# Compile the constants module
gfortran -c src/modules/nec2_constants.f90 -o build/nec2_constants.o

# Write a simple test
cat > test_constants.f90 << 'EOF'
program test_constants
  use nec2_constants
  implicit none

  write(*,*) 'PI = ', PI
  write(*,*) 'Speed of light = ', SPEED_OF_LIGHT
  write(*,*) '90 degrees = ', to_radians(90.0d0), ' radians'
  write(*,*) 'Wavelength at 300 MHz = ', wavelength(300.0d0), ' m'
end program
EOF

# Compile and run test
gfortran -o test_constants test_constants.f90 build/nec2_constants.o
./test_constants
```

### Task 4: Create Data Types Module (2-3 hours)

**File**: `src/modules/nec2_data_types.f90`

This is the most important module - it replaces all COMMON blocks.

**Priority COMMON blocks to replace:**

1. **/DATA/** - Geometry data (most used)
   ```fortran
   COMMON /DATA/ X(MAXSEG),Y(MAXSEG),Z(MAXSEG),SI(MAXSEG),BI(MAXSEG),
        1ALP(MAXSEG),BET(MAXSEG),WLAM,ICON1(2*MAXSEG),ICON2(2*MAXSEG),
        2ITAG(2*MAXSEG),ICONX(MAXSEG),LD,N1,N2,N,NP,M1,M2,M,MP,IPSYM
   ```
   Becomes:
   ```fortran
   type :: geometry_data
     real(8), allocatable :: x(:), y(:), z(:)
     real(8), allocatable :: si(:), bi(:)
     real(8), allocatable :: alp(:), bet(:)
     integer, allocatable :: icon1(:), icon2(:)
     integer, allocatable :: itag(:), iconx(:)
     real(8) :: wlam
     integer :: ld, n1, n2, n, np, m1, m2, m, mp, ipsym
   end type
   ```

2. **/GND/** - Ground parameters
3. **/CRNT/** - Current coefficients
4. **/ZLOAD/** - Loading impedances
5. **/CMB/** - Matrix storage

**Start with a skeleton:**

```bash
cd /home/user/nec2
```

Would you like me to create the `nec2_data_types.f90` module next?

### Task 5: Start with Simple Utilities (1-2 hours)

Pick the easiest functions to modernize first:

1. **DB10** - dB conversion (8 lines)
2. **ATGN2** - arctangent (18 lines)
3. **CANG** - complex angle (13 lines)
4. **ISEGNO** - segment number lookup (~40 lines)

These have:
- No COMMON blocks (or minimal)
- Simple logic
- Easy to test

Create `src/modules/nec2_utilities.f90` and port these functions.

## Recommended Order

```
Day 1:
├─ Verify original code ✓
├─ Generate reference data
├─ Create nec2_constants.f90 ✓
└─ Test constants module

Day 2-3:
├─ Create nec2_data_types.f90
└─ Define all derived types

Day 4-5:
├─ Create nec2_utilities.f90
├─ Port simple functions (DB10, ATGN2, CANG)
└─ Write unit tests for utilities

Week 2:
├─ Start nec2_geometry.f90
├─ Port WIRE, PATCH, HELIX
└─ Test geometry generation
```

## Your Next Command

```bash
# Compile original and generate reference data
cd /home/user/nec2
gfortran -O2 -std=legacy -o nec2dxs nec2dxs.f
cd tests
./generate_reference_data.sh
```

Then let me know if you want me to create `nec2_data_types.f90`!
