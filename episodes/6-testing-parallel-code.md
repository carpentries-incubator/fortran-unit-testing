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

Depending on the parallelisation tool and strategy employed, the implementation of parallel code can be very different
to that of serial code. This is especially true for code which utilises the message passing interface (MPI). These codes
almost always contain some functionality in which processes, or ranks, communicate by exchanging messages. This message
passing is often complex and will always benefit from testing.

There is added complexity when testing MPI code compared to serial as the logical path through the code is changed
depending on the number of ranks with which the code is executed. Therefore, it is important that we test for a range
of numbers of ranks. This will require controlling the number of ranks running the src and is not something we want
to implement ourselves. Thankfully, pFUnit can handle this for us.

## Tips for writing testable MPI code

### Where possible, separate calls to the MPI library into procedures.

If a procedure does not contain any calls to the MPI library, then it can be tested with a serial unit test. Therefore,
separating MPI calls into their own units makes for a simpler test suite for most of your logic. Only, procedures with
MPI library calls will require MPI enabled pFUnit tests.

### Pass the MPI communicator information into each mpi procedure to be tested.

If we pass the MPI communicator into a procedure, we can define this to be whatever we wish in our tests. This allows us
to use the communicator provided by pFUnit or some other communicator specific to our problem.

Creating types to wrap this information along with any other MPI specific information (neighbour ranks, etc) can be a
convenient approach. 

## Syntax of writing MPI enabled pFUnit tests

:::::::::::::::::::::::::::::::::::::::::::::::::::: spoiler

### Derived types:

To test MPI code, we must inform pFUnit that we intend to do so. Firstly, we must change how we define
our test parameters. Assuming our src procedure returns the same value to all ranks for any number of
MPI ranks, we can do the following:

- We now use **MPITestParameter** instead of **AbstractTestParameter**.
    - **MPITestParameter** inherits from **AbstractTestParameter** and provides an additional parameter in its constructor which
    corresponds to the number of processors for which a particular test should be ran.

```F90
@testParameter
type, extends(MPITestParameter) :: my_test_params
    integer :: input
    integer :: expected_output
contains
    procedure :: toString => my_test_params_toString
end type my_test_params
```

We also need to change how we define our test case:

- We now use **MPITestCase** instead of **ParameterizedTestCase**
    - **MPITestCase** provides several helpful methods for us to use whilst testing
        - **getProcessRank()** returns the rank of the current process allowing per rank selection of inputs and expected outputs.
        - **getMpiCommunicator()** returns the MPI communicator created by pFUnit to control the number of ranks per test.
        - **getNumProcesses()** returns the number of MPI ranks for the current test.

```F90
@TestCase(constructor=my_test_params_to_my_test_case, testParameters={my_test_suite()})
type, extends(MPITestCase) :: my_test_case
    type(my_test_params) :: params
end type my_test_case
```

::::::::::::::::::::::::::::::::::::: challenge 

#### Challenge: Update derived types to work with MPI

Take a look at the exercise [6-testing-parallel-code](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/6-testing-parallel-code/challenge). This exercise contains an MPI parallelised version of the game of life from episode [2. Refactoring Fortran](https://github-pages.arc.ucl.ac.uk/fortran-unit-testing-lesson/2-refactor-fortran.html) and the exercise [4-fortran-unit-test-syntax](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/4-fortran-unit-test-syntax/challenge).

Complete the first step of the challenge by converting the derived types within [test_find_steady_state.pf](https://github.com/carpentries-incubator/fortran-unit-testing/blob/main/exercises/6-testing-parallel-code/challenge/test/test_find_steady_state.pf#L10-L29) to work with MPI.

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

### Test Suite:

Now that we have updated our derived types, we must update how we populate our test parameter sets within
the test suite. There is actually very little that needs to change, all we must do is set how many MPI
ranks we want each parameter set to be run with. For example,

```f90
function my_test_suite() result(params)
    type(my_test_params), allocatable :: params(:)

    integer :: i, max_num_ranks

    # Run two tests for each number of MPI ranks
    max_num_ranks = 8
    allocate(params(max_num_ranks * 2))
    do i = 1, max_num_ranks
        params(i)     = my_test_params(i, 1, 2)  ! Given input is 1, output is 2
        params(i + 1) = my_test_params(i, 3, 4)  ! Given input is 3, output is 4
    end do
end function my_test_suite
```

::::::::::::::::::::::::::::::::::::: challenge 

#### Challenge: Update test suite to work with MPI

Continuing with the exercise [6-testing-parallel-code](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/6-testing-parallel-code/challenge). 

Complete the next step of the challenge by converting the test suite within [test_find_steady_state.pf](https://github.com/carpentries-incubator/fortran-unit-testing/blob/main/exercises/6-testing-parallel-code/challenge/test/test_find_steady_state.pf#L37-L63) to work with your new derived types.

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

### Test Logic:

As we are assuming our src procedure returns the same value to all ranks for any number of MPI ranks
there is not much that needs to change within our test logic subroutine. The one thing that is likely 
to change in this case is the call to the src procedure being tested as it is recommended to pass the
MPI communicator into each procedure which utilises MPI. For example, the test logic might look
something like this.

```F90
@Test
subroutine TestMySrcProcedure(this)
    class (my_test_case), intent(inout) :: this

    integer :: actual_output

    call my_src_procedure(this%params%input, actual_output, this%getMpiCommunicator(), this%getNumProcessesRequested())

    @assertEqual(this%params%expected_output, actual_output, "Unexpected output from my_src_procedure")
end subroutine TestMySrcProcedure
```

::::::::::::::::::::::::: callout

In the example above, the MPI communicator is passed into the src procedure. Using the function provided by pFUnit
**this%getMpiCommunicator()** allows pFUnit to manage the number of ranks used within each test.

:::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::: challenge 

#### Challenge: Update test logic to work with MPI

Continuing with the exercise [6-testing-parallel-code](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/6-testing-parallel-code/challenge). 

Converting the test logic within [test_find_steady_state.pf](https://github.com/carpentries-incubator/fortran-unit-testing/blob/main/exercises/6-testing-parallel-code/challenge/test/test_find_steady_state.pf#L69-L84) to work with the new src procedure
signature.

:::::::::::::::::::::::::::::::: solution

Your derived types should now look something like this,

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

:::::::::::::::::::::::::::::::::::::::::::::::::::: spoiler

### Type Constructors:

Converting to supporting MPI has not altered the relationship between the test parameters and the test case.
Therefore, the constructors will remain unchanged.

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

## Integrating with build systems

Just like serial tests, MPI tests can be integrated into projects which utilise either Make or CMake.

### Integrating with Make

To build MPI enabled pFUnit tests via Make, one must use an mpi enabled compiler such as **mpif90** and
include the pFUnit library in the compiler arguments **-lpfunit**. Therefore, the **tests/Makefile**
from [5-integrating-with-build-systems#integrating-pfunit-with-make](https://github-pages.arc.ucl.ac.uk/fortran-unit-testing-lesson/5-integrating-with-build-systems.html#integrating-pfunit-with-make) becomes,

```makefile
PFUNIT_INCLUDE_DIR ?= /path/to/pfunit/include

# Don't try to include if we're cleaning as this doesn't depend on pFUnit
ifneq ($(MAKECMDGOALS),clean)
include $(PFUNIT_INCLUDE_DIR)/PFUNIT.mk
TEST_FLAGS = -I$(BUILD_DIR) $(FC_FLAGS) $(LIBS) $(PFUNIT_EXTRA_FFLAGS) -lpfunit # <-- Lib added here
endif

# Define variables to be picked up by make_pfunit_test
tests_TESTS = \
  test_something.pf \
  test_something_else.pf
tests_OTHER_SOURCES = $(filter-out $(BUILD_DIR)/main.o, $(SRC_OBJS))
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

The difference between a serial test and an MPI test built using CMake is very minimal. For an MPI test
**add_pfunit_ctest** will produce an executable which must be run with an appropriate MPI runner (i.e.
**mpirun** or **mpiexec**). To achieve this, there is only one extra parameter we must pass into
**add_pfunit_ctest** as shown below.

```cmake
add_pfunit_ctest (test_something_interesting
  TEST_SOURCES ${test_srcs}
  LINK_LIBRARIES SUT # your application library
  MAX_PES 4
  )
```

**MAX_PES** informs pFUnit of the maximum number of MPI ranks with which the tests within **test_srcs**
should be run. Therefore, this number should match the largest number of ranks requested in the tests
defined within **test_srcs** (i.e. the largest value passed as the first argument into a **MPITestParameter**
constructor).

## Testing more complex procedures

So far we have been assuming our src procedure returns the same value to all ranks for any number of MPI
ranks. We must do things slightly differently if we expect different values to be returned for different
ranks. To handle this scenario we can make use of the functions provided by pFUnit, **getNumProcesses()** and
**getProcessRank()**. However, these values are not set until the test case runs (i.e. until we are within
the subroutine decorated with **@Test**). Therefore, we must be a little clever about how we populate our
test parameters.

We can build arrays of input parameters with the rank of a process matching the index of the parameter array.
For example, rank 0 would access index 1 of the input array during testing, rank 1 would access index 2 and so
on. For example, if we define our test parameter type to use arrays, like so,

```F90
@testParameter
type, extends(MPITestParameter) :: my_test_params
    integer, allocatable :: input(:)
    integer, allocatable :: expected_output(:)
contains
    procedure :: toString => my_test_params_toString
end type my_test_params
```

We can then update how we populate our test parameters to take into account the rank indexing:

```F90
function my_test_suite() result(params)
    type(my_test_params), allocatable :: params(:)
    integer, allocatable :: input(:)
    integer, allocatable :: expected_output(:)
    integer, max_number_of_ranks

    max_number_of_ranks = 2
    allocate(params(max_number_of_ranks))
    allocate(input(max_number_of_ranks))
    allocate(expected_output(max_number_of_ranks))

    ! Tests with one rank
    input(1) = 1
    expected_output(1) = 2
    params(1) = my_test_params(1, input, expected_output)

    ! Tests with two ranks
    !     rank 0
    input(1) = 1
    expected_output(1) = 1
    !     rank 1
    input(2) = 1
    expected_output(2) = 1
    params(2) = my_test_params(2, input, expected_output)
end function my_test_suite
```

Finally, we need to ensure each process accesses the correct rank indexed parameters during the test

```F90
@Test
subroutine TestMySrcProcedure(this)
    class (my_test_case), intent(inout) :: this

    integer :: actual_output, rank_index

    rank_index = this%getProcessRank() + 1

    call my_src_procedure(this%params%input(rank_index), actual_output)

    @assertEqual(this%params%expected_output(rank_index), actual_output, "Unexpected output from my_src_procedure")
end subroutine TestMySrcProcedure
```

::::::::::::::::::::::::::::::::::::: challenge 

### Challenge: A more complex MPI test

Take a look at part 3 of [6-testing-parallel-code/challenge](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/6-testing-parallel-code/challenge) in the exercises repository.

:::::::::::::::::::::::::::::::: solution

A solution is provided in [6-testing-parallel-code/solution](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/6-testing-parallel-code/solution).

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::
