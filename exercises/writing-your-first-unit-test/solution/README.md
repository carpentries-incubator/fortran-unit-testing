# Writing your first unit test - Solution

## Part 1 - Test with Standard Fortran

The solution is provided in the form of a single test file [standard_fortran/test_temp_conversions.f90](./standard_fortran/test_temp_conversions.f90)
which replaces the file of the same name provided in the
[challenge/test/standard_fortran](../challenge/test/standard_fortran/) directory.

### Key points

There are several key aspects within the solution that are important to implement in any test.

#### Isolated test subroutine

Each test subroutine in [standard_fortran/test_temp_conversions.f90](./standard_fortran/test_temp_conversions.f90) calls and tests
only one src function. For example, `test_fahrenheit_to_celsius` calls and tests `fahrenheit_to_celsius` and
`test_celsius_to_kelvin` calls and tests `celsius_to_kelvin`.

This is important as, in the event of a test failing it will be clear which src function is the cause of the failure.
If instead we had implemented a single test subroutine which calls both `test_fahrenheit_to_celsius` and
`fahrenheit_to_celsius`, then a failure in such a test could have been caused by either of those src functions and further
investigation would be required.

#### Parameterised tests

Each test subroutine in [standard_fortran/test_temp_conversions.f90](./standard_fortran/test_temp_conversions.f90) takes in an
`input` and an `expected_output`. This allows the same test subroutine to be called with multiple different inputs to test several
scenarios with the same test code. Therefore, we are able to test edge cases and other key scenarios more easily.

#### Clear failure message

Each test subroutine in [standard_fortran/test_temp_conversions.f90](./standard_fortran/test_temp_conversions.f90) populates
`failure_message` with a clear message that aims to make it as easy as possible to diagnose a failing test. Importantly, the
`failure_message` includes the `input`, the `expected_output` and the actual value which we have compared to the `expected_output`.

#### Comparing floats within an appropriate tolerance

We cannot compare two floats directly as due to rounding errors they will almost always
not be exactly the same. Therefore, we must check the difference between two floats that
we expect to be equal and ensure it is less than some appropriate tolerance. This tolerance
should be as small as possible whilst still making sense with the code we are testing.

## Part 2 - Convert tests to use pFUnit

### Writing the test

The solution is provided in the form of a single test file [pfunit/test_temp_conversions.pf](./pfunit/test_temp_conversions.pf)
which replaces the file of the same name provided in the [challenge/test/pfunit](../challenge/test/pfunit/) directory. The key
points mention within [Part 1](#key-points) are upheld in this solution. Any additional points are detailed below.

#### Parameterised tests

It may appear that these solutions are parameterised, however, if one instance of `verify_fahrenheit_to_celsius` or
`verify_celsius_to_kelvin` should fail, all future calls would be skipped which means we don't see the full picture. For how to
truly parameterise pFUnit tests, see Part 3.

### Building the test

- **i. Build your new test(s) with Make**
  - A solution is provided in [pfunit/Makefile](./pfunit/Makefile).
- **ii. Build your new test(s) with CMake**
  - A solution is provided in [pfunit/CMakeLists.txt](./pfunit/CMakeLists.txt).

## Part 3 - Parameterise your pFUnit test

The solution is provided in the form of the test file
[pfunit/test_temp_conversions_parameterised.pf](./pfunit/test_temp_conversions_parameterised.pf).
To add this parameterised test to your build there should be some lines to uncomment in the provided solution files -
[pfunit/Makefile](./pfunit/Makefile) and [pfunit/CMakeLists.txt](./pfunit/CMakeLists.txt).

#### Add a description for each test

This in-built pFUnit parameterisation also allows us to provide a description for each set of parameters in
[test_temp_conversions_parameterised.pf](./pfunit/test_temp_conversions_parameterised.pf) which aims to make clear what is being
tested. This can be useful when thinking about test coverage of edge cases. It can also help in the event of a test failure to hint
at what the problem may be.
