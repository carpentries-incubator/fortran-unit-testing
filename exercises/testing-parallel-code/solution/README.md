# Testing parallel code - Solution

The solution is provided in [test_parallel_temp_conversions.pf](./test_parallel_temp_conversions.pf). Copy this file into the
challenge `test` directory to build and run the MPI-enabled tests.

The test suite runs with 1, 2, and 4 MPI processes. Each rank receives an allocatable input array of the same length for
its test case. The tests check that the combined results are returned on every rank in rank order.
