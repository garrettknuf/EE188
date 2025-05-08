;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                                  Branch Tests                               ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file tests branch instructions for the SH-2.
;
; The tests are 
;
; Revision History:
;   27 Apr 25   Garrett Knuf    Initial revision.

.vectable
    PC: 1024
    KeyobardInt: 1028
    ...
    REsetInt: 

.text

InitDataSegAddr:
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    MOV     R0, R10 ; 1024

BFTest:
    CLRT
    BT      TestFail
    BF      BFSTest     ; take this branch (fail otherwise)
    BRA     TestFail
    NOP

BFSTest:
    CLRT
    BT/S    TestFail
    MOV     #0, R0
    BF/S    BTTest      ; take this branch (fail otherwise)
    MOV     #1, R0      ; this instruction should execute
    BRA     TestFail
    NOP

BTTest:
    SETT
    BF      TestFail
    BT      BTSTest     ; take this branch (fail otherwise)
    BRA     TestFail
    NOP

BTSTest:
    SETT
    BF/S    TestFail
    MOV     #0, R1
    BT/S    BRATest     ; take this branch (fail otherwise)
    MOV     #1, R1
    BRA     TestFail
    NOP

BRATest:
    BRA     BRAFTest    ; take this branch
    MOV     #1, R2      ; execute this instruction
    MOV     #0, R2      ; but not this one
    BRA     TestFail
    NOP

BRAFTest:
    MOV     #10, R3
    BRAF    R3          ; branch to BSRTest (PC+R3)
    MOV     #0, R3      ; change branching offset in R3 (should not matter)
    NOP
    BRA     TestFail
    NOP

BSR_RTSTest:
    MOV    #10, R11
    BSR    TestFunction
    MOV    #1, R4          ; should execute
    MOV.L  R11, @R10       ; should write 9
    ADD    #4, R10
    BRA    BSRF_RTSTest
    NOP

;
; TestFunction (decrement R11)
;
; @arg R11 value
; @return R11 = value-1
;
TestFunction:
    DT          R11
    RTS                     ; return from function call
    MOV     #1, R6          ; should execute
    BRA     TestFail        ; this should not

BSRF_RTSTest:
    MOV     #-12, R12       ; offset to TestFunction
    BSRF    R12             ; call test function
    MOV     #20, R11        ; should execute
    MOV.L  R11, @R10        ; should write 19
    ADD    #4, R10
    ; BRA    JMPTest

JMPTest:
    MOVA    @(3, PC), R0
    JMP     @R0
    NOP
    NOP
    BRA     TestFail
    NOP

JSRTest:
    MOVA    @(0,PC),R0
    ADD     #-30, R0
    MOV     R0, R13
    JSR     @R13        ; jump to TestFunction
    MOV     #37, R11
    MOV.L   R11, @R10
    ADD     #4, R10

TestSuccess:
    MOV     #1, R9
    MOV.L   R9, @R10 ; store SUCCESS (1)
    SETT    
    BT      TestEnd

TestFail:
    MOV     #0, R9
    MOV.L   R9, @R10 ; store FAIL (0)
    ;BRA    TestEnd

TestEnd:
    SLEEP

.data
