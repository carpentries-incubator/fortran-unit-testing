---
title: "Syntax of other unit test frameworks"
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

## What frameworks will we look at?

- [Veggies](https://gitlab.com/everythingfunctional/veggies)
  - Integrated with FPM and CMake.
- [test-drive](https://github.com/fortran-lang/test-drive)
  - This is the least featured of the frameworks.
  - Requires more boilerplate than the other frameworks.
  - Integrated with FPM and CMake.

## The shared structure of a test module

All three frameworks share the basic structure for their test modules.

```f90
module test_something
    ! use veggies|testdrive|funit
    ! use the src to be tested
    implicit none

    ! Derived types: Define types to act as test parameters and test cases.
contains

    ! Test Suite: Define a test suite (collection of tests) to be returned from a procedure.

    ! Test Logic: Define the actual test execution code which will call the src and execute assertions.

    ! Type Constructors: Define constructors for your derived types (test parameters/cases).
end module test_something
```

## Let's dive into the syntax

### Derived types

The key differences are:

- Whether the derived type extends another type or not.
- The required [type-bound procedures](https://fortran-lang.org/learn/quickstart/derived_types/#type-bound-procedures).
- Whether a test case derived type is needed.

::::::::::::::::::::::::::::: spoiler

#### Veggies

```F90
type, extends(input_t) :: my_test_params
    integer :: input, expected_output
end type my_test_params
```

:::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::: spoiler

#### test-drive

```F90
type :: my_test_params
    integer :: input, expected_output
end my_test_params
```

:::::::::::::::::::::::::::::::::::::

### Test Suite

::::::::::::::::::::::::::::: spoiler

#### Veggies

For Veggies, we define a function which returns a Veggies derived-type that takes an array of test parameters
representing different test scenarios and a generic test function, in this case **check_my_src_procedure**. This
test function is where we actually call our src procedure and carry out assertions (see the next section).

```F90
function my_test_suite() result(tests)
    type(test_item_t) :: tests

    type(example_t) :: my_test_data(1)

    ! Given input is 1, output is 2
    my_test_data(1) = example_t(my_test_params(1, 2))

    tests = describe( &
        "my_src_procedure", &
        [ it( &
            "given some inputs, when I call my_src_procedure, Then we get the expected output", &
            my_test_data, &
            check_my_src_procedure &
        )] &
    )
end function my_test_suite
```

:::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::: spoiler

#### test-drive

For test-drive, we define a subroutine which populates an array of test parameters called the testsuite.
To build this testsuite we provide additional subroutines which actually set up the test parameters and
then call the test function.

```F90
subroutine my_test_suite(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)

    testsuite = [ &
        new_unittest("my_src_procedure: Given input is 1, output is 2", test_my_procedure_with_input_1) &
    ]
end subroutine my_test_suite

!> Given input is 1, output is 2
subroutine test_my_procedure_with_input_1(error)
    type(error_type), allocatable, intent(out) :: error

    type(my_test_params) :: params

    params%input = 1
    params%expected_output = 2

    call check_my_src_procedure(error, params)
end subroutine test_my_procedure_with_input_1
```

:::::::::::::::::::::::::::::::::::::

### Test Logic

::::::::::::::::::::::::::::: spoiler

#### Veggies

For Veggies, we define a function which takes a veggies **input_t** type and returns a veggies **result_t**
type. As this input_t type is generic compared to out parameter type, we do some additional verification
to ensure we are passing the expected test parameter type.

```F90
function check_my_src_procedure(params) result(result_)
    class(input_t), intent(in) :: params
    type(result_t) :: result_

    integer :: actual_output

    select type (params)
    type is (my_test_params)
        call my_src_procedure(params%input, actual_output)

        reult_ = assert_equal(params%expected_output, actual_output, "Unexpected output from my_src_procedure")
    class default
        result_ = fail("Didn't get my_test_params")

    end select

end function check_my_src_procedure
```

:::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::: spoiler

#### test-drive

For test-drive, we define a subroutine which takes an error and an instance of our test parameters derived-type.

```F90
subroutine check_my_src_procedure(error, params)
    type(error_type), allocatable, intent(out) :: error
    class(my_test_params), intent(in) :: params

    integer :: actual_output

    call my_src_procedure(params%input, actual_output)

    call check(error, params%expected_output, actual_output, "Unexpected output from my_src_procedure")
    if (allocated(error)) return
end subroutine check_my_src_procedure
```

::::::::::::::::::::::::::::::::::::: callout

We must check if error has been allocated after every **check**. i.e.

```F90
call check(...)
if (allocated(error)) return

call check(...)
if (allocated(error)) return
```

:::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::

### Type Constructors

For **Veggies** and **test-drive**, this step is not always required but can be useful to simplify
populating multiple different test cases. For example, if we wished to test a subroutine which
performs some operations on a large matrix we could create a constructor to populate this matrix
with random values. We would then need to call this constructor with different
inputs to generate multiple test cases.

If we want to add a constructor for these types, it must be declared, at this point as an interface to
the derived-type

::::::::::::::::::::::::::::: spoiler

### Veggies and test-drive

Shown here is how to create an arbitrarily simple constructor. This would not actually be necessary as
compilers can handle this for us. However, we use the same syntax for more complex derived types. First,
declare your constructor,

```f90
interface my_test_params
    module procedure my_test_params_constructor
end interface my_test_params
```

Then, implement your constructor,

```f90
contains
    function my_test_params_constructor(input, expected_output) result(params)
        integer, intent(in) :: input, expected_output

        type(my_test_params) :: params

        my_test_params%input = input
        my_test_params%expected_output = expected_output
    end function check_for_steady_state_in_out_constructor
```

:::::::::::::::::::::::::::::::::::::
