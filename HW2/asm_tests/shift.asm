;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           Shift Operation Tests                             ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file tests shift operations for the SH-2 CPU.
;
; The tests are 
;
; Revision History:
;   28 Apr 25   Garrett Knuf    Initial revision.

.text

InitDataSegAddr:
    MOV.L   @(64,PC),R0     ; 0x0010
    ADD     #4, R0          ; add data offset
    MOV     R0, R10
    MOV.L   @R10+,R0
    MOV.L   @R10+,R1
    MOV.L   @R10+,R2
    MOV.L   @R10+,R3
    MOV.L   @R10+,R4

ROTTest:
    ROTL    R0
    MOV.L   R0, @R10
    ADD     

ROTCTest:


SHATest:

SHLTest:

SHL2Test:

SHL8Test:

SHL16Test:

TestSuccess:
    MOV     #1, R9
    MOV.L   R9, @R10 ; store SUCCESS (1)
    BRA     TestEnd

TestFail:
    MOV     #0, R9
    MOV.L   R9, @R10 ; store FAIL (0)
    ;BRA    TestEnd

TestEnd:
    END_SIM true


.data

DataSegAddr: .long  256
Num0:   .long b01101001001011100010001101100011
Num1:   .long b10010010101010111110101000101100