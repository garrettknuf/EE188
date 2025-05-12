;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           Data Transfer (xfer) Tests                        ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file tests data transfer operations for the SH-2 CPU.
;
; The tests are 
;
; Revision History:
;   28 Apr 25   Garrett Knuf    Initial revision.

.vectable
    PowerResetPC:           0x00000008  ; PC for power reset (0)
    PowerResetSP:           0xFFFFFFFC  ; SP for power reset (1)

.text

InitDataSegAddr:
    MOV     #64, R9     ; test immediate MOV
    SHLL    R9
    SHLL    R9
    SHLL    R9
    SHLL    R9
    MOV     R9, R10     ; test reg to reg MOV
    MOV     #32, R11    ; R10 is address of data to read from
    ADD     R10, R11    ; R11 is address to write data to

TestReadAtRegToReg:     ; test @reg to reg with and without post-increment
    MOV.B   @R10+,R0    ; R0 = -5
    MOV.B   @R10+,R1    ; R1 = 68
    MOV.W   @R10+,R2    ; R2 = 2000
    MOV.L   @R10+,R3    ; R3 = -6000
    MOV.B   @R10,R4     ; R4 = -36
    ADD     #1, R10
    MOV.B   @R10,R5     ; R5 = 0
    ADD     #1, R10
    MOV.W   @R10,R6     ; R6 = -4500
    ADD     #2, R10
    MOV.L   @R10,R7     ; R7 = 1357902468
    ADD     #4, R10

TestWriteRegToAtReg:        ; test reg to @reg
    MOV.B   R0, @R11        ; WRITE -5
    ADD     #1, R11
    MOV.B   R1, @R11        ; WRITE 68
    ADD     #1, R11
    MOV.B   R2, @R11        ; WRITE 0xD0
    ADD     #1, R11
    MOV.B   R3, @R11        ; WRITE 0x90
    ADD     #1, R11         ; now test words
    MOV.W   R2, @R11        ; WRITE 2000
    ADD     #2, R11
    MOV.W   R6, @R11        ; WRITE -4500
    ADD     #2, R11
    MOV.L   R7, @R11        ; WRITE 1357902468
    ADD     #4, R11

TestWritePreDec:
    ADD     #8, R11
    MOV.B   R0,@-R11    ; WRITE -5
    MOV.B   R4,@-R11    ; WRITE -36
    MOV.W   R2,@-R11    ; WRITE 2000
    MOV.L   R3,@-R11    ; WRITE -6000
    ADD     #8, R11

TestWriteR0ToAtDispReg:     ; test write R0 to @(disp x n + reg)
    MOV     #17, R0
    MOV.B   R0,@(0,R11)     ; WRITE 17
    MOV     #-4, R0
    MOV.B   R0,@(1,R11)     ; WRITE -4
    MOV     R3, R0
    MOV.W   R0,@(1,R11)     ; WRITE -6000
    ADD     #4, R11
    MOV.L   R7,@(1,R11)     ; WRITE 1357902468
    ADD     #8, R11
    
TestReadAtDispRegToR0:      ; test reading from @(reg+disp) to R0
    MOV.B   @(8,R9), R0     ; read -36
    MOV.L   R0, @R11
    ADD     #4, R11
    MOV.W   @(5,R9), R0     ; read -4500
    MOV.L   R0, @R11
    ADD     #4, R11
    MOV.L   @(3,R9), R13    ; read 1357902468
    MOV.L   R13, @R11
    ADD     #4, R11

TestWriteRmToAtR0Rn:        ; test writing reg to @(R0 + reg)
    MOV     R9, R0          ; base address 1024
    MOV     #76, R12        ; calculate offsets to write from base address
    MOV     #78, R13
    MOV     #80, R14
    MOV.B   R4,@(R0,R12)    ; WRITE -36
    MOV.W   R6,@(R0,R13)    ; WRITE -4500
    MOV.L   R3,@(R0,R14)    ; WRITE -6000
    ADD     #8, R11

TestReadAtR0RmToRn:
    MOV     R9, R0
    MOV     #8, R12
    MOV     #2, R13
    MOV     #12, R14
    MOV.B   @(R0,R12), R8
    MOV.L   R8, @R11
    ADD     #4, R11
    MOV.W   @(R0,R13), R13
    MOV.L   R13, @R11
    ADD     #4, R11
    MOV.L   @(R0,R14), R12
    MOV.L   R12, @R11
    ADD     #4, R11

TestWriteR0ToAtDispGBR:
    LDC     R9, GBR
    MOV     R4, R0
    MOV.B   R0,@(96,GBR)
    MOV     R6, R0
    MOV.W   R0,@(49,GBR)
    MOV     R3, R0
    MOV.L   R0,@(25,GBR)
    ADD     #8, R11

TestReadAtDispGBRToR0:
    MOV.B   @(8,GBR),R0     ; Read -36
    MOV.L   R0, @R11        ; Write -36
    ADD     #4, R11
    MOV.W   @(5,GBR),R0     ; Read -4500
    MOV.L   R0, @R11        ; Write -4500
    ADD     #4, R11
    MOV.L   @(3,GBR),R0     ; Read 1357902468
    MOV.L   R0, @R11        ; Write 1357902468
    ADD     #4, R11

TestReadAtDispPCToRn:       ; read @(disp + PC) to reg
    MOV.W   @(6, PC), R15   ; put MOV.L(2, PC) op code into R15
    NOP
    NOP
    NOP
    NOP
    NOP
    MOV.L   @(2, PC), R14   ; put NOT R3,R4 and ADD #4,R11 opcodes into R14
    MOV.L   R15, @R11       ; WRITE 0xFFFFDE02 (MOV.L instruction op code sign-ext)
    ADD     #4, R11
    MOV.L   R14, @R11       ; WRITE 0x64377B04 (NOT + ADD opcodes)
    NOT     R3, R4          ; used for NOT opcode
    ADD     #4, R11         ; used for AND opcode 


TestMOVA:
    MOVA    @(5,PC),R0      ; read (PC+5*4) = (0xE0 + 0x14) = 0xF4
    MOV.L   R0, @R11
    ADD     #4, R11

TestMOVT:
    SETT
    MOVT    R13
    MOV     R13, R0
    CMP/EQ  #1, R0
    BF      TestFail
    CLRT
    MOVT    R12
    MOV     R12, R0
    CMP/EQ  #0, R0
    BF      TestFail

TestSWAP:
    MOV.L   @(4,GBR), R0
    MOV     R0, R13
    SWAP.B  R13, R12
    MOV.L   R12, @R11
    ADD     #4, R11
    SWAP.W  R13, R12
    MOV.L   R12, @R11
    ADD     #4, R11
    ;BRA    TestXTRCT

TestXTRCT:
    MOV.L   @(5,GBR), R0
    XTRCT   R13, R0
    MOV.L   R0, @R11
    ADD     #4, R11
    ; BRA   TestSuccess

TestSuccess:
    MOV     #1, R9
    MOV.L   R9, @R11 ; store SUCCESS (1)
    BRA     TestEnd

TestFail:
    MOV     #0, R9
    MOV.L   R9, @R11 ; store FAIL (0)
    ;BRA    TestEnd

TestEnd:
    SLEEP

.data

Num0: .byte -5
Num1: .byte 68
Num2: .word 2000
Num3: .long -6000
Num4: .byte -36
Num5: .byte 0
Num6: .word -4500
Num7: .long 1357902468
Num8: .long 0x01234567
Num9: .long 0x89ABCDEF
