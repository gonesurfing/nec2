#!/bin/bash
# Build test version with modernized I/O module

echo "=== Step 1: Extract I/O subroutine names from nec2d_io.f90 ==="
grep "^subroutine" nec2d_io.f90 | awk '{print $2}' | cut -d'(' -f1

echo -e "\n=== Step 2: Create nec2dxs_no_io.f (remove I/O subroutines) ==="
# This is a placeholder - we'll need to actually remove the subroutines
# For now, let's try a different approach: compile both and link

echo -e "\n=== Step 3: Compile modernized I/O module ==="
gfortran -c -O0 nec2d_io.f90 -o nec2d_io.o 2>&1
if [ $? -eq 0 ]; then
    echo "✓ nec2d_io.f90 compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi

echo -e "\n=== Step 4: Check if we can build modular version ==="
echo "I/O subroutines in nec2d_io.f90:"
grep "^subroutine" nec2d_io.f90 | wc -l
echo "Total subroutines in nec2dxs.f:"
grep -i "^      SUBROUTINE" nec2dxs.f | wc -l

