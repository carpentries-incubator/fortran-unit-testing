find_package(PFUNIT REQUIRED)

add_pfunit_ctest(temp_conversions_tests
  TEST_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/test_parallel_temp_conversions.pf"
  LINK_LIBRARIES temp_conversions
  MAX_PES 4
)
