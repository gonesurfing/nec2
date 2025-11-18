#!/usr/bin/env python3
"""
Remove I/O subroutines from nec2dxs.f to create nec2dxs_no_io.f
The removed subroutines are now in nec2d_io.f90
"""

import re

# Subroutines to remove (case-insensitive)
IO_SUBROUTINES = [
    'READGM', 'READMN', 'PARSIT', 'UPCASE', 'PRNT',
    'GFIL', 'GFOUT', 'BLCKOT', 'REBLK'
]

def remove_subroutines(input_file, output_file, subroutines_to_remove):
    """Remove specified subroutines from Fortran file"""

    with open(input_file, 'r') as f:
        lines = f.readlines()

    output_lines = []
    in_subroutine = False
    current_subroutine = None
    removed_count = 0

    i = 0
    while i < len(lines):
        line = lines[i]

        # Check for SUBROUTINE declaration (case-insensitive)
        match = re.match(r'^\s+SUBROUTINE\s+(\w+)', line, re.IGNORECASE)
        if match:
            sub_name = match.group(1).upper()
            if sub_name in subroutines_to_remove:
                in_subroutine = True
                current_subroutine = sub_name
                print(f"Removing subroutine: {current_subroutine}")
                removed_count += 1
                i += 1
                continue

        # Check for END (of subroutine)
        if in_subroutine and re.match(r'^\s+END\s*$', line, re.IGNORECASE):
            in_subroutine = False
            print(f"  -> Finished removing {current_subroutine}")
            current_subroutine = None
            i += 1
            continue

        # Skip lines inside subroutines we're removing
        if in_subroutine:
            i += 1
            continue

        # Keep all other lines
        output_lines.append(line)
        i += 1

    # Write output
    with open(output_file, 'w') as f:
        f.writelines(output_lines)

    print(f"\nTotal subroutines removed: {removed_count}")
    print(f"Output written to: {output_file}")
    print(f"Original lines: {len(lines)}")
    print(f"Output lines: {len(output_lines)}")
    print(f"Lines removed: {len(lines) - len(output_lines)}")

if __name__ == '__main__':
    remove_subroutines('nec2dxs.f', 'nec2dxs_no_io.f', IO_SUBROUTINES)
