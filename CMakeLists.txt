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

# Source files
set(SOURCES
    nec2_common.f
    nec2_io.f
    nec2_geometry.f
    nec2_greens.f
    nec2_solve.f
    nec2_fields.f
    nec2_network.f
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
