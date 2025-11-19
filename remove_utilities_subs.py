#!/usr/bin/env python3
"""
Remove TRIO, UNERE, ROM1 subroutines from nec2dxs_integrated.f
These have been moved to nec2d_utilities.f90
"""

import re

def remove_subroutines(input_file, output_file):
    """Remove specified subroutines from the integrated file."""

    with open(input_file, 'r') as f:
        lines = f.readlines()

    # Track which subroutines we're removing
    subroutines_to_remove = ['TRIO', 'UNERE', 'ROM1']

    # State machine to track removal
    in_subroutine = False
    current_sub = None
    removed_lines = 0
    kept_lines = []

    i = 0
    while i < len(lines):
        line = lines[i]
        upper_line = line.upper()

        # Check if this is a SUBROUTINE declaration
        sub_match = re.match(r'\s*SUBROUTINE\s+(\w+)', upper_line)

        if sub_match and not in_subroutine:
            sub_name = sub_match.group(1)
            if sub_name in subroutines_to_remove:
                # Start removing this subroutine
                in_subroutine = True
                current_sub = sub_name
                print(f"Removing subroutine {current_sub}...")
                i += 1
                continue

        # Check for END of subroutine
        if in_subroutine:
            # Look for "END" or "END SUBROUTINE" or "END SUBROUTINE NAME"
            if re.match(r'\s*END(\s+SUBROUTINE)?(\s+\w+)?\s*$', upper_line):
                # Found the end, skip this line too
                removed_lines += 1
                in_subroutine = False
                print(f"  Completed removal of {current_sub}")
                current_sub = None
                i += 1
                continue
            else:
                # Inside subroutine being removed, skip line
                removed_lines += 1
                i += 1
                continue

        # Keep this line
        kept_lines.append(line)
        i += 1

    # Write output
    with open(output_file, 'w') as f:
        f.writelines(kept_lines)

    print(f"\nRemoved {removed_lines} lines")
    print(f"Kept {len(kept_lines)} lines")
    print(f"Output written to {output_file}")

if __name__ == '__main__':
    remove_subroutines('nec2dxs_integrated.f', 'nec2dxs_integrated_new.f')
