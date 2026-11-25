cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

project(
  "temp_conversions"
  LANGUAGES Fortran
  VERSION 0.1.0
  DESCRIPTION "Temperature conversion library with MPI procedures"
)

set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-none")

find_package(MPI REQUIRED COMPONENTS Fortran)

add_library(temp_conversions src/temp_conversions.f90)
target_link_libraries(temp_conversions PUBLIC MPI::MPI_Fortran)

set(TEMP_CONVERSIONS_MODULE_DIR "${CMAKE_CURRENT_BINARY_DIR}/modules")
set_target_properties(temp_conversions PROPERTIES
  Fortran_MODULE_DIRECTORY "${TEMP_CONVERSIONS_MODULE_DIR}"
)
target_include_directories(temp_conversions PUBLIC
  "$<BUILD_INTERFACE:${TEMP_CONVERSIONS_MODULE_DIR}>"
)

enable_testing()
add_subdirectory(test)
