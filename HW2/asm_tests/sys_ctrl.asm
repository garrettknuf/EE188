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
    PowerResetSP:           0xFFFFFFFF  ; SP for power reset (1)
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

.text

InitDataSegAddr:
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    MOV     R0, R10 ; 1024

BootTest:
    MOV.L   R15, @R10   ; write 0xFFFFFFFF (SP)
    ADD     #4, R10

; TbitTests:
;     SETT                ; T=1
;     BF      TestFail    ; fail if T=0
;     CLRT                ; T= 0
;     BT      TestFail    ; fail if T=1
;     ;BRA    LoadCtrlRegTests

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
;     NOP
;     NOP
;     NOP
;     NOP
;     ;BRA    RTETests

; RTETests:
;     RTE
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

; TrapaTests:
;     TRAPA   #8
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
    END_SIM true

.data

; SRVal:  .long   b; TODO
; GBRVal: .long   1024
; VBRVal: .long   1028
