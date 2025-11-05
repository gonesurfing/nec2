# Makefile for NEC2 test suite

FC = gfortran
FFLAGS = -O2 -std=legacy -w
PYTHON = python3

# Directories
SRC_DIR = ..
TEST_DIR = .
REF_DIR = reference_outputs
NEW_DIR = new_outputs
CASES_DIR = reference_cases

# Original executable
ORIG_EXEC = ../nec2dxs
NEW_EXEC = ../nec2dxs_new

# Test executables
TEST_UNITS = test_unit_functions

.PHONY: all reference test clean help

help:
	@echo "NEC2 Test Suite"
	@echo "==============="
	@echo ""
	@echo "Targets:"
	@echo "  make reference    - Generate reference data from original code"
	@echo "  make test         - Run all tests comparing new vs. reference"
	@echo "  make unit_tests   - Run unit tests on individual functions"
	@echo "  make compare      - Compare specific outputs"
	@echo "  make clean        - Remove test outputs"
	@echo ""
	@echo "Usage:"
	@echo "  1. First compile original: cd .. && make"
	@echo "  2. Generate reference: make reference"
	@echo "  3. Compile new version with changes"
	@echo "  4. Run tests: make test"

# Generate reference data from original code
reference: $(ORIG_EXEC)
	@echo "Generating reference data..."
	@mkdir -p $(REF_DIR)
	@bash generate_reference_data.sh

# Run comparison tests
test: $(NEW_EXEC)
	@echo "Running comparison tests..."
	@mkdir -p $(NEW_DIR)
	@# Run new version on all test cases
	@for necfile in $(CASES_DIR)/*.nec; do \
		if [ -f "$$necfile" ]; then \
			base=$$(basename "$$necfile" .nec); \
			echo "Testing: $$base"; \
			$(NEW_EXEC) < "$$necfile" > "$(NEW_DIR)/$${base}.out" 2>&1; \
		fi \
	done
	@# Compare outputs
	@$(PYTHON) compare_outputs.py $(REF_DIR) $(NEW_DIR)

# Build and run unit tests
unit_tests: $(TEST_UNITS)
	@echo "Running unit tests..."
	@./$(TEST_UNITS)

$(TEST_UNITS): test_unit_functions.f90
	$(FC) $(FFLAGS) -o $@ $^ $(SRC_DIR)/nec2dxs.f

# Compare specific test case
compare:
	@if [ -z "$(CASE)" ]; then \
		echo "Error: Specify CASE=testname"; \
		echo "Example: make compare CASE=dipole_halfwave"; \
		exit 1; \
	fi
	@$(PYTHON) compare_outputs.py $(REF_DIR) $(NEW_DIR) "$(CASE).out"

# Run performance comparison
benchmark: $(ORIG_EXEC) $(NEW_EXEC)
	@echo "Running performance benchmark..."
	@for necfile in $(CASES_DIR)/*.nec; do \
		if [ -f "$$necfile" ]; then \
			base=$$(basename "$$necfile" .nec); \
			echo "Benchmarking: $$base"; \
			echo -n "  Original: "; \
			/usr/bin/time -f "%E elapsed, %M KB" $(ORIG_EXEC) < "$$necfile" > /dev/null 2>&1; \
			echo -n "  New:      "; \
			/usr/bin/time -f "%E elapsed, %M KB" $(NEW_EXEC) < "$$necfile" > /dev/null 2>&1; \
		fi \
	done

# Clean test outputs
clean:
	rm -f $(TEST_UNITS)
	rm -f $(NEW_DIR)/*.out
	rm -f test_results.json
	rm -f *.mod

distclean: clean
	rm -rf $(REF_DIR)
	rm -rf $(NEW_DIR)

# Check if executables exist
$(ORIG_EXEC):
	@echo "Error: Original nec2dxs not found"
	@echo "Please compile it first: cd .. && make"
	@exit 1

$(NEW_EXEC):
	@echo "Error: New nec2dxs_new not found"
	@echo "Please compile the modernized version first"
	@exit 1
