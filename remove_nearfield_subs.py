#!/usr/bin/env python3
"""
Remove INTX, NHFLD, HINTG from nec2dxs_integrated.f
"""

# Read the file
with open('nec2dxs_integrated.f', 'r') as f:
    lines = f.readlines()

# Remove subroutines (in reverse order to avoid line number shifts)
# NHFLD: lines 5519-5628 (indices 5518-5627)
# INTX: lines 4560-4669 (indices 4559-4668)
# HINTG: lines 4204-4290 (indices 4203-4289)

# Remove NHFLD first (highest line number)
del lines[5518:5628]

# Remove INTX
del lines[4559:4669]

# Remove HINTG
del lines[4203:4290]

# Write the modified file
with open('nec2dxs_integrated.f', 'w') as f:
    f.writelines(lines)

print("Removed HINTG (87 lines), INTX (110 lines), NHFLD (110 lines)")
print("Total: 307 lines removed")
