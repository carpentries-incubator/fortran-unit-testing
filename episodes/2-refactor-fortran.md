---
title: "Refactoring Fortran"
teaching:
exercises:
---

:::::::::::::::::::::::::::::::::::::: questions

- What does good Fortran code look like?
- How do I refactor Fortran code to follow best practices?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Be able to spot bad practice within Fortran code.
- Understand why following best practice make Fortran more testable.

::::::::::::::::::::::::::::::::::::::::::::::::

Within Fortran projects, it is common to find many instances of bad practice which makes it difficult,
if not impossible to implement unit tests. Therefore, in many cases, the first step to writing unit tests
for a Fortran project is to refactor some section of the code into a more testable state which follows
best practice. Examples of what we mean by "bad practice" would be not limited to but could include…

- Using global variables.
- Large, multi-purpose procedures.
- Undocumented variables, procedures, modules and programs.

To demonstrate the benefits of refactoring Fortran and how it can be done, we're going to help John to
improve his Fortran implementation of the game of life. A copy of John's code can be found in the
exercises repo at [2-refactoring-fortran/challenge](https://github.com/carpentries-incubator/fortran-unit-testing/tree/main/exercises/2-refactoring-fortran/challenge).

:::::::::::::::::::::::::::::::::::::::::::: spoiler

### Conway's Game of Life

Conway's Game of life is a cellular automaton devised by the British mathematician John Horton Conway in 1970 (Gardner, 1970).

The universe of the Game of Life is an infinite, two-dimensional orthogonal grid of square cells, each of which is in one of two possible states, live or dead (or populated and unpopulated, respectively). Every cell interacts with its eight neighbours, which are the cells that are horizontally, vertically, or diagonally adjacent. At each step in time, the following transitions occur:

1. Any live cell with fewer than two live neighbours dies, as if by underpopulation.
2. Any live cell with two or three live neighbours lives on to the next generation.
3. Any live cell with more than three live neighbours dies, as if by overpopulation.
4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

See the [Wikipedia article](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) for more details.

::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::: callout

### Checking we haven't broken anything

To ensure we don't break anything during our refactoring we need to have some way to test our code.
Since we don't have any automated tests in place we will need to do this manually. Firstly, let's
generate a starting state which we know to be correct.

```sh
cd episodes/7-refactoring-fortran/challenge
cmake -B build
cmake --build build
./build/game-of-life ../models/model-1.dat > initial-state.out
```

Then, whenever we make a change, we can test if the code still works as expected

```sh
cmake --build build
./build/game-of-life ../models/model-1.dat > new-state.out
diff initial-state.out new-state.out
```

If there are no differences, we can assume we haven't broken anything.

::::::::::::::::::::::::::::::::::::::::::::::::::::

## The known refactorings

The next few sections will present some known refactorings.

We'll show before and after code, present any new coding techniques needed to do the refactoring, and describe [code smells](https://en.wikipedia.org/wiki/Code_smell): how you know you need to refactor.

### 1. Replace magic numbers with constants

#### Smells

- Raw numbers appear in your code.

#### Benefits

- When we use constant with a clear name, it is instantly clear what that value represents.
- If we use a constant in more than one place, when that value needs to be changed, there is only one
  place we need to make an update.

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### Before

```f90
do i = 1, 100
    x = i * 3.141 / 100.0
    data(i) = sin(x)
end do
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### After

```f90
do i = 1, resolution
    x = i * pi / real(resolution)
    data(i) = sin(x)
end do
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge

Replace all magic numbers in John's game of life code with constants.

:::::::::::::::::::::::: solution

This can be achieved with the changes shown in this [commit](https://github.com/UCL-ARC/fortran-unit-testing-exercises/commit/e9765a26a9e368571eb162771cd45cd3933c03c4)

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::

### 2. Change of variable name

#### Smells

- Code needs a comment to explain what it is for.

#### Benefits

- Someone reading your code can instantly understand what a variable represents and is much more likely
  to understand the logic employed.

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### Before

```f90
a = a + b*dt
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### After

```f90
velocity = velocity + acceleration * dt
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge

Update any poorly named variables in John's code to have clear names
which make it clear what they are.

:::::::::::::::::::::::: solution

This can be achieved with the changes shown in this [commit](https://github.com/UCL-ARC/fortran-unit-testing-exercises/commit/30cfcceb1fc80ef236230e21dae574bdebf64c87)

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::

### 3. Break large procedures into smaller units

#### Smells

- A function or subroutine no longer fits on a page in your editor.
- Multiple dummy arguments are updated (i.e. multiple `intent(out)` arguments)
- A line of code is deeply indented
- A piece of code interacts with the surrounding code through just a few variables.

#### Benefits

- Procedures with only one purpose will be much easier to fix should a bug be introduced.
- Unit testing becomes easier as there are less input/output variables and scenarios to consider
  when writing your tests.

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### Before

```f90
module process_marices_mod
    implicit none
    real, allocatable :: A(:,:), B(:,:), C(:,:)

contains
    subroutine process_matrices(filename)
        character(len=*), intent(in) :: filename
        integer :: n, iostat, i, j, k
        integer :: unit
        real :: trace

        open(newunit=unit, file=filename, status='old', action='read', iostat=iostat)
        if (iostat /= 0) then
            print *, 'Error opening file: ', trim(filename)
            stop
        end if

        read(unit, *, iostat=iostat) n
        if (iostat /= 0) stop 'Error reading matrix size.'

        allocate(A(n,n), B(n,n))

        print *, 'Reading matrix A (', n, 'x', n, ')'
        do i = 1, n
            read(unit, *, iostat=iostat) (A(i,j), j=1,n)
            if (iostat /= 0) stop 'Error reading matrix A.'
        end do

        print *, 'Reading matrix B (', n, 'x', n, ')'
        do i = 1, n
            read(unit, *, iostat=iostat) (B(i,j), j=1,n)
            if (iostat /= 0) stop 'Error reading matrix B.'
        end do

        close(unit)

        C = 0.0
        do i = 1, n
            do j = 1, n
                do k = 1, n
                    C(i,j) = C(i,j) + A(i,k) * B(k,j)
                end do
            end do
        end do

        n = size(C, 1)
        trace = 0.0
        do i = 1, n
            trace = trace + C(i,i)
        end do

        print *, 'Trace of matrix C = ', trace
    end subroutine process_matrices
end module process_marices_mod
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### After

```f90
module process_marices_mod
    implicit none
    real, allocatable :: A(:,:), B(:,:), C(:,:)

contains

    subroutine read_matrices_from_file(filename)
        character(len=*), intent(in) :: filename
        integer :: n, iostat, i, j
        integer :: unit

        open(newunit=unit, file=filename, status='old', action='read', iostat=iostat)
        if (iostat /= 0) then
            print *, 'Error opening file: ', trim(filename)
            stop
        end if

        read(unit, *, iostat=iostat) n
        if (iostat /= 0) stop 'Error reading matrix size.'

        allocate(A(n,n), B(n,n))

        print *, 'Reading matrix A (', n, 'x', n, ')'
        do i = 1, n
            read(unit, *, iostat=iostat) (A(i,j), j=1,n)
            if (iostat /= 0) stop 'Error reading matrix A.'
        end do

        print *, 'Reading matrix B (', n, 'x', n, ')'
        do i = 1, n
            read(unit, *, iostat=iostat) (B(i,j), j=1,n)
            if (iostat /= 0) stop 'Error reading matrix B.'
        end do

        close(unit)
    end subroutine read_matrices_from_file

    subroutine multiply_matrices()
        integer :: i, j, k, n
        n = size(A, 1)

        allocate(C(n,n))

        C = 0.0
        do i = 1, n
            do j = 1, n
                do k = 1, n
                    C(i,j) = C(i,j) + A(i,k) * B(k,j)
                end do
            end do
        end do
    end subroutine multiply_matrices

    subroutine display_trace()
        integer :: i, n
        real :: trace

        n = size(C, 1)
        trace = 0.0
        do i = 1, n
            trace = trace + C(i,i)
        end do

        print *, 'Trace of matrix C = ', trace
    end subroutine display_trace
end module process_marices_mod
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge

Update John's code to reduce the responsibilities of any procedures to one

:::::::::::::::::::::::: solution

This can be achieved with the changes shown in this [commit](https://github.com/UCL-ARC/fortran-unit-testing-exercises/commit/fb06543e12e217e6f39ffc9df2f13108f64ca7ac)

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::

### 4. Wrap program functionality in procedures

#### Smell

- Logic is repeated outside a procedure.
- Loops appear outside a procedure.
- Lots of inline comments requited to explain what is happening in the main program.

#### Benefits

- More of your code can be tested.
- It becomes harder to introduce side effects which may impact other aspects of your code.

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### Before

```f90
program my_matrix_prog
    use process_marices_mod, only : process_matrices
    implicit none

    character(len=200) :: temp_string
    character(:), allocatable :: filename


    print *, 'Enter input filename:'
    read (*,*) temp_string
    filename = trim(temp_string)

    call process_matrices(filename)

end program my_matrix_prog
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### After

```f90
program my_matrix_prog
    use process_marices_mod, only : process_matrices
    implicit none

    character(:), allocatable :: filename

    call read_filename(filename)
    call process_matrices(filename)

contains

    subroutine read_filename(filename)
        character(:), allocatable, intent(out) :: filename

        character(len=200) :: temp_string

        print *, 'Enter input filename:'
        read (*,*) temp_string

        filename = trim(temp_string)
    end subroutine read_filename

end program my_matrix_prog
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge

Update John's code to reduce the responsibilities of any procedures to one

:::::::::::::::::::::::: solution

This can be achieved with the changes shown in this [commit](https://github.com/UCL-ARC/fortran-unit-testing-exercises/commit/ee860cac1cc2b1c2f0f2ed99b2fe26060e576ce4)

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::

### 5. Replace repeated code with a procedure

#### Smells

- Fragments of repeated code appear.

#### Benefits

- If logic needs to be updated in the future, there is now just one place this needs to be done
- More of your code can be unit tested.

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### Before

```f90
subroutine read_matrices_from_file(filename)
    character(len=*), intent(in) :: filename
    integer :: n, iostat, i, j
    integer :: unit

    open(newunit=unit, file=filename, status='old', action='read', iostat=iostat)
    if (iostat /= 0) then
        print *, 'Error opening file: ', trim(filename)
        stop
    end if

    read(unit, *, iostat=iostat) n
    if (iostat /= 0) stop 'Error reading matrix size.'

    allocate(A(n,n), B(n,n))

    print *, 'Reading matrix A (', n, 'x', n, ')'
    do i = 1, n
        read(unit, *, iostat=iostat) (A(i,j), j=1,n)
        if (iostat /= 0) stop 'Error reading matrix A.'
    end do

    print *, 'Reading matrix B (', n, 'x', n, ')'
    do i = 1, n
        read(unit, *, iostat=iostat) (B(i,j), j=1,n)
        if (iostat /= 0) stop 'Error reading matrix B.'
    end do

    close(unit)
end subroutine read_matrices_from_file
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### After

```f90
subroutine read_matrices_from_file(filename)
    character(len=*), intent(in) :: filename
    integer :: n, iostat, i, j
    integer :: unit

    open(newunit=unit, file=filename, status='old', action='read', iostat=iostat)
    if (iostat /= 0) then
        print *, 'Error opening file: ', trim(filename)
        stop
    end if

    read(unit, *, iostat=iostat) n
    if (iostat /= 0) stop 'Error reading matrix size.'

    allocate(A(n,n), B(n,n))

    print *, 'Reading matrix A (', n, 'x', n, ')'
    call read_next_matrix_from_file(A, unit)

    print *, 'Reading matrix B (', n, 'x', n, ')'
    call read_next_matrix_from_file(B, unit)

    close(unit)
end subroutine read_matrices_from_file

subroutine read_next_matrix_from_file(matrix, unit)
    real, allocatable, intent(inout) :: matrix(:,:)
    integer, intent(in) :: unit

    integer :: i, j, iostat, n

    n = size(matrix, 1)

    do i = 1, n
        read(unit, *, iostat=iostat) (matrix(i,j), j=1,n)
        if (iostat /= 0) stop 'Error reading matrix.'
    end do
end subroutine read_next_matrix_from_file
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: callout

There's a delicate balance between reducing code repetition and make your code
unreadable. Try not to go too far when refactoring!

:::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge

Update John's code to move any repeated code into a procedure.

:::::::::::::::::::::::: solution

This can be achieved with the changes shown in this [commit](https://github.com/UCL-ARC/fortran-unit-testing-exercises/commit/da18b6af1a01c82235975ed1589d0496cf6b23f2)

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::

### 6. Replace global variables with procedure arguments

#### Smells

- A global variable is assigned and then used inside a called function.
- A variable is edited within a procedure in which it is not declared.

#### Benefits

- Testing becomes much easier because your code is more isolated and thus less code is required within your tests to setup state.
- You get more help from your compiler and it t is much clearer what your code is doing as you can provide more information about dummy arguments such as their `intent`.

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### Before

```f90
subroutine multiply_matrices()
    integer :: i, j, k, n
    n = size(A, 1)

    allocate(C(n,n))

    C = 0.0
    do i = 1, n
        do j = 1, n
            do k = 1, n
                C(i,j) = C(i,j) + A(i,k) * B(k,j)
            end do
        end do
    end do
end subroutine multiply_matrices
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::: spoiler

#### After

```f90
subroutine multiply_matrices(A, B, C)
    real, allocatable, intent(int) :: A(:,:), B(:,:)
    real, allocatable, intent(out) :: C(:,:)

    integer :: i, j, k, n
    n = size(A, 1)

    allocate(C(n,n))

    C = 0.0
    do i = 1, n
        do j = 1, n
            do k = 1, n
                C(i,j) = C(i,j) + A(i,k) * B(k,j)
            end do
        end do
    end do
end subroutine multiply_matrices
```

::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge

Update John's code to replace any global variables accessed within procedures
with dummy arguments.

:::::::::::::::::::::::: solution

This can be achieved with the changes shown in this [commit](https://github.com/UCL-ARC/fortran-unit-testing-exercises/commit/02da8d0b614d7d7412a066fbdd3c249eb308f5a9)

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::

### 7. Separate code concepts into files or modules

#### Smells

- You find it hard to locate a piece of code.
- You get a lot of version control conflicts.

#### Benefits

- This adds further clarity about what each unit of code is responsible for.
- Allows further isolation of code as you can scope some procedures or variables to be private.

::::::::::::::::::::::::::::::::::::: spoiler

#### Before

Using the example we have seen so far, we start with two files
`my_matrix_prog.f90` and `process_marices_mod.f90`.

```
|-- project/directory/
    |-- my_matrix_prog.f90
    |   |-- subroutine read_filename
    |-- process_marices_mod.f90
        |-- subroutine read_matrices_from_file
        |-- subroutine read_next_matrix_from_file
        |-- subroutine multiply_matrices
        |-- subroutine display_trace
```

:::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: spoiler

#### After

If we split the procedures in these files across multiple modules which focus
on different tasks, we could end up with something like this.

```
|-- project/directory/
    |-- my_matrix_prog.f90
    |-- io.f90
    |   |-- subroutine read_filename
    |   |-- subroutine read_matrices_from_file
    |   |-- subroutine read_next_matrix_from_file
    |-- matrix_operations.f90
        |-- subroutine multiply_matrices
        |-- subroutine display_trace
```

> Note: there isn't one correct way to group these subroutines. For example, we
> could place `display_trace` in `io.f90`.

:::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

#### Challenge

Update John's code to separate code concepts into modules.

:::::::::::::::::::::::: solution

You should end up with a module structure. For example, like this:

```
|-- src/
    |-- main.f90
    |-- animation.f90
    |   |-- subroutine draw_board
    |-- cli.f90
    |   |-- subroutine read_cli_arg
    |-- game_of_life.f90
    |   |-- subroutine find_steady_state
    |   |-- subroutine evolve_board
    |   |-- subroutine check_for_steady_state
    |-- io.f90
        |-- subroutine read_model_from_file
```

This can be achieved with the changes shown in this [commit](https://github.com/UCL-ARC/fortran-unit-testing-exercises/commit/b4c6afcdb2e3a37c602051966e55ad764cdb6203)

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::: callout

## Working effectively with legacy code

When working with Fortran it is common that you will be working with legacy code and a
large scale refactor can feel daunting. Therefore, a great resource for us is
*[Working Effectively with Legacy Code](https://search.worldcat.org/title/660166658)*
(Feathers, 2004)

If you don't have time to read the entire book, there is a good summary of the key point in this blog post
[The key points of Working Effectively with Legacy Code](https://understandlegacycode.com/blog/key-points-of-working-effectively-with-legacy-code/)

:::::::::::::::::::::::::::::::

## References

- Martin Gardner, 1970. [The fantastic combinations of John Conway’s new solitaire game “life” by Martin Gardner](https://web.stanford.edu/class/sts145/Library/life.pdf). Scientific American, 223, pp.120–123.
- Michael Feathers (2004). [Working Effectively with Legacy Code](https://search.worldcat.org/title/660166658). Pearson.
