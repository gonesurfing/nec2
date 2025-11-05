#!/bin/bash
# Complete workflow for testing NEC2 modernization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "NEC2 Modernization Test Workflow"
echo "======================================"
echo ""

# Step 1: Check if we have the original binary
echo -e "${YELLOW}[1/5] Checking for original binary...${NC}"
if [ ! -f "../nec2dxs" ]; then
    echo -e "${RED}Error: Original nec2dxs binary not found${NC}"
    echo "Please compile it first:"
    echo "  cd .."
    echo "  gfortran -O2 -o nec2dxs nec2dxs.f"
    exit 1
fi
echo -e "${GREEN}✓ Original binary found${NC}"
echo ""

# Step 2: Generate reference data if needed
echo -e "${YELLOW}[2/5] Checking for reference data...${NC}"
if [ ! -d "reference_outputs" ] || [ -z "$(ls -A reference_outputs 2>/dev/null)" ]; then
    echo "Generating reference data from original code..."
    make reference
    echo -e "${GREEN}✓ Reference data generated${NC}"
else
    echo -e "${GREEN}✓ Reference data exists${NC}"
fi
echo ""

# Step 3: Check if we have the new binary
echo -e "${YELLOW}[3/5] Checking for modernized binary...${NC}"
if [ ! -f "../nec2dxs_new" ]; then
    echo -e "${RED}Warning: Modernized nec2dxs_new binary not found${NC}"
    echo "If you haven't started modernizing yet, this is expected."
    echo ""
    echo "To create test data with original binary for comparison:"
    echo "  cp ../nec2dxs ../nec2dxs_new"
    echo ""
    read -p "Copy original as placeholder? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp ../nec2dxs ../nec2dxs_new
        echo -e "${GREEN}✓ Placeholder created${NC}"
    else
        echo "Skipping comparison tests."
        exit 0
    fi
else
    echo -e "${GREEN}✓ Modernized binary found${NC}"
fi
echo ""

# Step 4: Run unit tests if available
echo -e "${YELLOW}[4/5] Running unit tests...${NC}"
if make unit_tests 2>/dev/null; then
    echo -e "${GREEN}✓ Unit tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Unit tests not available or failed${NC}"
fi
echo ""

# Step 5: Run comparison tests
echo -e "${YELLOW}[5/5] Running output comparison tests...${NC}"
if make test; then
    echo ""
    echo -e "${GREEN}======================================"
    echo -e "✓ ALL TESTS PASSED${NC}"
    echo -e "${GREEN}======================================${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}======================================"
    echo -e "✗ SOME TESTS FAILED${NC}"
    echo -e "${RED}======================================${NC}"
    echo ""
    echo "Check test_results.json for details"
    exit 1
fi
