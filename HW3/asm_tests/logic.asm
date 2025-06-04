;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           Logic Operation Tests                             ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   This file is an assembly test suite exercising SH-2 system logic type
;   instructions to verify correct operation of the following instructions:
;   - AND Rm,Rn
;   - AND #imm,R0
;   - AND.B #imm,@(R0,GBR) 
;   - OR Rm,Rn
;   - OR #imm,R0
;   - OR #imm,@(R0,GBR)
;   - NOT
;   - XOR Rm,Rn
;   - XOR #imm,R0
;   - XOR #imm,@(R0,GBR)
;   - TST Rm,Rn
;   - TST #imm,R0
;   - TST #imm,@(R0,GBR)
;   - TAS
;
;   Test results are written to memory via the GBR base register and records
;   a final pass/fail code in memory at the end.
;
; Revision History:
;   27 Apr 25   Garrett Knuf    Initial revision.

;;------------------------------------------------------------------------------
;; Exception Vector Table
;;------------------------------------------------------------------------------
.vectable
    ; PowerResetPC:           0x00000008  ; PC for power reset (0)
    ; PowerResetSP:           0xFFFFFFFC  ; SP for power reset (1)

;;------------------------------------------------------------------------------
;; Code Section
;;------------------------------------------------------------------------------
.text

;;--------------------------------------------------------------------------
;; InitDataSegAddr: Initialize GBR and R10
;;   - Builds address 0x400 (1024) in R0 via shifts
;;   - Loads R0 into GBR as data buffer base
;;   - Sets R10 = GBR + 8 to skip header region
;;--------------------------------------------------------------------------
InitDataSegAddr:
    MOV     #4, R0      ; Load the start of the data segment into R0 (1024)
    SHLL8   R0          ; Multiply 4 by 258 to arrive at 1024 (8 shifts left)
    LDC     R0, GBR     ; GBR = 0x400: base of result buffer
    MOV     R0, R10     ; R10 points to start of buffer
    ADD     #8, R10     ; Skip initial offsets for tests

;;--------------------------------------------------------------------------
;; ANDTest: Test AND instruction (reg/reg, imm/reg, byte form)
;;--------------------------------------------------------------------------
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

;;--------------------------------------------------------------------------
;; NOTTest: Test NOT instruction
;;--------------------------------------------------------------------------
NOTTest:
    MOV     #9, R0
    NOT     R0, R0  ; ~b1001 = b0110 = b111...1110110 = -10
    CMP/EQ  #-10, R0
    BF      TestFail
    ;BRA    ORTest

;;--------------------------------------------------------------------------
;; ORTest: Test OR instruction (reg/reg, imm/reg, byte form)
;;--------------------------------------------------------------------------
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

;;--------------------------------------------------------------------------
;; TASTest: Test TAS instruction (test and set)
;;   - Tests byte at @GBR+4 then @GBR+5, checks T flag
;;--------------------------------------------------------------------------
TASTest:
    STC     GBR, R3
    ADD     #4, R3
    TAS.B   @R3         ; 0x70 -> 0xF0 and T = 0
    BT      TestFail
    ADD     #1, R3
    TAS.B   @R3         ; 0x00 -> 0x80 and T = 1
    BF      TestFail
    ;BT     TSTTest

;;--------------------------------------------------------------------------
;; TSTTest: Test TST instruction (test) sets T flag only
;;--------------------------------------------------------------------------
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

;;--------------------------------------------------------------------------
;; XORTest: Test XOR instruction (reg/reg, imm/reg, byte form)
;;--------------------------------------------------------------------------
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

;;--------------------------------------------------------------------------
;; RMWBranchSlotTest: Test read, modify, write instruction in branch slot
;;--------------------------------------------------------------------------
RMWBranchSlotTest1:
    MOV     #6, R0
    BRA     RMWBranchSlotTest2  ; test a RMW instruction in the branch slot
    AND.B   #38,@(R0,GBR)       ; read 0x55, AND 0x26, write 0x04
    NOP
    BRA     TestFail

RMWBranchSlotTest2:
    MOVA    @(3, PC), R0
    MOV     R0, R1
    MOV     #7, R0
    JMP     @R1              ; jump to TestSuccess
    OR.B    #93,@(R0,GBR)    ; read 0x55, OR 0x5D, write 0x5D
    BRA     TestFail

;;--------------------------------------------------------------------------
;; TestSuccess/Fail: Write final pass/fail code and halt
;;--------------------------------------------------------------------------
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

;;------------------------------------------------------------------------------
;; Data Section: Test patterns and workspace
;;   Num0, Num1: bytes for AND/OR tests
;;   Num2, Num3: bytes for XOR/TAS tests
;;   Num4: word for alignment
;;------------------------------------------------------------------------------
.data
Num0:   .byte   0x39        ; 0b00111001
Num1:   .byte   0x53        ; 0b01010011
Num2:   .byte   0x95        ; 0b10010101
Num3:   .byte   0xC3        ; 0b11000011
Num4:   .long   0x70005555  ; alignment/padding
