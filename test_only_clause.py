# Analyze CMNGF to see if ONLY clause would work

# CMNGF parameters
params = ["CB", "CC", "CD", "NB", "NC", "ND", "RKHX", "IEXKX"]

# COMMON /DATA/ variables
data_vars = ["X", "Y", "Z", "SI", "BI", "ALP", "BET", "WLAM", "ICON1", "ICON2", 
             "ITAG", "ICONX", "LD", "N1", "N2", "N", "NP", "M1", "M2", "M", "MP", "IPSYM"]

# COMMON /ZLOAD/ variables
zload_vars = ["ZARRAY", "NLOAD", "NLODF"]

# COMMON /SEGJ/ variables
segj_vars = ["AX", "BX", "CX", "JCO", "JSNO", "ISCON", "NSCON", "IPCON", "NPCON"]

# COMMON /DATAJ/ variables (need to handle name conflicts in COMPLEX*16 declaration)
dataj_vars = ["S", "B", "XJ", "YJ", "ZJ", "CABJ", "SABJ", "SALPJ", 
              "EXK", "EYK", "EZK", "EXS", "EYS", "EZS", "EXC", "EYC", "EZC",
              "RKH", "IND1", "INDD1", "IND2", "INDD2", "IEXK", "IPGND"]

# COMMON /MATPAR/ variables  
matpar_vars = ["ICASE", "NBLOKS", "NPBLK", "NLAST", "NBLSYM", "NPSYM", "NLSYM", 
               "IMAT", "ICASX", "NBBX", "NPBX", "NLBX", "NBBL", "NPBL", "NLBL"]

all_common = data_vars + zload_vars + segj_vars + dataj_vars + matpar_vars

# Check for conflicts
conflicts = []
for p in params:
    if p.upper() in [v.upper() for v in all_common]:
        conflicts.append(p)

print("CMNGF Parameter vs COMMON conflicts:", conflicts if conflicts else "NONE")
print("\nCOMMON variables needed from nec2d_commons:")
print(f"  /DATA/: {len(data_vars)} vars")
print(f"  /ZLOAD/: {len(zload_vars)} vars")
print(f"  /SEGJ/: {len(segj_vars)} vars")
print(f"  /DATAJ/: {len(dataj_vars)} vars")
print(f"  /MATPAR/: {len(matpar_vars)} vars")
print(f"  TOTAL: {len(all_common)} variables")
