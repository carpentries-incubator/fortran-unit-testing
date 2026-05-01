# Fortran unit testing lesson

A lesson for teaching how to unit test Fortran code.

## Building the website locally

From within RStudio run the following commands. First, install the needed dependencies.

```r
install.packages(c("sandpaper", "varnish", "pegboard")) # This may not need to be called as frequently as the following commands
```

Then can build the site

```r
setwd('/path/to/fortran-unit-testing-lesson')
sandpaper::build_lesson()
```

This will create a local build of the site at [site/docs/index.html](./site/docs/index.html).

## Dependencies

This repo utilises [fortitude](https://fortitude.readthedocs.io/en/stable/) alongside [pre-commit](https://pre-commit.com/) for
linting. To install these tools we use pip therefore contributors will require python version 3.9 or above.

To setup pre-commit and fortitude

1. Create a python virtual environment and activate it

   ```sh
   python3 -m venv .venv
   source .venv/bin/activate # or `source .venv/scripts/activate` on windows
   ```

2. Install the dev dependencies

   ```sh
   python -m pip install -r requirements.txt
   ```

3. Turn on pre-commit

   ```sh
   pre-commit install
   ```
