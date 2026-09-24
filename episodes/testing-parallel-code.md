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
For example, let's look at how our test of **dot_product** changes for the following MPI enabled version:

```f90
module mpi_implementations
    use mpi
    implicit none

contains

    !> Calculates the dot product of two arrays `a` and `b`, splitting the calculation across mpi processors
    function mpi_dot_product(a, b, rank, num_ranks, communicator) result(final_result)
        !> The input array `a` to be passed to dot_product
        integer, allocatable :: a(:)
        !> The input array `b` to be passed to dot_product
        integer, allocatable :: b(:)
        !> The rank of the current mpi process
        integer, intent(in) :: rank
        !> The number of mpi processors in the communicator
        integer, intent(in) :: num_ranks
        !> The mpi communicator to be used
        integer, intent(in) :: communicator

        integer :: final_result

        integer :: indices_per_rank, proc_start, proc_end, ierr, proc_result

        indices_per_rank = size(a) / num_ranks
        proc_start = (rank * size(a)) / num_ranks + 1
        proc_end   = ((rank + 1) * size(a)) / num_ranks

        proc_result = dot_product(a(proc_start:proc_end), b(proc_start:proc_end))

        CALL MPI_ALLREDUCE(proc_result, final_result, 1, MPI_INTEGER, MPI_SUM, communicator, ierr)
    end function mpi_dot_product
end module
```

::: spoiler

### Full pFUnit test of mpi_dot_product

```f90
module test_with_mpi
    use pfunit
    use mpi_implementations, only : mpi_dot_product

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

        result = mpi_dot_product(this%params%a, this%params%b, this%getProcessRank(), this%getNumProcesses(), this%getMpiCommunicator())

        ! Check that the call to dot_product returned what we expect
        @AssertEqual(this%params%expected_dot_product, result, message="Unexpected value returned for the dot_product")
    end subroutine test_mpi_dot_product
end module test_with_mpi
```

:::

Let's break down each section of this test and how it differs from the serial version we saw in the previous episode.

::: instructor

When writing out the new MPI versions of the **dot_product** test, it is best to start from the serial
version to emphasize the similarities between the two.

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

#### Challenge: Update derived types to work with MPI

Take a look at the [Testing parallel code exercise][ex-testing-parallel-code].
This exercise contains an MPI parallelised version of the game of life (See
appendix) from the **Fortran Unit Test Syntax exercise**. Complete the first
step of the challenge by converting the derived types within
[test_find_steady_state.pf](https://github.com/carpentries-incubator/fortran-unit-testing/blob/main/exercises/testing-parallel-code/challenge/test/test_find_steady_state.pf#L10-L29)
to work with MPI.

:::::::::::::::::::::::::::::::: solution

Your derived types should now look something like this,

```f90
@testParameter
type, extends(MPITestParameter) :: find_steady_state_test_params
    !> The initial starting board to be passed into find_steady_state
    integer, dimension(:,:), allocatable :: input_board
    !> The expected steady state result
    logical :: expected_steady_state
    !> The expected number of generations to reach steady state
    integer :: expected_generation_number
    !> A description of the test to be outputted for logging
    character(len=100) :: description
contains
    procedure :: toString => find_steady_state_test_params_toString
end type find_steady_state_test_params

!> Type to define a single find_steady_state test case
@TestCase(testParameters={getTestSuite()}, constructor=paramsToCase)
type, extends(MPITestCase) :: find_steady_state_test_case
    type(find_steady_state_test_params) :: params
end type find_steady_state_test_case
```

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::: spoiler

### Test Suite

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

#### Challenge: Update test suite to work with MPI

Continuing with the
[Testing parallel code exercise][ex-testing-parallel-code].

Complete the next step of the challenge by converting the test suite within
[test_find_steady_state.pf](https://github.com/carpentries-incubator/fortran-unit-testing/blob/main/exercises/testing-parallel-code/challenge/test/test_find_steady_state.pf#L37-L63)
to work with your new derived types.

:::::::::::::::::::::::::::::::: solution

Your derived types should now look something like this,

```f90
function getTestSuite() result(params)
    !> The array of test parameters
    type(find_steady_state_test_params), allocatable :: params(:)

    integer :: i, max_num_ranks
    integer, dimension(:,:), allocatable :: board

    !  Steady state should be reached after 17 iterations
    !       8  9 10 11 12
    !      -- -- -- -- --
    !   8 | 0  0  0  0  0
    !   9 | 0  0  1  0  0
    !  10 | 0  1  1  1  0
    !  11 | 0  1  0  1  0
    !  12 | 0  0  1  0  0
    !  13 | 0  0  0  0  0
    allocate(board(31, 31))
    board = 0
    board(9,9:11)  = [0,1,0]
    board(10,9:11) = [1,1,1]
    board(11,9:11) = [1,0,1]
    board(12,9:11) = [0,1,0]

    max_num_ranks = 8
    allocate(params(max_num_ranks))
    do i = 1, max_num_ranks
        params(i) = find_steady_state_test_params(i, board, .true., 17, "an exploder initial state")
    end do
end function getTestSuite
```

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::: spoiler

### Test Logic

Since we are assuming our src procedure returns the same value to all ranks, for any number of MPI ranks,
nothing much that needs to change within our test logic subroutine. The one thing that is likely to change
is the call to the src procedure being tested as it is recommended to pass the MPI communicator into each
procedure which utilises MPI. For example, the test logic might look something like this.

```F90
@Test(testParameters={mpi_dot_product_test_suite()})
subroutine test_mpi_dot_product(this)
    !> The instance of our test case type for this test
    class(mpi_dot_product_test_case), intent(inout) :: this

    integer :: result

    result = mpi_dot_product(this%params%a, this%params%b, this%getProcessRank(), this%getNumProcesses(), this%getMpiCommunicator())

    ! Check that the call to dot_product returned what we expect
    @AssertEqual(this%params%expected_dot_product, result, message="Unexpected value returned for the dot_product")
end subroutine test_mpi_dot_product
```

::::::::::::::::::::::::: callout

In the example above, the MPI communicator is passed into the src procedure. By using the function provided by pFUnit
(**this%getMpiCommunicator()**) we allow pFUnit to manage the number of ranks used within each test.

:::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge: Update test logic to work with MPI

Continuing with the
[Testing parallel code exercise][ex-testing-parallel-code].

Converting the test logic within
[test_find_steady_state.pf](https://github.com/carpentries-incubator/fortran-unit-testing/blob/main/exercises/testing-parallel-code/challenge/test/test_find_steady_state.pf#L69-L84)
to work with the new src procedure signature.

:::::::::::::::::::::::::::::::: solution

Your test logic should now look something like this,

```f90
@Test
subroutine TestFindSteadyState(this)
    !> The current test case including inputs and expected outputs
    class(find_steady_state_test_case), intent(inout) :: this

    logical :: actual_steady_state
    integer :: actual_generation_number

    call find_steady_state(actual_steady_state, actual_generation_number, this%params%input_board, &
        size(this%params%input_board, 1), size(this%params%input_board, 2), this%getMpiCommunicator(), &
        this%getNumProcessesRequested())

    @assertEqual(this%params%expected_generation_number, actual_generation_number, "Unexpected generation_number")

    @assertTrue(this%params%expected_steady_state .eqv. actual_steady_state, "Unexpected steady_state value")

end subroutine TestFindSteadyState
```

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

## Integrating with build systems

Just like serial tests, MPI tests can be integrated into projects which utilise either Make or CMake.

### Integrating with Make

To build MPI enabled pFUnit tests via Make, one must use an mpi enabled compiler such as **mpif90** and
include the pFUnit library in the compiler arguments **-lpfunit**. Therefore, the **tests/Makefile**
from
[Integrating with build systems#Integrating pFUnit with Make](https://carpentries-incubator.github.io/fortran-unit-testing/integrating-with-build-systems.html#integrating-pfunit-with-make)
becomes,

```makefile
PFUNIT_INCLUDE_DIR ?= /path/to/pfunit/include

# Don't try to include if we're cleaning as this doesn't depend on pFUnit
ifneq ($(MAKECMDGOALS),clean)
include $(PFUNIT_INCLUDE_DIR)/PFUNIT.mk
TEST_FLAGS = -I$(BUILD_DIR) $(FC_FLAGS) $(LIBS) $(PFUNIT_EXTRA_FFLAGS) -lpfunit # <-- Lib added here
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

## Testing more complex procedures

Thus far we have been assuming our src procedure returns the same value to all ranks for any number of MPI
ranks. We must do things slightly differently if we expect different values to be returned for different
ranks. For example, imagine we now wish to test **partial_mpi_dot_product** from the following module:

```f90
module mpi_implementations
    use mpi
    implicit none

contains

    !> Calculates the partial dot product of two arrays `a` and `b`, splitting the calculation across mpi processors
    function partial_mpi_dot_product(a, b, rank, num_ranks, communicator) result(final_result)
        !> The input array `a` to be passed to dot_product
        integer, allocatable :: a(:)
        !> The input array `b` to be passed to dot_product
        integer, allocatable :: b(:)
        !> The rank of the current mpi process
        integer, intent(in) :: rank
        !> The number of mpi processors in the communicator
        integer, intent(in) :: num_ranks
        !> The mpi communicator to be used
        integer, intent(in) :: communicator

        integer :: final_result

        integer :: indices_per_rank, proc_start, proc_end, ierr

        indices_per_rank = size(a) / num_ranks
        proc_start = (rank * size(a)) / num_ranks + 1
        proc_end   = ((rank + 1) * size(a)) / num_ranks

        final_result = dot_product(a(proc_start:proc_end), b(proc_start:proc_end))
    end function partial_mpi_dot_product
end module
```

In this new function, the value for each processor will be different since we don't call **MPI_ALLREDUCE**.
To handle this scenario we can make use of the functions provided by pFUnit, **getNumProcesses()** and
**getProcessRank()**. However, these values are not set until the test case runs (i.e. until we are within
the subroutine decorated with **@Test**). Therefore, we must be a little clever about how we populate our
test parameters.

We can build arrays of input/output parameters with the rank of a process matching the index of the parameter
array. For example, rank 0 would access index 1, rank 1 would access index 2 and so on. Therefore, we must now
update our test parameter type to use an integer array for **expected_dot_product**, like so:

```F90
!> Custom test parameters type containing all of the inputs and expected
!! outputs of the intrinsic dot_product
@TestParameter
type, extends(MPITestParameter) :: mpi_dot_product_test_parameters
    !> The input array `a` to be passed to dot_product
    integer, allocatable :: a(:)
    !> The input array `b` to be passed to dot_product
    integer, allocatable :: b(:)
    !> The expected values to be returned from dot_product
    integer, allocatable :: expected_dot_product(:)
    !> A description of the test to be outputted for logging
    character(len=100) :: description
contains
    !> The required type-bound procedure for converting an instance
    !> of this type to a string for logging
    procedure :: toString
end type mpi_dot_product_test_parameters
```

We can then update how we populate our test parameters to take into account the rank indexing:

```F90
!> The test suite in which parameter sets (inputs and expected outputs) for each
!! test are defined.
function mpi_dot_product_test_suite() result(parameter_sets)
    !> The array of parameter sets to be returned
    type(mpi_dot_product_test_parameters) :: parameter_sets(10)

    integer, allocatable :: a(:), b(:), c(:)
    integer :: i, c_sum

    allocate(a(100))
    allocate(b(100))
    allocate(c(8)) ! Allocate up to maximum number of ranks to be tested

    ! Parameter set 1
    a = [(i,i=1,100)]
    b = [(i,i=101,200)]
    c = 0
    c(1) = 843350
    parameter_sets(1) = mpi_dot_product_test_parameters(1, a, b, c, "10x10 incrementing values")
    c(1:2) = [170425,672925]
    parameter_sets(2) = mpi_dot_product_test_parameters(2, a, b, c, "10x10 incrementing values")
    c(1:4) = [38025,132400,258025,414900]
    parameter_sets(3) = mpi_dot_product_test_parameters(4, a, b, c, "10x10 incrementing values")
    c(1:6) = [15096,53533,101796,148696,223533,300696]
    parameter_sets(4) = mpi_dot_product_test_parameters(6, a, b, c, "10x10 incrementing values")
    c(1:8) = [8450,29575,49850,82550,106250,151775,177650,237250]
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

    ! Deallocate the temporary stores of a, b and c for completeness
    deallocate(a, b, c)
end function mpi_dot_product_test_suite
```

Finally, we need to ensure each process accesses the correct rank indexed parameters during the test

```F90
@Test(testParameters={mpi_dot_product_test_suite()})
subroutine test_partial_mpi_dot_product(this)
    !> The instance of our test case type for this test
    class(mpi_dot_product_test_case), intent(inout) :: this

    integer :: result, rank

    rank = this%getProcessRank()

    result = partial_mpi_dot_product(this%params%a, this%params%b, rank, this%getNumProcesses(), this%getMpiCommunicator())

    ! Check that the call to dot_product returned what we expect
    @AssertEqual(this%params%expected_dot_product(rank + 1), result, message="Unexpected value returned for the dot_product")
end subroutine test_partial_mpi_dot_product
```

::::::::::::::::::::::::::::::::::::: challenge

### Challenge: A more complex MPI test

Take a look at part 3 of the
[Testing parallel code exercise][exercises-challenge]
in the exercises repository.

:::::::::::::::::::::::::::::::: solution

A solution is provided in
[exercises/testing-parallel-code/solution][ex-testing-parallel-code-solution].

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::
