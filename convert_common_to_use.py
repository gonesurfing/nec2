#!/usr/bin/env python3
"""
Convert COMMON blocks to USE...ONLY clauses with proper aliasing
"""
import re
import sys

# Map COMMON block names to module variable names and original names
# Format: block_name: [(module_var, original_var), ...]
common_mappings = {
    'DATA': [
        ('X', 'X'), ('Y', 'Y'), ('Z', 'Z'), ('SI', 'SI'), ('BI', 'BI'),
        ('ALP', 'ALP'), ('BET', 'BET'), ('WLAM', 'WLAM'),
        ('ICON1', 'ICON1'), ('ICON2', 'ICON2'), ('ITAG', 'ITAG'), ('ICONX', 'ICONX'),
        ('LD', 'LD'), ('N1', 'N1'), ('N2', 'N2'), ('N', 'N'), ('NP', 'NP'),
        ('M1', 'M1'), ('M2', 'M2'), ('M', 'M'), ('MP', 'MP'), ('IPSYM', 'IPSYM')
    ],
    'DATAJ': [
        ('S_J', 'S'), ('B_J', 'B'), ('XJ', 'XJ'), ('YJ', 'YJ'), ('ZJ', 'ZJ'),
        ('CABJ', 'CABJ'), ('SABJ', 'SABJ'), ('SALPJ', 'SALPJ'),
        ('EXK', 'EXK'), ('EYK', 'EYK'), ('EZK', 'EZK'),
        ('EXS', 'EXS'), ('EYS', 'EYS'), ('EZS', 'EZS'),
        ('EXC', 'EXC'), ('EYC', 'EYC'), ('EZC', 'EZC'),
        ('RKH', 'RKH'), ('IND1', 'IND1'), ('INDD1', 'INDD1'),
        ('IND2', 'IND2'), ('INDD2', 'INDD2'), ('IEXK', 'IEXK'), ('IPGND', 'IPGND')
    ],
    'ANGL': [('SALP', 'SALP')],
    'GND': [
        ('ZRATI', 'ZRATI'), ('ZRATI2', 'ZRATI2'), ('FRATI', 'FRATI'),
        ('T1', 'T1'), ('T2', 'T2'), ('CL', 'CL'), ('CH', 'CH'),
        ('SCRWL', 'SCRWL'), ('SCRWR', 'SCRWR'), ('NRADL', 'NRADL'),
        ('KSYMP', 'KSYMP'), ('IFAR', 'IFAR'), ('IPERF', 'IPERF')
    ],
    'INCOM': [
        ('XO', 'XO'), ('YO', 'YO'), ('ZO', 'ZO'), ('SN', 'SN'),
        ('XSN', 'XSN'), ('YSN', 'YSN'), ('ISNOR', 'ISNOR')
    ],
    'PLOT': [('IPLP1', 'IPLP1'), ('IPLP2', 'IPLP2'), ('IPLP3', 'IPLP3'), ('IPLP4', 'IPLP4')],
    'VSORC': [
        ('VQD', 'VQD'), ('VSANT', 'VSANT'), ('VQDS', 'VQDS'),
        ('IVQD', 'IVQD'), ('ISANT', 'ISANT'), ('IQDS', 'IQDS'),
        ('NVQD', 'NVQD'), ('NSANT', 'NSANT'), ('NQDS', 'NQDS')
    ],
    'MATPAR': [
        ('ICASE', 'ICASE'), ('NBLOKS', 'NBLOKS'), ('NPBLK', 'NPBLK'),
        ('NLAST', 'NLAST'), ('NBLSYM', 'NBLSYM'), ('NPSYM', 'NPSYM'),
        ('NLSYM', 'NLSYM'), ('IMAT', 'IMAT'), ('ICASX', 'ICASX'),
        ('NBBX', 'NBBX'), ('NPBX', 'NPBX'), ('NLBX', 'NLBX'),
        ('NBBL', 'NBBL'), ('NPBL', 'NPBL'), ('NLBL', 'NLBL')
    ],
    'SEGJ': [
        ('AX', 'AX'), ('BX', 'BX'), ('CX', 'CX'), ('JCO', 'JCO'),
        ('JSNO', 'JSNO'), ('ISCON', 'ISCON'), ('NSCON', 'NSCON'),
        ('IPCON', 'IPCON'), ('NPCON', 'NPCON')
    ],
    'ZLOAD': [('ZARRAY', 'ZARRAY'), ('NLOAD', 'NLOAD'), ('NLODF', 'NLODF')],
    'GGRID': [
        ('AR1', 'AR1'), ('AR2', 'AR2'), ('AR3', 'AR3'), ('EPSCF', 'EPSCF'),
        ('DXA', 'DXA'), ('DYA', 'DYA'), ('XSA', 'XSA'), ('YSA', 'YSA'),
        ('NXA', 'NXA'), ('NYA', 'NYA')
    ],
    'EVLCOM': [
        ('CKSM', 'CKSM'), ('CT1', 'CT1'), ('CT2', 'CT2'), ('CT3', 'CT3'),
        ('CK1', 'CK1'), ('CK1SQ', 'CK1SQ'), ('CK2', 'CK2'), ('CK2SQ', 'CK2SQ'),
        ('TKMAG', 'TKMAG'), ('TSMAG', 'TSMAG'), ('CK1R', 'CK1R'),
        ('ZPH_EV', 'ZPH'), ('RHO_EV', 'RHO'), ('JH', 'JH')
    ],
    'GWAV': [
        ('U', 'U'), ('U2', 'U2'), ('XX1', 'XX1'), ('XX2', 'XX2'),
        ('R1', 'R1'), ('R2', 'R2'), ('ZMH', 'ZMH'), ('ZPH', 'ZPH')
    ],
    'SCRATM': [('SCRATM_REAL', 'D'), ('SCRATM_CPLX', 'Y')],  # Has multiple aliases
    'CNTOUR': [('A_CNTOUR', 'A'), ('B_CNTOUR', 'B')],
    'TMI': [('ZPK_TMI', 'ZPK'), ('RKB2', 'RKB2'), ('IJX_TMI', 'IJX')],
    'TMH': [('ZPK_TMH', 'ZPK'), ('RHKS', 'RHKS')],
    'SMAT': [('SSX', 'SSX')],
    'CMB': [('CM', 'CM')],
    'CRNT': [
        ('AIR', 'AIR'), ('AII', 'AII'), ('BIR', 'BIR'), ('BII', 'BII'),
        ('CIR', 'CIR'), ('CII', 'CII'), ('CUR', 'CUR')
    ],
    'YPARM': [
        ('Y11A', 'Y11A'), ('Y12A', 'Y12A'), ('NCOUP', 'NCOUP'),
        ('ICOUP', 'ICOUP'), ('NCTAG', 'NCTAG'), ('NCSEG', 'NCSEG')
    ],
    'NGFNAM': [('NGFNAM', 'NGFNAM')],
}

def find_common_blocks(filename):
    """Find all COMMON block declarations in a file"""
    with open(filename, 'r') as f:
        content = f.read()
    
    # Find all COMMON declarations with their line info
    blocks = {}
    for match in re.finditer(r'^(\s*)COMMON\s+/(\w+)/[^\n]*$', content, re.IGNORECASE | re.MULTILINE):
        indent = match.group(1)
        block = match.group(2).upper()
        line_start = content[:match.start()].count('\n') + 1
        blocks[line_start] = (indent, block, match.group(0))
    
    return blocks

def generate_use_only(blocks_used):
    """Generate USE...ONLY clause for given blocks"""
    if not blocks_used:
        return "  USE nec2d_params\n  ! No COMMON blocks"
    
    lines = ["  USE nec2d_params", "  USE nec2d_commons, ONLY: &"]
    
    block_list = sorted(blocks_used)
    for i, block in enumerate(block_list):
        if block not in common_mappings:
            print(f"WARNING: Unknown COMMON block /{block}/", file=sys.stderr)
            continue
        
        mappings = common_mappings[block]
        # Create aliases: original => MODULE_VAR
        aliases = []
        for mod_var, orig_var in mappings:
            if mod_var.lower() == orig_var.lower():
                aliases.append(mod_var)  # No alias needed
            else:
                aliases.append(f"{orig_var.lower()} => {mod_var}")
        
        var_list = ', '.join(aliases)
        comment = f"! /{block}/ - {len(mappings)} variables"
        
        is_last = (i == len(block_list) - 1)
        if is_last:
            lines.append(f"    {var_list}  {comment}")
        else:
            lines.append(f"    {var_list}, & {comment}")
    
    return '\n'.join(lines)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: convert_common_to_use.py <filename>")
        sys.exit(1)
    
    filename = sys.argv[1]
    blocks = find_common_blocks(filename)
    
    if not blocks:
        print(f"No COMMON blocks found in {filename}")
        sys.exit(0)
    
    print(f"Found {len(blocks)} COMMON block declarations in {filename}:")
    blocks_used = set()
    for line_num, (indent, block, full_line) in sorted(blocks.items()):
        print(f"  Line {line_num}: /{block}/")
        blocks_used.add(block)
    
    print("\nGenerated USE...ONLY clause:")
    print(generate_use_only(blocks_used))
    print("\nTo convert, replace COMMON declarations with the USE clause above.")

