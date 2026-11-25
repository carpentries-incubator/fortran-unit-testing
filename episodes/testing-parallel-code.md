---
title: "Testing parallel code"
teaching:
exercises:
---

:::::::::::::::::::::::::::::::::::::: questions

- How do I unit test a procedure which makes MPI calls?
- How do I easily test different numbers of MPI ranks?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Understand what is different when testing parallel vs serial code.

::::::::::::::::::::::::::::::::::::::::::::::::

## What's the difference?

Depending on the parallelisation tool and strategy employed, the implementation of parallel code can be different
to that of serial code. This is especially true for code which utilises the message passing interface (MPI). These codes
almost always contain some functionality in which processes, or ranks, communicate by exchanging messages. This message
passing is often complex and will always benefit from testing.

There is added complexity when testing MPI code compared to serial as the logical path through the code is changed
depending on the number of ranks with which the code is executed. Therefore, it is important that we test for a range
of numbers of ranks. This will require controlling the number of ranks running the src and is not something we want
to implement ourselves. pFUnit can handle this for us.

## Tips for writing testable MPI code

### Where possible, separate calls to the MPI library into procedures

If a procedure does not contain any calls to the MPI library, then it can be tested with a serial unit test. Therefore,
separating MPI calls into their own units makes for a simpler test suite for most of your logic. Only, procedures with
MPI library calls will require MPI enabled pFUnit tests.

### Pass the MPI communicator information into each mpi procedure to be tested

If we pass the MPI communicator into a procedure, we can define this to be whatever we wish in our tests. This allows us
to use the communicator provided by pFUnit or some other communicator specific to our problem.

Creating types to wrap this information along with any other MPI specific information (neighbour ranks, etc) can be a
convenient approach.

## Syntax of writing MPI enabled pFUnit tests

When we move from testing a serial code to an MPI enabled code, there are several changes we need to make to our pFUnit tests.
For example, let's look at how our test of **dot** changes for the following MPI enabled version:

```f90
module matrix_ops
    use mpi
    implicit none
contains
    !> Calculates the dot product of two arrays `a` and `b`, splitting the calculation across mpi processors
    function dot(a, b, communicator) result(final_result)
        !> The input array `a` to be passed to dot_product
        integer, allocatable :: a(:)
        !> The input array `b` to be passed to dot_product
        integer, allocatable :: b(:)
        !> The mpi communicator to be used
        integer, intent(in) :: communicator

        integer :: rank, num_ranks, ierr
        integer :: final_result, proc_result, indices_per_rank, proc_start, proc_end

        call MPI_COMM_RANK(communicator, rank, ierr)
        call MPI_COMM_SIZE(communicator, num_ranks, ierr)

        indices_per_rank = size(a) / num_ranks
        proc_start = (rank * size(a)) / num_ranks + 1
        proc_end   = ((rank + 1) * size(a)) / num_ranks

        proc_result = dot_product(a(proc_start:proc_end), b(proc_start:proc_end))
        CALL MPI_ALLREDUCE(proc_result, final_result, 1, MPI_INTEGER, MPI_SUM, communicator, ierr)
    end function dot
end module matrix_ops
```

::: spoiler

### Full pFUnit test of mpi_dot_product

```f90
module test_with_mpi
    use pfunit
    use matrix_ops, only : dot

    implicit none

    !> Custom test parameters type containing all of the inputs and expected
    !! outputs of the intrinsic dot_product
    @TestParameter
    type, extends(MPITestParameter) :: mpi_dot_product_test_parameters
        !> The input array `a` to be passed to dot_product
        integer, allocatable :: a(:)
        !> The input array `b` to be passed to dot_product
        integer, allocatable :: b(:)
        !> The expected value to be returned from dot_product
        integer :: expected_dot_product
        !> A description of the test to be outputted for logging
        character(len=100) :: description
    contains
        !> The required type-bound procedure for converting an instance
        !> of this type to a string for logging
        procedure :: toString
    end type mpi_dot_product_test_parameters

    !> Custom test case type allowing a single definition of tearDown logic.
    !! If teardown is not required, This could also be thought of as boilerplate
    !! required to make the parameters available within our @Test.
    @TestCase(constructor=mpi_dot_product_test_case_constructor)
    type, extends(MPITestCase) :: mpi_dot_product_test_case
        !> The instance of our test parameters type to be used within the test logic
        type(mpi_dot_product_test_parameters) :: params
    contains
        procedure :: tearDown
    end type mpi_dot_product_test_case

contains

    !> Trims and returns the description of the parameter set. The string returned
    !! by this function will be included by pFUnit in the name of this test
    function toString(this) result(string)
        class (mpi_dot_product_test_parameters), intent(in) :: this
        character(:), allocatable :: string

        string = trim(this%description)
    end function toString

    !> Boilerplate constructor required to convert our custom parameters type to
    !! the test case type.
    function mpi_dot_product_test_case_constructor(testParameters) result(newTestCase)
        type(mpi_dot_product_test_parameters), intent(in) :: testParameters
        type(mpi_dot_product_test_case) :: newTestCase

        newTestCase%params = testParameters
    end function mpi_dot_product_test_case_constructor

    !> Essentially a destructor for our custom test case type which deallocates
    !! arrays `a` and `b`
    subroutine tearDown(this)
        !> The instance of our custom test case type which we want to teardown
        class(mpi_dot_product_test_case), intent(inout) :: this

        deallocate(this%params%a)
        deallocate(this%params%b)
    end subroutine tearDown

    !> The test suite in which parameter sets (inputs and expected outputs) for each
    !! test are defined.
    function mpi_dot_product_test_suite() result(parameter_sets)
        !> The array of parameter sets to be returned
        type(mpi_dot_product_test_parameters) :: parameter_sets(10)

        integer, allocatable :: a(:), b(:)
        integer :: c, i

        allocate(a(100))
        allocate(b(100))

        ! Parameter set 1
        a = [(i,i=1,100)]
        b = [(i,i=101,200)]
        c = 843350
        parameter_sets(1) = mpi_dot_product_test_parameters(1, a, b, c, "10x10 incrementing values")
        parameter_sets(2) = mpi_dot_product_test_parameters(2, a, b, c, "10x10 incrementing values")
        parameter_sets(3) = mpi_dot_product_test_parameters(4, a, b, c, "10x10 incrementing values")
        parameter_sets(4) = mpi_dot_product_test_parameters(6, a, b, c, "10x10 incrementing values")
        parameter_sets(5) = mpi_dot_product_test_parameters(8, a, b, c, "10x10 incrementing values")

        ! Parameter set 2
        a = 0
        b = 0
        c = 0
        parameter_sets(6) = mpi_dot_product_test_parameters(1, a, b, c, "10x10 all zeros")
        parameter_sets(7) = mpi_dot_product_test_parameters(2, a, b, c, "10x10 all zeros")
        parameter_sets(8) = mpi_dot_product_test_parameters(4, a, b, c, "10x10 all zeros")
        parameter_sets(9) = mpi_dot_product_test_parameters(6, a, b, c, "10x10 all zeros")
        parameter_sets(10) = mpi_dot_product_test_parameters(8, a, b, c, "10x10 all zeros")

        ! Deallocate the temporary stores of a and b for completeness
        deallocate(a, b)
    end function mpi_dot_product_test_suite

    @Test(testParameters={mpi_dot_product_test_suite()})
    subroutine test_mpi_dot_product(this)
        !> The instance of our test case type for this test
        class(mpi_dot_product_test_case), intent(inout) :: this

        integer :: result

        result = dot(this%params%a, this%params%b, this%getMpiCommunicator())

        ! Check that the call to dot_product returned what we expect
        @AssertEqual(this%params%expected_dot_product, result, message="Unexpected value returned for the dot_product")
    end subroutine test_mpi_dot_product
end module test_with_mpi
```

:::

Let's break down each section of this test and how it differs from the serial version we saw in the previous episode.

::: instructor

When writing out the new MPI versions of the **dot_product** tests, it is best to start from the serial
version to emphasize the similarities between the two.

Follow the standard `src` and `test` dir structure then you can build and run this pFUnit version. Use the two **CMakeLists.txt**
files below:

**Top level:**

```cmake
cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

# Set project name
project(
  "matrix_ops"
  LANGUAGES "Fortran"
  VERSION "0.0.1"
  DESCRIPTION "Library for matrix operations"
)

# Define a variable which stores a list of src files
set(PROJ_SRC_FILES "${SRC_DIR}/src/matrix_ops.f90")

enable_testing()
add_subdirectory("test")
```

**Test level:**

```cmake
find_package(PFUNIT REQUIRED)

# Create library for src code
add_library(SUT STATIC ${PROJ_SRC_FILES})

# List all test files
set(test_srcs "${PROJECT_SOURCE_DIR}/test/test_with_mpi.pf")

# Add the test target
add_pfunit_ctest (test_with_mpi
  TEST_SOURCES ${test_srcs}
  LINK_LIBRARIES SUT # your application library
  MAX_PES 8
  )
```

This can then be compiled with the following commands:

```sh
cmake -B build -DCMAKE_PREFIX_PATH="/path/to/pfunit/build/installed"
cmake --build build
ctest --test-dir build --output-on-failure
```

:::

::: callout

### When inputs or outputs differ by rank

The `dot` procedure in the `matrix_ops` example splits its input arrays across ranks, then uses `MPI_ALLREDUCE` to return
the same final result on every rank. If you test a rank-local partial result instead, each rank needs its own input slice
and expected value. You would there need to store expected values in rank order, for example as an allocatable component:

```f90
integer, allocatable :: expected_values(:)
```

Then, inside the test, derive the rank's index and use it to select the expected result:

```f90
process_index = this%getProcessRank() + 1
expected_value = this%params%expected_values(process_index)
@assertEqual(expected_value, actual)
```

The `+ 1` converts MPI's zero-based rank to Fortran's one-based array indexing. The same index can select both
rank-specific input and expected-value parameters.

:::

:::::::::::::::::::::::::::::::::::::::::::::::::::: spoiler

### Derived types

To test MPI code, we must inform pFUnit that we intend to do so. Firstly, we must change how we define
our test parameters. Assuming our src procedure returns the same value to all ranks for any number of
MPI ranks, we can do the following:

- We now use **MPITestParameter** instead of **AbstractTestParameter**.
  - **MPITestParameter** inherits from **AbstractTestParameter** and provides an additional parameter in its constructor which
    corresponds to the number of processors for which a particular test should be ran.

```F90
!> Custom test parameters type containing all of the inputs and expected
!! outputs of the intrinsic dot_product
@TestParameter
type, extends(MPITestParameter) :: mpi_dot_product_test_parameters
    !> The input array `a` to be passed to dot_product
    integer, allocatable :: a(:)
    !> The input array `b` to be passed to dot_product
    integer, allocatable :: b(:)
    !> The expected value to be returned from dot_product
    integer :: expected_dot_product
    !> A description of the test to be outputted for logging
    character(len=100) :: description
contains
    !> The required type-bound procedure for converting an instance
    !> of this type to a string for logging
    procedure :: toString
end type mpi_dot_product_test_parameters
```

We also need to change how we define our test case:

- We now use **MPITestCase** instead of **ParameterizedTestCase**
  - **MPITestCase** provides several helpful methods for us to use whilst testing
    - **getProcessRank()** returns the rank of the current process allowing per rank selection of inputs and expected outputs.
    - **getMpiCommunicator()** returns the MPI communicator created by pFUnit to control the number of ranks per test.
    - **getNumProcesses()** returns the number of MPI ranks for the current test.

```F90
!> Custom test case type allowing a single definition of tearDown logic.
!! If teardown is not required, This could also be thought of as boilerplate
!! required to make the parameters available within our @Test.
@TestCase(constructor=mpi_dot_product_test_case_constructor)
type, extends(MPITestCase) :: mpi_dot_product_test_case
    !> The instance of our test parameters type to be used within the test logic
    type(mpi_dot_product_test_parameters) :: params
contains
    procedure :: tearDown
end type mpi_dot_product_test_case
```

::: callout

Note that the constructors (i.e. `toString`, `mpi_dot_product_test_case_constructor` and `teardown`) remain essentially unchanged.

:::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge: Define the temperature conversion test case

Start the [Testing parallel code exercise][ex-testing-parallel-code]. Define a parameter type to store each rank's
allocatable local temperature array and the expected complete output, and a test case type. The local arrays should have
the same size for every rank. You should think about:

- What decorators are needed?
- What types should be extended?
- What type-bound variables, if any, should be defined?
- Do we require different inputs or outputs for each rank?
- How do we instantiate one of these test cases?

:::::::::::::::::::::::::::::::: solution

The parameter type should extend `MPITestParameter` and the test case type should extend `MPITestCase`. Store each rank's
local input as one column of a two-dimensional allocatable array. Since the local arrays are the same size, the column
index is enough to select the current rank's input:

```f90
@testParameter
type, extends(MPITestParameter) :: parallel_conversion_test_params
    real, allocatable :: input_local_temps(:,:), expected_outputs_temps(:)
end type parallel_conversion_test_params

@TestCase(constructor=parallel_conversion_test_case_constructor)
type, extends(MPITestCase) :: parallel_conversion_test_case
    type(parallel_conversion_test_params) :: params
end type parallel_conversion_test_case
```

The constructor copies a parameter set into the test case:

```f90
function parallel_conversion_test_case_constructor(test_parameters) result(test_case)
    type(parallel_conversion_test_params), intent(in) :: test_parameters
    type(parallel_conversion_test_case) :: test_case

    test_case%params = test_parameters
end function parallel_conversion_test_case_constructor
```

::: callout

Notice that we do not define a `toString` procedure here. That is because `MPITestParameter`provides a default implementation which
logs the number of ranks for the given test.

:::

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::: spoiler

### Test suite

Now that we have updated our derived types, we must update how we populate our test parameter sets within
the test suite. There is actually little that needs to change, all we must do is set how many MPI
ranks we want each parameter set to be run with. To do this we will use the default constructor generated
for our custom type **mpi_dot_product_test_parameters**. Since we have extended **MPITestParameter**, we can
pass the desired number of MPI ranks as the first argument, as shown below.

```f90
!> The test suite in which parameter sets (inputs and expected outputs) for each
!! test are defined.
function mpi_dot_product_test_suite() result(parameter_sets)
    !> The array of parameter sets to be returned
    type(mpi_dot_product_test_parameters) :: parameter_sets(10)

    integer, allocatable :: a(:), b(:)
    integer :: c, i

    allocate(a(100))
    allocate(b(100))

    ! Parameter set 1
    a = [(i,i=1,100)]    !                             Here
    b = [(i,i=101,200)]  !                              |
    c = 843350           !                              V
    parameter_sets(1) = mpi_dot_product_test_parameters(1, a, b, c, "10x10 incrementing values")
    parameter_sets(2) = mpi_dot_product_test_parameters(2, a, b, c, "10x10 incrementing values")
    parameter_sets(3) = mpi_dot_product_test_parameters(4, a, b, c, "10x10 incrementing values")
    parameter_sets(4) = mpi_dot_product_test_parameters(6, a, b, c, "10x10 incrementing values")
    parameter_sets(5) = mpi_dot_product_test_parameters(8, a, b, c, "10x10 incrementing values")

    ! Parameter set 2
    a = 0                !                            and here
    b = 0                !                               |
    c = 0                !                               V
    parameter_sets(6)  = mpi_dot_product_test_parameters(1, a, b, c, "10x10 all zeros")
    parameter_sets(7)  = mpi_dot_product_test_parameters(2, a, b, c, "10x10 all zeros")
    parameter_sets(8)  = mpi_dot_product_test_parameters(4, a, b, c, "10x10 all zeros")
    parameter_sets(9)  = mpi_dot_product_test_parameters(6, a, b, c, "10x10 all zeros")
    parameter_sets(10) = mpi_dot_product_test_parameters(8, a, b, c, "10x10 all zeros")

    ! Deallocate the temporary stores of a and b for completeness
    deallocate(a, b)
end function mpi_dot_product_test_suite
```

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge: Define a test suite for your tests of `fahrenheit_to_celsius_parallel` with different numbers of MPI processors

Write a test suite for the tests of `sum_all_rank_values`. You should think about:

- What decorators are needed, if any?
- Do you need a function or subroutine?
- What should the inputs to this procedure be?
- What should be its outputs?
- How does pFUnit know how many ranks to use for each parameter set?
- What test cases would help check the function with small and larger communicators?

:::::::::::::::::::::::::::::::: solution

The exercise tests the conversion procedures with 1, 2, and 4 MPI processes. A test suite returns one parameter set for
each communicator size. Each parameter set stores one equal-sized input array per rank as columns. Eight temperatures
can be distributed across the ranks like this:

```f90
function fahrenheit_to_celsius_parallel_test_suite() result(params)
    type(parallel_conversion_test_params), allocatable :: params(:)
    real, allocatable :: expected_outputs(:)

    allocate(params(3), expected_outputs(8))
    expected_outputs = [-40.0, 0.0, 100.0, -17.777779, 37.0, 232.88889, -273.15, 37.77778]

    params(1) = parallel_conversion_test_params(1)
    params(1)%input_local_temps = reshape( &
        [-40.0, 32.0, 212.0, 0.0, 98.6, 451.2, -459.67, 100.0], [8, 1])
    params(1)%expected_outputs_temps = expected_outputs

    params(2) = parallel_conversion_test_params(2)
    params(2)%input_local_temps = reshape( &
        [-40.0, 32.0, 212.0, 0.0, 98.6, 451.2, -459.67, 100.0], [4, 2])
    params(2)%expected_outputs_temps = expected_outputs

    params(3) = parallel_conversion_test_params(4)
    params(3)%input_local_temps = reshape( &
        [-40.0, 32.0, 212.0, 0.0, 98.6, 451.2, -459.67, 100.0], [2, 4])
    params(3)%expected_outputs_temps = expected_outputs
end function fahrenheit_to_celsius_parallel_test_suite
```

Each local input array has the same length within its test case: eight values with one rank, four with two ranks, and two
with four ranks. The expected array is the same on every rank because the parallel procedure performs an all-gather.

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::: spoiler

### Test logic

Since we are assuming our src procedure returns the same value to all ranks, for any number of MPI ranks,
nothing much needs to change within our test logic subroutine. The one thing that is likely to change
is the call to the src procedure being tested as it is recommended to pass the MPI communicator into each
procedure which utilises MPI. For example, the test logic might look something like this.

```f90
@Test(testParameters={mpi_dot_product_test_suite()})
subroutine test_mpi_dot_product(this)
    !> The instance of our test case type for this test
    class(mpi_dot_product_test_case), intent(inout) :: this

    integer :: result

    result = dot(this%params%a, this%params%b, this%getMpiCommunicator())

    ! Check that the call to dot_product returned what we expect
    @AssertEqual(this%params%expected_dot_product, result, message="Unexpected value returned for the dot_product")
end subroutine test_mpi_dot_product
```

::::::::::::::::::::::::: callout

In the example above, the MPI communicator is passed into the src procedure. By using the function provided by pFUnit
(**this%getMpiCommunicator()**) we allow pFUnit to manage the number of ranks used within each test.

:::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge: Test the Fahrenheit-to-Celsius conversion

Write the actual test logic for the function `celsius_to_kelvin_parallel`. This test should assert that the result is the sum of
the. You should think about:

- What decorators are needed?
- Do you need a function or subroutine?
- What should the inputs to this procedure be?
- What should be its outputs?
- How do you link this test logic to the test suite you just defined?
- How do you check if a test scenario was successful?
- Which communicator should the test pass to `celsius_to_kelvin_parallel`?

:::::::::::::::::::::::::::::::: solution

Both temperature conversion procedures return the complete converted array on every rank. The test uses the rank only to
select that rank's column of local inputs; the expected output is the same on all ranks.

```F90
@Test(testParameters={fahrenheit_to_celsius_parallel_test_suite()})
subroutine test_fahrenheit_to_celsius_parallel(this)
    class(parallel_conversion_test_case), intent(inout) :: this
    integer :: process_index
    real, allocatable :: actual(:)

    process_index = this%getProcessRank() + 1
    call fahrenheit_to_celsius_parallel( &
        this%params%input_local_temps(:, process_index), actual, this%getMpiCommunicator())

    @assertEqual(this%params%expected_outputs_temps, actual, tolerance=1e-4)
end subroutine test_fahrenheit_to_celsius_parallel
```

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::: challenge

#### Test the Celsius-to-Kelvin conversion

Add tests for the subroutine `celsius_to_kelvin_parallel` alongside your tests of `fahrenheit_to_celsius_parallel`

:::solution

A solution is provided in
[exercises/testing-parallel-code/solution][ex-testing-parallel-code-solution].

:::

:::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

## Integrating with build systems

Just like serial tests, MPI tests can be integrated into projects which utilise either Make or CMake.

### Integrating with Make

To build MPI-enabled pFUnit tests with Make, use an MPI compiler wrapper such as mpif90 and a pFUnit
installation built with MPI support. Set USEMPI = YES before including PFUNIT.mk to select its
MPI-related build settings. Therefore, the **tests/Makefile** from
[Integrating with build systems - Integrating pFUnit with Make](https://carpentries-incubator.github.io/fortran-unit-testing/integrating-with-build-systems.html#integrating-pfunit-with-make)
becomes,

```makefile
PFUNIT_INCLUDE_DIR ?= /path/to/pfunit/include
USEMPI = YES # <-- New flag here

# Don't try to include if we're cleaning as this doesn't depend on pFUnit
ifneq ($(MAKECMDGOALS),clean)
include $(PFUNIT_INCLUDE_DIR)/PFUNIT.mk
TEST_FLAGS = -I$(BUILD_DIR) $(FC_FLAGS) $(LIBS) $(PFUNIT_EXTRA_FFLAGS)
endif

# Define variables to be picked up by make_pfunit_test
tests_TESTS = test_with_mpi.pf
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

::: callout

`USEMPI` configures the Make integration; it does not build or convert pFUnit into an MPI-enabled library.
Use a pFUnit installation that was built with MPI support.

:::

With this, we can compile for MPI using the following command.

```sh
PFUNIT_INCLUDE_DIR=/path/to/pfunit/include FC=mpif90 make tests
```

### Integrating with CMake

The difference between a serial test and an MPI test built using CMake is minimal. For an MPI test
**add_pfunit_ctest** will produce an executable which must be run with an appropriate MPI runner (i.e.
**mpirun** or **mpiexec**). To achieve this, there is only one extra parameter we must pass into
**add_pfunit_ctest** as shown below.

```cmake
add_pfunit_ctest (test_with_mpi
  TEST_SOURCES ${test_srcs}
  LINK_LIBRARIES SUT # your application library
  MAX_PES 4          # <-- max number of MPI ranks required for the test
  )
```

**MAX_PES** informs pFUnit of the maximum number of MPI ranks with which the tests within **test_srcs**
should be run. Therefore, this number should match the largest number of ranks requested in the tests
defined within **test_srcs** (i.e. the largest value passed as the first argument into a **MPITestParameter**
constructor).

::: challenge

### Challenge: Testing the parallel game of life

For more practice of testing an MPI parallelised Fortran code take a look at the exercise
[testing-the-game-of-life-with-mpi][ex-testing-the-game-of-life-with-mpi].

:::
