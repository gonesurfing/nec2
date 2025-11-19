# NEC2 Modernization - Quick Start Guide

## Current Status: 64.0% Complete (652/1,019 GOTOs)

### Instant Status Check
```bash
cd /home/user/nec2
python3 analyze_remaining.py
grep -i "GO TO" nec2dxs_integrated.f | wc -l  # Should show 367
git log --oneline -5
```

### Test Current Build (30 seconds)
```bash
rm -f *.o nec2dxs_integrated && bash build_integrated.sh
./nec2dxs_integrated < example1.nec > output_test.txt 2>&1
md5sum output_test.txt
# Expected: 7c45f1e15ba34584728075e0cf6402c1
```

---

## Remaining Routines (367 GOTOs)

### ✅ SAFE TO ATTEMPT (Recommended Order)
1. **CMNGF** (38 GOTOs) - Matrix filling, mathematical operations
   - Lines 1028-1296 (269 lines)
   - Location: `nec2dxs_integrated.f`

### ⚠️ HIGH RISK (Failed Before - Don't Retry)
- **TBF** (23 GOTOs) ❌ - Basis functions
- **QDSRC** (24 GOTOs) ❌ - Charge discontinuity
- **LOAD** (26 GOTOs) ❌ - Impedance loading
- **NETWK** (47 GOTOs) ❌ - Network analysis (FPE crash)

### ⚠️ COMPLEX EM PHYSICS (High Risk)
- **FFLD** (29 GOTOs) - Far-field calculation
- **NEFLD** (27 GOTOs) - Near-field calculation

### 🎯 BIGGEST CHALLENGE
- **Main Program** (153 GOTOs) - Lines 1-1027

---

## If Attempting Next Routine

### Step 1: Read and Analyze (10-15 min)
```bash
# For CMNGF example:
sed -n '1028,1296p' nec2dxs_integrated.f > cmngf_original.txt
cat cmngf_original.txt | grep -n "GO TO\|^[0-9 ]*[0-9][0-9]* " > cmngf_gotos.txt
# Study the control flow patterns
```

### Step 2: Create Module (30-60 min)
```bash
# Create nec2d_cmngf.f90 with:
# - Free-form Fortran 90
# - IMPLICIT REAL*8(A-H,O-Z) - REQUIRED for COMMON blocks
# - Eliminate all GOTOs with structured control flow
# - Keep COMMON blocks unchanged
# - Convert Hollerith FORMATs to quoted strings
```

### Step 3: Integrate (5 min)
```bash
# Create remove_cmngf.py
# Run: python3 remove_cmngf.py
# Update build_integrated.sh - add new step
```

### Step 4: Build and Test (5 min)
```bash
rm -f *.o nec2dxs_integrated
bash build_integrated.sh

# CRITICAL TEST:
./nec2dxs_integrated < example1.nec > output_test.txt 2>&1
md5sum output_test.txt

# If MD5 != 7c45f1e15ba34584728075e0cf6402c1:
# ❌ REVERT IMMEDIATELY - Bug introduced!
```

### Step 5: Commit (if successful)
```bash
git add MODERNIZATION_PLAN.md build_integrated.sh nec2dxs_integrated.f nec2d_cmngf.f90 remove_cmngf.py
git commit -m "Batch 13 Complete: Matrix NGF Filling - eliminate 38 GOTOs"
git push -u origin claude/resume-nec2-modernization-01NoV4FwVq68xQpgEHobYZGM
```

### Step 6: Update Progress
```bash
# Update MODERNIZATION_PLAN.md with new batch entry
# Update SESSION_STATUS.md if starting new session
```

---

## Critical Patterns

### LOGICAL Variables (Common Error)
```fortran
! WRONG - will fail compilation
IMPLICIT REAL*8(A-H,O-Z)
found_item = .FALSE.  ! ERROR: found_item is REAL*8!

! CORRECT
IMPLICIT REAL*8(A-H,O-Z)
LOGICAL :: found_item  ! Declare after IMPLICIT
found_item = .FALSE.  ! Now works
```

### CHARACTER Variables (Common Error)
```fortran
! CORRECT - declare after IMPLICIT
IMPLICIT REAL*8(A-H,O-Z)
CHARACTER*6 :: label_array(10)
CHARACTER*1 :: flag
```

### GOTO Elimination Patterns
```fortran
! Pattern 1: Forward GOTO
IF (condition) GO TO 5
code1
5 CONTINUE
code2

! Becomes:
IF (.NOT. condition) THEN
  code1
END IF
code2

! Pattern 2: Loop GOTO
DO I = 1, N
  IF (condition) GO TO 10
  code
10 CONTINUE
END DO

! Becomes:
DO I = 1, N
  IF (condition) CYCLE
  code
END DO

! Pattern 3: Computed GOTO
GO TO (10,20,30), INDEX

! Becomes:
SELECT CASE (INDEX)
  CASE (1)
    ! Label 10 code
  CASE (2)
    ! Label 20 code
  CASE (3)
    ! Label 30 code
END SELECT
```

---

## Emergency Procedures

### If Build Fails
```bash
# Check last commit
git log --oneline -1

# Revert changes
git restore build_integrated.sh nec2dxs_integrated.f
rm nec2d_newmodule.f90 remove_newmodule.py

# Clean rebuild
rm -f *.o nec2dxs_integrated
bash build_integrated.sh
```

### If Test Fails (Wrong MD5)
```bash
# Immediate revert - do not debug!
git restore build_integrated.sh nec2dxs_integrated.f
rm nec2d_newmodule.f90 remove_newmodule.py

# Verify recovery
./nec2dxs_integrated < example1.nec > output_test.txt 2>&1
md5sum output_test.txt  # Must be 7c45f1e15ba34584728075e0cf6402c1
```

---

## Success Indicators

### During Development
- ✅ Compiles without errors
- ✅ No new warnings
- ✅ All test passes

### Critical Test
- ✅ MD5: `7c45f1e15ba34584728075e0cf6402c1`
- ✅ No floating point exceptions
- ✅ No NaN or zero current values

### After Commit
- ✅ Git push succeeds
- ✅ Clean git status
- ✅ Documentation updated

---

## Files to Watch

### Must Update Each Batch
- `nec2dxs_integrated.f` - Remove old routine
- `build_integrated.sh` - Add new compilation step
- `MODERNIZATION_PLAN.md` - Add batch entry
- `nec2d_newroutine.f90` - New module (create)
- `remove_newroutine.py` - Extraction script (create)

### Reference Only
- `SESSION_STATUS.md` - Current session overview
- `QUICK_START.md` - This file
- `analyze_remaining.py` - GOTO counter
- `example1.nec` - Test input (don't modify!)

---

## Progress Tracking

### Current: 64.0% (652/1,019)
- ✅ Batches 1-11 complete
- ❌ 4 failed attempts (TBF, QDSRC, LOAD, NETWK)
- 🎯 Next milestone: 70% (needs 61 more GOTOs)

### Potential Next Steps
1. **CMNGF (38)** → 67.7% (690/1,019)
2. **CMNGF + Main (153+38)** → 82.7% (843/1,019)
3. **All safe routines** → Could reach ~70%

---

**Last Updated:** 2025-11-19
**Status:** ✅ Ready for next session
**Branch:** `claude/resume-nec2-modernization-01NoV4FwVq68xQpgEHobYZGM`
