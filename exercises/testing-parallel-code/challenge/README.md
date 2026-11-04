# Testing parallel code - Challenge: Rewrite serial test as a parallel test

This exercise aims to teach how to write pFUnit tests which test MPI-enabled code across different numbers of MPI
processes.

## The code

The [source code](./src) contains a small MPI library with two functions:

- `sum_all_rank_values(communicator)` sums each processor's one-based rank within the communicator. For `n` ranks, every rank receives
  `n * (n + 1) / 2`.
- `sum_preceding_rank_values(communicator)` returns the exclusive prefix sum of one-based ranks, giving rank `r` the value
  `r * (r + 1) / 2`. The first rank receives `0`, and each following rank gets a distinct value.

Both functions take an integer MPI communicator ID and return deterministic values. MPI must be initialized before either
function is called. Both functions are collective: all ranks in the communicator must call them in the same order.

Before building, select your compilers:

```sh
export OMPI_FC="$(which gfortran)"
export FC="$(which mpif90)"
```

Build the static library with CMake:

```sh
cmake -B build
cmake --build build
```

Or build it with Make:

```sh
make
```

The pFUnit tests cover communicators with 1, 2, and 4 ranks. Configure CMake with a pFUnit installation to build and run
them:

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

## Task

Write MPI enabled pFUnit tests for the each function in the `mpi_utils` library.

1. Write tests for `sum_all_rank_values` with MPI-enabled pFUnit.
2. Write tests for `sum_preceding_rank_values` with MPI-enabled pFUnit.
