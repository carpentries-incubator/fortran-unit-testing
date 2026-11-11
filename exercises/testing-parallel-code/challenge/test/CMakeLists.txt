find_package(PFUNIT REQUIRED)

add_pfunit_ctest(mpi_utils_tests
  TEST_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/test_sum_all_rank_values.pf"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_sum_preceding_rank_values.pf"
  LINK_LIBRARIES mpi_utils
  MAX_PES 4
)

