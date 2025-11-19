#!/usr/bin/env python3
"""
Remove CMSW, CMWS, CMWW subroutines from nec2dxs_integrated.f
These have been moved to nec2d_matrix3.f90
"""

import re

def remove_subroutines(input_file, output_file):
    """Remove specified subroutines from the integrated file."""

    with open(input_file, 'r') as f:
        lines = f.readlines()

    subroutines_to_remove = ['CMSW', 'CMWS', 'CMWW']

    in_subroutine = False
    current_sub = None
    removed_lines = 0
    kept_lines = []

    i = 0
    while i < len(lines):
        line = lines[i]
        upper_line = line.upper()

        sub_match = re.match(r'\s*SUBROUTINE\s+(\w+)', upper_line)

        if sub_match and not in_subroutine:
            sub_name = sub_match.group(1)
            if sub_name in subroutines_to_remove:
                in_subroutine = True
                current_sub = sub_name
                print(f"Removing subroutine {current_sub}...")
                i += 1
                continue

        if in_subroutine:
            if re.match(r'\s*END(\s+SUBROUTINE)?(\s+\w+)?\s*$', upper_line):
                removed_lines += 1
                in_subroutine = False
                print(f"  Completed removal of {current_sub}")
                current_sub = None
                i += 1
                continue
            else:
                removed_lines += 1
                i += 1
                continue

        kept_lines.append(line)
        i += 1

    with open(output_file, 'w') as f:
        f.writelines(kept_lines)

    print(f"\nRemoved {removed_lines} lines")
    print(f"Kept {len(kept_lines)} lines")
    print(f"Output written to {output_file}")

if __name__ == '__main__':
    remove_subroutines('nec2dxs_integrated.f', 'nec2dxs_integrated_new.f')
