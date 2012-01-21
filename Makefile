sim : 6502.c 6502.h simmain.c myops.s
	gcc -g -o sim myops.s 6502.c simmain.c
