---
title: "Fortran Unit Test Syntax"
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

## The most basics pFUnit test

As we've seen in the [previous episode](../3-writing-your-first-unit-test.html), if we were to write our own unit tests using a custom testing setup we would need to define a test runner that could track success and failure states for each test and report the reason for each failure back to us. 

Alternatively, if we were to use pFUnit, there is no longer a need to define this test runner because pFUnit handles that for us. Therefore, the most basic test we can define using pFunit becomes simple. For example, if we wanted to test the Fortran intrinsic function **dot_product**, we could write the following test.

```fortran
module test_dot_product_intrinsic
    use funit
    implicit none
contains
    @Test
    subroutine test_dot_product()
        integer :: a(10), b(10), c

        ! Define inputs and expected outputs for the scenario we want to test
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        c = 935

        ! Check that the call to dot_product returned what we expect
        @assertEqual(c, dot_product(a, b), message="Unexpected value returned for the dot_product")

    end subroutine test_dot_product
end module test_dot_product_intrinsic
```

Here we have introduced some new syntax in the form of **@Test** and **@AssertEqual**. These are pFUnit pre-processor directives which simplify how we write tests:

- **@Test** designates the subroutine **test_dot_product** as a test that should be ran on execution of your pFUnit test suite.
- **@AssertEqual** is one of many assert directives provided by pFUnit. More specifically, **@AssertEqual** allows the
  exact comparison of two values (also works for comparing arrays). For a full list of the available assertion directives see
  [pFUnit documentation page for their preprocessor directives](https://pfunit.sourceforge.net/page_Assert.html)
    - As is done here, it is recommended to provide a helpful message, in case of an assertion
      failing, to help diagnose the issue.

If we then wish to add a new test case we can add another subroutine, again decorated with **@Test**:

```fortran
module test_dot_product_intrinsic
    use funit
    implicit none
contains
    @Test
    subroutine test_dot_product()
        integer :: a(10), b(10), c

        ! Define inputs and expected outputs for the scenario we want to test
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        c = 935

        ! Check that the call to dot_product returned what we expect
        @AssertEqual(c, dot_product(a, b), message="Unexpected value returned for the dot_product")

    end subroutine test_dot_product

    @Test
    subroutine test_dot_product_all_zeros()
        integer :: a(10), b(10), c

        ! Define inputs and expected outputs for the scenario we want to test
        a = 0
        b = 0
        c = 0

        ! Check that the call to dot_product returned what we expect
        @AssertEqual(c, dot_product(a, b), message="Unexpected value returned for the dot_product")

    end subroutine test_dot_product_all_zeros
end module test_dot_product_intrinsic
```

## Handling state within tests

If multiple tests rely of the existence of some state such as the allocation of an array. We could repeat this step within each test, like so:

```fortran
module test_dot_product_intrinsic
    use funit
    implicit none
contains
    @Test
    subroutine test_dot_product()
        integer, allocatable :: a(:), b(:)
        integer :: c

        ! allocate a and b
        allocate(a(10), b(10))
        
        ! Define inputs and expected outputs for the scenario we want to test
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        c = 935

        ! Check that the call to dot_product returned what we expect
        @assertEqual(c, dot_product(a, b), message="Unexpected value returned for the dot_product")

        ! Deallocate to cleanup (not technically necessary)
        deallocate(a, b)

    end subroutine test_dot_product

    @Test
    subroutine test_dot_product_all_zeros()
        integer, allocatable :: a(:), b(:)
        integer :: c

        ! allocate a and b
        allocate(a(10), b(10))

        ! Define inputs and expected outputs for the scenario we want to test
        a = 0
        b = 0
        c = 0

        ! Check that the call to dot_product returned what we expect
        @assertEqual(c, dot_product(a, b), message="Unexpected value returned for the dot_product")

        ! Deallocate to cleanup (not technically necessary)
        deallocate(a, b)

    end subroutine test_dot_product_all_zeros
end module test_dot_product_intrinsic
```

However, it is generally better to minimise repeated code. Therefore, we can make use of another pFUnit pre-processor directive **@TestCase**:

```fortran
module test_dot_product_intrinsic
    use funit
    implicit none

    !> Custom test case type allowing a single definition of setup and tearDown logic
    @TestCase(constructor=dot_product_test_case_constructor)
    type, extends(TestCase) :: dot_product_test_case
        !> The input array `a` to be passed to dot_product
        integer, allocatable :: a(:)
        !> The input array `b` to be passed to dot_product
        integer, allocatable :: b(:)
    contains
        !> A type-bound procedure which will run after each test which, essentially,
        !> acts like a destructor for this type
        procedure :: tearDown
    end type dot_product_test_case

contains

    !> Constructor for our custom test case type which allocates arrays `a` and `b`
    function dot_product_test_case_constructor() result(newTestCase)
        !> The new instance of our custom test case type to be constructed
        type(dot_product_test_case) :: newTestCase

        allocate(newTestCase%a(10))
        allocate(newTestCase%b(10))
    end function dot_product_test_case_constructor

    !> Essentially a destructor for our custom test case type which deallocates
    !> arrays `a` and `b`
    subroutine tearDown(this)
        !> The instance of our custom test case type which we want to teardown
        class(dot_product_test_case), intent(inout) :: this

        deallocate(this%a)
        deallocate(this%b)
    end subroutine tearDown

    @Test
    subroutine test_dot_product(this)
        !> The instance of our test case type for this test
        class(dot_product_test_case), intent(inout) :: this
        integer :: c
        
        ! Define inputs and expected outputs for the scenario we want to test
        this%a = [1,2,3,4,5,6,7,8,9,10]
        this%b = [11,12,13,14,15,16,17,18,19,20]
        c = 935

        ! Check that the call to dot_product returned what we expect
        @assertEqual(c, dot_product(this%a, this%b), message="Unexpected value returned for the dot_product")
    end subroutine test_dot_product

    @Test
    subroutine test_dot_product_all_zeros(this)
        !> The instance of our test case type for this test
        class(dot_product_test_case), intent(inout) :: this
        integer :: c

        ! Define inputs and expected outputs for the scenario we want to test
        this%a = 0
        this%b = 0
        c = 0

        ! Check that the call to dot_product returned what we expect
        @assertEqual(c, dot_product(this%a, this%b), message="Unexpected value returned for the dot_product")
    end subroutine test_dot_product_all_zeros
end module test_dot_product_intrinsic
```

In the above code we have defined our own custom derived type **dot_product_test_case** which contains the two arrays **a** and **b** as type-bound prameters. **dot_product_test_case** also contains a type-bound procedures **tearDown** which deallocates **a** and **b**. To first allocate **a** and **b** we have defined a constructor **dot_product_test_case_constructor**. These two procedures allow us to move this previously repeated logic to one location. Finally, to ensure our new custom type is understood and used correctly by pFUnit, we must do two things. Ensure this type extends one provided by the pFUnit library - **TestCase**. Decorate this new type with the pre-processor directive **@TestCase**, ensuring that we pass **dot_product_test_case_constructor** as the constructor.

## Parameterising tests

By defining a custom test case type, we have begun to reduce repetition within our test. However, there is further repitition to be removed. For example, in both **@Test**'s we are calling **dot_product** and running the same assertion. To remove this, we can paramaterise our test. This is done by defining a new custom type **dot_product_test_parameters**:

```fortran
module test_dot_product_intrinsic
    use funit
    implicit none

    !> Custom test parameters type containing all of the inputs and expected
    !! outputs of the intrinsic dot_product
    @TestParameter
    type, extends(AbstractTestParameter) :: dot_product_test_parameters
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
    end type dot_product_test_parameters

    !> Custom test case type allowing a single definition of tearDown logic. 
    !! If teardown is not required, This could also be thought of as boilerplate
    !! required to make the parameters available within our @Test.
    @TestCase(constructor=dot_product_test_case_constructor)
    type, extends(ParameterizedTestCase) :: dot_product_test_case
        !> The instance of our test parameters type to be used within the test logic
        type(dot_product_test_parameters) :: params
    contains
        procedure :: tearDown
    end type dot_product_test_case

contains

    !> Trims and returns the description of the parameter set. The string returned
    !! by this function will be included by pFUnit in the name of this test
    function toString(this) result(string)
        class (dot_product_test_parameters), intent(in) :: this
        character(:), allocatable :: string

        string = trim(this%description)
    end function toString

    !> Boilerplate constructor required to convert our custom parameters type to
    !! the test case type.
    function dot_product_test_case_constructor(testParameters) result(newTestCase)
        type(dot_product_test_parameters), intent(in) :: testParameters
        type(dot_product_test_case) :: newTestCase

        newTestCase%params = testParameters
    end function dot_product_test_case_constructor

    !> Essentially a destructor for our custom test case type which deallocates
    !! arrays `a` and `b`
    subroutine tearDown(this)
        !> The instance of our custom test case type which we want to teardown
        class(dot_product_test_case), intent(inout) :: this

        deallocate(this%params%a)
        deallocate(this%params%b)
    end subroutine tearDown

    !> The test suite in which parameter sets (inputs and expected outputs) for each
    !! test are defined.
    function dot_product_test_suite() result(parameter_sets)
        !> The array of parameter sets to be returned
        type(dot_product_test_parameters) :: parameter_sets(2)

        integer, allocatable :: a(:), b(:)
        integer :: c

        allocate(a(10))
        allocate(b(10))

        ! Parameter set 1
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        c = 935
        ! Here `dot_product_test_parameters` is a default constructor generated by our
        ! type definition
        parameter_sets(1) = dot_product_test_parameters(a, b, c, "10x10 incrementing values") 

        ! Parameter set 2
        a = 0
        b = 0
        c = 0
        parameter_sets(2) = dot_product_test_parameters(a, b, c, "10x10 all zeros")

        ! Deallocate the temporary stores of a and b for completeness
        deallocate(a, b)
    end function dot_product_test_suite


    @Test(testParameters={dot_product_test_suite()})
    subroutine test_dot_product(this)
        !> The instance of our test case type for this test
        class(dot_product_test_case), intent(inout) :: this

        ! Check that the call to dot_product returned what we expect
        @AssertEqual(this%params%expected_dot_product, dot_product(this%params%a, this%params%b), message="Unexpected value returned for the dot_product")
    end subroutine test_dot_product
end module test_dot_product_intrinsic
```

There is a lot of new aspects being introduced in the above test so let's break them down.

:::::::::::: spoiler

### 1. Test parameters type

First of all we have defined a new custom type **dot_product_test_parameters**

```fortran
!> Custom test parameters type containing all of the inputs and expected
!> outputs of the intrinsic dot_product
@TestParameter
type, extends(AbstractTestParameter) :: dot_product_test_parameters
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
end type dot_product_test_parameters
```

The key features of this the type **dot_product_test_parameters** are

- It is decorated with the directive **@TestParameter**.
- It extends the type **AbstractTestParameter** provided by the pFUnit library.
- All inputs (**a** and **b**) and expected outputs (**expected_dot_product**) of **dot_product** are define as type-bound variables.
- The type-bound variable **description** and procedure **toString** allow conversion of a single test parameter instance to a character array for logging (see below). 

#### toString

pFUnit requires that a type which extends **AbstractTestParameter** must define a type-bound procedure called **toString**:

```fortran
!> Trims and returns the description of the parameter set. The string returned
!> by this function will be included by pFUnit in the name of this test
function toString(this) result(string)
    class (dot_product_test_parameters), intent(in) :: this
    character(:), allocatable :: string

    string = trim(this%description)
end function toString
```

For simplicity, we utilise the variable **description** to define this string in its entirity.

:::::::::: callout

#### Default type constructor

All derived types in Fortran are given a default constructor of the same name which can be invoked
like a function. For example, we can create an instance of our type **dot_product_test_parameters**
like so:

```fortran
type(dot_product_test_parameters) :: testParameters

testParameters = dot_product_test_parameters(a, b, expected_dot_product, "10x10 incrementing values")
```

::::::::::::::::::

::::::::::::

:::::::::::: spoiler

### 2. Parameterising the test case

Now that we have a new test parameter type, we must update our test case type to make use of it:

```fortran
!> Custom test case type allowing a single definition of tearDown logic. 
!! If teardown is not required, This could also be thought of as boilerplate
!! required to make the parameters available within our @Test.
@TestCase(constructor=dot_product_test_case_constructor)
type, extends(ParameterizedTestCase) :: dot_product_test_case
    !> The instance of our test parameters type to be used within the test logic
    type(dot_product_test_parameters) :: params
contains
    procedure :: tearDown
end type dot_product_test_case
```

The key points to highlight are:

- We are now extending the base type **ParameterizedTestCase**.
- To prevent duplication we simply define an instance of our test parameter type as a type-bound variable.
- The type-bound procedure **teardown** remains the same.

#### Test case constructor

Whilst **teardown** remains almost unchanged, **dot_product_test_case_constructor** has changed considerably.
We now no longer use this as a mechanism to setup state but instead we are converting an instance of our parameter
type (**dot_product_test_parameters**) into an instance of our test case type (**dot_product_test_case**).

```f90
!> Boilerplate constructor required to convert our custom parameters type to
!! the test case type.
function dot_product_test_case_constructor(testParameters) result(newTestCase)
    type(dot_product_test_parameters), intent(in) :: testParameters
    type(dot_product_test_case) :: newTestCase

    newTestCase%params = testParameters
end function dot_product_test_case_constructor
```

:::::::::::: callout

#### Setting up state

Now that we are not using the test case constructor for setting up state we need a new place for this to be done.
Thankfully, pFUnit allows us to do this in similar way to **teardown** by adding a new type-bound procedure within
our test case type called **setUp**. 

::::::::::::::::::::

:::::::::::: spoiler

::::::::::::

### 3. Defining a suite of tests / parameter sets

**TODO:**
- Returns a list of parameter sets where each set represents a single test
- If inputs need to be allocated, this is where we do it.

::::::::::::

:::::::::::: spoiler

### 4. Passing the test suite into the @Test

::::::::::::
