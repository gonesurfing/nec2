#!/bin/bash
# Generate reference data from original nec2dxs implementation

set -e

ORIG_BINARY="../nec2dxs"
REF_DIR="reference_outputs"
CASES_DIR="reference_cases"

mkdir -p "$REF_DIR"

echo "Generating reference data from original NEC2 implementation..."

# Check if original binary exists
if [ ! -f "$ORIG_BINARY" ]; then
    echo "Error: Original nec2dxs binary not found at $ORIG_BINARY"
    echo "Please compile the original version first."
    exit 1
fi

# Process each test case
for necfile in "$CASES_DIR"/*.nec; do
    if [ ! -f "$necfile" ]; then
        echo "No .nec files found in $CASES_DIR"
        exit 1
    fi

    basename=$(basename "$necfile" .nec)
    echo "Processing: $basename"

    # Run original code and capture output
    "$ORIG_BINARY" < "$necfile" > "$REF_DIR/${basename}.out" 2>&1

    # If additional output files were generated, move them
    [ -f "PLTDAT.NEC" ] && mv "PLTDAT.NEC" "$REF_DIR/${basename}_pltdat.nec"

    echo "  -> Generated $REF_DIR/${basename}.out"
done

echo ""
echo "Reference data generation complete!"
echo "Files saved in: $REF_DIR/"
