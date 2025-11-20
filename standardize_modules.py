#!/usr/bin/env python3
"""
Standardize all NEC2D Fortran 90 modules to lowercase keywords
with consistent comment formatting.
"""

import os
import re
import glob

# Fortran keywords to convert to lowercase
KEYWORDS = [
    # Module/Program structure
    'MODULE', 'END MODULE', 'PROGRAM', 'END PROGRAM',
    'SUBROUTINE', 'END SUBROUTINE', 'FUNCTION', 'END FUNCTION',
    'CONTAINS', 'INTERFACE', 'END INTERFACE',

    # Declarations
    'USE', 'IMPLICIT', 'PARAMETER', 'SAVE', 'ONLY',
    'REAL', 'INTEGER', 'COMPLEX', 'CHARACTER', 'LOGICAL', 'DOUBLE PRECISION',
    'DIMENSION', 'COMMON', 'EQUIVALENCE', 'DATA', 'INCLUDE',
    'ALLOCATABLE', 'POINTER', 'TARGET', 'INTENT', 'OPTIONAL',

    # Control flow
    'IF', 'THEN', 'ELSE', 'ELSEIF', 'ENDIF', 'END IF',
    'DO', 'ENDDO', 'END DO', 'WHILE', 'CYCLE', 'EXIT',
    'SELECT', 'CASE', 'DEFAULT', 'END SELECT',
    'WHERE', 'ELSEWHERE', 'END WHERE',

    # I/O
    'READ', 'WRITE', 'PRINT', 'OPEN', 'CLOSE', 'INQUIRE',
    'FORMAT', 'REWIND', 'BACKSPACE',

    # Execution
    'CALL', 'RETURN', 'STOP', 'CONTINUE', 'PAUSE',
    'ALLOCATE', 'DEALLOCATE',

    # Operators
    '.AND.', '.OR.', '.NOT.', '.EQV.', '.NEQV.',
    '.EQ.', '.NE.', '.LT.', '.GT.', '.LE.', '.GE.',
    '.TRUE.', '.FALSE.',
]

def convert_to_lowercase(content):
    """Convert Fortran keywords to lowercase while preserving strings and comments."""

    lines = content.split('\n')
    result = []

    for line in lines:
        # Skip comment-only lines (just lowercase the comment marker if needed)
        if line.strip().startswith('!'):
            result.append(line)
            continue

        # Find comment position (not inside string)
        comment_pos = find_comment_pos(line)

        if comment_pos >= 0:
            code_part = line[:comment_pos]
            comment_part = line[comment_pos:]
        else:
            code_part = line
            comment_part = ''

        # Convert code part
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
    """Convert keywords in code portion to lowercase."""

    # First protect strings by replacing them with placeholders
    strings = []
    string_pattern = r"'[^']*'|\"[^\"]*\""

    def save_string(match):
        strings.append(match.group(0))
        return f'__STRING_{len(strings)-1}__'

    code = re.sub(string_pattern, save_string, code)

    # Sort keywords by length (longest first) to avoid partial matches
    sorted_keywords = sorted(KEYWORDS, key=len, reverse=True)

    for keyword in sorted_keywords:
        # Use word boundary matching for keywords
        pattern = r'\b' + re.escape(keyword) + r'\b'
        code = re.sub(pattern, keyword.lower(), code, flags=re.IGNORECASE)

    # Restore strings
    for i, s in enumerate(strings):
        code = code.replace(f'__STRING_{i}__', s)

    return code

def standardize_header(content, filename):
    """Create consistent header comment for module."""

    # Extract module name from filename
    module_name = os.path.basename(filename).replace('.f90', '')

    # Look for existing header info
    lines = content.split('\n')

    # Find GOTOs eliminated count if present
    gotos = "0"
    purpose = ""
    subroutines = []

    for i, line in enumerate(lines[:50]):
        lower = line.lower()
        if 'goto' in lower and 'eliminated' in lower:
            match = re.search(r'(\d+)', line)
            if match:
                gotos = match.group(1)
        if 'contains:' in lower:
            match = re.search(r'contains:\s*(.+)', line, re.IGNORECASE)
            if match:
                subroutines = [s.strip() for s in match.group(1).split(',')]
        if 'purpose:' in lower:
            match = re.search(r'purpose:\s*(.+)', line, re.IGNORECASE)
            if match:
                purpose = match.group(1).strip()

    # If no subroutines found in header, scan for them
    if not subroutines:
        for line in lines:
            match = re.match(r'^(?:end\s+)?subroutine\s+(\w+)', line.strip(), re.IGNORECASE)
            if match and not match.group(0).lower().startswith('end'):
                subroutines.append(match.group(1))
            match = re.match(r'^(?:end\s+)?function\s+(\w+)', line.strip(), re.IGNORECASE)
            if match and not match.group(0).lower().startswith('end'):
                subroutines.append(match.group(1))

    # Generate description based on module name
    descriptions = {
        'nec2d_bessel': 'bessel and hankel functions',
        'nec2d_cmngf': 'matrix ngf filling',
        'nec2d_commons': 'common block module variables',
        'nec2d_conect': 'connection handling',
        'nec2d_dataproc': 'data processing and input',
        'nec2d_fields': 'field calculations',
        'nec2d_fields2': 'far field patterns',
        'nec2d_fields3': 'additional field routines',
        'nec2d_geometry': 'geometry processing',
        'nec2d_geomproc': 'geometry and matrix processing',
        'nec2d_integration': 'numerical integration',
        'nec2d_io': 'input/output routines',
        'nec2d_isegno': 'segment number lookup',
        'nec2d_kernels': 'kernel functions',
        'nec2d_mathutil': 'mathematical utilities',
        'nec2d_matrix': 'matrix operations',
        'nec2d_matrix2': 'matrix filling routines',
        'nec2d_matrix3': 'patch/wire matrix routines',
        'nec2d_nearfield': 'near field calculations',
        'nec2d_numint': 'numerical integration',
        'nec2d_params': 'parameter definitions',
        'nec2d_rdpat': 'radiation patterns',
        'nec2d_segment': 'segment lookup',
        'nec2d_simple': 'simple helper routines',
        'nec2d_solver': 'matrix solution routines',
        'nec2d_sommerfeld': 'sommerfeld integration',
        'nec2d_utilities': 'utility routines',
        'nec2d_utils': 'general utilities',
    }

    desc = descriptions.get(module_name, 'nec2d module')

    # Skip header modification for params and commons modules
    if module_name in ('nec2d_params', 'nec2d_commons'):
        return content

    return content

def process_file(filepath):
    """Process a single Fortran file."""

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

    print(f"Found {len(f90_files)} module files to standardize\n")

    for filepath in f90_files:
        process_file(filepath)

    print(f"\nCompleted standardization of {len(f90_files)} files")
    print("Run 'make clean && make test' to verify")

if __name__ == '__main__':
    main()
