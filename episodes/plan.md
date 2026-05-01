# Plan for this walkthrough

This file contains a rough plan for the walkthrough and will be removed from the final product.

## Episodes

### 1. Introduction and getting the walkthrough src code

Objectives

- [ ] Can clone the provided repo for the walkthrough.
- [ ] Understand the objectives of this walkthrough.

### 2. Intro to unit tests

Objectives

- [ ] Able to define the key aspects of a unit test (isolated, testing minimal functionality, fast, etc).
  - *Assessment:* Identify aspects of a test which does not follow all of these.
- [ ] Understand the key anatomy of a unit test in any language (given-when-then, starting state, assertions, fixtures, expected outputs, etc).
  - *Assessment:* Write a unit test in sudo code.
- [ ] Can explain the benefit of unit tests on top of integration/e2e tests.
  - Could use a narrative to highlight how an e2e failure does not show where in the code the bug exists.
    - A new member of the team is adding a feature and some existing e2e tests start failing.
    - They don't realize but this due to their edit of an intent in struct/type (`intent(in)` is not respected for these).
    - A unit test of this procedure would have highlighted that it was this function that had been broken.
- [ ] Understand when to run unit tests.

### 3. Intro to unit testing in Fortran

Objectives

- [ ] Understand the need for unit testing Fortran code.
- [ ] Able to identify Fortran code which is problematic for unit testing.
  - *Assessment:* Refactor a procedure to make it more testable.
  - *Assessment:* Highlight problematic aspects of difficult to test code.

### 6. Fortran unit test syntax

Objectives

- [ ] Able to write a unit test for a Fortran procedure with test-drive, veggies and/or pFUnit.
  - *Assessment:* Given a procedure, ask learner to write a unit test.
- [ ] Understand the similarities between each framework and where they differ.
  - *Assessment:* Assign the labels for shared unit test anatomy to sections of tests written with each framework.
  - *Assessment:* Provide a test in one framework and ask learners to reproduce in another.

### 7. Debugging a broken test

Objectives

- [ ] Can build and edit the provided repo for the walkthrough.
  - *Assessment:* Following the build instructions successfully builds the code.
  - *Assessment:* Following the instructions successfully runs the pre-existing tests.
- [ ] Capable of determining where in the tests or src code the failure is occurring.
  - *Assessment:* Starting from a failing test, find the failing test-suite/module/procedure/line
- [ ] Can fix a failing test.
  - *Assessment:* Starting from a failing test, update the code so the test passes
- [ ] Understand where a test is defined in the build system (CMake and FPM).
  - *Assessment:* Add a new test to the build system
  - *Assessment:* Update the name of a test in the build system
  - *Assessment:* Enabled and fix a disabled test which is broken.
- [ ] Understand the failure output of a Fortran unit test written in…
  - *Assessment:* Starting from a failing test, update the code so the test passes

### 8. Adding a test for an untested feature

Objectives

- [ ] Able to add a test for a completely untested feature/procedure.
  - *Assessment:* Write a test for an untested feature and add to the build system.

### 9. Testing parallel code

Objectives

- [ ] Understand what is different when testing parallel vs serial code.
  - *Assessment:* Provide a test and/or a command to run a test for serial code and ask what needs to change to test parallel code
  - *Assessment:* Provide two versions of a code (serial and parallel) with a test for the serial version and ask learners to write a test for the parallel version.
