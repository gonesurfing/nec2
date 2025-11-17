FC = gfortran
FFLAGS = -O0 -std=legacy -ffixed-form -ffixed-line-length-none

# Module objects will be added here as we refactor
OBJS = nec2_common.o nec2_io.o nec2dxs.o

all: nec2dxs

nec2dxs: $(OBJS)
	$(FC) $(OBJS) -o nec2dxs

%.o: %.f
	$(FC) -c $(FFLAGS) $< -o $@ 

clean:
	rm -f $(OBJS) nec2dxs
