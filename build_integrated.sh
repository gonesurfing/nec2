#!/bin/bash
# Build integrated version with modernized modules
# This builds:
#   - nec2dxs_integrated.f (legacy code with I/O, geometry, and math utilities removed)
#   - nec2d_io.f90 (modernized I/O - 0 GOTOs)
#   - nec2d_geometry.f90 (modernized geometry - 0 GOTOs)
#   - nec2d_mathutil.f90 (modernized math utilities - 0 GOTOs)

set -e  # Exit on error

echo "=== Building Integrated NEC2D with Modernized Modules ==="
echo

echo "Step 1: Compile modernized I/O module (nec2d_io.f90)"
gfortran -c -O0 -std=legacy nec2d_io.f90 -o nec2d_io.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_io.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 2: Compile modernized geometry module (nec2d_geometry.f90)"
gfortran -c -O0 -std=legacy nec2d_geometry.f90 -o nec2d_geometry.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_geometry.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 3: Compile modernized math utilities module (nec2d_mathutil.f90)"
gfortran -c -O0 -std=legacy nec2d_mathutil.f90 -o nec2d_mathutil.o
if [ $? -eq 0 ]; then
    echo "✓ nec2d_mathutil.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 4: Compile integrated main program (nec2dxs_integrated.f)"
gfortran -c -O0 -std=legacy nec2dxs_integrated.f -o nec2dxs_integrated.o
if [ $? -eq 0 ]; then
    echo "✓ nec2dxs_integrated.f compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 5: Link to create executable"
gfortran -O0 nec2dxs_integrated.o nec2d_io.o nec2d_geometry.o nec2d_mathutil.o -o nec2dxs_integrated
if [ $? -eq 0 ]; then
    echo "✓ Linking successful"
else
    echo "✗ Linking failed"
    exit 1
fi
echo

echo "=== Build Complete ==="
ls -lh nec2dxs_integrated
