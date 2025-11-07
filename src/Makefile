# Makefile for modernized NEC2
# Compiles all modules and main program in correct dependency order

# Compiler and flags
FC = gfortran
FFLAGS = -O2 -g -Wall -Wextra -Wno-compare-reals -pedantic -std=f2008 -fall-intrinsics -fbacktrace
MODDIR = modules
OBJDIR = obj

# Module source files in dependency order
MODULE_SOURCES = \
	$(MODDIR)/nec2_constants.f90 \
	$(MODDIR)/nec2_data_types.f90 \
	$(MODDIR)/nec2_utilities.f90 \
	$(MODDIR)/nec2_geometry.f90 \
	$(MODDIR)/nec2_current.f90 \
	$(MODDIR)/nec2_kernel.f90 \
	$(MODDIR)/nec2_sommerfeld.f90 \
	$(MODDIR)/nec2_matrix.f90 \
	$(MODDIR)/nec2_solver.f90 \
	$(MODDIR)/nec2_fields.f90 \
	$(MODDIR)/nec2_excitation.f90 \
	$(MODDIR)/nec2_io.f90

# Main program
MAIN_SOURCE = nec2_main.f90

# Object files
MODULE_OBJECTS = $(patsubst $(MODDIR)/%.f90,$(OBJDIR)/%.o,$(MODULE_SOURCES))
MAIN_OBJECT = $(OBJDIR)/nec2_main.o

# Executable
EXECUTABLE = nec2

# Default target
all: $(EXECUTABLE)

# Create object directory
$(OBJDIR):
	mkdir -p $(OBJDIR)

# Link executable
$(EXECUTABLE): $(MODULE_OBJECTS) $(MAIN_OBJECT)
	$(FC) $(FFLAGS) -o $@ $^
	@echo ""
	@echo "==================================="
	@echo "Build successful!"
	@echo "Executable: $(EXECUTABLE)"
	@echo "==================================="
	@echo ""

# Compile main program (depends on all modules)
$(MAIN_OBJECT): $(MAIN_SOURCE) $(MODULE_OBJECTS) | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

# Module compilation rules with explicit dependencies
$(OBJDIR)/nec2_constants.o: $(MODDIR)/nec2_constants.f90 | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_data_types.o: $(MODDIR)/nec2_data_types.f90 $(OBJDIR)/nec2_constants.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_utilities.o: $(MODDIR)/nec2_utilities.f90 $(OBJDIR)/nec2_constants.o $(OBJDIR)/nec2_data_types.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_geometry.o: $(MODDIR)/nec2_geometry.f90 $(OBJDIR)/nec2_constants.o $(OBJDIR)/nec2_data_types.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_current.o: $(MODDIR)/nec2_current.f90 $(OBJDIR)/nec2_constants.o $(OBJDIR)/nec2_data_types.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_kernel.o: $(MODDIR)/nec2_kernel.f90 $(OBJDIR)/nec2_constants.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_sommerfeld.o: $(MODDIR)/nec2_sommerfeld.f90 $(OBJDIR)/nec2_constants.o $(OBJDIR)/nec2_data_types.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_matrix.o: $(MODDIR)/nec2_matrix.f90 $(OBJDIR)/nec2_constants.o $(OBJDIR)/nec2_data_types.o $(OBJDIR)/nec2_kernel.o $(OBJDIR)/nec2_sommerfeld.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_solver.o: $(MODDIR)/nec2_solver.f90 $(OBJDIR)/nec2_constants.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_fields.o: $(MODDIR)/nec2_fields.f90 $(OBJDIR)/nec2_constants.o $(OBJDIR)/nec2_data_types.o $(OBJDIR)/nec2_kernel.o $(OBJDIR)/nec2_sommerfeld.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_excitation.o: $(MODDIR)/nec2_excitation.f90 $(OBJDIR)/nec2_constants.o $(OBJDIR)/nec2_data_types.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

$(OBJDIR)/nec2_io.o: $(MODDIR)/nec2_io.f90 $(OBJDIR)/nec2_constants.o $(OBJDIR)/nec2_data_types.o | $(OBJDIR)
	$(FC) $(FFLAGS) -J$(OBJDIR) -I$(OBJDIR) -c $< -o $@

# Clean targets
clean:
	rm -rf $(OBJDIR) *.mod

distclean: clean
	rm -f $(EXECUTABLE)

# Test target - compile only
test-compile: all
	@echo "Compilation test passed!"

# Help target
help:
	@echo "Modernized NEC2 Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all           - Build the NEC2 executable (default)"
	@echo "  clean         - Remove object files and modules"
	@echo "  distclean     - Remove all build artifacts including executable"
	@echo "  test-compile  - Test compilation only"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Module compilation order:"
	@echo "  1. nec2_constants"
	@echo "  2. nec2_data_types"
	@echo "  3. nec2_utilities"
	@echo "  4. nec2_geometry"
	@echo "  5. nec2_current"
	@echo "  6. nec2_kernel"
	@echo "  7. nec2_sommerfeld"
	@echo "  8. nec2_matrix"
	@echo "  9. nec2_solver"
	@echo "  10. nec2_fields"
	@echo "  11. nec2_excitation"
	@echo "  12. nec2_io"
	@echo "  13. nec2_main (links all)"

.PHONY: all clean distclean test-compile help
