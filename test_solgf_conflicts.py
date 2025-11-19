# SOLGF parameters
params = ["A", "B", "C", "D", "XY", "IP", "NP", "N1", "N", "MP", "M1", "M", "N1C", "N2C", "N2CZ"]

# From nec2d_commons.f90 - variables that would be imported
common_vars = {
    "DATA": ["X", "Y", "Z", "SI", "BI", "ALP", "BET", "WLAM", "ICON1", "ICON2", 
             "ITAG", "ICONX", "LD", "N1", "N2", "N", "NP", "M1", "M2", "M", "MP", "IPSYM"],
    "SAVE": ["EPSR", "SIG", "SCRWLT", "SCRWRT", "FMHZ", "IP", "KCOM"],
    "MATPAR": ["ICASE", "NBLOKS", "NPBLK", "NLAST", "NBLSYM", "NPSYM", "NLSYM", 
               "IMAT", "ICASX", "NBBX", "NPBX", "NLBX", "NBBL", "NPBL", "NLBL"],
    "SCRATM": ["SCRATM_REAL", "SCRATM_CPLX"],
    "SEGJ": ["AX", "BX", "CX", "JCO", "JSNO", "ISCON", "NSCON", "IPCON", "NPCON"]
}

all_common = []
for block, vars in common_vars.items():
    all_common.extend(vars)

# Check for conflicts
conflicts = []
for p in params:
    if p.upper() in [v.upper() for v in all_common]:
        conflicts.append(p)
        # Find which block
        for block, vars in common_vars.items():
            if p.upper() in [v.upper() for v in vars]:
                print(f"  {p} conflicts with /{block}/ variable")

print(f"\nSOLGF has {len(conflicts)} conflicts: {conflicts}")
print("\nWith ONLY clause, we would need to import:")
print("  /SCRATM/: Y (aliased from SCRATM_REAL)")
print("  /SEGJ/: AX, BX, CX, JCO, JSNO, ISCON, NSCON, IPCON, NPCON")
print("  /MATPAR/: ICASE, NBLOKS, NPBLK, NLAST, NBLSYM, NPSYM, NLSYM, IMAT, ICASX, NBBX, NPBX, NLBX, NBBL, NPBL, NLBL")
print("\n  EXCLUDING: IP, NP, N1, N, MP, M1, M (parameter conflicts)")
