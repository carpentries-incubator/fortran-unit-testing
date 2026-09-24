message(STATUS "Using pFUnit")

# Create library for src code
add_library (sut STATIC ${PROJ_SRC_FILES})

set(TEST_FILES
    "test_temp_conversions.pf"
    "test_temp_conversions_parameterised.pf"
)

add_pfunit_ctest (pfunit_test_temp_conversions_exec
    TEST_SOURCES ${TEST_FILES}
    LINK_LIBRARIES sut # your application library
    )
