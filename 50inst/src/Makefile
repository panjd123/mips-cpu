all: mips_tb

SRC_FILES = $(wildcard *.v) $(wildcard *.sv) $(wildcard *.vh)

mips_tb: $(SRC_FILES)
	@echo "Compiling $@..."
	iverilog -g2012 -o $@ $(SRC_FILES)
	mkdir -p output

run:
	vvp mips_tb

clean:
	rm -f mips_tb *.out *.txt
	rm -rf output