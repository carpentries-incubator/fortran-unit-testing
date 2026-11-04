PFUNIT_INCLUDE_DIR ?= /home/vscode/pfunit/build/installed/PFUNIT-4.12/include
USEMPI = YES

ifneq ($(MAKECMDGOALS),clean)
include $(PFUNIT_INCLUDE_DIR)/PFUNIT.mk
TEST_FLAGS = -I$(BUILD_DIR) $(FC_FLAGS) $(PFUNIT_EXTRA_FFLAGS)
endif

tests_TESTS = \
	test_sum_all_rank_values.pf \
	test_sum_preceding_rank_values.pf
tests_OTHER_SOURCES = $(SRC_OBJS)
tests_OTHER_LIBRARIES = $(TEST_FLAGS)

$(eval $(call make_pfunit_test,tests))

%.o: %.F90
	$(FC) -c $(TEST_FLAGS) $<

clean:
	rm -f *.o *.mod *.F90 *.inc tests
