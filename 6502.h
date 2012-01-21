/* Macros for convenience */
#define A a_reg
#define X x_reg
#define Y y_reg
#define P flag_reg
#define S s_reg
#define PC pc_reg

/* assumes WORD = 16bit, BYTE = 8bit!! */
typedef unsigned short WORD;
typedef unsigned char BYTE;
   
/* Address mask. Atari Asteroids/Deluxe use 0x7fff -
 * but use 0xffff for full 16 bit decode
 */
extern WORD addrmask;

/* pointer to the system's memory map */
extern BYTE *memImage;

/* must be called first to initialise all 6502 engines arrays */
extern void init6502(void);

/* sets all of the 6502 registers. The program counter is set from
 * locations $FFFC and $FFFD masked with the above addrmask
 */
extern void reset6502(void);

/* run the 6502 engine for specified number of clock cycles */
extern void exec6502(int timerTicks);

// Prototypes for functions in myops.m
extern void abs6502();
extern void zpx6502();
extern void sec6502();
extern void eor6502();
extern void lsr6502();
extern void pha6502();
extern void jmp6502();
extern void ldy6502();
extern void tax6502();
extern void bcs6502();
extern void dex6502();
extern void cpx6502();

