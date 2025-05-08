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

.vectable
    PowerResetPC:           0x00000008  ; PC for power reset (0)
    PowerResetSP:           0xFFFFFFFF  ; SP for power reset (1)

.text

InitDataSegAddr:
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    MOV     R0, R10 ; 1024
    MOV.L   @R10+,R0
    MOV.L   @R10+,R1

ROTTest:
    ROTL    R0
    MOV.L   R0, @R10
    ADD     #4, R10
    ROTR    R1
    MOV.L   R1, @R10
    ADD     #4, R10

ROTCTest:
    SETT                ; rotate right with carry (T=1)
    ROTCR   R0
    MOV.L   R0, @R10    ; write to mem
    ADD     #4, R10
    BF      TestFail    ; T flag should be set
    CLRT                ; rotate right with carry (T=0)
    ROTCR   R0
    MOV.L   R0, @R10    ; write to mem
    ADD     #4, R10
    BT      TestFail    ; T flag should be clear
    SETT                ; rotate left with carry (T=1)
    ROTCL   R1
    MOV.L   R1, @R10    ; write to mem
    ADD     #4, R10
    BF      TestFail    ; T flag should be ___
    CLRT                ; rotate left with carry (T=0)
    ROTCL   R1
    MOV.L   R1, @R10    ; write to mem
    ADD     #4, R10
    BT      TestFail    ; T flag should be 

SHATest:

SHLTest:

; SHL2Test:

; SHL8Test:

; SHL16Test:

TestSuccess:
    MOV     #1, R9
    MOV.L   R9, @R10 ; store SUCCESS (1)
    ;BRA     TestEnd

    
    SETT
    BT      TestEnd


TestFail:
    MOV     #0, R9
    MOV.L   R9, @R10 ; store FAIL (0)
    ;BRA    TestEnd

TestEnd:
    SLEEP

.data

Addr1REstsVec : .long x3523994
Addr1REstsVec : .long x3523994
Addr1REstsVec : .long x3523994
Addr1REstsVec : .long x3523994
Addr1REstsVec : .long x3523994
Addr1REstsVec : .long x3523994

Num0:   .long b10010010101010111110101000101100
Num1:   .long b01101001001011100010001101100011


