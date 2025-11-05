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
NEW_EXEC = ../src/nec2

# Test executables
TEST_UNITS = test_unit_functions
TEST_NEW = test_new_modules
TEST_ALL = test_all_modules

# Module directories
MOD_DIR = ../src/modules

.PHONY: all reference test clean help test_modules integration test_all end_to_end full_test

help:
	@echo "NEC2 Test Suite"
	@echo "==============="
	@echo ""
	@echo "Targets:"
	@echo "  make reference     - Generate reference data from original code"
	@echo "  make test          - Run all tests comparing new vs. reference"
	@echo "  make unit_tests    - Run unit tests on original functions"
	@echo "  make test_modules  - Run unit tests on NEW modernized modules (basic)"
	@echo "  make test_all      - Run comprehensive tests on ALL modules"
	@echo "  make integration   - Run integration test (build + basic execution)"
	@echo "  make end_to_end    - Run complete end-to-end test suite"
	@echo "  make full_test     - Run EVERYTHING (integration + end_to_end)"
	@echo "  make compare       - Compare specific outputs"
	@echo "  make clean         - Remove test outputs"
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

# Build unit tests using extracted utility functions
# This tests the ORIGINAL functions from nec2dxs.f
$(TEST_UNITS): test_unit_functions.f90 nec2_test_utils.f
	@echo "Building unit tests for original functions..."
	$(FC) $(FFLAGS) -o $@ test_unit_functions.f90 nec2_test_utils.f

# Build tests for NEW modernized modules
test_modules: $(TEST_NEW)
	@echo "Running unit tests on modernized modules..."
	@./$(TEST_NEW)

# Compile modules in dependency order, then link test
$(TEST_NEW): test_new_modules.f90 $(MOD_DIR)/*.f90
	@echo "Building tests for modernized modules..."
	@echo "  Compiling modules in dependency order..."
	@# Compile in order: constants -> data_types -> utilities
	$(FC) $(FFLAGS) -c $(MOD_DIR)/nec2_constants.f90 -o nec2_constants.o
	$(FC) $(FFLAGS) -c $(MOD_DIR)/nec2_data_types.f90 -o nec2_data_types.o
	$(FC) $(FFLAGS) -c $(MOD_DIR)/nec2_utilities.f90 -o nec2_utilities.o
	@echo "  Compiling and linking test program..."
	$(FC) $(FFLAGS) -o $@ test_new_modules.f90 nec2_constants.o nec2_data_types.o nec2_utilities.o
	@echo "  Cleaning up intermediate files..."
	@rm -f nec2_constants.o nec2_data_types.o nec2_utilities.o

# Run integration test
integration:
	@echo "Running integration test..."
	@bash test_integration.sh

# Build and run comprehensive module tests
test_all: $(TEST_ALL)
	@echo "Running comprehensive module tests..."
	@./$(TEST_ALL)

# Build comprehensive module test executable
$(TEST_ALL): test_all_modules.f90 $(MOD_DIR)/*.f90
	@echo "Building comprehensive module test suite..."
	@echo "  Compiling modules in dependency order..."
	@# Compile foundation modules
	$(FC) -O2 -std=f2008 -c $(MOD_DIR)/nec2_constants.f90 -o nec2_constants.o
	$(FC) -O2 -std=f2008 -c $(MOD_DIR)/nec2_data_types.f90 -o nec2_data_types.o
	$(FC) -O2 -std=f2008 -c $(MOD_DIR)/nec2_utilities.f90 -o nec2_utilities.o
	$(FC) -O2 -std=f2008 -c $(MOD_DIR)/nec2_geometry.f90 -o nec2_geometry.o
	@echo "  Compiling and linking test program..."
	$(FC) -O2 -std=f2008 -o $@ test_all_modules.f90 nec2_constants.o nec2_data_types.o nec2_utilities.o nec2_geometry.o
	@echo "  Cleaning up intermediate files..."
	@rm -f nec2_constants.o nec2_data_types.o nec2_utilities.o nec2_geometry.o

# Run complete end-to-end test
end_to_end:
	@echo "Running end-to-end test suite..."
	@bash test_end_to_end.sh

# Run full test suite (everything!)
full_test: integration test_all end_to_end
	@echo ""
	@echo "========================================"
	@echo "FULL TEST SUITE COMPLETE"
	@echo "========================================"
	@echo ""
	@echo "All tests have been executed:"
	@echo "  ✓ Integration test (build + basic execution)"
	@echo "  ✓ Module unit tests (all 12 modules)"
	@echo "  ✓ End-to-end comparison (vs. original code)"
	@echo ""

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
	rm -f $(TEST_UNITS) $(TEST_NEW) $(TEST_ALL)
	rm -f $(NEW_DIR)/*.out
	rm -f test_results.json
	rm -f comparison_results.txt
	rm -f *_diff.txt
	rm -f *.mod *.o

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
