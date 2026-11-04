ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
FC = mpif90
AR = ar
FC_FLAGS ?= -O2
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_DIR = $(ROOT_DIR)/test

LIBRARY = $(BUILD_DIR)/libmpi_utils.a
SRC_OBJS = $(BUILD_DIR)/mpi_utils.o
MODULE = $(BUILD_DIR)/mpi_utils.mod
SOURCE = $(ROOT_DIR)/src/mpi_utils.f90

.PHONY: all tests clean

all: $(LIBRARY)

$(BUILD_DIR):
	mkdir -p $@

$(SRC_OBJS): $(SOURCE) | $(BUILD_DIR)
	$(FC) $(FC_FLAGS) -J$(BUILD_DIR) -c $< -o $@

$(LIBRARY): $(SRC_OBJS)
	$(AR) rcs $@ $<

tests: $(SRC_OBJS)
	$(MAKE) -C $(TEST_DIR) tests

clean:
	$(MAKE) -C $(TEST_DIR) clean
	rm -f $(LIBRARY) $(SRC_OBJS) $(MODULE)

export BUILD_DIR
export FC
export FC_FLAGS
export LIBRARY
export ROOT_DIR
export SRC_OBJS
export TEST_DIR
