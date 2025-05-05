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

.text

InitDataSegAddr:
    MOV     #64, R9     ; test immediate MOV
    SHLL    R9
    SHLL    R9
    SHLL    R9
    SHLL    R9
    MOV     R9, R10     ; R10 is address of data to read from
    MOV     #48, R11
    ADD     R10, R11    ; R11 is address to write data to (also move reg to reg)

TestMOV_At_Disp_PC_To_Rn:   ; store PC relative values into reg
    MOV.W   @(5, PC), R2    ; put XOR instruction below into R2
    NOP
    NOP
    NOP
    NOP
    XOR     R3, R4          ; used for MOV.W above
    MOV.L   @(2, PC), R3    ; put NOT + AND instructions byte code below into R3
    MOV.L   R2, @R11        ; WRITE 0x0000243A
    ADD     #4, R11
    MOV.L   R3, @R11        ; WRITE 0x64377B04
    NOT     R3, R4          ; used for MOV.L below
    ADD     #4, R11

TestMOVB_Rm_to_At_Rn:       ; write byte from reg to @reg
    MOV     #1, R1          ; test immediate MOV
    MOV.B   R1, @R11        ; WRITE 0x01
    ADD     #1, R11
    MOV     #17, R1
    MOV.B   R1, @R11        ; WRITE 0x11
    ADD     #1, R11
    MOV     #3, R1
    MOV.B   R1, @R11        ; WRITE 0x03
    ADD     #1, R11
    MOV     #-1, R1         ; WRITE 0xFF
    MOV.B   R1, @R11
    ADD     #1, R11

TestMOVW_Rm_to_At_Rn:
    MOV.W   R3, @R11        ; WRITE 0x7B04
    ADD     #2, R11
    ADD     #2, R11         ; skip to next long word (psuedo WRITE 0x0000)

TestMOVL_Rm_to_At_Rn:
    ; Already tested in TestMOV_At_Disp_PC_To_Rn

TestMOVBWL_At_Rm_to_Rn:
    MOV.B   @R10, R0    ; READ -5
    ADD     #1, R10
    MOV.B   @R10, R1    ; READ 68
    ADD     #1, R10
    MOV.W   @R10, R2    ; READ 2000
    ADD     #2, R10
    MOV.L   @R10, R3    ; READ -6000
    ADD     #4, R10
    ADD     R1, R0
    ADD     R2, R0
    ADD     R3, R0
    MOV.L   R0, @R11    ; write sum of the 4 previous reads (WRITE = -3937 = 0xFFFFF09F)
    ADD     #3, R11

TestWritePreDec:
    ADD     #9, R11
    MOV     #-7, R0
    MOV.B   R0,@-R11    ; WRITE -7
    MOV.B   R1,@-R11    ; WRITE 68
    MOV.W   R2,@-R11    ; WRITE 2000
    MOV.L   R3,@-R11    ; WRITE -6000
    ADD     #8, R11

TestReadPostInc:
    MOV.B   @R10+,R0
    ADD     #1, R10
    MOV.W   @R10+,R1
    MOV.L   @R10+,R2
    MOV.L   R0, @R11
    ADD     #4, R11
    MOV.L   R1, @R11
    ADD     #4, R11
    MOV.L   R2, @R11
    ADD     #4, R11

Test_Rn_to_At_Disp_Reg:
    MOV     #-11, R0
    ; MOV.W   R0,@(0,R1)
    MOV     #8, R0
    MOV     #8, R0
    MOV     #8, R0
    ; MOV.B   R0,@(5,R11)
    ; MOV     #65, R0
    ; MOV.W   R0,@(4,R11)
    ; MOV     #-123, R1
    ; MOV.L   R1,@(2,R11)

Test_At_Disp_Rm_To_Rn:
    ; TODO

Test_Rm_To_At_R0_Rn:
    ; TODO

Test_At_R0_Rm_To_Rn:
    ; TODO

Test_R0_To_At_Disp_GBR:
    ; TODO

Test_At_Disp_GBR_To_R0:
    ; TODO

TestMOVA:
    ; TODO

TestMOVT:
    ; SETT
    ; MOVT    R5
    ; CMP/EQ  #1, R5
    ; BF      TestFail
    ; CLRT
    ; MOVT    R5
    ; CMP/EQ  #0, R5
    ; BF      TestFail

TestSWAP:
    ; TODO

TestXTRCT:
    ; TODO

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
