---
title: "What is a Unit Test"
teaching:
exercises:
---

:::::::::::::::::::::::::::::::::::::: questions

- What is unit testing?
- Why do we need unit tests?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Define the key aspects of a good unit test (isolated, testing minimal functionality, fast, etc).
- Understand the key anatomy of a unit test in any language.
- Explain the benefit of unit tests on top of other types of tests.
- Understand when to run unit tests.

::::::::::::::::::::::::::::::::::::::::::::::::

Unit testing is a way of verifying the validity of a code base by testing its smallest individual components, or **units**.

>*"If the parts don't work by themselves, they probably won't work well together"*
> --  (Thomas and Hunt, 2019, [The pragmatic programmer](https://search.worldcat.org/search?q=bn:9780135957059), Topic 51).

Several key aspects define a unit test. They should be...

- **Isolated** - Does not rely on any other unit of code within the repository.
- **Minimal** - Tests only one unit of code.
- **Fast** - Run on the scale of ms or s.

::::::::::::::::::::::::::::::::::::: callout

### Other forms of testing

There are other forms of testing, such as integration testing in which two or more units of a code base are tested to verify that they work together, or that they are correctly **integrated**.
However, today we are focusing on unit tests as it is often the case that many of these larger tests are written using the same test tools and frameworks, hence we will make progress with both by starting with unit testing.

::::::::::::::::::::::::::::::::::::::::::::::::

## What does a unit test look like?

All unit tests tend to follow the same pattern of Given-When-Then.

- **Given** we are in some specific starting state
  - Units of code almost always have some inputs. These inputs may be scalars to be passed into a function, but they may also be an external dependency such as a database, file or array which must be allocated.
  - This database, file or array memory must exist before the unit can be tested. Hence, we must set up this state in advance of calling the unit we are testing.
- **When** we carry out a specific action
  - This is the step in which we call the unit of code to be tested, such as a call to a function or subroutine.
  - We should limit the number of actions being performed here to ensure it is easy to determine which unit is failing in the event that a test fails.
- **Then** some specific event/outcome will have occurred.
  - Once we have called our unit of code, we must check that what we expected to happen did indeed happen.
  - This could mean comparing a scalar or vector quantity returned from the called unit against some expected value. However, it could be something more complex such as validating the contents of a database or outputted file.

::::::::::::::::::::::::::::::::::::: challenge

### Challenge 1: Write a unit test in pseudo code

Assuming you have a function `reverse_array` which reverses the order of an allocated array. Write a unit test in pseudo code for `reverse_array` using the pattern above.

:::::::::::::::::::::::: solution

 ```
! Given
Allocate the input array `input_array`
Fill `input_array`, for example with `(1,2,3,4)`
Allocate the expected output array `expected_output_array`
Fill `expected_output_array` with the correct expected output, i.e., `(4,3,2,1)`

! When
Call `reverse_array` with `input_array`

! Then
for each element in `input_array`:
    Assert that the corresponding element of `expected_output_array` matches that of `input_array`
```

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::

## When should unit tests be run?

A major benefit of unit tests is the ability to identify bugs at the earliest possible stage. Therefore, unit tests should be run frequently throughout the development process. Passing unit tests give you and your collaborators confidence that changes to your code aren't modifying the previously expected behaviour, so run your unit tests...

- if you make a change locally
- if you raise a merge request
- if you plan to do a release
- if you are reviewing someone else's changes
- if you have recently installed your code into a new environment
- if your dependencies have been updated

Basically, all the time.

## Do we really need unit tests?

Yes!

You may be thinking that you don't require unit tests as you already have some well-defined end-to-end test cases which demonstrate that your code base works as expected. However, consider the case where this end-to-end test begins to fail. The message for this failure is likely to be something along the lines of

```
Expected my_special_number to be 1.234 but got 5.678
```

If you have a comprehensive understanding of your code, perhaps this is all you need. However, assuming the newest feature that caused this failure was not written by you, it's going to be difficult to identify what is going wrong without some lengthy debugging.

Now imagine the situation where this developer added unit tests for their new code. When running these unit tests, you may see something like

```
test_populate_arrays Failed: Expected 1 for index 1 but got 0
```

This is much clearer. We immediately have an idea of what could be going wrong and the unit test itself will help us determine the problematic code to investigate.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 2: Unit test bad practices

Take a look at [1-into-to-unit-tests/challenge](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/1-into-to-unit-tests/challenge) in the exercises repository.

:::::::::::::::::::::::::::::::: solution

A solution is provided in [1-into-to-unit-tests/solution](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/1-into-to-unit-tests/solution).

:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

## References

- David Thomas and Andrew Hunt (2019). [The Pragmatic Programmer: your journey to mastery](https://search.worldcat.org/search?q=bn:9780135957059), 20th Anniversary Edition, 2nd Edition. Addison-Wesley Professional.
