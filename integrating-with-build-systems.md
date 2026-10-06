---
title: "Integrating with build systems"
teaching:
exercises:
---

:::::::::::::::::::::::::::::::::::::: questions

- How do we go from **.pf** files to an executable test?
- How do we identify which test is failing and where?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Be able to add a new test to an existing Make and CMake build system.
- Understand where we name tests within the build system.

::::::::::::::::::::::::::::::::::::::::::::::::

## Integrating pFUnit with Make

Let's look at the steps required to add pFUnit tests to a project built using Make.
Firstly, assume we have the following file structure.

```txt
|-- ROOT_DIR/
    | Makefile
    |-- src/
    |   |-- matrix_ops.f90
    |
    |-- tests/
        |-- Makefile
        |-- test_matrix_ops_dot.pf
```

The top level **Makefile** is responsible for compiling the src code but
should do little regarding building the tests. However, it should…

- Export relevant variables for the **tests/Makefile** to pick up.

  ```bash
  export SRC_BUILD_DIR
  export ROOT_DIR
  export SRC_OBJS
  export FC
  export FC_FLAGS
  export LIBS
  ```

- Define targets which pass through to targets in the **tests/Makefile**.

  ```Makefile
  tests: $(SRC_OBJS)
   @echo "Building pFUnit test suite..."
   @$(MAKE) -C $(TEST_DIR) tests

  clean:
   rm -rf $(BUILD_DIR)
   $(MAKE) -C $(TEST_DIR) clean
  ```

::::::::::::::::::::: spoiler

### Full file

The full top level **Makefile** may look something like this:

```makefile
# Top level variables
ROOT_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
FC ?= gfortran
FC_FLAGS = #... Some flags required for compilation
LIBS = #... Some libs to link to

#------------------------------------#
#      Targets for compiling src     #
#------------------------------------#
SRC_DIR = $(ROOT_DIR)/src
BUILD_DIR = $(ROOT_DIR)/build

# List src files
SRC_FILES = matrix_ops.f90

# Map src files to .o files
SRC_OBJS = $(patsubst %.f90, $(BUILD_DIR)/%.o, $(SRC_FILES))

# Build src .o files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.f90 | $(BUILD_DIR)
 @echo "Building $@"
 $(FC) -c -J $(BUILD_DIR) -o $@ $<

# Ensure the build dirs exists
$(BUILD_DIR):
 mkdir -p $@

#------------------------------------#
#         Targets for testing        #
#------------------------------------#
TEST_DIR = $(ROOT_DIR)/tests

# Include make command from tests Makefile
tests: $(SRC_OBJS)
 @echo "Building pFUnit test suite..."
 @$(MAKE) -C $(TEST_DIR) tests


#------------------------------------#
#        Targets for cleaning        #
#------------------------------------#
# Define target for cleaning the build dir
clean:
 rm -rf $(BUILD_DIR)
 $(MAKE) -C $(TEST_DIR) clean

.PHONY: clean

#--------------------------------------#
# Export variables for child Makefiles #
#--------------------------------------#
# Export variables for the other Makefiles to use
export BUILD_DIR
export ROOT_DIR
export SRC_OBJS
export FC
export FC_FLAGS
export LIBS
```

:::::::::::::::::::::::::::::

The **tests/Makefile** would then look like this:

```makefile
PFUNIT_INCLUDE_DIR ?= /path/to/pfunit/include

# Don't try to include if we're cleaning as this doesn't depend on pFUnit
ifneq ($(MAKECMDGOALS),clean)
include $(PFUNIT_INCLUDE_DIR)/PFUNIT.mk
TEST_FLAGS = -I$(BUILD_DIR) $(FC_FLAGS) $(LIBS) $(PFUNIT_EXTRA_FFLAGS)
endif

# Define variables to be picked up by make_pfunit_test
# Note that you will need to filter out the src program from the SRC_OBJS if one exists
tests_TESTS = test_matrix_ops_dot.pf
tests_OTHER_SOURCES = $(SRC_OBJS)
tests_OTHER_LIBRARIES = $(TEST_FLAGS)

# Triggers pre-processing and defines rule for building test executable
$(eval $(call make_pfunit_test,tests))

# Converts pre-processed test files into objects ready for building of the executable
%.o: %.F90
 $(FC) -c $(TEST_FLAGS) $<

clean:
 \rm -f *.o *.mod *.F90 *.inc tests
```

**Key points:**

- We must include the pre-installed pFUnit dependencies and Makefile options via the **PFUNIT.mk** file.
  - The version of pFUnit that has been built will affect the path to this file (i.e. **…/installed/PFUNIT-4.12/include/…**)
- We are utilising the function provided by pFUnit **make_pfunit_test**
  - This will create a target of the provided name (in this case **tests**)
  - We define the variables pFUnit requires to build the **tests** target as variables prefixed with **tests_**.
    - **tests_TESTS** - A list of the **.pf** test files to be pre-processed before compilation.
    - **tests_OTHER_SOURCES** - A list of src object files required for the tests (excluding the src main/program file)
    - **tests_OTHER_LIBRARIES** - A list of library flags to pass to the compiler when compiling the test code
- We must create a target for compiling object files which uses the same flags as **tests_OTHER_LIBRARIES**

We can then build and run our tests with the following commands

```sh
$ make tests
...
$ ./tests/tests --verbose


 Start: <test_matrix_ops_dot.test_dot_one_to_twenty>
.   end: <test_matrix_ops_dot.test_dot_one_to_twenty>


 Start: <test_matrix_ops_dot.test_dot_all_zeros>
.   end: <test_matrix_ops_dot.test_dot_all_zeros>

Time:         0.001 seconds

 OK
 (2 tests)
```

### Naming our tests with Make

In the output shown above we have ran using the **--verbose** flag. This flag
includes the name of our test suites and test subroutines in the output. For
example, we have **2 tests** which here indicates two test functions in total,
**test_dot_one_to_twenty** and **test_dot_all_zeros**. However, we can see that
these two test functions are both stored within the same test suite
**test_matrix_ops_dot**.

Here, we are defining a test suite as a single test module file (**.pf** file).
Therefore, we can see that the name of the test suite comes from the name of
the module. The name of the test is then taken from the name of the test subroutine.

:::::::::::::::::::::::::::::::::::: challenge

### Challenge: Practice integrating with Make

To verify your newly implemented tests of **temp_conversions** from
the previous episode, complete **part i** of the [Building the test][ex-writing-your-first-unit-test]
section of the **Writing your first unit test exercise** and integrate your
test(s) with the **Make** build system provided in the exercise.

:::::::::::::::::::::::::::::::: solution

A solution is provided in [exercises/writing-your-first-unit-test/solution][ex-writing-your-first-unit-test-solution].

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::

## Integrating pFUnit with CMake

Let's now look at the steps required to add pFUnit tests to a project built using
CMake. Similar to before, let's assume we have the following file structure.

```txt
|-- ROOT_DIR/
    | CMakeLists.txt
    |-- src/
    |   |-- matrix_ops.f90
    |
    |-- tests/
        |-- CMakeLists.txt
        |-- test_matrix_ops_dot.pf
```

Just like with Make, the top level **CMakeLists.txt** file is responsible for
compiling the src code but should do little regarding building the tests.
However, it should…

- Define a variable which stores a list of src files

  ```cmake
  set(SRC_DIR "${PROJECT_SOURCE_DIR}/src")
  set(PROJ_SRC_FILES
    "${SRC_DIR}/matrix_ops.f90"
  )
  ```

- Enable testing.

  ```cmake
  enable_testing()
  ```

- Add the **tests/** dir as a subdirectory.

  ```cmake
  add_subdirectory("tests")
  ```

::::::::::::::::::::: spoiler

### Full file

The full top level **CMakeLists.txt** may look something like this:

```cmake
cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

# Set project name
project(
  "matrix_ops"
  LANGUAGES "Fortran"
  VERSION "0.0.1"
  DESCRIPTION "Library of matrix operations"
)

# Define a variable which stores a list of src files
set(SRC_DIR "${PROJECT_SOURCE_DIR}/src")
set(PROJ_SRC_FILES
  "${SRC_DIR}/matrix_ops.f90"
)

# Enable testing.
enable_testing()

# Add the tests dir as a subdirectory.
add_subdirectory("tests")
```

:::::::::::::::::::::::::::::

The **tests/CMakeLists.txt** file would then look like this:

```cmake
find_package(PFUNIT REQUIRED)


# Create library for src code
# Note that you will need to filter out the src program from the SRC_OBJS if one exists
add_library (SUT STATIC ${PROJ_SRC_FILES})

# List all test files
set(test_srcs
  "${PROJECT_SOURCE_DIR}/tests/test_matrix_ops_dot.pf"
)

# Add the test target
add_pfunit_ctest (test_matrix_ops_dot
  TEST_SOURCES ${test_srcs}
  LINK_LIBRARIES SUT # your application library
  )
```

**Key points:**

- First, we find the pFUnit package to ensure the required libraries and cmake
  functions are available
- We store the src files in a library (**SUT**, stands for system under test)
  to be referenced later.
- We list the test **.pf** files we wish to include within **test_srcs**.
- We then create a test with pFUnit and CTest using the function provided by
  pFUnit, **add_pfunit_ctest**. Here we are…
  - naming the test **test_matrix_ops_dot**.
  - informing pFUnit of the relevant src files via **TEST_SOURCES**.
  - linking to the src library via **LINK_LIBRARIES**.

### Building with CMake

We can then build our tests with the following commands

```sh
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/pfunit/build/installed
cmake --build build
ctest --test-dir build # or ./build/tests/test_matrix_ops_dot
```

:::::::::::::::::::: callout

### Mixing CTest and pFUnit

In this case we have called **add_pfunit_ctest** once with all of our **.pf**
test files. This results in there being one CTest test (i.e. one executable
**./build/tests/test_matrix_ops_dot**) which runs all tests. However, it may be
preferable to call **add_pfunit_ctest** more than once, thus creating multiple
executables to further divide up your tests.

Note that the tests can still be filtered by calling the executable itself and
using pFUnit's inbuilt filtering option, like so.

```sh
$ ./build/tests/test_matrix_ops_dot -f test_dot_one_to_twenty -v


 Start: <test_matrix_ops_dot.test_dot_one_to_twenty>
.   end: <test_matrix_ops_dot.test_dot_one_to_twenty>

Time:         0.001 seconds

 OK
 (1 test)
```

::::::::::::::::::::::::::::

### Naming our tests with CMake

When we run our tests by directly calling the executable as shown above, we can see
that the test suite names and test subroutine names are identical to when
[built using make](#naming-our-tests-with-make). However, when using CMake we have
control of one other name. The name of the CTest test. This name is set when we
call **add_pfunit_ctest**. For example the below will create a test named
**test_matrix_ops_dot**.

```cmake
add_pfunit_ctest (test_matrix_ops_dot
  TEST_SOURCES ${test_srcs}
  LINK_LIBRARIES sut # your application library
  )
```

:::::::::::::::::::::::::::::::::::: challenge

### Challenge: Practice integrating with CMake

To verify your newly implemented tests of **temp_conversions** from
the previous episode, complete **part ii** of the [building-the-test][ex-writing-your-first-unit-test]
section of **writing-your-first-unit-test/challenge** and integrate your test(s) with the **CMake** build system provided in the exercise.

:::::::::::::::::::::::::::::::: solution

A solution is provided in [exercises/writing-your-first-unit-test/solution][ex-writing-your-first-unit-test-solution].

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::
