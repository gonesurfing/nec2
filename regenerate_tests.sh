#!/bin/bash
# Script to regenerate test .val files from original nec2dxs_orig.f

set -e

cd "$(dirname "$0")"

echo "Compiling nec2dxs_orig.f..."
gfortran -O0 -std=legacy -o nec2_orig nec2dxs_orig.f

echo "Regenerating test .val files..."

for nec_file in tests/*.nec; do
    base=$(basename "$nec_file" .nec)
    val_file="tests/${base}.val"

    echo -n "  Generating $val_file... "

    # Run the test
    if ./nec2_orig < "$nec_file" > "$val_file" 2>&1; then
        echo "done"
    else
        echo "FAILED (exit code $?)"
        exit 1
    fi
done

echo "Done! Cleaning up..."
rm -f nec2_orig

echo "Test .val files regenerated."
