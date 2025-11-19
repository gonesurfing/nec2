#!/bin/bash
# Count GOTOs in each subroutine/function in nec2dxs_integrated.f

awk '
/SUBROUTINE|FUNCTION/ {
    if (name != "") {
        print name ": " count " GOTOs"
    }
    name = $0
    gsub(/^[[:space:]]+/, "", name)
    count = 0
}
/GO TO|GOTO/ {
    count++
}
END {
    if (name != "") {
        print name ": " count " GOTOs"
    }
}
' nec2dxs_integrated.f | grep -v ": 0 GOTOs" | sort -t: -k2 -n
