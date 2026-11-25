# Testing parallel code - Challenge: Test parallel temperature conversions

This exercise teaches how to write pFUnit tests for MPI-enabled procedures across different numbers of MPI processes.

## The code

The [source code](./src) contains the `temp_conversions` module from the
[Writing your first unit test exercise](../writing-your-first-unit-test/challenge/README.md), with the original scalar
functions `fahrenheit_to_celsius` and `celsius_to_kelvin`. It also provides MPI procedures
`fahrenheit_to_celsius_parallel` and `celsius_to_kelvin_parallel`.

The `fahrenheit_to_celsius_parallel` and `celsius_to_kelvin_parallel` procedures take each rank's allocatable local array
and an MPI communicator. All ranks must provide arrays of the same length. The procedures convert the local values and
return the combined converted array on every rank, ordered by rank. All ranks in the communicator must call the procedures
in the same order.

Before building, select your compilers:

```sh
export OMPI_FC="$(which gfortran)"
export FC="$(which mpif90)"
```

Build the library with CMake:

```sh
cmake -B build-cmake
cmake --build build-cmake
```

Or build it with Make:

```sh
make
```

## The task

Write MPI-enabled pFUnit tests for both parallel conversion procedures.

1. Test both parallel conversion procedures with multiple ranks.
2. Check that the full output is returned on every rank, in rank order, and that results match the corresponding scalar conversion.
3. Use inputs that divide evenly across the 1-, 2-, and 4-process test cases so every rank receives an equal-sized array.

The pFUnit test should cover different communicator sizes (for example 1, 2, and 4 processes). Use the communicator and rank
information provided by `MPITestCase`; do not initialize or finalize MPI yourself.

With CMake, configure using a pFUnit installation and run the tests:

```bash
cmake -S . -B build-cmake \
  -DCMAKE_PREFIX_PATH=/path/to/pfunit/install
cmake --build build-cmake
ctest --test-dir build-cmake --output-on-failure
```

With Make, provide the directory containing `PFUNIT.mk`:

```bash
PFUNIT_INCLUDE_DIR=/path/to/pfunit/include uv run make tests
mpirun -n 4 ./test/tests --verbose
```

> If you are using the devcontainer, pFUnit is installed at `/home/vscode/pfunit/build/installed`.
