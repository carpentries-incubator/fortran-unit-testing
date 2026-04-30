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
