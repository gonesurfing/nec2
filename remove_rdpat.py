#!/usr/bin/env python3
"""
Remove RDPAT subroutine from nec2dxs_integrated.f
Lines 2566-2845 (280 lines)
"""

def remove_rdpat(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # Remove lines 2566-2845 (0-indexed: 2565-2844)
    # RDPAT starts at line 2566 and ends at line 2845
    start_line = 2565  # 0-indexed
    end_line = 2845    # 0-indexed (inclusive)

    # Verify we're removing the right content
    if 'SUBROUTINE RDPAT' not in lines[start_line]:
        print(f"ERROR: Line {start_line+1} doesn't contain 'SUBROUTINE RDPAT'")
        print(f"Found: {lines[start_line][:50]}")
        return False

    if 'END' not in lines[end_line] and 'subroutine stopwtch' not in lines[end_line+1]:
        print(f"ERROR: Line {end_line+1} doesn't look like the end of RDPAT")
        print(f"Found: {lines[end_line][:50]}")
        print(f"Next: {lines[end_line+1][:50]}")
        return False

    print(f"Removing lines {start_line+1} to {end_line+1} (RDPAT subroutine)")
    print(f"First line: {lines[start_line][:50]}")
    print(f"Last line: {lines[end_line][:50]}")

    # Remove the routine
    new_lines = lines[:start_line] + lines[end_line+1:]

    with open(output_file, 'w') as f:
        f.writelines(new_lines)

    removed = end_line - start_line + 1
    print(f"Removed {removed} lines")
    print(f"Original: {len(lines)} lines")
    print(f"New: {len(new_lines)} lines")
    return True

if __name__ == '__main__':
    success = remove_rdpat('nec2dxs_integrated.f', 'nec2dxs_integrated.f.new')
    if success:
        import shutil
        shutil.move('nec2dxs_integrated.f.new', 'nec2dxs_integrated.f')
        print("Successfully removed RDPAT from integrated file")
    else:
        print("Failed to remove RDPAT")
