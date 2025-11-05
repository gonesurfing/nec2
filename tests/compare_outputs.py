#!/usr/bin/env python3
"""
Compare NEC2 output files from original and modernized versions.
Extracts numerical data and compares with appropriate tolerances.
"""

import sys
import re
import numpy as np
from pathlib import Path
from dataclasses import dataclass
from typing import List, Tuple, Dict
import json


@dataclass
class TestResult:
    """Store test comparison results"""
    test_name: str
    passed: bool
    max_relative_error: float
    max_absolute_error: float
    details: str = ""


class NEC2OutputParser:
    """Parse NEC2 output files and extract numerical data"""

    def __init__(self, filename):
        self.filename = filename
        with open(filename, 'r') as f:
            self.lines = f.readlines()

    def extract_currents(self) -> Dict[int, Tuple[complex, complex]]:
        """Extract current distribution (I_real, I_imag) for each segment"""
        currents = {}
        in_current_section = False

        for line in self.lines:
            # Look for current data section
            if 'CURRENTS AND LOCATION' in line:
                in_current_section = True
                continue

            if in_current_section:
                # Check for end of section
                if line.strip() == '' or '---' in line:
                    if len(currents) > 0:
                        break
                    continue

                # Parse current data line
                # Format: SEG TAG REAL IMAG REAL IMAG ...
                match = re.match(r'\s*(\d+)\s+\d+\s+([-\d.E+]+)\s+([-\d.E+]+)\s+([-\d.E+]+)\s+([-\d.E+]+)', line)
                if match:
                    seg = int(match.group(1))
                    i_real = float(match.group(2))
                    i_imag = float(match.group(3))
                    currents[seg] = (complex(i_real, i_imag), 0)  # First current only

        return currents

    def extract_impedance(self) -> Dict[str, complex]:
        """Extract input impedance data"""
        impedances = {}

        for i, line in enumerate(self.lines):
            if 'IMPEDANCE' in line and 'OHMS' in line:
                # Look ahead for data
                for j in range(i+1, min(i+10, len(self.lines))):
                    match = re.search(r'([-\d.E+]+)\s+([-\d.E+]+)', self.lines[j])
                    if match:
                        real_part = float(match.group(1))
                        imag_part = float(match.group(2))
                        impedances['input'] = complex(real_part, imag_part)
                        break

        return impedances

    def extract_gain_pattern(self) -> Dict[Tuple[float, float], float]:
        """Extract radiation pattern (theta, phi) -> gain"""
        pattern = {}
        in_pattern = False

        for line in self.lines:
            if 'RADIATION PATTERN' in line or 'GAIN' in line.upper():
                in_pattern = True
                continue

            if in_pattern:
                # Look for pattern data: THETA PHI ... GAIN
                match = re.match(r'\s*([-\d.E+]+)\s+([-\d.E+]+).*?([-\d.E+]+)\s*$', line)
                if match:
                    try:
                        theta = float(match.group(1))
                        phi = float(match.group(2))
                        gain = float(match.group(3))
                        pattern[(theta, phi)] = gain
                    except ValueError:
                        continue

        return pattern

    def extract_power_budget(self) -> Dict[str, float]:
        """Extract power calculations"""
        power = {}

        for line in self.lines:
            if 'POWER BUDGET' in line or 'RADIATED POWER' in line:
                match = re.search(r'([-\d.E+]+)', line)
                if match:
                    power['radiated'] = float(match.group(1))

            if 'INPUT POWER' in line:
                match = re.search(r'([-\d.E+]+)', line)
                if match:
                    power['input'] = float(match.group(1))

        return power


def compare_complex_dict(ref_data: Dict, new_data: Dict,
                        name: str, rel_tol=1e-9, abs_tol=1e-10) -> TestResult:
    """Compare two dictionaries of complex values"""

    if set(ref_data.keys()) != set(new_data.keys()):
        return TestResult(
            test_name=name,
            passed=False,
            max_relative_error=float('inf'),
            max_absolute_error=float('inf'),
            details=f"Key mismatch: ref has {len(ref_data)}, new has {len(new_data)}"
        )

    max_rel_err = 0.0
    max_abs_err = 0.0
    worst_key = None

    for key in ref_data:
        ref_val = ref_data[key]
        new_val = new_data[key]

        # Handle tuples of complex numbers
        if isinstance(ref_val, tuple):
            ref_val = ref_val[0]
            new_val = new_val[0]

        abs_err = abs(ref_val - new_val)
        rel_err = abs_err / max(abs(ref_val), 1e-20)

        if rel_err > max_rel_err:
            max_rel_err = rel_err
            max_abs_err = abs_err
            worst_key = key

    passed = max_rel_err < rel_tol and max_abs_err < abs_tol

    details = f"Worst at {worst_key}: rel_err={max_rel_err:.3e}, abs_err={max_abs_err:.3e}"

    return TestResult(
        test_name=name,
        passed=passed,
        max_relative_error=max_rel_err,
        max_absolute_error=max_abs_err,
        details=details
    )


def compare_outputs(ref_file: str, new_file: str, test_name: str) -> List[TestResult]:
    """Compare two NEC2 output files comprehensively"""

    print(f"\nComparing: {test_name}")
    print(f"  Reference: {ref_file}")
    print(f"  New:       {new_file}")

    ref_parser = NEC2OutputParser(ref_file)
    new_parser = NEC2OutputParser(new_file)

    results = []

    # Compare currents
    ref_currents = ref_parser.extract_currents()
    new_currents = new_parser.extract_currents()

    if ref_currents and new_currents:
        result = compare_complex_dict(
            ref_currents, new_currents,
            f"{test_name}: Currents",
            rel_tol=1e-9
        )
        results.append(result)
        print(f"  Currents: {'PASS' if result.passed else 'FAIL'} "
              f"(max_rel_err={result.max_relative_error:.3e})")

    # Compare impedances
    ref_impedance = ref_parser.extract_impedance()
    new_impedance = new_parser.extract_impedance()

    if ref_impedance and new_impedance:
        result = compare_complex_dict(
            ref_impedance, new_impedance,
            f"{test_name}: Impedance",
            rel_tol=1e-4  # 0.01% tolerance
        )
        results.append(result)
        print(f"  Impedance: {'PASS' if result.passed else 'FAIL'} "
              f"(max_rel_err={result.max_relative_error:.3e})")

    # Compare radiation pattern
    ref_pattern = ref_parser.extract_gain_pattern()
    new_pattern = new_parser.extract_gain_pattern()

    if ref_pattern and new_pattern:
        # Convert to dict with string keys for comparison
        ref_pattern_dict = {str(k): v for k, v in ref_pattern.items()}
        new_pattern_dict = {str(k): v for k, v in new_pattern.items()}

        result = compare_complex_dict(
            ref_pattern_dict, new_pattern_dict,
            f"{test_name}: Radiation Pattern",
            rel_tol=1e-3  # 0.1% tolerance for patterns
        )
        results.append(result)
        print(f"  Pattern: {'PASS' if result.passed else 'FAIL'} "
              f"(max_rel_err={result.max_relative_error:.3e})")

    return results


def main():
    """Run comparison tests"""

    if len(sys.argv) < 3:
        print("Usage: compare_outputs.py <reference_dir> <new_output_dir> [test_pattern]")
        print("\nExample:")
        print("  compare_outputs.py reference_outputs/ new_outputs/ dipole")
        sys.exit(1)

    ref_dir = Path(sys.argv[1])
    new_dir = Path(sys.argv[2])
    pattern = sys.argv[3] if len(sys.argv) > 3 else "*.out"

    if not ref_dir.exists():
        print(f"Error: Reference directory not found: {ref_dir}")
        sys.exit(1)

    if not new_dir.exists():
        print(f"Error: New output directory not found: {new_dir}")
        sys.exit(1)

    # Find all reference output files
    ref_files = list(ref_dir.glob(pattern))

    if not ref_files:
        print(f"No reference files found matching {pattern} in {ref_dir}")
        sys.exit(1)

    all_results = []

    for ref_file in sorted(ref_files):
        test_name = ref_file.stem
        new_file = new_dir / ref_file.name

        if not new_file.exists():
            print(f"\nWARNING: No new output for {test_name}")
            continue

        results = compare_outputs(str(ref_file), str(new_file), test_name)
        all_results.extend(results)

    # Summary
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)

    passed = sum(1 for r in all_results if r.passed)
    failed = len(all_results) - passed

    print(f"\nTotal tests: {len(all_results)}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")

    if failed > 0:
        print("\nFailed tests:")
        for result in all_results:
            if not result.passed:
                print(f"  - {result.test_name}")
                print(f"    {result.details}")

    # Save detailed results to JSON
    results_file = "test_results.json"
    with open(results_file, 'w') as f:
        json.dump([{
            'test_name': r.test_name,
            'passed': r.passed,
            'max_relative_error': r.max_relative_error,
            'max_absolute_error': r.max_absolute_error,
            'details': r.details
        } for r in all_results], f, indent=2)

    print(f"\nDetailed results saved to: {results_file}")

    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
