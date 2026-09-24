---
title: "Parameterising pFUnit tests"
teaching:
exercises:
---

::: questions

- Why is it useful to parameterise a test?
- What is the syntax of writing a parameterised unit test in Fortran?

:::

::: objectives

- Parameterise our own pFUnit test.

:::

No that we are able to compile and run the most basic of pFUnit tests, we are ready to look at a more advanced topic,
parameterising our tests with pFUnit.

## Handling state within tests

If multiple tests rely of the existence of some state such as the allocation of an array. We could repeat this step within each
test, like so:

```fortran
module test_matrix_ops_dot
    use matrix_ops, only : dot
    use funit
    implicit none
contains
    @Test
    subroutine test_dot_one_to_twenty()
        integer, allocatable :: a(:), b(:)
        integer :: c

        ! allocate a and b
        allocate(a(10), b(10))

        ! Define inputs and expected outputs for the scenario we want to test
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        c = 935

        ! Check that the call to dot returned what we expect
        @assertEqual(c, dot(a, b), message="Unexpected value returned from dot")

        ! Deallocate to cleanup (not technically necessary)
        deallocate(a, b)

    end subroutine test_dot_one_to_twenty

    @Test
    subroutine test_dot_all_zeros()
        integer, allocatable :: a(:), b(:)
        integer :: c

        ! allocate a and b
        allocate(a(10), b(10))

        ! Define inputs and expected outputs for the scenario we want to test
        a = 0
        b = 0
        c = 0

        ! Check that the call to dot returned what we expect
        @assertEqual(c, dot(a, b), message="Unexpected value returned from dot")

        ! Deallocate to cleanup (not technically necessary)
        deallocate(a, b)

    end subroutine test_dot_all_zeros
end module test_matrix_ops_dot
```

However, it is generally better to minimise repeated code. Therefore, we can make use of another pFUnit pre-processor directive **@TestCase**:

```fortran
module test_matrix_ops_dot
    use funit
    implicit none

    !> Custom test case type allowing a single definition of setup and tearDown logic
    @TestCase(constructor=dot_test_case_constructor)
    type, extends(TestCase) :: dot_test_case
        !> The input array `a` to be passed to dot
        integer, allocatable :: a(:)
        !> The input array `b` to be passed to dot
        integer, allocatable :: b(:)
    contains
        !> A type-bound procedure which will run after each test which, essentially,
        !> acts like a destructor for this type
        procedure :: tearDown
    end type dot_test_case

contains

    !> Constructor for our custom test case type which allocates arrays `a` and `b`
    function dot_test_case_constructor() result(newTestCase)
        !> The new instance of our custom test case type to be constructed
        type(dot_test_case) :: newTestCase

        allocate(newTestCase%a(10))
        allocate(newTestCase%b(10))
    end function dot_test_case_constructor

    !> Essentially a destructor for our custom test case type which deallocates
    !> arrays `a` and `b`
    subroutine tearDown(this)
        !> The instance of our custom test case type which we want to teardown
        class(dot_test_case), intent(inout) :: this

        deallocate(this%a)
        deallocate(this%b)
    end subroutine tearDown

    @Test
    subroutine test_dot_one_to_twenty(this)
        !> The instance of our test case type for this test
        class(dot_test_case), intent(inout) :: this
        integer :: c

        ! Define inputs and expected outputs for the scenario we want to test
        this%a = [1,2,3,4,5,6,7,8,9,10]
        this%b = [11,12,13,14,15,16,17,18,19,20]
        c = 935

        ! Check that the call to dot returned what we expect
        @assertEqual(c, dot(this%a, this%b), message="Unexpected value returned from dot")
    end subroutine test_dot_one_to_twenty

    @Test
    subroutine test_dot_all_zeros(this)
        !> The instance of our test case type for this test
        class(dot_test_case), intent(inout) :: this
        integer :: c

        ! Define inputs and expected outputs for the scenario we want to test
        this%a = 0
        this%b = 0
        c = 0

        ! Check that the call to dot returned what we expect
        @assertEqual(c, dot(this%a, this%b), message="Unexpected value returned from dot")
    end subroutine test_dot_all_zeros
end module test_matrix_ops_dot
```

There are a few key things we have done in the above code:

- Defined our own custom derived type **dot_test_case** which contains the two arrays **a** and **b** as type-bound
  parameters.
- **dot_test_case** also contains a type-bound procedures **tearDown** which deallocates **a** and **b**.
- To first allocate **a** and **b** we have defined a constructor **dot_test_case_constructor**.
- These two procedures, **tearDown** and **dot_test_case_constructor**, allow us to move the previously repeated logic to
  one location.
- Finally, to ensure our new custom type is understood and used correctly by pFUnit, we must include two things in it's definition:
    1. Ensure this type extends one provided by the pFUnit library - **TestCase**.
    2. Decorate this new type with the pre-processor directive **@TestCase**, ensuring that we pass
    **dot_test_case_constructor** as the constructor.

## Parameterising tests

By defining a custom test case type, we have begun to reduce repetition within our test. However, there is further repetition to
be removed. For example, in both **@Test**'s we are calling **dot** and running the same assertion. To remove this, we can
paramaterise our test. This is done by defining a new custom type **dot_test_parameters**:

```fortran
module test_matrix_ops_dot
    use funit
    implicit none

    !> Custom test parameters type containing all of the inputs and expected
    !! outputs of dot
    @TestParameter
    type, extends(AbstractTestParameter) :: dot_test_parameters
        !> The input array `a` to be passed to dot
        integer, allocatable :: a(:)
        !> The input array `b` to be passed to dot
        integer, allocatable :: b(:)
        !> The expected value to be returned from dot
        integer :: expected_dot_product
        !> A description of the test to be outputted for logging
        character(len=100) :: description
    contains
        !> The required type-bound procedure for converting an instance
        !> of this type to a string for logging
        procedure :: toString
    end type dot_test_parameters

    !> Custom test case type allowing a single definition of tearDown logic.
    !! If teardown is not required, This could also be thought of as boilerplate
    !! required to make the parameters available within our @Test.
    @TestCase(constructor=dot_test_case_constructor)
    type, extends(ParameterizedTestCase) :: dot_test_case
        !> The instance of our test parameters type to be used within the test logic
        type(dot_test_parameters) :: params
    contains
        procedure :: tearDown
    end type dot_test_case

contains

    !> Trims and returns the description of the parameter set. The string returned
    !! by this function will be included by pFUnit in the name of this test
    function toString(this) result(string)
        class (dot_test_parameters), intent(in) :: this
        character(:), allocatable :: string

        string = trim(this%description)
    end function toString

    !> Boilerplate constructor required to convert our custom parameters type to
    !! the test case type.
    function dot_test_case_constructor(testParameters) result(newTestCase)
        type(dot_test_parameters), intent(in) :: testParameters
        type(dot_test_case) :: newTestCase

        newTestCase%params = testParameters
    end function dot_test_case_constructor

    !> Essentially a destructor for our custom test case type which deallocates
    !! arrays `a` and `b`
    subroutine tearDown(this)
        !> The instance of our custom test case type which we want to teardown
        class(dot_test_case), intent(inout) :: this

        deallocate(this%params%a)
        deallocate(this%params%b)
    end subroutine tearDown

    !> The test suite in which parameter sets (inputs and expected outputs) for each
    !! test are defined.
    function dot_test_suite() result(parameter_sets)
        !> The array of parameter sets to be returned
        type(dot_test_parameters) :: parameter_sets(2)

        integer, allocatable :: a(:), b(:)
        integer :: c

        allocate(a(10))
        allocate(b(10))

        ! Parameter set 1
        a = [1,2,3,4,5,6,7,8,9,10]
        b = [11,12,13,14,15,16,17,18,19,20]
        c = 935
        ! Here `dot_test_parameters` is a default constructor generated by our
        ! type definition
        parameter_sets(1) = dot_test_parameters(a, b, c, "10x10 incrementing values")

        ! Parameter set 2
        a = 0
        b = 0
        c = 0
        parameter_sets(2) = dot_test_parameters(a, b, c, "10x10 all zeros")

        ! Deallocate the temporary stores of a and b for completeness
        deallocate(a, b)
    end function dot_test_suite


    @Test(testParameters={dot_test_suite()})
    subroutine test_dot(this)
        !> The instance of our test case type for this test
        class(dot_test_case), intent(inout) :: this

        ! Check that the call to dot returned what we expect
        @AssertEqual(this%params%expected_dot_product, dot(this%params%a, this%params%b), message="Unexpected value returned from dot")
    end subroutine test_dot
end module test_matrix_ops_dot
```

There is a lot of new aspects being introduced in the above test so let's break them down.

::: spoiler

### 1. Test parameters type

First of all, we have defined a new custom type **dot_test_parameters**

```fortran
!> Custom test parameters type containing all of the inputs and expected
!> outputs of dot
@TestParameter
type, extends(AbstractTestParameter) :: dot_test_parameters
    !> The input array `a` to be passed to dot
    integer, allocatable :: a(:)
    !> The input array `b` to be passed to dot
    integer, allocatable :: b(:)
    !> The expected value to be returned from dot
    integer :: expected_dot_product
    !> A description of the test to be outputted for logging
    character(len=100) :: description
contains
    !> The required type-bound procedure for converting an instance
    !> of this type to a string for logging
    procedure :: toString
end type dot_test_parameters
```

The key features of the type **dot_test_parameters** are

- It is decorated with the directive **@TestParameter** to inform the pre-processor that this is a test parameter type.
- It extends the type **AbstractTestParameter** provided by the pFUnit library to allow the pfunit test runner to utilise this
  custom type.
- All inputs (**a** and **b**) and expected outputs (**expected_dot_product**) of **dot** are define as type-bound
  variables.
- The type-bound variable **description** and procedure **toString** allow conversion of a single test parameter instance to a
  character array for logging (see below).

#### toString

pFUnit requires that a type which extends **AbstractTestParameter** must define a type-bound procedure called **toString**:

```fortran
!> Trims and returns the description of the parameter set. The string returned
!> by this function will be included by pFUnit in the name of this test
function toString(this) result(string)
    class (dot_test_parameters), intent(in) :: this
    character(:), allocatable :: string

    string = trim(this%description)
end function toString
```

For simplicity, we utilise the variable **description** to define this string in its entirety.

::: callout

#### Default type constructor

All derived types in Fortran are given a default constructor of the same name which can be invoked
like a function. For example, we can create an instance of our type **dot_test_parameters**
like so:

```fortran
type(dot_test_parameters) :: testParameters

testParameters = dot_test_parameters(a, b, expected_dot_product, "10x10 incrementing values")
```

:::

::: challenge

### Challenge: Parameterising tests with pFUnit, part 1

Continuing with the [Writing your first unit test exercise][ex-writing-your-first-unit-test], take a look at part three. Write
your own derived-type to act as the test parameter type for parameterised tests of the temperature conversion library. You should
think about:

- What decorators are needed?
- What type should be extended?
- What type-bound variables should be defined, i.e. what inputs will the library require and what expected outputs?
- What other type-bound variables and/or procedures will be required?
- If you need a type-bound procedure, have you defined it?

:::

:::

::: spoiler

### 2. Parameterising the test case

Now that we have a new test parameter type, we must update our test case type to make use of it:

```fortran
!> Custom test case type allowing a single definition of tearDown logic.
!! If teardown is not required, This could also be thought of as boilerplate
!! required to make the parameters available within our @Test.
@TestCase(constructor=dot_test_case_constructor)
type, extends(ParameterizedTestCase) :: dot_test_case
    !> The instance of our test parameters type to be used within the test logic
    type(dot_test_parameters) :: params
contains
    procedure :: tearDown
end type dot_test_case
```

The key points to highlight are:

- We are now extending the base type **ParameterizedTestCase** to inform the pre-processor that this is a test case that should be
  parameterised.
- To prevent duplication we only define an instance of our test parameter type as a type-bound variable, rather than repeat the
  contents of **dot_test_parameters**.
- The type-bound procedure **teardown** remains the same.

#### Test case constructor

Whilst **teardown** remains almost unchanged, **dot_test_case_constructor** has changed considerably.
We now no longer use this as a mechanism to setup state but instead we are converting an instance of our parameter
type (**dot_test_parameters**) into an instance of our test case type (**dot_test_case**).

```f90
!> Boilerplate constructor required to convert our custom parameters type to
!! the test case type.
function dot_test_case_constructor(testParameters) result(newTestCase)
    type(dot_test_parameters), intent(in) :: testParameters
    type(dot_test_case) :: newTestCase

    newTestCase%params = testParameters
end function dot_test_case_constructor
```

::: callout

#### Setting up state

Now that we are not using the test case constructor for setting up state we need a new place for this to be done.
pFUnit allows us to do this in similar way to **teardown** by adding a new type-bound procedure within
our test case type called **setUp**.

:::

::: challenge

### Challenge: Parameterising tests with pFUnit, part 2

Continuing with part three of the [Writing your first unit test exercise][ex-writing-your-first-unit-test]. Write your own
derived-type to act as the test case type for your parameterised tests of the temperature conversion library. You should think about:

- What decorators are needed?
- What type should be extended?
- What type-bound variables should be defined?
- How do we instantiate one of these test cases?

:::

:::

::: spoiler

### 3. Defining a suite of tests / parameter sets

We now are able to parameterise our test case. To do this we define a function (**dot_test_suite**) which returns an array
of our custom test parameter type - **dot_test_parameters** - which we call the test suite.

```f90
!> The test suite in which parameter sets (inputs and expected outputs) for each
!! test are defined.
function dot_test_suite() result(parameter_sets)
    !> The array of parameter sets to be returned
    type(dot_test_parameters) :: parameter_sets(2)

    integer, allocatable :: a(:), b(:)
    integer :: c

    allocate(a(10))
    allocate(b(10))

    ! Parameter set 1
    a = [1,2,3,4,5,6,7,8,9,10]
    b = [11,12,13,14,15,16,17,18,19,20]
    c = 935
    ! Here `dot_test_parameters` is a default constructor generated by our
    ! type definition
    parameter_sets(1) = dot_test_parameters(a, b, c, "10x10 incrementing values")

    ! Parameter set 2
    a = 0
    b = 0
    c = 0
    parameter_sets(2) = dot_test_parameters(a, b, c, "10x10 all zeros")

    ! Deallocate the temporary stores of a and b for completeness
    deallocate(a, b)
end function dot_test_suite
```

Let's look at the key aspects of this function:

- We return an array of **dot_test_parameters** where each element is a single test case.
- This is now where we allocate **a** and **b**.

::: challenge

### Challenge: Parameterising tests with pFUnit, part 3

Continuing with part three of the [Writing your first unit test exercise][ex-writing-your-first-unit-test]. Write the test suite
for tests of the function `fahrenheit_to_celsius`. You should think about:

- What decorators are needed, if any?
- Do you need a function or subroutine?
- What should the inputs to this procedure be?
- What should be its outputs?
- How do you define a single test scenario?
- How do you add more scenarios?

:::

:::

::: spoiler

### 4. Passing the test suite into the @Test

Since we are now defining our inputs and expected outputs within our custom type **dot_test_parameters** and setting their
values in **dot_test_suite**, we can simplify the contents of our test subroutine:

```f90
@Test(testParameters={dot_test_suite()})
subroutine test_dot(this)
    !> The instance of our test case type for this test
    class(dot_test_case), intent(inout) :: this

    ! Check that the call to dot returned what we expect
    @AssertEqual(this%params%expected_dot_product, dot(this%params%a, this%params%b), message="Unexpected value returned from dot")
end subroutine test_dot
```

The key aspects are:

- The **@Test** directive now takes a **testParameters** value which we return from our test suite **dot_test_suite**.
- We no longer set any inputs or expected outputs within this test subroutine, we only call **dot** and **@AssertEqual**.

::: challenge

### Challenge: Parameterising tests with pFUnit, part 4

Continuing with part three of the [Writing your first unit test exercise][ex-writing-your-first-unit-test]. Write the actual test
logic for the function `fahrenheit_to_celsius`. You should think about:

- What decorators are needed?
- Do you need a function or subroutine?
- What should the inputs to this procedure be?
- What should be its outputs?
- How do you link this test logic to the test suite you just defined?
- How do you check if a test scenario was successful?

:::

:::

::: challenge

### Challenge: Parameterising tests with pFUnit, part 5

To finish part three of the [Writing your first unit test exercise][ex-writing-your-first-unit-test]. Alongside the tests you have
just written for `fahrenheit_to_celsius`, add unit tests for the function `celsius_to_kelvin`. You should think about:

- What can be re-used from your tests of `fahrenheit_to_celsius`.
- What new functions and subroutines need to be written?

::: solution

You can find a solution to this and all previous **Parameterising tests with pFUnit** challenges within
[exercises/writing-your-first-unit-test/solution][ex-writing-your-first-unit-test-solution].

:::

:::

::: instructor

The following challenge will take learners a long time to complete. Therefore, for shorter workshops, it is recommended to skip
this and/or suggest it as some homework.

:::

::: challenge

### Challenge: Testing the game of life

Take a look at the [Fortran Unit Test Syntax exercise][ex-fortran-unit-test-syntax]. Apply what you've just learnt to writing unit
tests for the [Game of Life][appendix-game-of-life]

::: solution

A solution is provided in [exercises/fortran-unit-test-syntax/solution][ex-fortran-unit-test-syntax-solution].

:::

:::
