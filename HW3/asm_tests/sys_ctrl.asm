;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           System Control Tests                              ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   This file is an assembly test suite exercising SH-2 system control type
;   instructions to verify correct operation of the following instructions:
;   - SETT
;   - CLRT
;   - LDC   Rn,GBR/VBR/SR
;   - STC   GBR/VBR/SR,Rn
;   - LDC.L @Rn+,GBR/VBR/SR
;   - STC.L GBR/VBR/SR,@-Rn
;   - LDS   Rn,PR
;   - STS   PR,Rn
;   - LDS.L @Rn+,PR
;   - STS.L PR,@-Rn
;   - NOP
;   - RTE
;   - TRAPA
;
;   Test results are written to memory and a final
;   success/fail code is stored.
;
; Revision History:
;   27 Apr 25   Garrett Knuf    Initial revision.

;;------------------------------------------------------------------------------
;; Exception Vector Table
;;------------------------------------------------------------------------------
.vectable
    ; PowerResetPC:           0x00000050  ; PC for power reset (0)
    ; PowerResetSP:           0x00000000  ; SP for power reset (1)
    ; ManualResetPC:          0x00000000  ; PC for manual reset (2)
    ; ManualResetSP:          0x00000000  ; SP for manual reset (3)
    ; InvalidInstruction:     0x00000000  ; General invalid instruction (4)
    ; Reserved:               0x00000000  ; reserved (5)
    ; SlotInvalidInstruction: 0x00000000  ; Slot invalid instruction (6)
    ; Reserved:               0x00000000  ; reserved (7)
    ; Reserved:               0x00000000  ; reserved (8)
    ; CPUAddrError:           0x00000000  ; CPU address error (9)
    ; DTCAddrError:           0x00000000  ; DTC address error (10)
    ; InterruptNMI:           0x00000000  ; Interrupt NMI (11)
    ; InterruptUserBreak:     0x00000000  ; Interrupt UserBreak (12)
    ; Reserved:               0x00000000  ; reserved (13)
    ; Reserved:               0x00000000  ; reserved (14)
    ; Reserved:               0x00000000  ; reserved (15)
    ; ; 16-31 typically reserved (but ignoring here)
    ; TrapInstUser0:          0x000000B4  ; trap instruction (uservector) (13) (typically 32)
    ; TrapInstUser1:          0x00000000  ; trap instruction (uservector) (14) (typically 33)
    ; TrapInstUser2:          0x00000000  ; trap instruction (uservector) (15) (typically 34)
    ; TrapInstUser3:          0x00000000  ; trap instruction (uservector) (16) (typically 35)
    ; ; 36-63 trap instruction (user vector)
    ; ; 64 RQ0
    ; ; 65 IRQ1
    ; ; 66 IRQ2
    ; ; 67 IRQ3
    ; ; 68-71 reserved
    ; ; 72-255 built-in peripheral modules

;;------------------------------------------------------------------------------
;; Code Section
;;------------------------------------------------------------------------------
.text

;;--------------------------------------------------------------------------
;; Initialize Data Segment Pointers
;;   R10 -> write buffer base + offset
;;   R11 -> read buffer base
;;--------------------------------------------------------------------------
InitDataSegAddr:
    MOV     #4, R0      ; Load the start of the data segment into R0 (1024)
    SHLL8   R0          ; Multiply 4 by 258 to arrive at 1024 (8 shifts left)
    MOV     R0, R10     ; R10 = write buffer pointer
    ADD     #24, R10    ; Increment buffer write pointer
    MOV     R0, R11     ; R11 = read buffer pointer

;;--------------------------------------------------------------------------
;; BootTest: Store initial SP (R15) into write buffer
;;--------------------------------------------------------------------------
BootTest:
    MOV.L   R15, @R10       ; Write current SP (0x00000000) to buffer
    ADD     #4, R10         ; Advance write pointer

;;--------------------------------------------------------------------------
;; TbitTests: Test T flag manipulation
;;   SETT sets T=1, CLRT clears T=0
;;--------------------------------------------------------------------------
TbitTests:
    SETT                    ; Assert T flag
    BF      TestFail        ; Branch if T=0 -> failure
    CLRT                    ; Clear T flag
    BT      TestFail        ; Branch if T=1 -> failure

;;--------------------------------------------------------------------------
;; TestGBR: Verify GBR load/store
;;--------------------------------------------------------------------------
TestGBR:
    MOV     #62,R7
    LDC     R7,GBR      ; R7 = 62
    STC     GBR,R8      ; R8 = 62
    MOV.L   R8,@R10     ; WRITE 62
    ADD     #4,R10
    LDC.L   @R11+,GBR   ; Read 1024
    ADD     #4, R10     ; Counteract pre-dec
    STC.L   GBR,@-R10   ; WRITE 1024
    ADD     #4, R10

;;--------------------------------------------------------------------------
;; TestSR: Verify SR (status register) load/store
;;--------------------------------------------------------------------------
TestSR:
    MOV     #23,R7
    LDC     R7,SR       ; R7 = 23
    STC     SR,R8       ; R8 = 23
    MOV.L   R8,@R10     ; WRITE 23
    ADD     #4,R10
    NOP
    LDC.L   @R11+,SR    ; Read 80
    ADD     #4, R10     ; Counteract pre-dec
    NOP
    STC.L   SR,@-R10    ; WRITE 80
    ADD     #4, R10

;;--------------------------------------------------------------------------
;; TestVBR: Verify VBR (vector base register) load/store
;;--------------------------------------------------------------------------
TestVBR:
    MOV     #42,R7
    LDC     R7,VBR      ; R7 = 42
    STC     VBR,R8      ; R8 = 42
    MOV.L   R8,@R10     ; WRITE 42
    ADD     #4,R10
    LDC.L   @R11+,VBR   ; Read 2048
    ADD     #4, R10     ; Counteract pre-dec
    STC.L   VBR,@-R10   ; WRITE 2048
    ADD     #4, R10
    MOV     #0,R2       ; Set VBR back to 0
    LDC     R2,VBR

;;--------------------------------------------------------------------------
;; TestPR: Verify PR (processor register) load/store
;;--------------------------------------------------------------------------
TestPR:
    MOV     #98,R7
    LDS     R7,PR      ; R7 = 98
    STS     PR,R8      ; R8 = 98
    MOV.L   R8,@R10    ; WRITE 98
    ADD     #4,R10
    LDS.L   @R11+,PR   ; Read 432
    ADD     #4, R10    ; Counteract pre-dec
    STS.L   PR,@-R10   ; WRITE 432
    ADD     #4, R10

;;--------------------------------------------------------------------------
;; Test Trapa: GOTO TRAPA test
;;--------------------------------------------------------------------------
    BRA    TrapaTests

;;--------------------------------------------------------------------------
;; Test NOP (Trapa vector address)
;;--------------------------------------------------------------------------
NOPTests:
    NOP             ; TRAPA #16 will point here
    MOV     #3,R8   ; Put a test value to prove it got here
    MOV.L   R8,@R10 ; WRITE 3
    ADD     #4,R10

;;--------------------------------------------------------------------------
;; Test RTE: Verify RTE instruction returns with branch slot
;;--------------------------------------------------------------------------
RTETests:
    SETT    ; Change SR to test SR restore
    RTE
    NOP     ; Branch slot NOP
; IF CODE GETS PAST RTE SLOT THEN IT HAS FAILED
    BRA    TestFail

;;--------------------------------------------------------------------------
;; Test Trapa: Verify TRAPA instruction triggers trap
;;--------------------------------------------------------------------------
TrapaTests:
    NOP     ; Trapa Test
    CLRT
    TRAPA   #16
    STC     SR,R8   ; Put SR into R8 and put into memory to verify SR restore
    MOV.L   R8,@R10 ; WRITE 80
    ADD     #4,R10


;;--------------------------------------------------------------------------
;; TestSuccess/Fail: Record final pass/fail code
;;--------------------------------------------------------------------------
TestSuccess:
    MOV     #1, R9
    MOV.L   R9, @R10 ; store SUCCESS (1)
    BRA     TestEnd

TestFail:
    MOV     #0, R9
    MOV.L   R9, @R10 ; store FAIL (0)
    ;BRA    TestEnd

TestEnd:
    SLEEP

;;------------------------------------------------------------------------------
;; Data Section:
;;------------------------------------------------------------------------------
.data

GBRVal: .long   1024
SRVal:  .long   80
VBRVal: .long   2048
PRVal:  .long   432
