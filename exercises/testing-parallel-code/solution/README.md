# Testing parallel code - Solution

The solution is provided in [test_parallel_temp_conversions.pf](./test_parallel_temp_conversions.pf). Copy this file into the
challenge `test` directory to build and run the MPI-enabled tests.

The test suite runs with 1, 2, and 4 MPI processes. It checks that the combined results are returned on every rank in rank
order. The Celsius-to-Kelvin case also has fewer input values than ranks, so some ranks contribute empty arrays.
