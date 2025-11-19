#!/usr/bin/env python3
"""Analyze COMMON block usage in NEC2 modernized code"""
import re
from collections import defaultdict

# Track which files use which COMMON blocks
common_usage = defaultdict(list)

# Analyze modules
import glob
for fname in sorted(glob.glob('nec2d_*.f90')):
    with open(fname) as f:
        content = f.read()
        # Find COMMON block declarations
        for match in re.finditer(r'COMMON\s+/(\w+)/', content, re.IGNORECASE):
            block = match.group(1)
            common_usage[block].append(fname)

# Analyze main program
with open('nec2dxs_integrated.f') as f:
    content = f.read()
    for match in re.finditer(r'COMMON\s+/(\w+)/', content, re.IGNORECASE):
        block = match.group(1)
        if 'nec2dxs_integrated.f' not in common_usage[block]:
            common_usage[block].append('nec2dxs_integrated.f')

# Print report
print("=" * 70)
print("COMMON BLOCK USAGE ANALYSIS")
print("=" * 70)
print()

for block in sorted(common_usage.keys()):
    print(f"/{block}/")
    print(f"  Used in {len(common_usage[block])} file(s):")
    for fname in common_usage[block]:
        print(f"    - {fname}")
    print()

print("=" * 70)
print(f"Total COMMON blocks: {len(common_usage)}")
print("=" * 70)
