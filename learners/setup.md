---
title: "Setup"
---

## Exercises repository

Throughout this walkthrough, we will use the Fortran [exercises](../exercises/) defined within this repo.

### Codespaces

The exercises repository is setup to work via GitHub codespaces. This process is documented in the
[README.md of the exercises](../exercises/README.md).

#### TL;DR

You can open the exercises repository within a container running on a GitHub server with all dependencies pre-built and installed.
To do this, click select the `<> Code` drop-down within the repository home page. Then, from the codespaces tab, select
`Create codespace on main`.

::::::::::::::::::::::::::::::::::::::::::::::: spoiler

### Running locally outside of container

If you do not wish to use GitHub Codespaces or the VSCode devcontainer, you can build/install the relevant dependencies on your
local machine.

#### Software Setup

To following along with this lesson's exercises you will require the following

- CMake
- pFUnit

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge: Install the above dependencies

Try to install the dependencies listed above.

- CMake can be installed via [homebrew](https://formulae.brew.sh/formula/cmake) on mac or your package manager (apt, etc) on Linux.
- pFUnit can be install via the bash script provided [build-pfunit.sh](../scripts/build-pfunit.sh).

:::::::::::::::::::::::::::: solution

```bash
$ cmake --version
cmake version 3.27.0

$ ./build-pfunit.sh -t -p <path/to/pfunit/src/dir>
[  0%] Built target posix_predefined.x
[  0%] Built target generate_posix_parameters
[ 19%] Built target funit-core
[ 33%] Built target fhamcrest
[ 55%] Built target asserts
[ 56%] Built target funit-main
[ 56%] Built target funit
[ 57%] Built target pfunit-core
[ 58%] Built target pfunit
[ 59%] Built target new_ptests
[ 60%] Built target new_ptests.x
[ 62%] Built target other_shared
[ 67%] Built target funit_tests
[ 68%] Built target funit_tests.x
[ 69%] Built target robust
[ 70%] Built target remote.x
[ 72%] Built target robust_tests.x
[ 88%] Built target new_tests.x
[ 97%] Built target fhamcrest_tests.x
[ 99%] Built target pfunittests
[100%] Built target parallel_tests.x
[100%] Built target build-tests
      Start  1: unit_test_processor
 1/14 Test  #1: unit_test_processor ........................   Passed    0.09 sec
      Start  2: processor_test_MpiParameterizedTestCaseC
 2/14 Test  #2: processor_test_MpiParameterizedTestCaseC ...   Passed    0.32 sec
      Start  3: processor_test_MpiTestCaseB
 3/14 Test  #3: processor_test_MpiTestCaseB ................   Passed    0.08 sec
      Start  4: processor_test_ParameterizedTestCaseB
 4/14 Test  #4: processor_test_ParameterizedTestCaseB ......   Passed    0.06 sec
      Start  5: processor_test_TestA
 5/14 Test  #5: processor_test_TestA .......................   Passed    0.07 sec
      Start  6: processor_test_TestCaseA
 6/14 Test  #6: processor_test_TestCaseA ...................   Passed    0.06 sec
      Start  7: processor_test_beforeAfter
 7/14 Test  #7: processor_test_beforeAfter .................   Passed    0.06 sec
      Start  8: processor_test_simple
 8/14 Test  #8: processor_test_simple ......................   Passed    0.06 sec
      Start  9: old_tests
 9/14 Test  #9: old_tests ..................................   Passed    0.05 sec
      Start 10: robust_tests.x
10/14 Test #10: robust_tests.x .............................   Passed    0.02 sec
      Start 11: new_tests.x
11/14 Test #11: new_tests.x ................................   Passed    0.03 sec
      Start 12: fhamcrest_tests.x
12/14 Test #12: fhamcrest_tests.x ..........................   Passed    0.02 sec
      Start 13: mpi-tests
13/14 Test #13: mpi-tests ..................................   Passed    0.19 sec
      Start 14: new_ptests
14/14 Test #14: new_ptests .................................   Passed    0.12 sec

100% tests passed, 0 tests failed out of 14

Total Test time (real) =   1.26 sec
```

:::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::
