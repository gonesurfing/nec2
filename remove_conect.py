#!/usr/bin/env python3
"""
Remove CONECT subroutine from nec2dxs_integrated.f
Lines 1297-1603 (307 lines)
"""

def remove_conect(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # Remove lines 1297-1603 (0-indexed: 1296-1602)
    # CONECT starts at line 1297 and ends at line 1603
    start_line = 1296  # 0-indexed
    end_line = 1602    # 0-indexed (inclusive)

    # Verify we're removing the right content
    if 'SUBROUTINE CONECT' not in lines[start_line]:
        print(f"ERROR: Line {start_line+1} doesn't contain 'SUBROUTINE CONECT'")
        print(f"Found: {lines[start_line][:50]}")
        return False

    if 'END' not in lines[end_line] and 'LOGICAL FUNCTION ENF' not in lines[end_line+1]:
        print(f"ERROR: Line {end_line+1} doesn't look like the end of CONECT")
        print(f"Found: {lines[end_line][:50]}")
        if end_line+1 < len(lines):
            print(f"Next: {lines[end_line+1][:50]}")
        return False

    print(f"Removing lines {start_line+1} to {end_line+1} (CONECT subroutine)")
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
    success = remove_conect('nec2dxs_integrated.f', 'nec2dxs_integrated.f.new')
    if success:
        import shutil
        shutil.move('nec2dxs_integrated.f.new', 'nec2dxs_integrated.f')
        print("Successfully removed CONECT from integrated file")
    else:
        print("Failed to remove CONECT")
