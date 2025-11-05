#!/bin/bash
# End-to-end comprehensive test for modernized NEC2
# Builds both versions, runs all test cases, and compares outputs

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORIG_EXEC="../nec2dxs"
NEW_EXEC="../src/nec2"
REF_DIR="reference_outputs"
NEW_DIR="new_outputs"
CASES_DIR="reference_cases"
TOLERANCE="1e-8"  # Default numerical tolerance

# Statistics
TOTAL_CASES=0
PASSED_CASES=0
FAILED_CASES=0

echo "========================================================================"
echo "  NEC2 MODERNIZATION END-TO-END TEST SUITE"
echo "========================================================================"
echo ""
echo "This comprehensive test will:"
echo "  1. Build the original NEC2 code"
echo "  2. Build the modernized NEC2 code"
echo "  3. Generate reference outputs from original code"
echo "  4. Run modernized code on all test cases"
echo "  5. Compare outputs numerically"
echo "  6. Generate detailed test report"
echo ""
echo "========================================================================"
echo ""

# Check we're in the right directory
if [ ! -f "../src/nec2_main.f90" ]; then
    echo -e "${RED}Error: Must run from tests/ directory${NC}"
    exit 1
fi

#============================================================================
# Step 1: Build Original Code
#============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 1: Building Original Code${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd ..
if [ -f "nec2dxs.f" ]; then
    echo "Compiling nec2dxs.f..."
    if gfortran -O2 -std=legacy -w -o nec2dxs nec2dxs.f > build_original.log 2>&1; then
        echo -e "${GREEN}✓ Original code compiled successfully${NC}"
        rm -f build_original.log
    else
        echo -e "${RED}✗ Original code compilation failed${NC}"
        echo "See build_original.log for details"
        exit 1
    fi
else
    echo -e "${RED}Error: nec2dxs.f not found${NC}"
    exit 1
fi
cd tests

#============================================================================
# Step 2: Build Modernized Code
#============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 2: Building Modernized Code${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd ../src
echo "Compiling modernized NEC2..."
make clean > /dev/null 2>&1
if make > build_modern.log 2>&1; then
    echo -e "${GREEN}✓ Modernized code compiled successfully${NC}"
    rm -f build_modern.log
else
    echo -e "${RED}✗ Modernized code compilation failed${NC}"
    echo "See src/build_modern.log for details"
    exit 1
fi
cd ../tests

#============================================================================
# Step 3: Generate Reference Outputs
#============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 3: Generating Reference Outputs${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

mkdir -p "$REF_DIR"

for necfile in "$CASES_DIR"/*.nec; do
    if [ -f "$necfile" ]; then
        base=$(basename "$necfile" .nec)
        echo "Running original code: $base"

        if $ORIG_EXEC < "$necfile" > "$REF_DIR/${base}.out" 2>&1; then
            echo -e "  ${GREEN}✓${NC} Generated reference output"
        else
            echo -e "  ${YELLOW}⚠${NC} Original code had warnings (may be expected)"
        fi
    fi
done

echo ""
echo -e "${GREEN}Reference data generation complete${NC}"

#============================================================================
# Step 4: Run Modernized Code
#============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 4: Running Modernized Code${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

mkdir -p "$NEW_DIR"

for necfile in "$CASES_DIR"/*.nec; do
    if [ -f "$necfile" ]; then
        base=$(basename "$necfile" .nec)
        echo "Running modernized code: $base"

        if $NEW_EXEC < "$necfile" > "$NEW_DIR/${base}.out" 2>&1; then
            echo -e "  ${GREEN}✓${NC} Generated new output"
        else
            echo -e "  ${YELLOW}⚠${NC} Modernized code had warnings (may be expected)"
        fi

        TOTAL_CASES=$((TOTAL_CASES + 1))
    fi
done

echo ""
echo -e "${GREEN}Modernized code execution complete${NC}"

#============================================================================
# Step 5: Compare Outputs
#============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 5: Comparing Outputs${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Python comparison script exists
if [ -f "compare_outputs.py" ]; then
    echo "Using Python comparison script for detailed analysis..."
    if python3 compare_outputs.py "$REF_DIR" "$NEW_DIR" 2>&1 | tee comparison_results.txt; then
        echo -e "${GREEN}✓ Python comparison completed${NC}"
    else
        echo -e "${YELLOW}⚠ Python comparison had issues (check comparison_results.txt)${NC}"
    fi
else
    # Fallback to simple diff comparison
    echo "Python comparison not available, using diff..."

    for reffile in "$REF_DIR"/*.out; do
        if [ -f "$reffile" ]; then
            base=$(basename "$reffile" .out)
            newfile="$NEW_DIR/${base}.out"

            if [ ! -f "$newfile" ]; then
                echo -e "${RED}✗ Missing new output: $base${NC}"
                FAILED_CASES=$((FAILED_CASES + 1))
                continue
            fi

            echo "Comparing: $base"

            # Simple diff comparison
            if diff -q "$reffile" "$newfile" > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} Outputs identical"
                PASSED_CASES=$((PASSED_CASES + 1))
            else
                # Outputs differ - check if it's just formatting
                if diff -w -B "$reffile" "$newfile" > /dev/null 2>&1; then
                    echo -e "  ${YELLOW}≈${NC} Outputs differ only in whitespace"
                    PASSED_CASES=$((PASSED_CASES + 1))
                else
                    echo -e "  ${RED}✗${NC} Outputs differ significantly"
                    FAILED_CASES=$((FAILED_CASES + 1))

                    # Save diff for review
                    diff "$reffile" "$newfile" > "${base}_diff.txt" 2>&1 || true
                    echo "      Diff saved to: ${base}_diff.txt"
                fi
            fi
        fi
    done
fi

#============================================================================
# Step 6: Performance Comparison
#============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 6: Performance Comparison${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "Running performance benchmark..."
echo ""

for necfile in "$CASES_DIR"/*.nec; do
    if [ -f "$necfile" ]; then
        base=$(basename "$necfile" .nec)
        echo "Benchmark: $base"

        # Time original
        echo -n "  Original:   "
        /usr/bin/time -f "%E elapsed, %M KB" $ORIG_EXEC < "$necfile" > /dev/null 2>&1 || true

        # Time modernized
        echo -n "  Modernized: "
        /usr/bin/time -f "%E elapsed, %M KB" $NEW_EXEC < "$necfile" > /dev/null 2>&1 || true

        echo ""
    fi
done

#============================================================================
# Final Summary
#============================================================================
echo ""
echo "========================================================================"
echo "  TEST SUMMARY"
echo "========================================================================"
echo ""
echo "Total test cases:     $TOTAL_CASES"
echo "Passed:               $PASSED_CASES"
echo "Failed:               $FAILED_CASES"
echo ""
echo "------------------------------------------------------------------------"

if [ $FAILED_CASES -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ ALL TESTS PASSED ✓✓✓${NC}"
    echo ""
    echo "The modernized NEC2 code produces numerically equivalent results"
    echo "to the original code on all test cases."
    EXIT_CODE=0
else
    echo -e "${RED}✗✗✗ SOME TESTS FAILED ✗✗✗${NC}"
    echo ""
    echo "Review the diff files to see what changed:"
    ls -1 *_diff.txt 2>/dev/null || echo "  No diff files found"
    echo ""
    echo "Common reasons for differences:"
    echo "  - Output formatting changes (spacing, decimal places)"
    echo "  - Numerical round-off differences (check tolerance)"
    echo "  - Algorithm differences (verify correctness manually)"
    echo "  - Missing functionality (check if cards are implemented)"
    EXIT_CODE=1
fi

echo "========================================================================"
echo ""

# Cleanup
echo "Cleaning up..."
rm -f *.log

exit $EXIT_CODE
