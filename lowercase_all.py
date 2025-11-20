#!/usr/bin/env python3
"""
Convert all Fortran code (keywords AND variables) to lowercase,
preserving only string literals and comments.
"""

import re
import glob

def convert_to_lowercase(content):
    """Convert all code to lowercase, preserving strings and comments."""

    lines = content.split('\n')
    result = []

    for line in lines:
        # Find comment position (not inside string)
        comment_pos = find_comment_pos(line)

        if comment_pos >= 0:
            code_part = line[:comment_pos]
            comment_part = line[comment_pos:]
        else:
            code_part = line
            comment_part = ''

        # Convert code part (preserving strings)
        code_part = convert_code_part(code_part)

        result.append(code_part + comment_part)

    return '\n'.join(result)

def find_comment_pos(line):
    """Find position of ! comment that's not inside a string."""
    in_string = False
    string_char = None

    for i, char in enumerate(line):
        if char in ('"', "'") and not in_string:
            in_string = True
            string_char = char
        elif char == string_char and in_string:
            in_string = False
            string_char = None
        elif char == '!' and not in_string:
            return i

    return -1

def convert_code_part(code):
    """Convert all code to lowercase, preserving strings."""

    # Protect strings by replacing them with placeholders
    strings = []
    string_pattern = r"'[^']*'|\"[^\"]*\""

    def save_string(match):
        strings.append(match.group(0))
        return f'__STRING_{len(strings)-1}__'

    code = re.sub(string_pattern, save_string, code)

    # Convert everything to lowercase
    code = code.lower()

    # Restore strings
    for i, s in enumerate(strings):
        code = code.replace(f'__string_{i}__', s)

    return code

def process_file(filepath):
    """Process a single Fortran file."""
    import os
    print(f"Processing {os.path.basename(filepath)}...")

    with open(filepath, 'r') as f:
        content = f.read()

    # Convert to lowercase
    content = convert_to_lowercase(content)

    # Write back
    with open(filepath, 'w') as f:
        f.write(content)

    return True

def main():
    # Find all Fortran 90 module files
    f90_files = sorted(glob.glob('/home/user/nec2/nec2d_*.f90'))

    print(f"Converting {len(f90_files)} module files to full lowercase\n")

    for filepath in f90_files:
        process_file(filepath)

    print(f"\nCompleted lowercase conversion of {len(f90_files)} files")
    print("Run 'make clean && make test' to verify")

if __name__ == '__main__':
    main()
