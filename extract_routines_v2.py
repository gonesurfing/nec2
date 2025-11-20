#!/usr/bin/env python3
"""
Extract remaining routines from nec2dxs_integrated.f,
convert to lowercase free-form Fortran 90, and add to modules.
Improved version with better continuation handling.
"""

import re

def convert_fixed_to_free(lines):
    """Convert fixed-form Fortran to free-form with proper continuation handling."""
    result = []
    i = 0

    while i < len(lines):
        line = lines[i].rstrip()

        if not line:
            result.append('')
            i += 1
            continue

        # Check for comment (C or c or * in column 1)
        if line and line[0] in 'Cc*':
            comment_text = line[1:] if len(line) > 1 else ''
            result.append('!' + comment_text)
            i += 1
            continue

        # Get the main statement (columns 7-72 in fixed form)
        if len(line) >= 6:
            label = line[:5].strip()
            stmt = line[6:72] if len(line) > 6 else ''
        else:
            label = ''
            stmt = line

        # Check for continuation lines following this one
        full_stmt = stmt.rstrip()
        j = i + 1
        while j < len(lines):
            next_line = lines[j].rstrip()
            # Check if this is a continuation line (non-blank/non-zero in column 6)
            if len(next_line) >= 6 and next_line[5] not in ' 0' and next_line[0] not in 'Cc*':
                # This is a continuation - append the content (columns 7+)
                cont_text = next_line[6:72] if len(next_line) > 6 else ''
                full_stmt = full_stmt + cont_text.rstrip()
                j += 1
            else:
                break

        # Format the output
        if label:
            result.append(label + ' ' + full_stmt)
        else:
            result.append('  ' + full_stmt)

        i = j

    return result

def convert_to_lowercase(lines):
    """Convert code to lowercase, preserving strings and comments."""
    result = []

    for line in lines:
        if not line.strip():
            result.append(line)
            continue

        # Find comment position
        comment_pos = -1
        in_string = False
        string_char = None
        for idx, char in enumerate(line):
            if char in ('"', "'") and not in_string:
                in_string = True
                string_char = char
            elif char == string_char and in_string:
                in_string = False
                string_char = None
            elif char == '!' and not in_string:
                comment_pos = idx
                break

        if comment_pos >= 0:
            code_part = line[:comment_pos]
            comment_part = line[comment_pos:]
        else:
            code_part = line
            comment_part = ''

        # Protect strings
        strings = []
        def save_string(match):
            strings.append(match.group(0))
            return f'__STRING_{len(strings)-1}__'

        code_part = re.sub(r"'[^']*'|\"[^\"]*\"", save_string, code_part)

        # Convert to lowercase
        code_part = code_part.lower()

        # Restore strings
        for idx, s in enumerate(strings):
            code_part = code_part.replace(f'__string_{idx}__', s)

        result.append(code_part + comment_part)

    return result

def extract_and_convert():
    """Main extraction and conversion routine."""

    # Read the source file
    with open('/home/user/nec2/nec2dxs_integrated.f', 'r') as f:
        all_lines = f.readlines()

    # Define routines to extract with their line ranges and destinations
    routines = [
        ('SOMSET', 1056, 1063, 'nec2d_sommerfeld.f90', 'block data'),
        ('ENF', 1064, 1076, 'nec2d_io.f90', 'function'),
        ('FFLD', 1077, 1292, 'nec2d_fields2.f90', 'subroutine'),
        ('LOAD', 1293, 1434, 'nec2d_utilities.f90', 'subroutine'),
        ('NEFLD', 1435, 1561, 'nec2d_nearfield.f90', 'subroutine'),
        ('NETWK', 1562, 1896, 'nec2d_utilities.f90', 'subroutine'),
        ('QDSRC', 1897, 2025, 'nec2d_matrix2.f90', 'subroutine'),
        ('stopwtch', 2026, 2288, 'nec2d_utilities.f90', 'subroutine'),
        ('TBF', 2289, 2428, 'nec2d_matrix2.f90', 'subroutine'),
    ]

    # Group routines by destination file
    by_file = {}
    for name, start, end, dest, rtype in routines:
        if dest not in by_file:
            by_file[dest] = []
        routine_lines = all_lines[start-1:end]
        by_file[dest].append((name, routine_lines, rtype))

    # Process each destination file
    for dest_file, routine_list in by_file.items():
        filepath = f'/home/user/nec2/{dest_file}'

        # Read existing module
        with open(filepath, 'r') as f:
            existing = f.read()

        # Prepare converted routines
        new_code = []
        for name, lines, rtype in routine_list:
            # Convert fixed to free form
            free_lines = convert_fixed_to_free(lines)
            # Convert to lowercase
            lower_lines = convert_to_lowercase(free_lines)

            # Replace INCLUDE with USE
            processed_lines = []
            for line in lower_lines:
                if "include 'nec2dpar.inc'" in line.lower():
                    processed_lines.append('  use nec2d_params')
                else:
                    processed_lines.append(line)

            # Add separator comment
            new_code.append('')
            new_code.append(f'! -----------------------------------------------------------------------------')
            new_code.append(f'! {name.lower()} - extracted from nec2dxs_integrated.f')
            new_code.append(f'! -----------------------------------------------------------------------------')
            new_code.extend(processed_lines)

        # Append to existing file
        with open(filepath, 'a') as f:
            f.write('\n'.join(new_code))

        print(f"Added {len(routine_list)} routines to {dest_file}")

    # Truncate the original file after line 1055
    with open('/home/user/nec2/nec2dxs_integrated.f', 'w') as f:
        f.writelines(all_lines[:1055])

    print(f"\nTruncated nec2dxs_integrated.f to 1055 lines")
    print("Extraction complete!")

if __name__ == '__main__':
    extract_and_convert()
