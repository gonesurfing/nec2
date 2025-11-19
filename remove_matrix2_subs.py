#!/usr/bin/env python3
"""
Remove CMSET, CMSS, FBNGF from nec2dxs_integrated.f
"""

# Read the file
with open('nec2dxs_integrated.f', 'r') as f:
    lines = f.readlines()

# Remove subroutines (in reverse order to avoid line number shifts)
# FBNGF: lines 3761-3834 (indices 3760-3833)
# CMSS: lines 1941-2025 (indices 1940-2024)
# CMSET: lines 1828-1940 (indices 1827-1939)

# Remove FBNGF first (highest line number)
del lines[3760:3834]

# Remove CMSS
del lines[1940:2025]

# Remove CMSET
del lines[1827:1940]

# Write the modified file
with open('nec2dxs_integrated.f', 'w') as f:
    f.writelines(lines)

print("Removed CMSET (113 lines), CMSS (85 lines), FBNGF (74 lines)")
print("Total: 272 lines removed")
