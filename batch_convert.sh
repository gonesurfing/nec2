#!/bin/bash
# Batch convert modules without EQUIVALENCE issues

# Modules to convert (no EQUIVALENCE): 
# nec2d_geometry.f90, nec2d_integration.f90, nec2d_kernels.f90, 
# nec2d_sommerfeld.f90, nec2d_mathutil.f90, nec2d_matrix.f90,
# nec2d_matrix2.f90, nec2d_matrix3.f90, nec2d_nearfield.f90,
# nec2d_utilities.f90, nec2d_rdpat.f90, nec2d_simple.f90, nec2d_io.f90

# Check which don't have EQUIVALENCE
for f in nec2d_geometry.f90 nec2d_integration.f90 nec2d_kernels.f90 nec2d_sommerfeld.f90 nec2d_mathutil.f90 nec2d_matrix.f90 nec2d_matrix2.f90 nec2d_matrix3.f90 nec2d_nearfield.f90 nec2d_utilities.f90 nec2d_rdpat.f90 nec2d_simple.f90 nec2d_io.f90; do
  if ! grep -qi "EQUIVALENCE" "$f"; then
    echo "$f - NO EQUIVALENCE"
  else
    echo "$f - HAS EQUIVALENCE"
  fi
done
