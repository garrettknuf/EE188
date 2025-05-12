;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           Logic Operation Tests                             ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file tests logic operations for the SH-2 CPU.
;
; The tests are the logic instructions in Table 5.5 of SH-2 Programming Manual.
;
; Revision History:
;   27 Apr 25   Garrett Knuf    Initial revision.

.vectable
    PowerResetPC:           0x00000008  ; PC for power reset (0)
    PowerResetSP:           0xFFFFFFFC  ; SP for power reset (1)

.text

InitDataSegAddr:
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    LDC     R0, GBR
    MOV     R0, R10 ; 1024
    ADD     #8, R10
    ;BRA    ANDTest

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
    MOV     #0, R0
    AND.B   #83,@(R0,GBR) ; b00111001 & b01010011 = 00010001
    ;BRA    NOTTest

NOTTest:
    MOV     #9, R0
    NOT     R0, R0  ; ~b1001 = b0110 = b111...1110110 = -10
    CMP/EQ  #-10, R0
    BF      TestFail
    ;BRA    ORTest

ORTest:
    MOV     #10, R0
    MOV     #3, R1
    OR      R1, R0  ; b0011 | b1010 = b1011 = 11 (reg | reg)
    CMP/EQ  #11, R0
    BF      TestFail
    MOV     #10, R0
    OR      #3, R0  ; b0011 | b1010 = b1011 = 11 (imm | reg
    BF      TestFail
    MOV     #1,R0
    OR.B    #-106,@(R0,GBR) ; b01010011 | b10010110 = b11010111
    ;BRA    TASTest

TASTest:
    STC     GBR, R3
    ADD     #4, R3
    TAS.B   @R3         ; 0x70 -> 0xF0 and T = 0
    BT      TestFail
    ADD     #1, R3
    TAS.B   @R3         ; 0x00 -> 0x80 and T = 1
    BF      TestFail
    ;BT     TSTTest

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
    MOV     #2, R0
    TST.B   #89,@(R0,GBR)   ; b10010101 & b01011001 = b00010001
    BT      TestFail
    TST.B   #106,@(R0,GBR)  ; b10010101 & b01101010 = b00000000
    BF      TestFail
    ;BT     XORTest

XORTest:
    MOV     #3, R0
    MOV     #10, R1
    XOR     R1, R0  ; b0011 ^ b1010 = b1001 = 9 (reg & reg)
    CMP/EQ  #9, R0
    BF      TestFail
    XOR     #5, R0  ; b1001 ^ b0101 = b1100 = 12 (imm & reg)
    CMP/EQ  #12, R0
    BF      TestFail
    MOV     #3, R0
    XOR.B   #89,@(R0,GBR)   ; b11000011 ^ b01011001 = b10011010
    ;BRA    TestSuccess

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
    SLEEP

.data

Num0: .byte 0x39
Num1: .byte 0x53
Num2: .byte 0x95
Num3: .byte 0xC3
Num4: .long 0x70007777
