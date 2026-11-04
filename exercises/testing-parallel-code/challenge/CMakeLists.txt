cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

project(
  "mpi_utils"
  LANGUAGES Fortran
  VERSION 0.1.0
  DESCRIPTION "Small MPI utility library"
)

set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-none")

find_package(MPI REQUIRED COMPONENTS Fortran)

add_library(mpi_utils src/mpi_utils.f90)
target_link_libraries(mpi_utils PUBLIC MPI::MPI_Fortran)

set(MPI_UTILS_MODULE_DIR "${CMAKE_CURRENT_BINARY_DIR}/modules")
set_target_properties(mpi_utils PROPERTIES
  Fortran_MODULE_DIRECTORY "${MPI_UTILS_MODULE_DIR}"
)
target_include_directories(mpi_utils PUBLIC
  "$<BUILD_INTERFACE:${MPI_UTILS_MODULE_DIR}>"
)

enable_testing()
add_subdirectory(test)
