#!/usr/bin/env python3
"""
Remove CMNGF routine from nec2dxs_integrated.f
Lines 1028-1296 (269 lines) - Matrix NGF Filling routine
"""

def remove_cmngf():
    input_file = 'nec2dxs_integrated.f'
    output_file = 'nec2dxs_integrated_new.f'
    backup_file = 'nec2dxs_integrated.f.bak_cmngf'

    # Read all lines
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # Backup original
    with open(backup_file, 'w') as f:
        f.writelines(lines)

    # Remove lines 1028-1296 (0-indexed: 1027-1295)
    # CMNGF starts at line 1028 and ends at line 1296
    start_idx = 1027  # Line 1028 (0-indexed)
    end_idx = 1295    # Line 1296 (0-indexed, inclusive)

    # Verify we're removing the right section
    if 'SUBROUTINE CMNGF' not in lines[start_idx]:
        print(f"ERROR: Line {start_idx+1} does not contain 'SUBROUTINE CMNGF'")
        print(f"Found: {lines[start_idx]}")
        return False

    if 'END' not in lines[end_idx]:
        print(f"ERROR: Line {end_idx+1} does not contain 'END'")
        print(f"Found: {lines[end_idx]}")
        return False

    print(f"Removing CMNGF routine (lines {start_idx+1}-{end_idx+1})")
    print(f"First line: {lines[start_idx].strip()}")
    print(f"Last line: {lines[end_idx].strip()}")

    # Create new file without CMNGF
    new_lines = lines[:start_idx] + lines[end_idx+1:]

    # Write new file
    with open(output_file, 'w') as f:
        f.writelines(new_lines)

    print(f"\nOriginal lines: {len(lines)}")
    print(f"Lines removed: {end_idx - start_idx + 1}")
    print(f"New lines: {len(new_lines)}")
    print(f"\nBackup saved to: {backup_file}")
    print(f"New file: {output_file}")
    print("\nTo apply changes:")
    print(f"  mv {output_file} {input_file}")

    return True

if __name__ == '__main__':
    success = remove_cmngf()
    exit(0 if success else 1)
