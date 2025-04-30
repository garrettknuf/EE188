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
    MOV     #2, R11
    BSR     TestFunction
    MOV     #1, R4          ; should execute
    MOV     R11, R5         ; should be 2-1=1
    BRA    BSRF_RTSTest
    NOP

;
; TestFunction (decrement R11)
;
; @arg R11 value
; @return R11 = value-1
;
TestFunction:
    MOV     R0, R14         ; save R0
    MOVA    @(0, PC), R0    ; save address of function  ;; WRONG WRONG WRONG
    ; TODO: fix
    MOV     R0, R13         
    MOV     R14, R0         ; restore R0
    DT  R11
    RTS                     ; return from function call
    MOV     #1, R6          ; should execute
    BRA     TestFail        ; this should not

BSRF_RTSTest:
    MOV     #-8, R12        ; offset to TestFunction
    MOV     #2, R11
    BSRF    R12             ; call test function
    MOV     #1, R7          ; should execute
    MOV     R11, R8         ; should be 2-1=1
    ;BRA    JMPTest

JMPTest:
    MOV     R0, R14         ; save R0
    MOVA    @(0, PC), R0    ; get 
    MOV     R0, R13         
    MOV     R14, R0         ; restore R0
    

JSRTest:
    JMP     @R13        ; jump to TestFunction



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

SRVal:  .long   b; TODO
GBRVal: .long   1024
VBRVal: .long   1028
