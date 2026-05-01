---
title: "Understanding test output"
teaching:
exercises:
---

:::::::::::::::::::::::::::::::::::::: questions 

- How do I know if my tests are failing?
- How do I fix a failing tests?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Understand where the name and description of a test is defined for each framework.
- Understand the success and failure output of a test for each framework.
- Able to filter which tests are run at a time. 
- Able to follow the output of a failing test through to the cause of the failure.

::::::::::::::::::::::::::::::::::::::::::::::::

## Test output

Each of the three frameworks print the output of their tests to the terminal in
different formats. We have a lot of control over the contents of this output, whether
that's for a failing test or a passing test.

Several aspects of the output can be defined by us for all frameworks,

- The name and description of each test.
- The message printed in the event of a failed assertion.

## Defining the name and description of a test

Each of the three frameworks offer the ability to give a name to a test and to add a
description which gives a more detailed explanation of what exactly is being tested. 

::::::::::::::::::::::::::::: spoiler

#### Veggies

The name and description of a Veggies test are defined within the testsuite function.

```F90
function my_test_suite() result(tests)
    type(test_item_t) :: tests
    type(example_t) :: my_test_data(1)
    
    ! Given input is 1, output is 2
    my_test_data(1) = example_t(my_test_params(1, 2))

    tests = describe( &
        "my_src_procedure", &
        [ it( &
            "with specific inputs causes something else specific to happen", &
            my_test_data, &
            check_my_src_procedure &
        )] &
    )
end function my_test_suite
```

The first argument given to `describe` defines an overarching name which is applied
to all the tests within it, in the case `"my_src_procedure"`. Each `it` then defines
its own descriptor which tells us exactly which scenario we are testing, in this case
`"with specific inputs causes something else specific to happen"`. This results in the
output.

```bash
$ fpm test
Test that
    my_src_procedure
        with specific inputs causes something else specific to happen

A total of 1 test cases

All Passed
Took 4.47e-4 seconds
```

:::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::: spoiler

#### test-drive

With test-drive, we can name both a testsuite and an individual test within a testsuite.
The testuite name is applied within the program. In the example below we are giving the
testuite defined by `test_my_src_procedure_testsuite` the name `my_src_procedure`. 

```F90
!...
type(testsuite_type), allocatable :: testsuites(:)

testsuites = [ &
    new_testsuite("my_src_procedure", test_my_src_procedure_testsuite) &
]
!...
```

Within the test suite `test_my_src_procedure_testsuite` we can then give names to each
test. In the example below we have defined two tests `"a special test case"` and 
`"another special test case"`.

```F90
subroutine test_my_src_procedure_testsuite(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)

    testsuite =[ &
        new_unittest("a special test case", test_transpose_special_case), &
        new_unittest("another special test case", test_transpose_other_special_case) &
    ]
end subroutine test_my_src_procedure_testsuite
```

This results in the following output

```bash
$ fpm test
# Running testdrive tests suite
# Testing: my_src_procedure
  Starting a special test case ... (1/2)
       ... a special test case [PASSED]
  Starting another special test case ... (2/2)
       ... another special test case [PASSED]
```

:::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::: spoiler

#### pFUnit

With pFUnit, we name a test within the CMakeLists.txt. In the example below we define
a test with the name `pfunit_my_src_procedure_tests`.

```cmake
find_package(PFUNIT REQUIRED)
enable_testing()

# Filter out the main.f90 files. We can only have one main() function in our tests
set(PROJ_SRC_FILES_EXEC_MAIN ${PROJ_SRC_FILES})
list(FILTER PROJ_SRC_FILES_EXEC_MAIN EXCLUDE REGEX ".*main.f90")

# Create library for src code
add_library (sut STATIC ${PROJ_SRC_FILES_EXEC_MAIN})

# List all  test files
file(GLOB
  test_srcs
  "${PROJECT_SOURCE_DIR}/test/pfunit/*.pf"
)

# evolve_board tests
set(test_my_src_procedure ${test_srcs})
list(FILTER test_my_src_procedure INCLUDE REGEX ".*test_my_src_procedure.pf")

add_pfunit_ctest (pfunit_my_src_procedure_tests
  TEST_SOURCES ${test_my_src_procedure}
  LINK_LIBRARIES sut # your application library
  )
```

The other aspect of a pFUnit test in which we can add a descriptor is the string
printed to describe an individual test case. This is defined within the toString
function. In the example below, we directly print a description contained within
the parameter set itself.

```F90
@testParameter
type, extends(AbstractTestParameter) :: test_my_src_procedure_params
    integer :: input, output
    character(len=100) :: description
contains
    procedure :: toString => test_my_src_procedure_params_toString
end type test_my_src_procedure_params
!..
function test_my_src_procedure_testsuite() result(params)
    !...
    ! Define a set of input params within the testsuite function
    params(1) = test_my_src_procedure_params(input, output, "Some description")
    !...
end function test_my_src_procedure_testsuite
!..
function test_my_src_procedure_params_toString(this) result(string)
    class(test_my_src_procedure_params), intent(in) :: this
    character(:), allocatable :: string

    string = trim(this%description)
end function test_my_src_procedure_params_toString
!..
```

This results in the output

```bash
$ ctest 
Test project /Users/connoraird/work/fortran-unit-testing/exercises/5-debugging-a-broken-test/challenge-1/build-cmake
    Start 2: pfunit_transpose_tests
1/1 Test #2: pfunit_transpose_tests ...........   Passed    0.24 sec

100% tests passed, 0 tests failed out of 2

Total Test time (real) =   0.55 sec
```

Notice that this is the output from ctest and if there are no test failures, only
a short summary is outputted. In the event of a failure we can get more detail
via the `--output-on-failure` flag

```bash
$ ctest --output-on-failure
    Start 1: pfunit_my_src_procedure_tests
1/1 Test #1: pfunit_my_src_procedure_tests ...........***Failed  Error regular expression found in output. Regex=[Encountered 1 or more failures/errors during testing]  0.01 sec
 

 Start: <test_my_src_procedure.TestMySrcProcedure[Some description][Some description]>
. Failure in <test_my_src_procedure.TestMySrcProcedure[Some description][Some description]>
F   end: <test_my_src_procedure.TestMySrcProcedure[Some description][Some description]>

Time:         0.000 seconds
  
Failure
 in: 
test_my_src_procedure.TestMySrcProcedure[Some description][Some description]
  Location: 
[test_my_src_procedure.pf:59]
ArrayAssertEqual failure:
      Expected: <2.00000000>
        Actual: <1.00000000>
    Difference: <1.00000000> (greater than tolerance of 0.999999975E-5)
  
 FAILURES!!!
Tests run: 1, Failures: 1, Errors: 0
, Disabled: 0
STOP *** Encountered 1 or more failures/errors during testing. ***


0% tests passed, 1 tests failed out of 1

Total Test time (real) =   0.02 sec

The following tests FAILED:
          1 - pfunit_my_src_procedure_tests (Failed)
Errors while running CTest
```

:::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

### Challenge 1: Rename a test and improve its output.

Using one of the previous exercises we've looked at, try to rename a test in each of
the three frameworks. Can you improve the information outputted in the event of a
test failure?

::::::::::::::::::::::::::::::::::::::::::::::::

## Filtering tests

Each of the three frameworks offer the ability to filter which tests run. This can
be useful when debugging a failing test in order to reduce the noise on the terminal
screen, especially if there are many tests failing and you wish to tackle them one at
a time.

::::::::::::::::::::::::::::: spoiler

#### Veggies

Veggies comes with a built-in mechanism for filtering tests via the CLI flag `-f`.

```
-f string, --filter string    Only run cases or collections whose
                              description matches the given regular
                              expression. This option may be provided
                              multiple times to filter repeatedly before
                              executing the suite.
```

Using the example above, we could filter for this specific test with the following
command

```sh
fpm test -- -f "my_src_procedure" -f "specific inputs"
```

:::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::: spoiler

#### test-drive

test-drive does not come with  mechanism for filtering individual tests out-of-the-box. However, we are able to add this functionality ourselves by implementing a custom test
runner. The example provided below allows running a single testsuite or an individual
test.

```F90
program test_main
    use testdrive, only : run_testsuite, new_testsuite, testsuite_type, &
            & select_suite, run_selected, get_argument

    use test_my_src_procedure, only : test_my_src_procedure_testsuite

    implicit none

    type(testsuite_type), allocatable :: testsuites(:)

    testsuites = [ &
        new_testsuite("my_src_procedure", test_my_src_procedure_testsuite) &
    ]

    call run_tests(testsuites)

contains

    subroutine run_tests(testsuites)
        use, intrinsic :: iso_fortran_env, only : error_unit

        type(testsuite_type), allocatable, intent(in) :: testsuites(:)

        integer :: stat, is
        character(len=:), allocatable :: suite_name, test_name
        character(len=*), parameter :: fmt = '("#", *(1x, a))'

        stat = 0

        call get_argument(1, suite_name)
        call get_argument(2, test_name)

        write(error_unit, fmt) "Running testdrive tests suite"
        if (allocated(suite_name)) then
            is = select_suite(testsuites, suite_name)
            if (is > 0 .and. is <= size(testsuites)) then
                if (allocated(test_name)) then
                    write(error_unit, fmt) "Suite:", testsuites(is)%name
                    call run_selected(testsuites(is)%collect, test_name, error_unit, stat)
                    if (stat < 0) then
                        error stop 1
                    end if
                else
                    write(error_unit, fmt) "Testing:", testsuites(is)%name
                    call run_testsuite(testsuites(is)%collect, error_unit, stat)
                end if
            else
                write(error_unit, fmt) "Available testsuites"
                do is = 1, size(testsuites)
                    write(error_unit, fmt) "-", testsuites(is)%name
                end do
                error stop 1
            end if
        else
            do is = 1, size(testsuites)
                write(error_unit, fmt) "Testing:", testsuites(is)%name
                call run_testsuite(testsuites(is)%collect, error_unit, stat)
            end do
        end if

        if (stat > 0) then
            write(error_unit, '(i0, 1x, a)') stat, "test(s) failed!"
            error stop 1
        end if
    end subroutine run_tests

end program test_main
```

With this in place, as long as we run the test executable itself, we can then
filter with the following command

```bash
/path/to/test/exec my_src_procedure "a special test case"
```

If we run with ctest, we are limited to ctest's filtering mechanism.

:::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::: spoiler

#### pFUnit

pFUnit leverages CTest's mechanism to filter tests.

:::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::: spoiler

#### CTest

When building test-drive and veggies with CMake, to maintian the ability to run
our tests individually, we can add named tests to ctest. To do this, we can add
the following to the CMakeLists.txt.

```cmake
# Create a list of tests
set(
  tests
  "my_src_procedure"
)
#...
# Define test executable and Link library 
#...
# Define tests using the veggies test executable
foreach(t IN LISTS tests)
  add_test(NAME "veggies_${t}" COMMAND "test_${PROJECT_NAME}-veggies" "-f" "${t}")
endforeach()

# Or define tests using the test-drive executable
foreach(t IN LISTS tests)
  add_test(NAME "testdrive_${t}" COMMAND "test_${PROJECT_NAME}-test-drive" "${t}" WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
endforeach()
```

:::::::::::::::::::::::::::::::::::::

## Debugging a failing test

As with the output of a passing test, the output of a failing test differs
depending on the framework used to write them. As shown above, the
information we get from a test output is highly configurable. The more effort we
put in when writing tests the easier it will be to debug should it fail. For
example, it's clear which of the following options will be easier to debug should
the assertion fail.

```F90
! This will not be very clear
do row = 1, nrow
    do col = 1, ncol
        call check(error, params%expected_output_matrix(row, col), actual_output(row, col), &
            "Actual and expected output matrices did not match")
        if (allocated(error)) return
    end do
end do

! This is much better
do row = 1, nrow
    do col = 1, ncol
        write(failure_message,'(a,i1,a,i1,a,F3.1,a,F3.1)') "Unexpected value for output(", row, ",", col, "), got ", &
            actual_output(row, col), " expected ", params%expected_output_matrix(row, col)
        call check(error, params%expected_output_matrix(row, col), actual_output(row, col), failure_message)
        if (allocated(error)) return
    end do
end do
```

::::::::::::::::::::::::::::::::::::: challenge

### Challenge 2: Debug and fix a failing test.

Take a look at the [5-debugging-a-broken-test/challenge](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/5-debugging-a-broken-test/challenge) in the exercises repository.

:::::::::::::::::::::::::::::::: solution

A solution is provided in [README-solution.md](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/5-debugging-a-broken-test/solution).

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::
