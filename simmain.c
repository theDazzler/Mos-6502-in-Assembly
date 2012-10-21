// simmain.c -- A (very) simple driver program for 6502 simulator
//
// Memory map for the simulated system:
// $0000 - $0100 	Zero page
// $0100 - $01FF	System stack
// $EF00 - $EFFF	Memory-mapped I/O area
// $FFFA - $FFFF	Interrupt table


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "6502.h"
extern BYTE a_reg,x_reg,y_reg,flag_reg,s_reg;
extern WORD pc_reg;


WORD addrmask = 0xffff; // We're simulating a 6502 accessing a full 64KB of
						// RAM here, but many systems had much less RAM
						// than that. The address mask allows us to progressively
						// mask bits off the left of memory addresses. In
						// hardware, fewer bits = few pins and fewer traces
						// on the circuit board.

BYTE *memImage; // Pointer to our (simulated) system RAM.


WORD code_location = 0xC000; // A traditional place to put a 6502
							 // program in memory.
									  


// Initialize the system RAM -- all mighty 64k of it!
// To be nice, we're going to fill most of RAM not with zeros by default...
// but with nops.... in case you run for too many cycles.
void initMem()
{
	memImage = malloc(65536*sizeof(BYTE));
	memset(memImage, 0x42, sizeof(BYTE)*65536); // Nops for all!
	
	// Except the I/O registers, which we will initialize to 0
	memImage[0xEF00] = 0;
	memImage[0xEF01] = 0;
	memImage[0xEF02] = 0;

}


// Print the current state of the 6502 registers to stdout.
void dump6502reg()
{
	printf(" A: %d\n X: %d\n Y: %d\n S: 0x%X\n P: 0x%X\nPC: 0x%X\n",A,X,Y,S,P,PC);
}

// Print a memory location to stdout.
void dumpMem(WORD memloc)
{
	printf("[0x%X]: %d\n",memloc,get6502memory(memloc));
}

// Convert a character to a value, assuming it's a hex digit. Return the
// value as an unsigned byte.
inline char ASCIIHextoValue(char ascii)
{
	if(ascii>57) return(ascii-65+10);
	else return(ascii-48);
}

// Load ASCII "object code" from a string ('object_code') into memory at location 'memptr',
// converting to the proper, numeric, representation, of course.
void loadMem(char *object_code, WORD memptr)
{
	char *sptr;
	char a,b;
	
	sptr = object_code;
	
	while(*sptr != '\0') {
		a = *sptr; sptr++; 
		b = *sptr; sptr++;
		if (*sptr != '\0') sptr++; // Read space between hex codes
		a = 16*ASCIIHextoValue(a) + ASCIIHextoValue(b);
		put6502memory(memptr, a);
		memptr++;
	}

}


// Utility function to read an "6502 ASCII Object File" into a string
char * read_obj_file(char *filename)
{
	FILE *fp;
	char *ascii;
	
	fp = fopen(filename,"r");
	if(fp == NULL) {
		printf("ASCII Object file %s not found.\n", filename);
		exit(-1);
	}
	
	// Find the end of the file and use it to set the length.
	fseek(fp, 0, SEEK_END);
	long int length = ftell(fp);
	
	rewind(fp); // Back to the beginning of the file!
	
	// Allocate space to read the string into
	ascii = malloc(sizeof(char)*(length+1));
	
	// Read the whole file into one big string.
	fread(ascii,1,length,fp);
	
	return ascii;
	
	// R'uh oh -- we allocated memory here that we didn't free.
	// Any thoughts on why this might be evil?
}



// Main program for our 6502 system simulator.
// Loads an "ASCII Object File" specified on the command line and runs it.
// None of the heavy lifting is done here -- this is all just wrappers for I/O,
// basic initialization, etc. All the simulation code is in 6502.c and my6502.s.

		// Stuff that's indented by a tab isn't core to the assignment at hand, it's
		// just some nice stuff I've added in to make life easier.

int main(int argc, char **argv)
{
	int cycles_to_run;
	
	char *machine_code; // This will hold our "ASCII Object File"
	
	char debug_command[180]="init";
	char *cmdptr;
	unsigned int dbg_addr;
	
		printf("6502 simulator front end for CS 2208a.\n\n");

		// Did the user specify an object file on the command line?
		// If not... help them.
		if(argc < 3) {
			printf("Usage: %s [ASCII Object File name] [# cycles to simulate] {-d}\n",argv[0]);
			printf(" e.g.: %s test.obj 3000 -d\n\n",argv[0]);
			exit(-1);
		}
	
		// Read the object file into a string.
		machine_code = read_obj_file(argv[1]);
	
	// Fire up the system RAM
	initMem();
	
	// Load the object file from the string into our simulated RAM,
	// starting at memory location 'code_location'.
	loadMem(machine_code,code_location);

		// We did something horribly underhanded in read_obj_file()... 
		// we allocated memory with 'malloc' and then passed back a pointer.
		// But note that the onus is on us, the C programmer, to _remember_ 
		// that we did that and free up the memory when it's no longer needed.
		// Not a big deal here, but imagine a bigger program where you're keeping
		// track of hundreds of mallocs and frees. Now you know why C programs
		// leak memory like the titanic.
		free(machine_code);

	
	// Initialize the 6502
	init6502();
	reset6502();
	
	PC = code_location; // Make sure the program counter points to our code!
	
	
	// All set to run the simulator now!
	
	
	// Everything below is just fanciness to give you a rudimentry 6502 debugger
	// to help with your assignment. Without the fancyness, all we're really doing
	// is one call:
	//
	// exec6502(num_cycles);
	
	
	// Run in debug mode, if requested
	if( (argc > 3) && (!strcmp(argv[3],"-d"))) {

		printf("Running in DEBUG MODE.\n\nType '?' for help.\n");
		
		// Debug loop
		while(strcmp(debug_command,"quit")) {

			
			//dumpMem(0x0021); // Check the value we stored to the zero page
			//dumpMem(0x01FF); // Peek at the top of the stack. Remember, the stack
						     // is hard-coded to addresses $0100–$01FF.
			//dump6502reg();	// print registers to the screen
			
			printf("debug> ");
			
			if( (gets(debug_command))[0] != '\0'){
			
			  cmdptr = strtok(debug_command," ");
			
			  switch(cmdptr[0]) {
			
				case 'p':
					if(cmdptr = strtok(NULL," ")) {
					  sscanf(cmdptr, "%x", &dbg_addr);
					  dumpMem((WORD)dbg_addr);
					}
					break;
				
				case 'r':
					dump6502reg();
					break;
					
				case 's':
					exec6502(1); // Execute 1 command
					break;
					
				case '?':
					printf("\n\np [0xAddress] - print value at memory location\n");
					printf("r - print register values\n");
					printf("s - step through program\n");
					printf("quit - exit\n\n");
					break;
			
				default:
					(cmdptr[0] % 2) ? printf("Herp.\n") : printf("Derp.\n");
					
			  }
			}
						
		}
	} else {
	// Otherwise, run in regular mode.
		exec6502(atoi(argv[2]));
	}
}
