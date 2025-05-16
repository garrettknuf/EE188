;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                                  Branch Tests                               ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   This file is an assembly test suite exercising SH-2 data transfer type
;   instructions to verify correct operation of the following instructions:
;   - BF
;   - BT
;   - BF/S
;   - BT/S
;   - BRA
;   - BRAF
;   - BSR
;   - BSRF
;   - JMP
;   - JSR
;   - RTS
;
;   Verifies conditional branches, delayed slots, relative and register
;   based branching, subroutine calls/returns, and program counter
;   manipulation. Results are written to memory via R10 and a final
;   pass/fail flag is logged.

;
; Revision History:
;   27 Apr 25   Garrett Knuf    Initial revision.

;;------------------------------------------------------------------------------
;; Exception Vector Table
;;------------------------------------------------------------------------------
.vectable
    PowerResetPC:           0x00000050  ; PC for power reset (0)
    PowerResetSP:           0xFFFFFFFC  ; SP for power reset (1)
    ManualResetPC:          0x00000000  ; PC for manual reset (2)
    ManualResetSP:          0x00000000  ; SP for manual reset (3)
    InvalidInstruction:     0x00000000  ; General invalid instruction (4)
    Reserved:               0x00000000  ; reserved (5)
    SlotInvalidInstruction: 0x00000000  ; Slot invalid instruction (6)
    Reserved:               0x00000000  ; reserved (7)
    Reserved:               0x00000000  ; reserved (8)
    CPUAddrError:           0x00000000  ; CPU address error (9)
    DTCAddrError:           0x00000000  ; DTC address error (10)
    InterruptNMI:           0x00000000  ; Interrupt NMI (11)
    InterruptUserBreak:     0x00000000  ; Interrupt UserBreak (12)
    Reserved:               0x00000000  ; reserved (13)
    Reserved:               0x00000000  ; reserved (14)
    Reserved:               0x00000000  ; reserved (15)
    ; 16-31 typically reserved (but ignoring here)
    TrapInstUser0:          0x00000000  ; trap instruction (uservector) (13) (typically 32)
    TrapInstUser1:          0x00000000  ; trap instruction (uservector) (14) (typically 33)
    TrapInstUser2:          0x00000000  ; trap instruction (uservector) (15) (typically 34)
    TrapInstUser3:          0x00000000  ; trap instruction (uservector) (16) (typically 35)
    ; 36-63 trap instruction (user vector)
    ; 64 RQ0
    ; 65 IRQ1
    ; 66 IRQ2
    ; 67 IRQ3
    ; 68-71 reserved
    ; 72-255 built-in peripheral modules

;;------------------------------------------------------------------------------
;; Code Section
;;------------------------------------------------------------------------------
.text

;;--------------------------------------------------------------------------
;; InitDataSegAddr: Compute data buffer base in R0 and set R10
;;   - Build 0x400 via shifts on 64 in R0
;;   - R10 points at start of result buffer
;;--------------------------------------------------------------------------
InitDataSegAddr:
    MOV     #4, R0      ; Load the start of the data segment into R0 (1024)
    SHLL8   R0          ; Multiply 4 by 256 to arrive at 1024 (8 shifts left)
    MOV     R0, R10     ; R10 = buffer base (0x400)

;;--------------------------------------------------------------------------
;; BFTest: Test BF (branch if False) and BFS delayed execution
;;--------------------------------------------------------------------------
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

;;--------------------------------------------------------------------------
;; BTTest: Test BT (branch if True) and BTS delayed execution
;;--------------------------------------------------------------------------
BTTest:
    MOV.L   R0, @R10    ; WRITE 1
    ADD     #4, R10
    SETT
    BF      TestFail
    BT      BTSTest     ; take this branch (fail otherwise)
    BRA     TestFail
    NOP

BTSTest:
    SETT
    BF/S    TestFail
    MOV     #63, R1
    MOV     #2, R2
    BT/S    BRATest     ; take this branch (fail otherwise)
    MOV.L   R1, @R10    ; WRITE 63 (test memory access in delay slot)
    BRA     TestFail
    NOP

;;--------------------------------------------------------------------------
;; BRATest: Test BRA unconditional and delay slot
;;--------------------------------------------------------------------------
BRATest:
    ADD     #4, R10
    BRA     BRAFTest    ; take this branch
    MOV.L   R2, @R10
    ADD     #-20, R10   ; should not executre
    BRA     TestFail
    NOP

;;--------------------------------------------------------------------------
;; BRAFTest: Branch Relative Absolute (register offset)
;;--------------------------------------------------------------------------
BRAFTest:
    ADD     #4, R10
    MOV     #10, R3
    BRAF    R3          ; branch to BSRTest (PC+R3)
    MOV     #0, R3      ; change branching offset in R3 (should not matter)
    NOP
    BRA     TestFail
    NOP

;;--------------------------------------------------------------------------
;; BSR_RTSTest: Branch to subroutine (relative)
;;   - BSR pushes return PC, jumps to TestFunction
;;--------------------------------------------------------------------------
BSR_RTSTest:
    MOV    #10, R11
    BSR    TestFunction
    MOV    #1, R4          ; should execute
    MOV.L  R11, @R10       ; WRITE 9
    ADD    #4, R10
    BRA    BSRF_RTSTest
    NOP

;;--------------------------------------------------------------------------
;; TestFunction: Decrements R11 and returns via RTS
;       @arg R11 value
;       @return R11 = value-1
;;--------------------------------------------------------------------------
TestFunction:
    DT          R11
    RTS                     ; return from function call
    MOV     #1, R6          ; should execute
    BRA     TestFail        ; this should not

;;--------------------------------------------------------------------------
;; BSRF_RTSTest: Branch to subroutine (register form)
;;   - Offset in R12 calls TestFunction
;;--------------------------------------------------------------------------
BSRF_RTSTest:
    MOV     #-12, R12       ; offset to TestFunction
    BSRF    R12             ; call test function
    MOV     #20, R11        ; should execute
    MOV.L  R11, @R10        ; WRITE 19 on first call, 36 on second call
    ADD    #4, R10
    ; BRA    JMPTest

;;--------------------------------------------------------------------------
;; JMPTest: Test JMP to PC-relative address via MOVA
;;--------------------------------------------------------------------------
JMPTest:
    MOVA    @(3, PC), R0
    MOV    #-20, R1
    JMP     @R0
    NOP
    NOP
    BRA     TestFail

;;--------------------------------------------------------------------------
;; JSRTest: Test JSR to register-indirect subroutine
;;--------------------------------------------------------------------------
JSRTest:
    MOVA    @(0,PC),R0
    MOV     #37, R11
    JSR     @R13        ; jump to TestFunction
    MOV.L   R11, @R10
    ADD     #4, R10

;;--------------------------------------------------------------------------
;; TestSuccess/Fail: Record final pass/fail and halt
;;--------------------------------------------------------------------------
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

;;------------------------------------------------------------------------------
;; Data Section: (None required for branch tests)
;;------------------------------------------------------------------------------
.data
