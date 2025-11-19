#!/usr/bin/env python3
import re

with open('nec2dxs_integrated.f', 'r') as f:
    content = f.read()

# Find all subroutines and functions with their content
pattern = r'^\s+(SUBROUTINE|.*FUNCTION)\s+(\w+)'
matches = list(re.finditer(pattern, content, re.MULTILINE))

results = []
for i, match in enumerate(matches):
    name = match.group(2)
    start = match.start()
    # Find end (next subroutine/function or end of file)
    end = matches[i+1].start() if i+1 < len(matches) else len(content)
    
    section = content[start:end]
    goto_count = len(re.findall(r'\bGO\s*TO\b|\bGOTO\b', section, re.IGNORECASE))
    
    if goto_count > 0:
        results.append((name, goto_count))

# Sort by GOTO count
results.sort(key=lambda x: x[1])

print("Remaining Subroutines/Functions with GOTOs:")
print("=" * 50)
for name, count in results:
    print(f"{name:20s}: {count:3d} GOTOs")

print(f"\nTotal: {sum(c for _, c in results)} GOTOs in {len(results)} routines")
