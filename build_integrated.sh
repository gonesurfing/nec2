#!/bin/bash
# Build integrated version with modernized I/O module
# This builds nec2dxs_integrated.f (legacy code with I/O removed) + nec2d_io.f90 (modernized I/O)

set -e  # Exit on error

echo "=== Building Integrated NEC2D with Modernized I/O Module ==="
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

echo "Step 2: Compile integrated main program (nec2dxs_integrated.f)"
gfortran -c -O0 -std=legacy nec2dxs_integrated.f -o nec2dxs_integrated.o
if [ $? -eq 0 ]; then
    echo "✓ nec2dxs_integrated.f compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi
echo

echo "Step 3: Link to create executable"
gfortran -O0 nec2dxs_integrated.o nec2d_io.o -o nec2dxs_integrated
if [ $? -eq 0 ]; then
    echo "✓ Linking successful"
else
    echo "✗ Linking failed"
    exit 1
fi
echo

echo "=== Build Complete ==="
ls -lh nec2dxs_integrated
