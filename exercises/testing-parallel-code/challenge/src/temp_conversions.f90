module temp_conversions
    use mpi, only : MPI_Allgather, MPI_Allreduce, MPI_INTEGER, MPI_MAX, MPI_MIN, MPI_REAL, MPI_Comm_size
    implicit none
    private
    public :: fahrenheit_to_celsius, celsius_to_kelvin
    public :: fahrenheit_to_celsius_parallel, celsius_to_kelvin_parallel

    abstract interface
        function scalar_conversion(temperature) result(converted)
            implicit none
            real, intent(in) :: temperature
            real :: converted
        end function scalar_conversion

    end interface

contains

    function fahrenheit_to_celsius(fahrenheit) result(celsius)
        real, intent(in) :: fahrenheit
        real :: celsius
        celsius = (fahrenheit - 32.0) * 5.0 / 9.0
    end function fahrenheit_to_celsius

    function celsius_to_kelvin(celsius) result(kelvin)
        real, intent(in) :: celsius
        real :: kelvin
        kelvin = celsius + 273.15
    end function celsius_to_kelvin

    subroutine fahrenheit_to_celsius_parallel(local_fahrenheit, all_celsius, communicator)
        real, intent(in) :: local_fahrenheit(:)
        real, allocatable, intent(out) :: all_celsius(:)
        integer, intent(in) :: communicator

        call convert_parallel(local_fahrenheit, all_celsius, communicator, fahrenheit_to_celsius)
    end subroutine fahrenheit_to_celsius_parallel

    subroutine celsius_to_kelvin_parallel(local_celsius, all_kelvin, communicator)
        real, intent(in) :: local_celsius(:)
        real, allocatable, intent(out) :: all_kelvin(:)
        integer, intent(in) :: communicator

        call convert_parallel(local_celsius, all_kelvin, communicator, celsius_to_kelvin)
    end subroutine celsius_to_kelvin_parallel

    subroutine convert_parallel(local_input, all_output, communicator, conversion)
        real, intent(in) :: local_input(:)
        real, allocatable, intent(out) :: all_output(:)
        integer, intent(in) :: communicator
        procedure(scalar_conversion) :: conversion

        integer :: ierr, num_processes, local_count, total_count, min_count, max_count, i
        real, allocatable :: local_output(:)

        call MPI_Comm_size(communicator, num_processes, ierr)
        local_count = size(local_input)
        call MPI_Allreduce(local_count, min_count, 1, MPI_INTEGER, MPI_MIN, communicator, ierr)
        call MPI_Allreduce(local_count, max_count, 1, MPI_INTEGER, MPI_MAX, communicator, ierr)
        if (min_count /= max_count) error stop "All ranks must provide the same number of temperatures"

        allocate(local_output(local_count))
        do i = 1, local_count
            local_output(i) = conversion(local_input(i))
        end do

        total_count = local_count * num_processes
        allocate(all_output(total_count))
        call MPI_Allgather(local_output, local_count, MPI_REAL, all_output, local_count, MPI_REAL, &
                           communicator, ierr)
    end subroutine convert_parallel

end module temp_conversions
