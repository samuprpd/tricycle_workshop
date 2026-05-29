PWD := $(realpath .)
.PHONY: verilator c_test asm_test isa_test _isa_test

# RISC-V Cross compiler config
RV_CROSS    := $(HOME)/opt/bip/bin/riscv64-unknown-elf-
RV_CC       := $(RV_CROSS)gcc
RV_DMP      := $(RV_CROSS)objdump
RV_OBJCPY   := $(RV_CROSS)objcopy
RV_ISA      := -march=rv32i -mabi=ilp32
OPT_LEVEL   := -O0
RV_CC_FLAGS := $(RV_ISA) $(OPT_LEVEL) -Wall -Wextra -nostartfiles -Wl,--no-warn-rwx-segments -I. 
ISA_TEST_SET := "base rv32ui"

# Verilator config
VV := verilator
VTARGET := Vtop
TOP_MODULE := top
CPP_SRC := testbench/testbench.cpp
CPP_TB_FLAGS := -march=native -std=c++20 -Wall -Wextra 
ALL_SV_MODULES := $(shell find rtl -name "*.sv")

# Verilator build

obj_dir/$(VTARGET): obj_dir/.verilator.stamp
	make -C obj_dir -f Vtop.mk

# Verilate files
obj_dir/.verilator.stamp: rvtarget.h Makefile $(CPP_SRC) $(ALL_SV_MODULES)

	$(VV) -Wall -F tricycle.f testbench/top.sv \
	--top-module ${TOP_MODULE} \
	--x-assign unique --x-initial unique $(VTRACE_FLAGS) \
	--cc -CFLAGS "-I$(PWD) $(CPP_TB_FLAGS) $(CPP_TRACE_FLAG)" \
	--exe $(CPP_SRC)

	touch obj_dir/.verilator.stamp

# Wave (gtkwave) trace visualizer
gtkwave: clean
	make -s VTRACE_FLAGS="--trace --trace-structs" CPP_TRACE_FLAG="-DTRACE_WAVE"

BUILDIR := build
LINKER_FILE := linker.lds 

# ISA test battery

ISA_TEST := base/base.S
ISA_TEST_DIR := $(dir $(ISA_TEST))
ISA_TEST_NAME := $(shell basename $(ISA_TEST) .S)
ISA_TARGET_DIR := $(BUILDIR)/$(ISA_TEST_DIR)

_isa_test: 
	@mkdir -p $(ISA_TARGET_DIR)
	@$(RV_CC) $(RV_CC_FLAGS) isa_test/$(ISA_TEST) -I isa_test/macros -T$(LINKER_FILE) -o $(ISA_TARGET_DIR)/$(ISA_TEST_NAME).elf
	@$(RV_OBJCPY) -O binary $(ISA_TARGET_DIR)/$(ISA_TEST_NAME).elf $(ISA_TARGET_DIR)/$(ISA_TEST_NAME).bin
	@$(RV_DMP) -D $(ISA_TARGET_DIR)/$(ISA_TEST_NAME).elf > $(ISA_TARGET_DIR)/$(ISA_TEST_NAME).dmp

# C/ASM example

TEST := c_test
TEST_SCRS := $(shell find $(TEST) -name "*.c") $(shell find $(TEST) -name "*.S")
TEST_ELF := $(BUILDIR)/$(TEST)/$(TEST).elf
TEST_BIN := $(BUILDIR)/$(TEST)/$(TEST).bin
TEST_DMP := $(BUILDIR)/$(TEST)/$(TEST).dump

$(TEST_BIN): $(TEST_SCRS) Makefile
	mkdir -p $(dir $@)
	$(RV_CC) $(RV_CC_FLAGS) -T$(LINKER_FILE) $(TEST_SCRS) -o $(TEST_ELF)
	$(RV_OBJCPY) -O binary $(TEST_ELF) $(TEST_BIN)
	$(RV_DMP) -D $(TEST_ELF) > $(TEST_DMP)

# Helpers Fast calls

test: gtkwave obj_dir/$(VTARGET)
	python isa_test/isa_test.py $(ISA_TEST_SET)

c_test: obj_dir/$(VTARGET)
	@make -s TEST=c_test build/c_test/c_test.bin
	@./obj_dir/Vtop -e build/c_test/c_test.bin

asm_test: obj_dir/$(VTARGET)
	@make -s TEST=asm_test build/asm_test/asm_test.bin
	@./obj_dir/Vtop -e build/asm_test/asm_test.bin

mul_bench: obj_dir/$(VTARGET)
	@make -s TEST=mul_bench build/mul_bench/mul_bench.bin
	@./obj_dir/Vtop -e build/mul_bench/mul_bench.bin; echo ""

# Cleanup
clean:
	rm -rf obj_dir fails build *.vcd

