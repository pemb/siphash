GHDL=ghdl
GHDLFLAGS= --ieee=synopsys

# Default target
all: tb_siphash

# Elaboration target
tb_siphash: tb_siphash.o siphash.o sipround.o
	$(GHDL) -e $(GHDLFLAGS) $@

# Run target
run: tb_siphash
	$(GHDL) -r tb_siphash $(GHDLRUNFLAGS) < test_vector

# Targets to analyze files
tb_siphash.o: tb_siphash.vhd siphash_package.o
	$(GHDL) -a $(GHDLFLAGS) $<
siphash.o: siphash.vhd siphash_package.o
	$(GHDL) -a $(GHDLFLAGS) $<
sipround.o: sipround.vhd siphash_package.o
	$(GHDL) -a $(GHDLFLAGS) $<
siphash_package.o: siphash_package.vhd
	$(GHDL) -a $(GHDLFLAGS) $<

.PHONY: clean

clean:
	rm -f *.o work-obj93.cf tb_siphash
