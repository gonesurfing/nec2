cmake_minimum_required(VERSION 3.10)
project(nec2 Fortran)

# Set project directories (used by tests/CMakeLists.txt)
set(CNEC2_SOURCE_DIR ${CMAKE_SOURCE_DIR})
set(CNEC2_BINARY_DIR ${CMAKE_BINARY_DIR})

# Compiler flags
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -O0 -std=legacy -ffixed-form -ffixed-line-length-none")

# Find bash for test scripts
find_program(BASH_PROGRAM bash)

# Option for built-in SOMNEC
option(BUILTIN_SOMNEC "Use built-in SOMNEC" OFF)

# Source files (order matters for module dependencies)
set(SOURCES
    # Core modules
    nec2_parameters.f
    nec2_common.f

    # I/O routines
    io_utils.f
    stopwtch.f
    parsit.f
    gfil.f
    gfout.f

    # Geometry routines
    geometry_utils.f
    datagn.f
    reflc.f
    conect.f
    patch.f
    intrp.f
    load.f
    tbf.f
    sbf.f
    move.f

    # Green's function routines
    greens_utils.f
    som2d.f
    etmns.f
    intx.f
    gshank.f
    rom2.f

    # Solver routines
    solve.f
    reblk.f
    cmngf.f
    cmset.f
    cmsw.f
    cmww.f
    cmss.f
    cmws.f
    solves.f
    solgf.f
    lfactr.f
    facgf.f
    factr.f
    factrs.f
    fblock.f
    fbngf.f
    ltsolv.f
    lunscr.f
    facio.f

    # Field calculation routines
    fields_utils.f
    ffld.f
    rdpat.f
    efld.f
    gfld.f
    nefld.f
    sflds.f
    hsfld.f
    nhfld.f

    # Network routines
    network_utils.f
    netwk.f
    qdsrc.f

    # Main program
    nec2dxs.f
)

# Main executable
add_executable(nec2dxs ${SOURCES})

# Set executable path for test scripts
set(NEC2_EXECUTABLE ${CMAKE_BINARY_DIR}/nec2dxs)

# Enable testing
enable_testing()

# Add test subdirectory
add_subdirectory(tests)
