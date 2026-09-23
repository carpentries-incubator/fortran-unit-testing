---
title: "pFUnit basics"
teaching:
exercises:
---

:::::::::::::::::::::::::::::::::::::: questions

- What is the syntax of writing a unit test in Fortran?
- How do I build my tests with my existing build system?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Able to write a unit test for a Fortran procedure with test-drive, veggies and/or pFUnit.
- Understand the similarities between each framework and where they differ.

::::::::::::::::::::::::::::::::::::::::::::::::

## What framework will we look at?

There are multiple frameworks available for writing unit tests in Fortran, as detailed on the
[Fortran Lang website](https://fortran-lang.org/packages/programming/). However, we recommend
the use of [pFUnit](https://github.com/Goddard-Fortran-Ecosystem/pFUnit) as it is…

- the most feature rich framework.
- the most widely used framework.
- being maintained.
- able to integrate with CMake and make.

**Key features of pFUnit:**

- **Supports MPI**: Supports testing MPI parallelized code, including parametrizing tests by
  number of MPI ranks.
- **Simple interface**: Tests are written in **.pf** format which is then pre-processed by a tool
  provided by pFUnit into **.f90** before compilation. This removes the need to write a lot of
  boilerplate code.

## The most basic pFUnit test

As we've seen in the [previous episode][ep-writing-your-first-unit-test], if we
were to write our own unit tests using a custom testing setup we would need to
define a test runner that could track success and failure states for each test
and report the reason for each failure back to us.

Alternatively, if we were to use pFUnit, there is no longer a need to define this test runner because pFUnit handles that for us.
Therefore, the most basic test we can define using pFunit becomes simple. For example, if we wanted to test the function **dot**
which performs a dot product on two arrays, we could write the following test.

::: instructor

The **dot** function should only be a wrapper around the intrinsic function **dot_product** to keep the example simple but
incorporate compiling src and tests together:

```fortran
module matrix_ops
    implicit none
contains
    !> Returns the dot product (a.b) of the two inputted arrays a and b
    integer function dot(a, b)
        !> The two arrays to be dotted together
        integer :: a(:), b(:)

        dot = dot_product(a, b)
    end function dot
end module matrix_ops
```

When writing the pFUnit version of the unit test for the dot product, begin from this standard Fortran version to highlight the
benefits of pFUnit.

```fortran
program test_dot
    use matrix_ops, only : dot
    implicit none

    integer :: i

    ! Declare passed and failure message arrays to be set by a test subroutine(s)
    logical :: passed(1)
    character(len=200) :: failure_message(1)

    ! Define set of tests for dot
    call test_dot_one_to_twenty(passed(1), failure_message(1))

    if (all(passed)) then
        write(*,*) "All tests passed!"
    else
      do i = 1, size(passed)
          if (.not. passed(i)) then
              write(*,*) "FAIL: ", trim(failure_message(i))
          end if
      end do
      stop 1
    end if

contains
    !> Unit test subroutine for dot
    subroutine test_dot_one_to_twenty(passed, failure_message)
        !> A logical to track whether the test passed or not
        logical, intent(out) :: passed
        !> A failure message to be displayed if passed is false
        character(len=200), intent(out) :: failure_message

        integer :: a(10), b(10), expected_c, actual_c

        ! Define inputs and expected outputs for the scenario we want to test
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        expected_c = 935

        actual_c = dot(a, b)

        ! Check that the actual value matches the expected value
        passed = expected_c == actual_c

        ! Populate the failure message
        write(failure_message, '(A,I3,A,I3)') "Expected ", expected_c, " but got ", actual_c

    end subroutine test_dot_one_to_twenty
end program test_dot
```

This should be able to be compiled with the command `gfortran matrix_ops.f90 test_dot.f90`

:::

```fortran
module test_dot
    use matrix_ops, only : dot
    use funit
    implicit none
contains
    @Test
    subroutine test_dot_product_one_to_twenty()
        integer :: a(10), b(10), c

        ! Define inputs and expected outputs for the scenario we want to test
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        c = 935

        ! Check that the call to dot returned what we expect
        @assertEqual(c, dot(a, b), message="Unexpected value returned from dot")

    end subroutine test_dot_product_one_to_twenty
end module test_dot
```

Here we have introduced some new syntax in the form of **@Test** and **@AssertEqual**. These are pFUnit pre-processor directives
which simplify how we write tests:

- **@Test** designates the subroutine **test_dot_product_one_to_twenty** as a test that should be ran on execution of your pFUnit
  test suite.
- **@AssertEqual** is one of many assert directives provided by pFUnit. More specifically, **@AssertEqual** allows the
  exact comparison of values (also works for comparing arrays). For a full list of the available assertion directives see
  [pFUnit documentation page for their preprocessor directives](https://pfunit.sourceforge.net/page_Assert.html)
  - As is done here, it is recommended to provide a helpful message, in case of an assertion
      failing, to help diagnose the issue.

::: callout

### @AssertEqual for floating point values

For floating point values, @AssertEqual no longer carries out an exact comparison but become a comparison up to a tolerance.

:::

If we then wish to add a new test case we can add another subroutine, again decorated with **@Test**:

```fortran
module test_dot
    use matrix_ops, only : dot
    use funit
    implicit none
contains
    @Test
    subroutine test_dot_one_to_twenty()
        integer :: a(10), b(10), c

        ! Define inputs and expected outputs for the scenario we want to test
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        c = 935

        ! Check that the call to dot returned what we expect
        @assertEqual(c, dot(a, b), message="Unexpected value returned from dot")

    end subroutine test_dot_one_to_twenty

    @Test
    subroutine test_dot_all_zeros()
        integer :: a(10), b(10), c

        ! Define inputs and expected outputs for the scenario we want to test
        a = 0
        b = 0
        c = 0

        ! Check that the call to dot_product returned what we expect
        @assertEqual(c, dot(a, b), message="Unexpected value returned from dot")

    end subroutine test_dot_all_zeros
end module test_dot
```

::: instructor

To build and run this pFUnit version. Use the **CMakeLists.txt** below:

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
set(SRC_DIR "${PROJECT_SOURCE_DIR}")
set(PROJ_SRC_FILES "${SRC_DIR}/matrix_ops.f90")

#---------------------------
# Configure testing.
#---------------------------
enable_testing()

find_package(PFUNIT REQUIRED)

# Create library for src code
add_library(SUT STATIC ${PROJ_SRC_FILES})

# List all test files
set(test_srcs "${PROJECT_SOURCE_DIR}/test_dot.pf")

# Add the test target
add_pfunit_ctest (test_dot
  TEST_SOURCES ${test_srcs}
  LINK_LIBRARIES SUT # your application library
  )
```

This can then be compiled with the following commands:

```sh
cmake -B build -DCMAKE_PREFIX_PATH="/path/to/pfunit/build/installed"
cmake --build build
./build/test_dot
```

:::

::: challenge

### Challenge: Test temperature conversions using pFUnit

Continuing with part two of the
[Writing your first unit test exercise][ex-writing-your-first-unit-test]
from the exercises. Write a single test for the temperature conversion using pFUnit.

::: solution

A solution is provided in [exercises/writing-your-first-unit-test/solution][ex-writing-your-first-unit-test-solution].

:::

:::
