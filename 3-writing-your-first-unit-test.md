---
title: "Writing your first unit test"
teaching:
exercises:
---

:::::::::::::::::::::::::::::::::::::: questions

- What does a unit test look like?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Understand the benefits of parameterized tests.
- Able to write a unit test which is isolated, minimal and fast.

::::::::::::::::::::::::::::::::::::::::::::::::

The key aspects of a unit test are the same no matter the language being testing
(python, Fortran, etc) or the framework we are using (pFUnit, etc). Therefore,
when we are first learning unit testing, it can be useful to think about what the
content of a unit test might look like before we try to learn the specific syntax
of any one tool.

## Testing the temperature

We'll now use an example Fortran library which converts between units of temperature.
This code can be found in the exercises repo under
[3-writing-your-first-unit-test/challenge/src/temp_conversions.f90][temp-lib]. This
library contains two functions, one to convert from Fahrenheit to Celsius
(`fahrenheit_to_celsius`) and another to convert from Celsius to Kelvin
(`celsius_to_kelvin`).

Imagine we want to use this library to do some temperature conversions from Fahrenheit
to Kelvin. To ensure the library contains the functionality we need, we decide to write
some unit tests.

:::::::::::::::::::::::::::::::::::::::: challenge

### Challenge: Pseudo test

Write a unit test in pseudocode for the temperature library to check that it can
convert from Fahrenheit to Kelvin.

::::::::::::::::::::::::::::::::::: solution

Your test could look something like this:

```txt
Set some input value of Fahrenheit, for example 32.0
Call fahrenheit_to_celsius with this input
Check that the output is equal to the expected value of 0.0

Set some input value of Celsius, for example 0.0
Call celsius_to_kelvin with this input
Check that the output is equal to the expected value of 273.15
```

::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::

## Writing a test

All unit tests tend to follow a similar pattern.

1. Define the inputs to your unit of code to be tested as well as the outputs you
   expect from execution with these inputs.

2. Setup and verify any state required for successful execution (verify a file exists,
   allocate memory, etc)

3. Call the unit of code to be tested using the inputs defined in the first step.

4. Verify the actual outputs of your unit of code with the expected outputs defined in the
   first step.

:::::::::::::::::::::::::::::::::::::::: challenge

### Challenge: Standard Fortran test

Write a unit test in standard Fortran for the temperature library to check that it can
convert from Fahrenheit to Kelvin. You can use your pseudocode as a starting point.

As we are not yet using a testing framework, some boilerplate code has been provided to
help you create a test-suite. Take a look at part one of the exercise
[3-writing-your-first-unit-test/challenge][exercises-challenge].

::::::::::::::::::::::::::::::::::: solution

A solution is provided in [3-writing-your-first-unit-test/solution][exercises-solution].

::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::

[temp-lib]: https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/3-writing-your-first-unit-test/challenge/src/temp_conversions.f90
[exercises-challenge]: https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/3-writing-your-first-unit-test/challenge
[exercises-solution]: https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/3-writing-your-first-unit-test/solution
