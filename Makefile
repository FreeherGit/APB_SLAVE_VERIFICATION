TOP      = tb_top
FILELIST = filelist.f
TEST     ?= write

XVLOG = xvlog
XELAB = xelab
XSIM  = xsim
XCRG  = xcrg

SNAPSHOT = $(TOP)_sim
WAVE     = apb_wave.wdb
LOG      = sim.log

CC_DIR   = ./xsim.codeCov
COV_DIR  = ./xsim.covdb
REPORT   = ./cov_report

# Define all regression tests
TEST_LIST = reset write read wait back_to_back error protocol overwrite

.PHONY: all compile elaborate run view wave clean coverage_report $(TEST_LIST)

# Full regression: clean, elaborate ONCE, run all tests, build HTML report
all: clean elaborate
	@for t in $(TEST_LIST); do \
		echo "========================================"; \
		echo " REGRESSION: Running test '$$t'"; \
		echo "========================================"; \
		$(MAKE) run TEST=$$t || echo "WARNING: test '$$t' returned an error"; \
	done
	$(MAKE) coverage_report

compile:
	$(XVLOG) -sv -f $(FILELIST)

# Elaborate with code coverage (statement, branch, condition, toggle)
elaborate: compile
	$(XELAB) -cc_type sbct $(TOP) -s $(SNAPSHOT)

# Run without re-elaborating. xsim keeps coverage in memory, so the generated
# Tcl script runs the sim, then SAVES both databases under the test's name:
#   functional -> ./xsim.covdb/<test>/xsim.covinfo
#   code       -> ./xsim.codeCov/<test>/xsim.CCInfo
# -onfinish stop keeps the simulator alive after $finish so the save can happen.
# (xsim has no -cc_db/-cc_dir; those are xelab-only options.)
run:
	@printf 'run all\nwrite_xsim_coverage -cov_db_name %s\nquit\n' $(TEST) > $(TEST)_cov.tcl
	$(XSIM) $(SNAPSHOT) \
		-testplusarg TEST=$(TEST) \
		-wdb $(TEST)_$(WAVE) \
		-log $(TEST)_$(LOG) \
		-cov_db_name $(TEST) \
		-onfinish stop \
		-tclbatch $(TEST)_cov.tcl

# Merge functional + code coverage of every test that actually produced a DB
coverage_report:
	@if [ ! -d $(CC_DIR) ]; then \
		echo "ERROR: $(CC_DIR) not found - code coverage was not collected."; \
		echo "       Run 'make elaborate' and at least one 'make run TEST=<name>' first."; \
		exit 1; \
	fi
	@CC_ARGS=""; FOUND=""; FUNC_ARGS=""; \
	if [ -d $(COV_DIR) ]; then FUNC_ARGS="-dir $(COV_DIR)"; fi; \
	for t in $(TEST_LIST); do \
		if [ -f $(CC_DIR)/$$t/xsim.CCInfo ]; then \
			CC_ARGS="$$CC_ARGS -cc_db $$t"; FOUND="$$FOUND $$t"; \
		fi; \
	done; \
	if [ -z "$$CC_ARGS" ]; then \
		echo "ERROR: no per-test code coverage DBs in $(CC_DIR). Contents:"; \
		ls -R $(CC_DIR); \
		exit 1; \
	fi; \
	echo "Merging code coverage from:$$FOUND"; \
	$(XCRG) $$FUNC_ARGS -cc_dir $(CC_DIR) $$CC_ARGS \
		-report_dir $(REPORT) -report_format html
	@echo "Reports written under $(REPORT)/ (code coverage: $(REPORT)/codeCoverageReport/)"

view:
	$(XSIM) $(SNAPSHOT) -gui -view $(TEST)_$(WAVE)

wave: view

# Single-test shortcuts
$(TEST_LIST):
	$(MAKE) run TEST=$@

# Wipe all generated files, including both coverage databases
clean:
	rm -rf xsim.dir .Xil *.log *.jou *.pb *.wdb *_cov.tcl xsim.covdb xsim.codeCov cov_report
