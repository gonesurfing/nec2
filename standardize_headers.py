#!/usr/bin/env python3
"""
Standardize header comments across all NEC2D Fortran 90 modules.
Uses consistent format with equals-sign borders.
"""

import os
import re
import glob

# Module descriptions
MODULE_INFO = {
    'nec2d_bessel': {
        'desc': 'Bessel and Hankel Functions',
        'purpose': 'Special mathematical functions for electromagnetic calculations',
    },
    'nec2d_cmngf': {
        'desc': 'Matrix NGF Filling',
        'purpose': 'Fill interaction matrices B, C, and D for NGF solution',
    },
    'nec2d_commons': {
        'desc': 'Common Block Module Variables',
        'purpose': 'All COMMON blocks wrapped as module variables',
    },
    'nec2d_conect': {
        'desc': 'Connection Handling',
        'purpose': 'Wire and patch connection processing',
    },
    'nec2d_dataproc': {
        'desc': 'Data Processing and Input',
        'purpose': 'Geometry data input and field calculations',
    },
    'nec2d_fields': {
        'desc': 'Field Calculations',
        'purpose': 'H field and kernel functions for segments',
    },
    'nec2d_fields2': {
        'desc': 'Far Field Patterns',
        'purpose': 'Far field radiation pattern calculations',
    },
    'nec2d_fields3': {
        'desc': 'Additional Field Routines',
        'purpose': 'FFLD, GFLD, and related field computations',
    },
    'nec2d_geometry': {
        'desc': 'Geometry Processing',
        'purpose': 'Arc, helix, and geometry transformation routines',
    },
    'nec2d_geomproc': {
        'desc': 'Geometry and Matrix Processing',
        'purpose': 'H field computation, matrix factorization, patch subdivision',
    },
    'nec2d_integration': {
        'desc': 'Numerical Integration',
        'purpose': 'Integration routines for kernel evaluations',
    },
    'nec2d_io': {
        'desc': 'Input/Output Routines',
        'purpose': 'File I/O, NGF file handling, block storage',
    },
    'nec2d_isegno': {
        'desc': 'Segment Number Lookup',
        'purpose': 'Find segment number from tag and index',
    },
    'nec2d_kernels': {
        'desc': 'Kernel Functions',
        'purpose': 'Thin-wire kernel approximations',
    },
    'nec2d_mathutil': {
        'desc': 'Mathematical Utilities',
        'purpose': 'Complex arithmetic and special function helpers',
    },
    'nec2d_matrix': {
        'desc': 'Matrix Operations',
        'purpose': 'Matrix setup and excitation routines',
    },
    'nec2d_matrix2': {
        'desc': 'Matrix Filling Routines',
        'purpose': 'Interaction matrix computation and filling',
    },
    'nec2d_matrix3': {
        'desc': 'Patch and Wire Matrix Routines',
        'purpose': 'Patch-to-patch and wire-to-patch interactions',
    },
    'nec2d_nearfield': {
        'desc': 'Near Field Calculations',
        'purpose': 'Near field E and H computation at observation points',
    },
    'nec2d_numint': {
        'desc': 'Numerical Integration',
        'purpose': 'Sommerfeld integral evaluation and ROM integration',
    },
    'nec2d_params': {
        'desc': 'Parameter Definitions',
        'purpose': 'Dimensional parameters for NEC2D arrays',
    },
    'nec2d_rdpat': {
        'desc': 'Radiation Patterns',
        'purpose': 'Radiation pattern computation and output',
    },
    'nec2d_segment': {
        'desc': 'Segment Lookup',
        'purpose': 'Find segment number from tag number',
    },
    'nec2d_simple': {
        'desc': 'Simple Helper Routines',
        'purpose': 'Basic utility functions and calculations',
    },
    'nec2d_solver': {
        'desc': 'Matrix Solution Routines',
        'purpose': 'Matrix partitioning, factorization, and solution',
    },
    'nec2d_sommerfeld': {
        'desc': 'Sommerfeld Integration',
        'purpose': 'Ground wave and Sommerfeld integral evaluations',
    },
    'nec2d_utilities': {
        'desc': 'Utility Routines',
        'purpose': 'Network parameter setup and general utilities',
    },
    'nec2d_utils': {
        'desc': 'General Utilities',
        'purpose': 'Move and test functions using module variables',
    },
}

def find_subroutines(content):
    """Find all subroutine and function names in the file."""
    subs = []
    for match in re.finditer(r'^(?:\s*)(?:subroutine|function)\s+(\w+)', content, re.MULTILINE | re.IGNORECASE):
        name = match.group(1).upper()
        if name not in subs:
            subs.append(name)
    return subs

def find_gotos_eliminated(content):
    """Extract GOTOs eliminated count from existing comments."""
    # Look for patterns like "GOTOs eliminated: 38" or "38 GOTOs eliminated"
    match = re.search(r'goto[s]?\s+eliminated[:\s]+(\d+)', content, re.IGNORECASE)
    if match:
        return match.group(1)
    match = re.search(r'(\d+)\s+goto[s]?\s+eliminated', content, re.IGNORECASE)
    if match:
        return match.group(1)
    # Look for pattern like "12 → 0" in "GOTOs eliminated: 12 → 0"
    match = re.search(r'goto[s]?\s+eliminated[:\s]+(\d+)\s*[→>]', content, re.IGNORECASE)
    if match:
        return match.group(1)
    return "0"

def find_header_end(lines):
    """Find where the header comments end."""
    for i, line in enumerate(lines):
        stripped = line.strip()
        # Look for first non-comment, non-empty line
        if stripped and not stripped.startswith('!'):
            return i
    return len(lines)

def generate_header(module_name, subroutines, gotos):
    """Generate standardized header."""
    info = MODULE_INFO.get(module_name, {
        'desc': module_name.replace('nec2d_', '').replace('_', ' ').title(),
        'purpose': 'NEC2D module'
    })

    header_lines = [
        "! =============================================================================",
        f"! {module_name} - {info['desc']}",
        "! =============================================================================",
        f"! Purpose: {info['purpose']}",
    ]

    if subroutines:
        header_lines.append(f"! Contains: {', '.join(subroutines)}")

    if gotos != "0":
        header_lines.append(f"! GOTOs eliminated: {gotos}")

    header_lines.append("! =============================================================================")
    header_lines.append("")

    return '\n'.join(header_lines)

def process_file(filepath):
    """Process a single Fortran file to standardize its header."""
    module_name = os.path.basename(filepath).replace('.f90', '')

    # Skip params and commons as they have specific formats
    if module_name in ('nec2d_params', 'nec2d_commons'):
        print(f"Skipping {module_name} (special module)")
        return

    with open(filepath, 'r') as f:
        content = f.read()

    lines = content.split('\n')

    # Find subroutines
    subroutines = find_subroutines(content)

    # Find GOTOs eliminated
    gotos = find_gotos_eliminated(content)

    # Find where header ends
    header_end = find_header_end(lines)

    # Generate new header
    new_header = generate_header(module_name, subroutines, gotos)

    # Combine new header with code (skip old header)
    new_content = new_header + '\n'.join(lines[header_end:])

    # Write back
    with open(filepath, 'w') as f:
        f.write(new_content)

    print(f"Updated {module_name}: {len(subroutines)} subroutines, {gotos} GOTOs eliminated")

def main():
    # Find all Fortran 90 module files
    f90_files = sorted(glob.glob('/home/user/nec2/nec2d_*.f90'))

    print(f"Standardizing headers for {len(f90_files)} module files\n")

    for filepath in f90_files:
        process_file(filepath)

    print(f"\nHeader standardization complete")
    print("Run 'make clean && make test' to verify")

if __name__ == '__main__':
    main()
