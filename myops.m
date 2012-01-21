!************************************************************************************
!************************************************************************************
!*  Devon Guinane                                                                                                                                 
!*  File: myops.m
!*                                                                                      
!*  Description:
!*      This program implements absolute addresing mode for the mos 6502 
!*      as well as 10 opcodes.
!*      
!*
!*  Revision History:
!*      12/1/11 - started absolute addressing mode
!*      12/2/11 - finished absolute addressing mode
!*      12/3/11 - implmented 1st 3 opcodes
!*      12/4/11 - implemented 2 opcodes
!*      12/5/11 - finished opcodes
!*      12/6/11 - finished testing and commenting
!*          
!*
!*  Register Legend:
!*      %mem_r          stores memImage             %l0
!*      %pc_r           stores program counter      %l1
!*      %savepc_r       stores savepc               %l4

!************************************************************************************
!************************************************************************************

define(SHIFT, 8)                        ! 'used to shift 8 bits'
define(ZERO_MASK, 0xFD)                 ! 'mask to test zero flag'
define(CARRY_ONE, 0x01)                 ! 'mask to set carry flag'
define(NEG_ONE, 0x7F)                   ! 'mask to set negative flag'
define(ZERO_ONE, 0x02)                  ! 'mask to set zero flag'
define(NEG_TWO, 0x80)                   ! 'mask to set negative flag'
define(OFFSET_SP, 0x100)                ! 'stack pointer offset'

define(mem_r, l0)                       ! 'used to store memImage'
define(pc_r, l1)                        ! 'used to store program counter'
define(savepc_r, l4)                    ! 'used to store savepc'

    .text
    .align 4

    
    .global abs6502
abs6502:
    save %sp, -96, %sp
    nop
    
    set     memImage, %mem_r            ! 'store address of memImage'
    ld      [%mem_r], %mem_r            ! 'get value stored in memImage'
    
    set     pc_reg, %pc_r               ! 'store address of program counter'
    lduh    [%pc_r], %pc_r              ! 'get value stored in program counter'
    
    ldub    [%mem_r + %pc_r], %l2       ! 'load memImage[PC]'
    inc     %pc_r                       ! 'increment program counter'
    
    ldub    [%mem_r + %pc_r], %l3       ! 'load memImage[PC + 1]'
    inc     %pc_r                       ! 'increment program counter'
    
    sll     %l3, SHIFT, %l3             ! 'put MSB in bits 8-15 for the sparc'
    add     %l2, %l3, %l3               ! 'add LSB and MSB'

    set     savepc, %savepc_r           ! 'store address of savepc'
    
    stuh    %l3, [%savepc_r]            ! 'store value in savepc'
    
    set     pc_reg, %l5 
    stuh    %pc_r, [%l5]                ! 'store new program counter value in program counter'
    
    ret 
    restore

    .global zpx6502
zpx6502:
    save %sp, -96, %sp
    nop
        
    ret
    restore

    .global ldy6502
ldy6502:
    save %sp, -96, %sp
    nop
        
    set     opcode, %g1                 ! Load the memory location in which
                                        ! the emulator stores the current opcode
                                        ! into %g1.

    ldub    [%g1], %g1                  ! Fetch that current 8-bit opcode from memory
                                        ! Note -ldub- because we only want
                                        ! 8 bits from memory as the 6502 is
                                        ! an 8-bit processor and its instructions
                                        ! are all 8-bits wide.
    
    and     %g1, 0xff, %g3              ! move it to %g3 (bottom 8 bits only!)

    set     adrmode, %g2                ! Load the memory location pointing to
                                        ! the beginning of the array of 6502
                                        ! addressing modes. This array has one
                                        ! entry per opcode.

                                        ! What is this an array of? Weird, evil
                                        ! things: function pointers. Each
                                        ! entry in this array is the memory
                                        ! location of a function which handles
                                        ! a specific addressing mode. The
                                        ! addressing modes are 6502, of course,
                                        ! but these functions have to run on
                                        ! the machine doing the emulating...
                                        ! the SPARC. So 'adrmode' is an array
                                        ! of pointers to SPARC functions.

                                        ! Think 'jump table'.

    sll     %g3, 2, %g1                 ! multiply %g3 by 4... (why?)
                                        ! Answer: We want a pointer to a SPARC
                                        ! function, which is just a SPARC address.
                                        ! How big are SPARC V7 addresses? 32 bits or
                                        ! 4 bytes. Each element in our array has size
                                        ! 4, so we have to multiply our array index,
                                        ! which just happens to be the opcode number,
                                        ! by 4.

    ld      [%g2+%g1], %g1              ! %g2 points to the beginning of our
                                        ! array of function pointers. %g1
                                        ! now contains the -offset- for the
                                        ! specific function to handle the
                                        ! addressing mode for current 6502
                                        ! opcode.
                                        !
                                        ! Load the 32 bits stored in the memory location
                                        ! (array_base + pointer), just like in the lecture notes

                                        ! %g1 now contains a memory address that
                                        ! points to a -function- rather than a
                                        ! data item. (Hey, memory is memory, bits
                                        ! are bits... the SPARC doesn't care what
                                        ! we point to).

    call    %g1, 0                      ! Since %g1 is pointing to a function we
                                        ! need to call... lets just go ahead and
                                        ! call that function. Feels weird, doesn't it?
                                        ! "Calling" a register? Totally legal though,
                                        ! and very useful (if used for good).
    nop                                 ! fill delay slot. derp.

                                        ! We have now called a function to interpret the addressing mode for the current
                                        ! opcode _and_ this function has returned a pointer to the operand -- which is
                                        ! just a memory address -- in 'savepc'.

                                        ! Again, because this is important:
                                        ! All of the complexity of the addressing mode has been abstracted away
                                        ! from us. All we need to know is that memImage[savepc] contains the
                                        ! operand value.

                                        ! END Boilerplate code.

    
    set     memImage, %mem_r            ! 'store address of memImage'
    ld      [%mem_r], %mem_r            ! 'get value stored in memImage'
    
    set     savepc, %savepc_r           ! 'store address of savepc'
    lduh    [%savepc_r], %savepc_r      ! 'get value stored in savepc'
    
    mov     %savepc_r, %o0
    call    get6502memory
    nop
    
    mov     %o0, %l2
    
    set     y_reg, %l3                  ! 'store address of y register'
    
    stb     %l2, [%l3]                  ! 'store value in y_reg'
    
    cmp     %l2, %g0                    ! 'if value is zero'
    be      zero
    nop
    
    cmp     %l2, %g0                    ! 'if value is negative'
    bl      negative
    nop
    
    set     flag_reg, %l2               ! 'set zero flag to 0'
    ldub    [%l2], %l5
    and     ZERO_MASK, %l5, %l5
    
    set     flag_reg, %l2               ! 'set negative flag to 0'
    ldub    [%l2], %l5
    and     NEG_ONE, %l5, %l5
    
    ba      done
    nop
    
zero:
    set     flag_reg, %l2               ! 'set zero flag to 1'
    ldub    [%l2], %l5
    or      ZERO_ONE, %l5, %l5
    
    ba      done
    nop

negative:
    set     flag_reg, %l2               ! 'set negative flag to 1'
    ldub    [%l2], %l5
    or      NEG_TWO, %l5, %l5
    
done:
    stub    %l5, [%l2]                  ! 'store value in flag register'
    ret
    restore

    .global lsr6502
lsr6502:
    save %sp, -96, %sp
    nop
        
    set     opcode, %g1                 ! Load the memory location in which
                                        ! the emulator stores the current opcode
                                        ! into %g1.

    ldub    [%g1], %g1                  ! Fetch that current 8-bit opcode from memory
                                        ! Note -ldub- because we only want
                                        ! 8 bits from memory as the 6502 is
                                        ! an 8-bit processor and its instructions
                                        ! are all 8-bits wide.
    
    and     %g1, 0xff, %g3              ! move it to %g3 (bottom 8 bits only!)

    set     adrmode, %g2                ! Load the memory location pointing to
                                        ! the beginning of the array of 6502
                                        ! addressing modes. This array has one
                                        ! entry per opcode.

                                        ! What is this an array of? Weird, evil
                                        ! things: function pointers. Each
                                        ! entry in this array is the memory
                                        ! location of a function which handles
                                        ! a specific addressing mode. The
                                        ! addressing modes are 6502, of course,
                                        ! but these functions have to run on
                                        ! the machine doing the emulating...
                                        ! the SPARC. So 'adrmode' is an array
                                        ! of pointers to SPARC functions.

                                        ! Think 'jump table'.

    sll     %g3, 2, %g1                 ! multiply %g3 by 4... (why?)
                                        ! Answer: We want a pointer to a SPARC
                                        ! function, which is just a SPARC address.
                                        ! How big are SPARC V7 addresses? 32 bits or
                                        ! 4 bytes. Each element in our array has size
                                        ! 4, so we have to multiply our array index,
                                        ! which just happens to be the opcode number,
                                        ! by 4.

    ld      [%g2+%g1], %g1              ! %g2 points to the beginning of our
                                        ! array of function pointers. %g1
                                        ! now contains the -offset- for the
                                        ! specific function to handle the
                                        ! addressing mode for current 6502
                                        ! opcode.
                                        !
                                        ! Load the 32 bits stored in the memory location
                                        ! (array_base + pointer), just like in the lecture notes

                                        ! %g1 now contains a memory address that
                                        ! points to a -function- rather than a
                                        ! data item. (Hey, memory is memory, bits
                                        ! are bits... the SPARC doesn't care what
                                        ! we point to).

    call    %g1, 0                      ! Since %g1 is pointing to a function we
                                        ! need to call... lets just go ahead and
                                        ! call that function. Feels weird, doesn't it?
                                        ! "Calling" a register? Totally legal though,
                                        ! and very useful (if used for good).
    nop                                 ! fill delay slot. derp.

                                        ! We have now called a function to interpret the addressing mode for the current
                                        ! opcode _and_ this function has returned a pointer to the operand -- which is
                                        ! just a memory address -- in 'savepc'.

                                        ! Again, because this is important:
                                        ! All of the complexity of the addressing mode has been abstracted away
                                        ! from us. All we need to know is that memImage[savepc] contains the
                                        ! operand value.

                                        ! END Boilerplate code.
                                        
                                        
    set     memImage, %mem_r            ! 'store address of memImage'
    ld      [%mem_r], %mem_r            ! 'get value stored in memImage'
    
    set     savepc, %savepc_r           ! 'store address of savepc'
    lduh    [%savepc_r], %savepc_r      ! 'get value stored in savepc'
    
    ldub    [%mem_r + %savepc_r], %l2   ! 'load memImage[savepc]'
    
    and     CARRY_ONE, %l2, %l5         ! 'get 1st bit to set carry bit in flag reg'
    
    srl     %l2, 1, %l2                 ! 'shift right 1 bit'
    
    stb     %l2, [%mem_r + %savepc_r]   ! 'store value in memImage'
    
    set     flag_reg, %l3
    ldub    [%l3], %l1
    or      %l5, %l1, %l1               ! 'set carry bit in flag register'
    
    btst    NEG_TWO, %l2                ! 'check if bit 7 is set(negative)'
    bne     set_neg_bit2
    nop
    
    and     NEG_ONE, %l1, %l1           ! 'set negative bit to 0'
    
    cmp     %l2, %g0
    be      is_zero2                    ! 'if result is 0'
    nop
    
    and     ZERO_MASK, %l1, %l1         ! 'set zero flag to 0'
    
    ba      done2                       ! 'return'
    nop
    
is_zero2:
    set     flag_reg, %l3               ! 'store address of flag register'
    ldub    [%l3], %l1
    or      ZERO_ONE, %l1, %l1          ! 'set zero flag to 1'
    
    ba      done2
    nop
    
set_neg_bit2:
    or      NEG_TWO, %l1, %l1           ! 'set negative bit to 1'
    
done2:
    stub    %l1, [%l3]                  ! 'store value in flag register'
    ret 
    restore

    .global tax6502
tax6502:
    save %sp, -96, %sp
    nop
        
    set     a_reg, %l2                  ! 'store address of a_reg'
    ldub    [%l2], %l2                  ! 'get value stored in a_reg'
        
    set     x_reg, %l3                  ! 'store address of x_reg'
            
    stb     %l2, [%l3]                  ! 'copy value from a_reg to x_reg'
        
    cmp     %l2, %g0                    ! 'if value is zero, set zero flag'
    be      is_zero3
    nop
        
    btst    NEG_TWO, %l2                ! 'check leftmost bit for negativity'
    bne     is_negative3
    nop 
    
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    and     NEG_ONE, %l1, %l1           ! 'set negative bit to 0'
    and     ZERO_MASK, %l1, %l1         ! 'set zero flag to 0'
    
    ba      done3
    nop
        
is_zero3:
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    or      ZERO_ONE, %l1, %l1          ! 'set zero flag to 1'
    
    ba      done3
    nop

is_negative3:
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    or      NEG_TWO, %l1, %l1           ! 'set negative bit to 1'

done3:
    stub    %l1, [%l5]                  ! 'store value in flag register'
    ret
    restore

    .global pha6502
pha6502:
    save %sp, -96, %sp
    nop
        
    set     a_reg, %l2                  ! 'store address of a_reg'
    ldub    [%l2], %l2                  ! 'get value stored in a_reg'
    
    set     s_reg, %l3                  ! 'store address of s_reg'
    ldub    [%l3], %l3                  ! 'get value stored in stack pointer'
    
    set     memImage, %mem_r            ! 'store address of memImage'
    ld      [%mem_r], %mem_r            ! 'get value stored in memImage'
    
    add     %l3, OFFSET_SP, %l5         ! 'add offset to stack pointer'
    
    stb     %l2, [%mem_r + %l5]         ! 'store a_reg value in memImage'
    
    dec     %l3                         ! 'decrement statck pointer by 1'
    
    set     s_reg, %l5  
    stub    %l3, [%l5]                  ! 'store new stack pointer value'
    
    ret
    restore

    .global eor6502
eor6502:
    save %sp, -96, %sp
    nop
    
    set     opcode, %g1                 ! Load the memory location in which
                                        ! the emulator stores the current opcode
                                        ! into %g1.

    ldub    [%g1], %g1                  ! Fetch that current 8-bit opcode from memory
                                        ! Note -ldub- because we only want
                                        ! 8 bits from memory as the 6502 is
                                        ! an 8-bit processor and its instructions
                                        ! are all 8-bits wide.
    
    and     %g1, 0xff, %g3              ! move it to %g3 (bottom 8 bits only!)

    set     adrmode, %g2                ! Load the memory location pointing to
                                        ! the beginning of the array of 6502
                                        ! addressing modes. This array has one
                                        ! entry per opcode.

                                        ! What is this an array of? Weird, evil
                                        ! things: function pointers. Each
                                        ! entry in this array is the memory
                                        ! location of a function which handles
                                        ! a specific addressing mode. The
                                        ! addressing modes are 6502, of course,
                                        ! but these functions have to run on
                                        ! the machine doing the emulating...
                                        ! the SPARC. So 'adrmode' is an array
                                        ! of pointers to SPARC functions.

                                        ! Think 'jump table'.

    sll     %g3, 2, %g1                 ! multiply %g3 by 4... (why?)
                                        ! Answer: We want a pointer to a SPARC
                                        ! function, which is just a SPARC address.
                                        ! How big are SPARC V7 addresses? 32 bits or
                                        ! 4 bytes. Each element in our array has size
                                        ! 4, so we have to multiply our array index,
                                        ! which just happens to be the opcode number,
                                        ! by 4.

    ld      [%g2+%g1], %g1              ! %g2 points to the beginning of our
                                        ! array of function pointers. %g1
                                        ! now contains the -offset- for the
                                        ! specific function to handle the
                                        ! addressing mode for current 6502
                                        ! opcode.
                                        !
                                        ! Load the 32 bits stored in the memory location
                                        ! (array_base + pointer), just like in the lecture notes

                                        ! %g1 now contains a memory address that
                                        ! points to a -function- rather than a
                                        ! data item. (Hey, memory is memory, bits
                                        ! are bits... the SPARC doesn't care what
                                        ! we point to).

    call    %g1, 0                      ! Since %g1 is pointing to a function we
                                        ! need to call... lets just go ahead and
                                        ! call that function. Feels weird, doesn't it?
                                        ! "Calling" a register? Totally legal though,
                                        ! and very useful (if used for good).
    nop                                 ! fill delay slot. derp.

                                        ! We have now called a function to interpret the addressing mode for the current
                                        ! opcode _and_ this function has returned a pointer to the operand -- which is
                                        ! just a memory address -- in 'savepc'.

                                        ! Again, because this is important:
                                        ! All of the complexity of the addressing mode has been abstracted away
                                        ! from us. All we need to know is that memImage[savepc] contains the
                                        ! operand value.

                                        ! END Boilerplate code.
        
    set     memImage, %mem_r            ! 'store address of memImage'
    ld      [%mem_r], %mem_r            ! 'get value stored in memImage'
    
    set     savepc, %savepc_r           ! 'store address of savepc'
    lduh    [%savepc_r], %savepc_r      ! 'get value stored in savepc'
    
    set     a_reg, %l2                  ! 'store address of a_reg'
    ldub    [%l2], %l2                  ! 'get value stored in a_reg'
    
    ldub    [%mem_r + %savepc_r], %l3   ! 'get value of memImage[savepc]'
    
    xor     %l3, %l2, %l5               ! 'xor a_reg with memImage[savepc]'
    
    set     a_reg, %l2                  ! 'store address of a_reg'
    stub    %l5, [%l2]                  ! 'store xor result in a_reg'
    
    
    cmp     %l5, %g0                    ! 'if value is zero, set zero flag'
    be      is_zero4
    nop
        
    btst    NEG_TWO, %l5                ! 'check leftmost bit for negativity'
    bne     is_negative4
    nop 
    
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    and     NEG_ONE, %l1, %l1           ! 'set negative bit to 0'
    
    and     ZERO_MASK, %l1, %l1         ! 'set zero flag to 0'
    
    ba      done4
    nop
    
is_zero4:
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    or      ZERO_ONE, %l1, %l1          ! 'set zero flag to 1'
    
    ba      done4
    nop
    
is_negative4:
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    or      NEG_TWO, %l1, %l1           ! 'set negative bit to 1'
    
done4:
    stub    %l1, [%l5]                  ! 'store value in flag register'

    ret
    restore

    .global cpx6502
cpx6502:
    save %sp, -96, %sp
    nop
    set     opcode, %g1                 ! Load the memory location in which
                                        ! the emulator stores the current opcode
                                        ! into %g1.

    ldub    [%g1], %g1                  ! Fetch that current 8-bit opcode from memory
                                        ! Note -ldub- because we only want
                                        ! 8 bits from memory as the 6502 is
                                        ! an 8-bit processor and its instructions
                                        ! are all 8-bits wide.
    
    and     %g1, 0xff, %g3              ! move it to %g3 (bottom 8 bits only!)

    set     adrmode, %g2                ! Load the memory location pointing to
                                        ! the beginning of the array of 6502
                                        ! addressing modes. This array has one
                                        ! entry per opcode.

                                        ! What is this an array of? Weird, evil
                                        ! things: function pointers. Each
                                        ! entry in this array is the memory
                                        ! location of a function which handles
                                        ! a specific addressing mode. The
                                        ! addressing modes are 6502, of course,
                                        ! but these functions have to run on
                                        ! the machine doing the emulating...
                                        ! the SPARC. So 'adrmode' is an array
                                        ! of pointers to SPARC functions.

                                        ! Think 'jump table'.

    sll     %g3, 2, %g1                 ! multiply %g3 by 4... (why?)
                                        ! Answer: We want a pointer to a SPARC
                                        ! function, which is just a SPARC address.
                                        ! How big are SPARC V7 addresses? 32 bits or
                                        ! 4 bytes. Each element in our array has size
                                        ! 4, so we have to multiply our array index,
                                        ! which just happens to be the opcode number,
                                        ! by 4.

    ld      [%g2+%g1], %g1              ! %g2 points to the beginning of our
                                        ! array of function pointers. %g1
                                        ! now contains the -offset- for the
                                        ! specific function to handle the
                                        ! addressing mode for current 6502
                                        ! opcode.
                                        !
                                        ! Load the 32 bits stored in the memory location
                                        ! (array_base + pointer), just like in the lecture notes

                                        ! %g1 now contains a memory address that
                                        ! points to a -function- rather than a
                                        ! data item. (Hey, memory is memory, bits
                                        ! are bits... the SPARC doesn't care what
                                        ! we point to).

    call    %g1, 0                      ! Since %g1 is pointing to a function we
                                        ! need to call... lets just go ahead and
                                        ! call that function. Feels weird, doesn't it?
                                        ! "Calling" a register? Totally legal though,
                                        ! and very useful (if used for good).
    nop                                 ! fill delay slot. derp.

                                        ! We have now called a function to interpret the addressing mode for the current
                                        ! opcode _and_ this function has returned a pointer to the operand -- which is
                                        ! just a memory address -- in 'savepc'.

                                        ! Again, because this is important:
                                        ! All of the complexity of the addressing mode has been abstracted away
                                        ! from us. All we need to know is that memImage[savepc] contains the
                                        ! operand value.

                                        ! END Boilerplate code.
                                        
    set     memImage, %mem_r            ! 'store address of memImage'
    ld      [%mem_r], %mem_r            ! 'get value stored in memImage'
    
    set     savepc, %savepc_r           ! 'store address of savepc'
    lduh    [%savepc_r], %savepc_r      ! 'get value stored in savepc'
    
    ldub    [%mem_r + %savepc_r], %l2   ! 'get value of memImage[savepc]'
    
    set     x_reg, %l3                  ! 'store address of x_reg'
    ldub    [%l3], %l3                  ! 'get value stored in x_reg'
    
    cmp     %l3, %l2                    ! 'compare x_reg and memImage[savepc] values'
    bge     setCarry5
    nop
    
is_negative_5:
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    or      NEG_TWO, %l1, %l1           ! 'set negative bit to 1'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
    set     flag_reg, %l5
    ldub    [%l5], %l1
    and     ZERO_MASK, %l1, %l1         ! 'set zero flag to 0'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
    set     flag_reg, %l5
    ldub    [%l5], %l1
    or      CARRY_ONE, %l1, %l1         ! 'set carry bit to 0'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
    ba      done5
    nop
    
setCarry5:
    set     flag_reg, %l5
    ldub    [%l5], %l1
    or      CARRY_ONE, %l1, %l1         ! 'set carry bit to 1'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'

compare5:
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    and     NEG_ONE, %l1, %l1           ! 'set negative bit to 0'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
    cmp     %l3, %l2                    ! 'check if X and memImage[savepc] are equal'
    be      setZero5
    nop
    
    set     flag_reg, %l5
    ldub    [%l5], %l1
    and     ZERO_MASK, %l1, %l1         ! 'set zero flag to 0'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
    ba      done5
    nop
    
setZero5:
    set     flag_reg, %l5
    ldub    [%l5], %l1
    or      ZERO_ONE, %l1, %l1          ! 'set zero flag to 1'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
    
done5:
    ret                                 ! 'return'
    restore

    .global dex6502
dex6502:
    save %sp, -96, %sp
    nop
        
    set     x_reg, %l2                  ! 'store address of x_reg'
    ldub    [%l2], %l3                  ! 'get value stored in x_reg'
        
    dec     %l3                         ! 'decrement x_reg by 1'
    stub    %l3, [%l2]
        
    cmp     %l2, %g0                    ! 'check if x_reg value is zero'
    be      is_zero6
    nop
    
    set     flag_reg, %l5
    ldub    [%l5], %l1
    and     ZERO_MASK, %l1, %l1         ! 'set zero flag to 0'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
    cmp     %l2, %g0                    ! 'check if value is negative'
    bl      is_negative_6
    nop
    
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    and     NEG_ONE, %l1, %l1           ! 'set negative bit to 0'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
    ba      done6
    nop
        
is_zero6:
    set     flag_reg, %l5
    ldub    [%l5], %l1
    or      ZERO_ONE, %l1, %l1          ! 'set zero flag to 1'
    stub        %l1, [%l5]              ! 'store condition codes in flag register'
    
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    and     NEG_ONE, %l1, %l1           ! 'set negative bit to 0'
    stub        %l1, [%l5]              ! 'store condition codes in flag register'
    
    ba      done6
    nop
    
is_negative_6:
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l1
    or      NEG_TWO, %l1, %l1           ! 'set negative bit to 1'
    stub    %l1, [%l5]                  ! 'store condition codes in flag register'
    
done6:
    ret
    restore

    .global jmp6502
jmp6502:
    save %sp, -96, %sp
    nop
        
    set     opcode, %g1                 ! Load the memory location in which
                                        ! the emulator stores the current opcode
                                        ! into %g1.

    ldub    [%g1], %g1                  ! Fetch that current 8-bit opcode from memory
                                        ! Note -ldub- because we only want
                                        ! 8 bits from memory as the 6502 is
                                        ! an 8-bit processor and its instructions
                                        ! are all 8-bits wide.
    
    and     %g1, 0xff, %g3              ! move it to %g3 (bottom 8 bits only!)

    set     adrmode, %g2                ! Load the memory location pointing to
                                        ! the beginning of the array of 6502
                                        ! addressing modes. This array has one
                                        ! entry per opcode.

                                        ! What is this an array of? Weird, evil
                                        ! things: function pointers. Each
                                        ! entry in this array is the memory
                                        ! location of a function which handles
                                        ! a specific addressing mode. The
                                        ! addressing modes are 6502, of course,
                                        ! but these functions have to run on
                                        ! the machine doing the emulating...
                                        ! the SPARC. So 'adrmode' is an array
                                        ! of pointers to SPARC functions.

                                        ! Think 'jump table'.

    sll     %g3, 2, %g1                 ! multiply %g3 by 4... (why?)
                                        ! Answer: We want a pointer to a SPARC
                                        ! function, which is just a SPARC address.
                                        ! How big are SPARC V7 addresses? 32 bits or
                                        ! 4 bytes. Each element in our array has size
                                        ! 4, so we have to multiply our array index,
                                        ! which just happens to be the opcode number,
                                        ! by 4.

    ld      [%g2+%g1], %g1              ! %g2 points to the beginning of our
                                        ! array of function pointers. %g1
                                        ! now contains the -offset- for the
                                        ! specific function to handle the
                                        ! addressing mode for current 6502
                                        ! opcode.
                                        !
                                        ! Load the 32 bits stored in the memory location
                                        ! (array_base + pointer), just like in the lecture notes

                                        ! %g1 now contains a memory address that
                                        ! points to a -function- rather than a
                                        ! data item. (Hey, memory is memory, bits
                                        ! are bits... the SPARC doesn't care what
                                        ! we point to).

    call    %g1, 0                      ! Since %g1 is pointing to a function we
                                        ! need to call... lets just go ahead and
                                        ! call that function. Feels weird, doesn't it?
                                        ! "Calling" a register? Totally legal though,
                                        ! and very useful (if used for good).
    nop                                 ! fill delay slot. derp.

                                        ! We have now called a function to interpret the addressing mode for the current
                                        ! opcode _and_ this function has returned a pointer to the operand -- which is
                                        ! just a memory address -- in 'savepc'.

                                        ! Again, because this is important:
                                        ! All of the complexity of the addressing mode has been abstracted away
                                        ! from us. All we need to know is that memImage[savepc] contains the
                                        ! operand value.

                                        ! END Boilerplate code.

    set     savepc, %savepc_r           ! 'store address of savepc'
    lduh    [%savepc_r], %savepc_r      ! 'get value stored in savepc'

    set     pc_reg, %pc_r               ! 'store address of program counter'
    
    stuh    %savepc_r, [%pc_r]          ! 'store value in program counter'

    ret
    restore

    .global bcs6502
bcs6502:
    save %sp, -96, %sp
    nop
        
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l2                  ! 'get value of flag register'
    
    btst    CARRY_ONE, %l2              ! 'check if carry bit is set'
    bne     carry_set8                  ! 'branch if carry bit is a 1'
    nop
    
                                        ! 'if carry bit is a 0'
    set     pc_reg, %pc_r               ! 'store address of program counter'
    ldub    [%pc_r], %l5                ! 'get value of program counter'
    inc     %l5                         ! 'increment program counter by 1'

    stuh    %l5, [%pc_r]                ! 'store new program counter value in program counter'
    
    ba      done8
    nop
    
carry_set8:
    set     opcode, %g1                 ! Load the memory location in which
                                        ! the emulator stores the current opcode
                                        ! into %g1.

    ldub    [%g1], %g1                  ! Fetch that current 8-bit opcode from memory
                                        ! Note -ldub- because we only want
                                        ! 8 bits from memory as the 6502 is
                                        ! an 8-bit processor and its instructions
                                        ! are all 8-bits wide.
    
    and     %g1, 0xff, %g3              ! move it to %g3 (bottom 8 bits only!)

    set     adrmode, %g2                ! Load the memory location pointing to
                                        ! the beginning of the array of 6502
                                        ! addressing modes. This array has one
                                        ! entry per opcode.

                                        ! What is this an array of? Weird, evil
                                        ! things: function pointers. Each
                                        ! entry in this array is the memory
                                        ! location of a function which handles
                                        ! a specific addressing mode. The
                                        ! addressing modes are 6502, of course,
                                        ! but these functions have to run on
                                        ! the machine doing the emulating...
                                        ! the SPARC. So 'adrmode' is an array
                                        ! of pointers to SPARC functions.

                                        ! Think 'jump table'.

    sll     %g3, 2, %g1                 ! multiply %g3 by 4... (why?)
                                        ! Answer: We want a pointer to a SPARC
                                        ! function, which is just a SPARC address.
                                        ! How big are SPARC V7 addresses? 32 bits or
                                        ! 4 bytes. Each element in our array has size
                                        ! 4, so we have to multiply our array index,
                                        ! which just happens to be the opcode number,
                                        ! by 4.

    ld      [%g2+%g1], %g1              ! %g2 points to the beginning of our
                                        ! array of function pointers. %g1
                                        ! now contains the -offset- for the
                                        ! specific function to handle the
                                        ! addressing mode for current 6502
                                        ! opcode.
                                        !
                                        ! Load the 32 bits stored in the memory location
                                        ! (array_base + pointer), just like in the lecture notes

                                        ! %g1 now contains a memory address that
                                        ! points to a -function- rather than a
                                        ! data item. (Hey, memory is memory, bits
                                        ! are bits... the SPARC doesn't care what
                                        ! we point to).

    call    %g1, 0                      ! Since %g1 is pointing to a function we
                                        ! need to call... lets just go ahead and
                                        ! call that function. Feels weird, doesn't it?
                                        ! "Calling" a register? Totally legal though,
                                        ! and very useful (if used for good).
    nop                                 ! fill delay slot. derp.

                                        ! We have now called a function to interpret the addressing mode for the current
                                        ! opcode _and_ this function has returned a pointer to the operand -- which is
                                        ! just a memory address -- in 'savepc'.

                                        ! Again, because this is important:
                                        ! All of the complexity of the addressing mode has been abstracted away
                                        ! from us. All we need to know is that memImage[savepc] contains the
                                        ! operand value.

                                        ! END Boilerplate code.
                                        
    
    set     savepc, %savepc_r           ! 'store address of savepc'
    lduh    [%savepc_r], %savepc_r      ! 'get value stored in savepc'
    
    set     pc_reg, %pc_r               ! 'store address of program counter'
    lduh    [%pc_r], %pc_r              ! 'get value of program counter'
    
    add     %savepc_r, %pc_r, %pc_r     ! 'add savepc to program counter'
    mov     %pc_r, %l3
    
    set     pc_reg, %pc_r               ! 'store address of program counter'
    
    stuh    %l3, [%pc_r]                ! 'store new program counter value in program counter'  
    
    set     clockticks6502, %l3         ! 'store address of clockticks6502'
    ld      [%l3], %l5                  ! 'get value stored in clockticks6502'
    
    inc     %l5                         ! 'increment clockticks by 1'
    st      %l5, [%l3]                  ! 'store new value in clockticks'
    
done8:
    ret
    restore

    .global sec6502
sec6502:
    save %sp, -96, %sp
    nop
        
    set     flag_reg, %l5               ! 'store address of flag register'
    ldub    [%l5], %l2                  ! 'get value of flag register'
    or      CARRY_ONE, %l2, %l2         ! 'set carry flag to 1'
    stub    %l2, [%l5]                  ! 'store condition codes in flag register'

    ret
    restore



