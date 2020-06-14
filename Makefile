
###
### Makefile for the C256 Utilities
###

ASM = /mnt/d/64tass/64tass.exe
ASM_ARGS = --long-address --flat -b --m65816
ASM_ARGS_HEX = --long-address --flat -b --m65816 --intel-hex
COMMON_DEPS = src/kernel.s src/macros.s src/bank0.s

all: build/mkboot.pgx

build/%.hex: src/%.s ${COMMON_DEPS}
	${ASM} ${ASM_ARGS_HEX} --list=build/$*.lst --labels=build/$*.lbl -o $@ $<

build/%.pgx: src/%.s ${COMMON_DEPS}
	${ASM} ${ASM_ARGS} --list=build/$*.lst -o $@ $<

clean:
	@echo "Cleaning up..."
	rm -rvf build/*.pgx build/*.hex build/*.lst build/*.lbl
