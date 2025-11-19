#!/bin/bash
# Build integrated version with modernized modules
# This builds:
#   - nec2dxs_integrated.f (legacy code with modernized modules removed)
#   - nec2d_io.f90 (modernized I/O - 0 GOTOs)
#   - nec2d_geometry.f90 (modernized geometry - 0 GOTOs)
#   - nec2d_mathutil.f90 (modernized math utilities - 0 GOTOs)
#   - nec2d_simple.f90 (modernized simple routines - 0 GOTOs)
#   - nec2d_bessel.f90 (modernized Bessel functions - 0 GOTOs)
#   - nec2d_kernels.f90 (modernized kernels & solvers - 0 GOTOs)
#   - nec2d_matrix.f90 (modernized matrix & coupling - 0 GOTOs)
#   - nec2d_fields.f90 (modernized field calculations - 0 GOTOs)
#   - nec2d_integration.f90 (modernized integration & factorization - 0 GOTOs)
#   - nec2d_nearfield.f90 (modernized near field calculations - 0 GOTOs)
#   - nec2d_matrix2.f90 (modernized matrix computation - 0 GOTOs)
#   - nec2d_utilities.f90 (modernized utilities & computation - 0 GOTOs)

set -e  # Exit on error

# Compiler flags
FFLAGS="-O0 -std=legacy -Wall -Wno-unused-parameter"
# -std=legacy: Accept REAL*8, COMPLEX*16, Hollerith formats
# -Wall: Enable all warnings
# -Wno-unused-parameter: Suppress warnings for unused PARAMETERs (common in legacy code)

echo "=== Building Integrated NEC2D with Modernized Modules ==="
echo

echo "Step 1: Compile modernized I/O module (nec2d_io.f90)"
gfortran -c $FFLAGS nec2d_io.f90 -o nec2d_io.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_io.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 2: Compile modernized geometry module (nec2d_geometry.f90)"
gfortran -c $FFLAGS nec2d_geometry.f90 -o nec2d_geometry.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_geometry.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 3: Compile modernized math utilities module (nec2d_mathutil.f90)"
gfortran -c $FFLAGS nec2d_mathutil.f90 -o nec2d_mathutil.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_mathutil.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 4: Compile modernized simple routines module (nec2d_simple.f90)"
gfortran -c $FFLAGS nec2d_simple.f90 -o nec2d_simple.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_simple.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 5: Compile modernized Bessel functions module (nec2d_bessel.f90)"
gfortran -c $FFLAGS nec2d_bessel.f90 -o nec2d_bessel.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_bessel.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 6: Compile modernized kernels module (nec2d_kernels.f90)"
gfortran -c $FFLAGS nec2d_kernels.f90 -o nec2d_kernels.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_kernels.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 7: Compile modernized matrix module (nec2d_matrix.f90)"
gfortran -c $FFLAGS nec2d_matrix.f90 -o nec2d_matrix.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_matrix.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 8: Compile modernized fields module (nec2d_fields.f90)"
gfortran -c $FFLAGS nec2d_fields.f90 -o nec2d_fields.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_fields.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 9: Compile modernized integration module (nec2d_integration.f90)"
gfortran -c $FFLAGS nec2d_integration.f90 -o nec2d_integration.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_integration.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 10: Compile modernized near field module (nec2d_nearfield.f90)"
gfortran -c $FFLAGS nec2d_nearfield.f90 -o nec2d_nearfield.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_nearfield.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 11: Compile modernized matrix module 2 (nec2d_matrix2.f90)"
gfortran -c $FFLAGS nec2d_matrix2.f90 -o nec2d_matrix2.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_matrix2.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 12: Compile modernized utilities module (nec2d_utilities.f90)"
gfortran -c $FFLAGS nec2d_utilities.f90 -o nec2d_utilities.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_utilities.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 13: Compile integrated main program (nec2dxs_integrated.f)"
gfortran -c $FFLAGS nec2dxs_integrated.f -o nec2dxs_integrated.o
if [ $? -eq 0 ]; then
    echo "✓ nec2dxs_integrated.f compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 14: Link to create executable"
gfortran -O0 nec2dxs_integrated.o nec2d_io.o nec2d_geometry.o nec2d_mathutil.o nec2d_simple.o nec2d_bessel.o nec2d_kernels.o nec2d_matrix.o nec2d_fields.o nec2d_integration.o nec2d_nearfield.o nec2d_matrix2.o nec2d_utilities.o -o nec2dxs_integrated
if [ $? -eq 0 ]; then
    echo "✓ Linking successful"
else
    echo "✗ Linking failed"
    exit 1
fi
echo

echo "=== Build Complete ==="
ls -lh nec2dxs_integrated
