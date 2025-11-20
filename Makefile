# Makefile for NEC2D with Modernized Modules
# ============================================
# Builds nec2dxs_integrated executable with modernized Fortran 90 modules
#
# Usage:
#   make              - Build nec2dxs_integrated
#   make clean        - Remove object files and executable
#   make test         - Build and run test with MD5 verification
#   make help         - Show this help

# Compiler and flags
FC = gfortran
FFLAGS = -O0 -std=legacy -Wall -Wno-unused-parameter
# -std=legacy: Accept REAL*8, COMPLEX*16, Hollerith formats
# -Wall: Enable all warnings
# -Wno-unused-parameter: Suppress warnings for unused PARAMETERs

# Executable name
TARGET = nec2dxs_modern

# Main program object file
MAIN_OBJ = nec2dxs_modern.o

# Module object files (order matters for dependencies)
# These must be compiled BEFORE files that USE them
MODULE_DEPS = nec2d_params.o nec2d_commons.o

# Modernized module object files (alphabetical order)
MODULE_OBJS = \
	nec2d_bessel.o \
	nec2d_cmngf.o \
	nec2d_conect.o \
	nec2d_dataproc.o \
	nec2d_fields.o \
	nec2d_fields2.o \
	nec2d_fields3.o \
	nec2d_geometry.o \
	nec2d_geomproc.o \
	nec2d_integration.o \
	nec2d_io.o \
	nec2d_isegno.o \
	nec2d_kernels.o \
	nec2d_mathutil.o \
	nec2d_matrix.o \
	nec2d_matrix2.o \
	nec2d_matrix3.o \
	nec2d_nearfield.o \
	nec2d_numint.o \
	nec2d_rdpat.o \
	nec2d_segment.o \
	nec2d_simple.o \
	nec2d_solver.o \
	nec2d_sommerfeld.o \
	nec2d_utilities.o \
	nec2d_utils.o

# All object files
ALL_OBJS = $(MAIN_OBJ) $(MODULE_DEPS) $(MODULE_OBJS)

# Default target
all: $(TARGET)

# Link executable
$(TARGET): $(ALL_OBJS)
	@echo "Linking $(TARGET)..."
	$(FC) -O0 $(ALL_OBJS) -o $(TARGET)
	@echo "Build complete: $(TARGET)"
	@ls -lh $(TARGET)

# Main program depends on module dependencies
$(MAIN_OBJ): nec2dxs_integrated.f $(MODULE_DEPS)
	@echo "Compiling main program..."
	$(FC) -c $(FFLAGS) nec2dxs_integrated.f -o $(MAIN_OBJ)

# Module dependency compilation order
# nec2d_params.o has no dependencies (compile first)
nec2d_params.o: nec2d_params.f90
	@echo "Compiling nec2d_params (no dependencies)..."
	$(FC) -c $(FFLAGS) nec2d_params.f90 -o nec2d_params.o

# nec2d_commons.o depends on nec2d_params.o
nec2d_commons.o: nec2d_commons.f90 nec2d_params.o
	@echo "Compiling nec2d_commons (depends on nec2d_params)..."
	$(FC) -c $(FFLAGS) nec2d_commons.f90 -o nec2d_commons.o

# Modules that USE nec2d_commons must be compiled after it
# (These 4 modules explicitly USE nec2d_commons)
nec2d_cmngf.o: nec2d_cmngf.f90 $(MODULE_DEPS)
	@echo "Compiling nec2d_cmngf (uses nec2d_commons)..."
	$(FC) -c $(FFLAGS) nec2d_cmngf.f90 -o nec2d_cmngf.o

nec2d_segment.o: nec2d_segment.f90 $(MODULE_DEPS)
	@echo "Compiling nec2d_segment (uses nec2d_commons)..."
	$(FC) -c $(FFLAGS) nec2d_segment.f90 -o nec2d_segment.o

nec2d_isegno.o: nec2d_isegno.f90 $(MODULE_DEPS)
	@echo "Compiling nec2d_isegno (uses nec2d_commons)..."
	$(FC) -c $(FFLAGS) nec2d_isegno.f90 -o nec2d_isegno.o

nec2d_utils.o: nec2d_utils.f90 $(MODULE_DEPS)
	@echo "Compiling nec2d_utils (uses nec2d_commons)..."
	$(FC) -c $(FFLAGS) nec2d_utils.f90 -o nec2d_utils.o

# Pattern rule for other .f90 files (don't USE modules, only need params compiled first)
%.o: %.f90 nec2d_params.o
	@echo "Compiling $<..."
	$(FC) -c $(FFLAGS) $< -o $@

# Pattern rule for .f files (legacy fixed-form Fortran)
%.o: %.f
	@echo "Compiling $<..."
	$(FC) -c $(FFLAGS) $< -o $@

# Test target - build and verify output
test: $(TARGET)
	@echo ""
	@echo "Running test with example1.nec..."
	@./$(TARGET) < example1.nec > test_output.txt 2>&1
	@echo "Verifying MD5 checksum..."
	@md5sum test_output.txt
	@echo "Expected: 7c45f1e15ba34584728075e0cf6402c1"
	@if md5sum test_output.txt | grep -q 7c45f1e15ba34584728075e0cf6402c1; then \
		echo "✅ Test PASSED - Output is bit-identical"; \
	else \
		echo "❌ Test FAILED - Output differs from expected"; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(ALL_OBJS) $(TARGET) *.mod test_output.txt
	@echo "Clean complete"

# Help target
help:
	@echo "NEC2D Modernized Build System"
	@echo "=============================="
	@echo ""
	@echo "Targets:"
	@echo "  make              - Build nec2dxs_integrated executable"
	@echo "  make test         - Build and run test with MD5 verification"
	@echo "  make clean        - Remove all build artifacts"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Module Dependencies:"
	@echo "  1. nec2d_params.o   - Compiled first (no dependencies)"
	@echo "  2. nec2d_commons.o  - Depends on nec2d_params.o"
	@echo "  3. Other modules    - Compiled after dependencies"
	@echo "  4. Main program     - Compiled last"
	@echo ""
	@echo "Modules using USE nec2d_commons:"
	@echo "  - nec2d_cmngf.o"
	@echo "  - nec2d_segment.o"
	@echo "  - nec2d_isegno.o"
	@echo "  - nec2d_utils.o"
	@echo ""
	@echo "Current Status:"
	@echo "  - GOTO elimination: 68.6% complete (699/1,019)"
	@echo "  - COMMON modernization: 10.7% (3/28 modules)"
	@echo "  - Expected MD5: 7c45f1e15ba34584728075e0cf6402c1"

# Phony targets (not actual files)
.PHONY: all clean test help
