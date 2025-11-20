#!/bin/bash
# Script to regenerate test .val files from original nec2dxs_orig.f

set -e

cd "$(dirname "$0")"

echo "Compiling nec2dxs_orig.f..."
gfortran -O0 -std=legacy -o nec2_orig nec2dxs_orig.f

echo "Regenerating test .val files..."

# Clean up any existing NGF files
rm -f NGF2D.NEC testngf1.ngf testngf2.ngf

for nec_file in tests/*.nec; do
    base=$(basename "$nec_file" .nec)
    val_file="tests/${base}.val"

    # Skip testngf files - they need special handling after createngf
    if [[ "$base" == testngf* ]]; then
        continue
    fi

    echo -n "  Generating $val_file... "

    # Run the test
    if ./nec2_orig < "$nec_file" > "$val_file" 2>&1; then
        echo "done"
    else
        echo "FAILED (exit code $?)"
        exit 1
    fi

    # After createngf, generate the testngf .val files
    if [[ "$base" == "createngf" ]]; then
        # testngf1 uses the NGF file created by createngf
        cp NGF2D.NEC testngf1.ngf
        echo -n "  Generating tests/testngf1.val... "
        if ./nec2_orig < tests/testngf1.nec > tests/testngf1.val 2>&1; then
            echo "done"
        else
            echo "FAILED (exit code $?)"
            exit 1
        fi

        # testngf2 also uses the NGF file
        cp NGF2D.NEC testngf2.ngf
        echo -n "  Generating tests/testngf2.val... "
        if ./nec2_orig < tests/testngf2.nec > tests/testngf2.val 2>&1; then
            echo "done"
        else
            echo "FAILED (exit code $?)"
            exit 1
        fi
    fi
done

# Clean up NGF files
rm -f NGF2D.NEC testngf1.ngf testngf2.ngf

echo "Done! Cleaning up..."
rm -f nec2_orig

echo "Test .val files regenerated."
