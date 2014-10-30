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

basedir  = ..

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

# Verilog sources

srcdir = $(basedir)/src
testbench_srcs := $(wildcard $(srcdir)/*Testbench*.v)

vsrcs := \
	$(filter-out $(testbench_srcs), $(wildcard $(srcdir)/*.v)) \
	$(srcdir)/ALUTestbench.v \


#
#	$(UCB_VLSI_HOME)/stdcells/synopsys-32nm/multi_vt/verilog/pll.v \
#	$(UCB_VLSI_HOME)/stdcells/synopsys-32nm/multi_vt/verilog/io_wb.v \
#	$(UCB_VLSI_HOME)/stdcells/synopsys-32nm/multi_vt/verilog/sram.v \


testvector := testvectors.input
pythontestvectorfile := ALUTestGen.py
$(testvector) : 
	python $(pythontestvectorfile)

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

VCS      = vcs -full64
VCS_OPTS = -notice -PP -line +lint=all,noVCDE +v2k -timescale=1ns/10ps -debug

#--------------------------------------------------------------------
# Build the simulator
#--------------------------------------------------------------------

vcs_sim = simv
$(vcs_sim) : Makefile $(vsrcs) $(testvector) $(pythontestvectorfile)
	$(VCS) $(VCS_OPTS) +incdir+$(srcdir) -o $(vcs_sim) \
	       +define+CLOCK_PERIOD=$(vcs_clock_period) \
	       $(vsrcs)

#--------------------------------------------------------------------
# Run
#--------------------------------------------------------------------

vpd = vcdplus.vpd
$(vpd): $(vcs_sim)
	./simv +verbose=1
	date > timestamp

run: $(vpd)

#--------------------------------------------------------------------
# Default make target
#--------------------------------------------------------------------

.PHONY: run

all : $(vcs_sim)

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------

junk += simv* csrc *.vpd *.key DVE* .vcs* timestamp

clean :
	rm -rf $(junk) *~ \#* *.log *.cmd *.daidir
