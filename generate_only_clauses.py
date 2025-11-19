#!/usr/bin/env python3
"""Generate USE...ONLY clauses for each module by analyzing COMMON usage"""
import re
import sys
from collections import defaultdict

# Map COMMON block names to nec2d_commons.f90 variable names
# This handles case differences and renamed variables
common_var_map = {
    'DATA': ['X', 'Y', 'Z', 'SI', 'BI', 'ALP', 'BET', 'WLAM', 'ICON1', 'ICON2', 
             'ITAG', 'ICONX', 'LD', 'N1', 'N2', 'N', 'NP', 'M1', 'M2', 'M', 'MP', 'IPSYM'],
    'CMB': ['CM'],
    'MATPAR': ['ICASE', 'NBLOKS', 'NPBLK', 'NLAST', 'NBLSYM', 'NPSYM', 'NLSYM', 
               'IMAT', 'ICASX', 'NBBX', 'NPBX', 'NLBX', 'NBBL', 'NPBL', 'NLBL'],
    'SAVE': ['EPSR', 'SIG', 'SCRWLT', 'SCRWRT', 'FMHZ', 'IP', 'KCOM'],
    'CSAVE': ['COM'],
    'CRNT': ['AIR', 'AII', 'BIR', 'BII', 'CIR', 'CII', 'CUR'],
    'GND': ['ZRATI', 'ZRATI2', 'FRATI', 'T1', 'T2', 'CL', 'CH', 'SCRWL', 'SCRWR', 
            'NRADL', 'KSYMP', 'IFAR', 'IPERF'],
    'ZLOAD': ['ZARRAY', 'NLOAD', 'NLODF'],
    'YPARM': ['Y11A', 'Y12A', 'NCOUP', 'ICOUP', 'NCTAG', 'NCSEG'],
    'SEGJ': ['AX', 'BX', 'CX', 'JCO', 'JSNO', 'ISCON', 'NSCON', 'IPCON', 'NPCON'],
    'VSORC': ['VQD', 'VSANT', 'VQDS', 'IVQD', 'ISANT', 'IQDS', 'NVQD', 'NSANT', 'NQDS'],
    'NETCX': ['ZPED', 'PIN', 'PNLS', 'X11R', 'X11I', 'X12R', 'X12I', 'X22R', 'X22I',
              'NTYP', 'ISEG1', 'ISEG2', 'NEQ', 'NPEQ', 'NEQ2', 'NONET', 'NTSOL', 'NPRINT', 'MASYM'],
    'FPAT': ['THETS', 'PHIS', 'DTH', 'DPH', 'RFLD', 'GNOR', 'CLT', 'CHT', 'EPSR2', 'SIG2',
             'XPR6', 'PINR', 'PNLR', 'PLOSS', 'XNR', 'YNR', 'ZNR', 'DXNR', 'DYNR', 'DZNR',
             'NTH', 'NPH', 'IPD', 'IAVP', 'INOR', 'IAX', 'IXTYP', 'NEAR', 'NFEH', 'NRX', 'NRY', 'NRZ'],
    'GGRID': ['AR1', 'AR2', 'AR3', 'EPSCF', 'DXA', 'DYA', 'XSA', 'YSA', 'NXA', 'NYA'],
    'GWAV': ['U', 'U2', 'XX1', 'XX2', 'R1', 'R2', 'ZMH', 'ZPH'],
    'PLOT': ['IPLP1', 'IPLP2', 'IPLP3', 'IPLP4'],
    'ANGL': ['SALP'],
    'DATAJ': ['S_J', 'B_J', 'XJ', 'YJ', 'ZJ', 'CABJ', 'SABJ', 'SALPJ',
              'EXK', 'EYK', 'EZK', 'EXS', 'EYS', 'EZS', 'EXC', 'EYC', 'EZC',
              'RKH', 'IND1', 'INDD1', 'IND2', 'INDD2', 'IEXK', 'IPGND'],
    'EVLCOM': ['CKSM', 'CT1', 'CT2', 'CT3', 'CK1', 'CK1SQ', 'CK2', 'CK2SQ',
               'TKMAG', 'TSMAG', 'CK1R', 'ZPH_EV', 'RHO_EV', 'JH'],
    'INCOM': ['XO', 'YO', 'ZO', 'SN', 'XSN', 'YSN', 'ISNOR'],
    'CNTOUR': ['A_CNTOUR', 'B_CNTOUR'],
    'SMAT': ['SSX'],
    'SCRATM': ['SCRATM_REAL', 'SCRATM_CPLX'],
    'TMI': ['ZPK_TMI', 'RKB2', 'IJX_TMI'],
    'TMH': ['ZPK_TMH', 'RHKS'],
    'NGFNAM': ['NGFNAM']
}

def analyze_file(filename):
    """Analyze a file and return COMMON blocks used"""
    try:
        with open(filename, 'r') as f:
            content = f.read()
    except:
        return None
    
    # Find all COMMON declarations
    common_blocks = set()
    for match in re.finditer(r'COMMON\s+/(\w+)/', content, re.IGNORECASE):
        block = match.group(1).upper()
        common_blocks.add(block)
    
    return sorted(common_blocks)

def generate_only_clause(common_blocks):
    """Generate USE...ONLY clause for given COMMON blocks"""
    if not common_blocks:
        return "  USE nec2d_params\n  ! No COMMON blocks used"
    
    lines = ["  USE nec2d_params", "  USE nec2d_commons, ONLY: &"]
    
    for i, block in enumerate(common_blocks):
        if block in common_var_map:
            vars = common_var_map[block]
            var_list = ', '.join(vars)
            comment = f"! /{block}/ - {len(vars)} variables"
            
            if i < len(common_blocks) - 1:
                lines.append(f"    {var_list}, & {comment}")
            else:
                lines.append(f"    {var_list}  {comment}")
        else:
            print(f"WARNING: Unknown COMMON block /{block}/", file=sys.stderr)
    
    return '\n'.join(lines)

# Analyze all modules
import glob
modules = sorted(glob.glob('nec2d_*.f90'))

print("=" * 80)
print("COMMON Block Usage Analysis for USE...ONLY Conversion")
print("=" * 80)
print()

for module in modules:
    blocks = analyze_file(module)
    if blocks is None:
        continue
    
    basename = module.replace('nec2d_', '').replace('.f90', '')
    print(f"\n### {module}")
    print(f"COMMON blocks: {len(blocks)}")
    if blocks:
        print(f"Blocks: {', '.join(f'/{b}/' for b in blocks)}")
        print("\nGenerated ONLY clause:")
        print(generate_only_clause(blocks))
    else:
        print("No COMMON blocks found")
    print("-" * 80)

