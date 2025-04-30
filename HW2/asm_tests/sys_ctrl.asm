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

.text

InitDataSegAddr:
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    MOV     R0, R10 ; 1024

TbitTests:
    SETT                ; T=1
    BF      TestFail    ; fail if T=0
    CLRT                ; T= 0
    BT      TestFail    ; fail if T=1
    ;BRA    LoadCtrlRegTests

LoadCtrlRegTests:
    LDC     Rm, SR
    LDC     Rm, GBR
    LDC     Rm, VBR
    LDC.L   @Rm+, SR
    LDC.L   @Rm+, GBR
    LDC.L   @Rm+, VBR
    ;BRA    LoadSysRegTests

LoadSysRegTests:
    LDS     Rm, PR
    LDS.L   @Rm+,PR
    ;BRA    NOPTests

NOPTests:
    NOP
    NOP
    NOP
    NOP
    ;BRA    RTETests

RTETests:
    RTE
    ;BRA    StoreCtrlRegTests

StoreCtrlRegTests:
    STC     SR, Rn
    STC     GBR, Rn
    STC     VBR, Rn
    STC.L   SR, @-Rn
    STC.L   GBR, @-Rn
    STC.L   VBR, @-Rn
    ;BRA    StoreSysRegTests

StoreSysRegTests:
    STS     PR, Rn
    STS.L   PR, @-Rn
    ;BRA    TrapaTests

TrapaTests:
    TRAPA   #8
    ;BRA    TestSuccess

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
