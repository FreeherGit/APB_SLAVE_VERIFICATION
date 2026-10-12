
# ==========================================
# APB Slave Verification - Vivado / XSim
# ==========================================

TOP       = tb_top
FILELIST  = filelist.f
TEST      ?= write

XVLOG     = xvlog
XELAB     = xelab
XSIM      = xsim

SNAPSHOT  = $(TOP)_sim
WAVE      = apb_wave.wdb
LOG       = sim.log

.PHONY: all compile elaborate run wave view clean \
        reset write read wait back_to_back error protocol \
        parameter walking1 overwrite

# Default target
all: run

# ==========================================
# Compile SystemVerilog sources
# ==========================================
compile:
	$(XVLOG) -sv -f $(FILELIST)

# ==========================================
# Elaborate the testbench
# ==========================================
elaborate: compile
	$(XELAB) $(TOP) -s $(SNAPSHOT)

# ==========================================
# Run simulation and save waveform
# ==========================================
run: elaborate
	$(XSIM) $(SNAPSHOT) -testplusarg TEST=$(TEST) \
		-wdb $(WAVE) -log $(LOG) -runall

# ==========================================
# Open waveform viewer
# ==========================================
view:
	$(XSIM) $(SNAPSHOT) -gui -view $(WAVE)

wave: view

# ==========================================
# Individual test targets
# ==========================================
reset:
	$(MAKE) run TEST=reset

write:
	$(MAKE) run TEST=write

read:
	$(MAKE) run TEST=read

wait:
	$(MAKE) run TEST=wait

back_to_back:
	$(MAKE) run TEST=back_to_back

error:
	$(MAKE) run TEST=error

protocol:
	$(MAKE) run TEST=protocol

parameter:
	$(MAKE) run TEST=parameter

walking1:
	$(MAKE) run TEST=walking1

overwrite:
	$(MAKE) run TEST=overwrite

# ==========================================
# Clean generated files
# ==========================================
clean:
	rm -rf xsim.dir .Xil *.jou *.log *.pb *.wdb *.vcd

