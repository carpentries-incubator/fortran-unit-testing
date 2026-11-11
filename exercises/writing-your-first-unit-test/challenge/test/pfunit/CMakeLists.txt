message(STATUS "Using pfunit")

add_library(temp_conversions STATIC ${PROJ_SRC_FILES})

# Define test file(s)
set(test_srcs "${PROJECT_SOURCE_DIR}/test/pfunit/test_temp_conversions.pf")

# Add pfUnit tests
add_pfunit_ctest (test_temp_conversions
  TEST_SOURCES ${test_srcs}
  LINK_LIBRARIES temp_conversions
  )
