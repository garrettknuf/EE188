;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           Logic Operation Tests                             ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file tests logic operations for the SH-2 CPU.
;
; The tests are the arithmetic instructions in Table 5.5 of SH-2 Programming Manual.
; Tests: ADD, ADDC, ADDV, DT, NEG, NEGC, SUB, SUBC, SUBV,
;        EXTS.B, EXTS.W, EXTU.B, EXTU.W,
;        CMP/EQ, CMP/HS, CMP/GE, CMP/HI, CMP/GT, CMP/PL, CMP/PZ, CMP/PZ, CMP/STR
;
; Revision History:
;   27 Apr 25   Garrett Knuf    Initial revision.

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

ANDTest:
    MOV     #3, R0
    MOV     #10, R1
    AND     R1, R0  ; b0011 & b1010 = b0010 = 2 (reg & reg)
    CMP/EQ  #2, R0
    BF      TestFail
    MOV     #10, R0
    AND     #12, R0 ; b1100 & b1010 = b1000 = 8 (imm & reg)
    CMP/EQ  #8, R0
    BF      TestFail
    ; TODO: AND.B

NOTTest:
    MOV     #9, R0
    NOT     R0, R0  ; ~b1001 = b0110 = b111...1110110 = -10
    CMP/EQ  #-10, R0
    BF      TestFail

ORTest:
    MOV     #10, R0
    MOV     #3, R1
    OR      R1, R0  ; b0011 | b1010 = b1011 = 11 (reg | reg)
    CMP/EQ  #11, R0
    BF      TestFail
    MOV     #10, R0
    OR      #3, R0  ; b0011 | b1010 = b1011 = 11 (imm | reg
    BF      TestFail
    ; TODO: OR.B

TASTest:
    ; TODO: TAS.B

TSTTest:
    MOV     #12, R0
    MOV     #3, R1
    TST     R0, R1  ; b1100 & b0011 = b0000 (T=1) (reg & reg)
    BF      TestFail
    TST     #3, R0  ; b1100 & b0011 = b0000 (T=1) (imm & reg)
    BF      TestFail
    MOV     #13, R0
    MOV     #3, R1
    TST     R0, R1  ; b1100 & b0011 = b0001 (T=0) (reg & reg)
    BT      TestFail
    TST     #3, R0  ; b1100 & b0011 = b0001 (T=0) (imm & reg)
    BT      TestFail
    ; TODO: TST.B

XORTest:
    MOV     #3, R0
    MOV     #10, R1
    XOR     R1, R0  ; b0011 ^ b1010 = b1001 = 9 (reg & reg)
    CMP/EQ  #9, R0
    BF      TestFail
    XOR     #5, R0  ; b1001 ^ b0101 = b1100 = 12 (imm & reg)
    CMP/EQ  #12, R0
    BF      TestFail
    ; TODO: AND.B

TestSuccess:
    MOV     #1, R9
    MOV.L   R9, @R10 ; store SUCCESS (1)

    SETT
    BT      TestEnd

    ;BRA     TestEnd

TestFail:
    MOV     #0, R9
    MOV.L   R9, @R10 ; store FAIL (0)
    ;BRA    TestEnd

TestEnd:
    END_SIM true
