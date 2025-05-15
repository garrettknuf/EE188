;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           System Control Tests                              ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file tests system control instructions for the SH-2.
;
; The tests are 
;
; Revision History:
;   27 Apr 25   Garrett Knuf    Initial revision.

.vectable
    PowerResetPC:           0x00000050  ; PC for power reset (0)
    PowerResetSP:           0x80000000  ; SP for power reset (1)
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
    TrapInstUser0:          0x000000BA  ; trap instruction (uservector) (13) (typically 32)
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

.text

InitDataSegAddr:
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    MOV     R0, R10 ; R10 is pointer to data to write to
    ADD     #24, R10
    MOV     R0, R11 ; R11 is pointer to data to read from

BootTest:
    MOV.L   R15, @R10   ; write 0xFFFFFFFF (SP)
    ADD     #4, R10

TbitTests:
    SETT                ; T=1
    BF      TestFail    ; fail if T=0
    CLRT                ; T= 0
    BT      TestFail    ; fail if T=1
    ;BRA    LoadCtrlRegTests

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

TestSR:
    MOV     #23,R7
    LDC     R7,SR       ; R7 = 23
    STC     SR,R8       ; R8 = 23
    MOV.L   R8,@R10     ; WRITE 23
    ADD     #4,R10
    LDC.L   @R11+,SR    ; Read 80
    ADD     #4, R10     ; Counteract pre-dec
    STC.L   SR,@-R10    ; WRITE 80
    ADD     #4, R10

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
; AFTER TESTING PR BEGIN TESTING TRAPA
    BRA    TrapaTests

; LoadCtrlRegTests:
;     LDC     Rm, SR
;     LDC     Rm, GBR
;     LDC     Rm, VBR
;     LDC.L   @Rm+, SR
;     LDC.L   @Rm+, GBR
;     LDC.L   @Rm+, VBR
;     ;BRA    LoadSysRegTests

; LoadSysRegTests:
;     LDS     Rm, PR
;     LDS.L   @Rm+,PR
;     ;BRA    NOPTests

; NOPTests:
    NOP     ; NOP Tests
    NOP
    NOP
    NOP
;     ;BRA    RTETests

; RTETests:
    SETT    ; RTE Tests
    RTE
    NOP
; IF CODE GETS PAST RTE SLOT THEN IT HAS FAILED
    BRA    TestFail
;     ;BRA    StoreCtrlRegTests

; StoreCtrlRegTests:
;     STC     SR, Rn
;     STC     GBR, Rn
;     STC     VBR, Rn
;     STC.L   SR, @-Rn
;     STC.L   GBR, @-Rn
;     STC.L   VBR, @-Rn
;     ;BRA    StoreSysRegTests

; StoreSysRegTests:
;     STS     PR, Rn
;     STS.L   PR, @-Rn
;     ;BRA    TrapaTests

TrapaTests:
    NOP     ; Trapa Test
    NOP
    TRAPA   #16
    NOP
    NOP
;     ;BRA    TestSuccess

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

.data

GBRVal: .long   1024
SRVal:  .long   80
VBRVal: .long   2048
PRVal:  .long   432