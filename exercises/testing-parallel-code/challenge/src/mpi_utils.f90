module mpi_utils
    use mpi, only : MPI_Comm_rank, MPI_Allreduce, MPI_Exscan, MPI_INTEGER, MPI_SUM
    implicit none
    private
    public :: sum_all_rank_values, sum_preceding_rank_values

contains

    !> Sum each rank's one-based rank value across the communicator.
    integer function sum_all_rank_values(communicator) result(value)
        !> MPI communicator containing the participating ranks.
        integer, intent(in) :: communicator
        integer :: ierr, rank, contribution

        call MPI_Comm_rank(communicator, rank, ierr)
        contribution = rank + 1
        call MPI_Allreduce(contribution, value, 1, MPI_INTEGER, MPI_SUM, communicator, ierr)
    end function sum_all_rank_values

    !> Return the sum of one-based rank values preceding this rank.
    integer function sum_preceding_rank_values(communicator) result(value)
        !> MPI communicator containing the participating ranks.
        integer, intent(in) :: communicator
        integer :: ierr, rank, contribution

        call MPI_Comm_rank(communicator, rank, ierr)
        contribution = rank + 1
        call MPI_Exscan(contribution, value, 1, MPI_INTEGER, MPI_SUM, communicator, ierr)
        if (rank == 0) value = 0
    end function sum_preceding_rank_values

end module mpi_utils
