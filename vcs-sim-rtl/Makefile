#=======================================================================
# UCB VLSI FLOW: Makefile for vcs-sim-rtl
#-----------------------------------------------------------------------
# Yunsup Lee (yunsup@cs.berkeley.edu)
#
# This makefile will build a rtl simulator and run various tests to
# verify proper functionality.
#

include ../Makefrag

default : all

base_dir  = ..
sim_dir = .
output_dir = output
CONFIG = vlsi
timeout_cycles = 10000
disasm := 2>
which_disasm := $(shell which riscv-dis)
ifneq ($(which_disasm),)
	disasm := 3>&1 1>&2 2>&3 | $(which_disasm) $(DISASM_EXTENSION) >
endif

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

# Verilog sources

srcdir = $(base_dir)/src
sim_vsrcs = \
	$(srcdir)/const.vh \
	$(srcdir)/ALU.v \
	$(srcdir)/ALUdec.v \
	$(srcdir)/ALUop.vh \
	$(srcdir)/backup_mem.v \
	$(srcdir)/riscv_arbiter.v \
	$(srcdir)/Cache.v \
	$(srcdir)/controller.v \
	$(srcdir)/datapath.v \
	$(srcdir)/Memory141.v \
	$(srcdir)/Opcode.vh \
	$(srcdir)/Riscv141.v \
	$(srcdir)/riscv_test_harness.v \
	$(srcdir)/riscv_top.v \
	$(srcdir)/BranchPro.v \
	$(srcdir)/ImmProcess.v \
	$(srcdir)/MemWHB.v \
	$(UCB_VLSI_HOME)/stdcells/synopsys-32nm/multi_vt/verilog/sram.v \


vsrcs := \
	$(filter-out $(testbench_srcs), $(wildcard $(srcdir)/*.v)) \
	$(srcdir)/ALUTestbench.v \

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------



VCS = vcs -full64

# If don't use initreg/initmem, then get X propagated
# through everywhere
VCS_OPTS = -notice -line +lint=all,noVCDE,noONGS,noUI +warn=noTMR -error=PCWM-L -timescale=1ns/10ps -quiet \
	+incdir+$(srcdir) \
	+v2k +vcs+lic+wait \
	+vcs+initreg+0 \
	+vcs+initmem+0 \
	+rad \
	-top rocketTestHarness \
	-debug_pp \
	+define+CLOCK_PERIOD=$(vcs_clock_period) $(sim_vsrcs) \

#--------------------------------------------------------------------
# Build the simulator
#--------------------------------------------------------------------

simv = $(sim_dir)/simv-$(CONFIG)
$(simv) : $(sim_vsrcs)
	cd $(sim_dir) && \
	$(VCS) $(VCS_OPTS) -o $(simv) \

simv_debug = $(sim_dir)/simv-$(CONFIG)-debug
$(simv_debug) : $(sim_vsrcs)
	cd $(sim_dir) && \
	$(VCS) $(VCS_OPTS) -o $(simv_debug) \
	+define+DEBUG -debug_pp \


tests_isa_dir = $(base_dir)/tests/isa

	#asmtest \

asm_p_tests = \
	rv32ui-p-simple \


#--------------------------------------------------------------------
# Run
#--------------------------------------------------------------------

seed = $(shell date +%s)
exec_simv = $(simv) -q +ntb_random_seed_automatic
exec_simv_debug = $(simv_debug) -q +ntb_random_seed_automatic

#--------------------------------------------------------------------
# Run
#--------------------------------------------------------------------
asm_tests_out = $(foreach test, $(asm_p_tests), $(output_dir)/$(test).out)

asm_tests_vcd = $(foreach test, $(asm_p_tests), $(output_dir)/$(test).vcd)

asm_tests_vpd = $(foreach test, $(asm_p_tests), $(output_dir)/$(test).vpd)

asm_tests_saif = $(foreach test, $(asm_p_tests), $(output_dir)/$(test).saif)

$(output_dir)/%.out: $(tests_isa_dir)/%.hex  $(simv)
	mkdir -p $(output_dir)
	cd $(sim_dir) && $(exec_simv)  +verbose +max-cycles=$(timeout_cycles) +loadmem=$< $(disasm) $@ && [ $$PIPESTATUS -eq 0 ]

$(output_dir)/%.vcd: $(tests_isa_dir)/%.hex  $(simv_debug)
	mkdir -p $(output_dir)
	cd $(sim_dir) && $(exec_simv_debug)  +verbose +vcdfile=$@ +max-cycles=$(timeout_cycles) +loadmem=$< $(disasm) $(patsubst %.vcd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]

$(output_dir)/%.vpd: $(tests_isa_dir)/%.hex  $(simv_debug)
	mkdir -p $(output_dir)
	cd $(sim_dir) && $(exec_simv_debug)  +verbose +vcdplusfile=$@ +max-cycles=$(timeout_cycles) +loadmem=$< $(disasm) $(patsubst %.vpd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]

$(output_dir)/%.saif: $(output_dir)/%.hex  $(simv_debug)
	mkdir -p $(output_dir)
	cd $(sim_dir) && rm -f $(output_dir)/output_dirpipe-$*.vcd && vcd2saif -input $(output_dir)/pipe-$*.vcd -pipe "$(exec_simv_debug)  +verbose +vcdfile=$(output_dir)/pipe-$*.vcd +max-cycles=$(timeout_cycles) +loadmem=$<" -output $@ > $(patsubst %.saif,%.out,$@) 2>&1


run-asm-tests: $(asm_tests_out)
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' \
	       $(asm_tests_out); echo;

run: run-asm-tests 
	run-debug: run-asm-tests-debug 

.PHONY: run-asm-tests 
	.PHONY: run-asm-tests-debug 
.PHONY: run run-debug

junk += $(output_dir)

#--------------------------------------------------------------------
# Default make target
#--------------------------------------------------------------------

.PHONY: run

all : $(simv)

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------

junk += simv* *.vpd *.key DVE* .vcs* timestamp

clean :
	rm -rf $(junk) *~ \#* *.log *.cmd *.daidir
