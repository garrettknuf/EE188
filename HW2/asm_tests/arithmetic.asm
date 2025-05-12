;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                            Arithmetic Tests                                 ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file tests arithmetic operations for the SH-2 CPU.
; It writes necessary ALU results to memory using the GBR. These values can be
; evaluated after the simulation runs in a memory dump. If the Tbit is the incorrect
; value, the code will jump to TestFail and not finish the remaining tests.
;
; The tests are the arithmetic instructions in Table 5.4 of SH-2 Programming Manual.
; Tests: ADD, ADDC, ADDV, DT, NEG, NEGC, SUB, SUBC, SUBV,
;        EXTS.B, EXTS.W, EXTU.B, EXTU.W,
;        CMP/EQ, CMP/HS, CMP/GE, CMP/HI, CMP/GT, CMP/PL, CMP/PZ, CMP/PZ, CMP/STR
;
; Revision History:
;   26 Apr 25   Garrett Knuf    Initial revision.

.vectable
    PowerResetPC:           0x00000008  ; PC for power reset (0)
    PowerResetSP:           0xFFFFFFFC  ; SP for power reset (1)

.text

InitGBR:                    ; calculate starting address of data segment
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    LDC     R0, GBR         ; GBR = 0x00000400 (1024)
    ; BRA   ADDTests

ADDTests:
    SETT
    MOV     #30, R0
    MOV     #24, R1
    ADD     R1, R0      
    MOV.L   R0,@(4,GBR) ; WRITE 30+24=54
    ADD     #-5, R0     
    MOV.L   R0,@(5,GBR) ; WRITE 54-5=49
    ; BRA   ADDCTests

ADDCTests:
    CLRT
    MOV     #17, R0
    MOV     #22, R1
    ADDC    R1, R0
    MOV.L   R0,@(6,GBR) ; WRITE 17+22+T=39 where T=0
    BT      TestFail    ; carry = 0
    MOV     #-1, R0
    MOV     #53, R1
    ADDC    R1, R0
    MOV.L   R0,@(7,GBR) ; WRITE -1+53+T=52 where T=0
    BF      TestFail    ; carry = 1
    SETT
    MOV     #0, R1
    ADDC    R1, R0
    MOV.L   R0,@(8,GBR) ; WRITE 0+52+T=53 where T=1
    ;BRA    ADDVTests

ADDVTests:
    MOV.L   @(2,GBR),R0
    MOV     #1, R1
    ADDV    R1, R0
    MOV.L   R0,@(9,GBR)  ; WRITE 0x7FFFFFFF+0x00000001=0x80000000
    BF      TestFail    ; overflow = 1
    MOV.L   @(2,GBR),R0
    MOV     #-1, R1
    ADDV    R1, R0
    MOV.L   R0,@(10,GBR) ; WRITE 0x7FFFFFFF+0xFFFFFFFF=0x7FFFFFFE
    BT      TestFail    ; overflow = 0
    ;BF     DTTests

DTTests:
    MOV     #2, R2
    DT      R2
    BT      TestFail        ; R2 != 0
    DT      R2
    MOV     R2, R0
    MOV.L   R0,@(11,GBR)    ; WRITE 0
    BF      TestFail        ; R2 = 0
    ;BT     EXTTests

EXTTests:   
    MOV.L   @(1,GBR),R0 ; read 0x5555D19B
    EXTS.B  R0, R1      ; sign extend byte
    EXTS.W  R0, R2      ; sign extend word
    EXTU.B  R0, R3      ; zero extend byte
    EXTU.W  R0, R4      ; zero extend word
    MOV     R1, R0
    MOV.L   R0,@(12,GBR) ; WRITE 0xFFFFFF9B
    MOV     R2, R0
    MOV.L   R0,@(13,GBR) ; WRITE 0xFFFFD19B
    MOV     R3, R0
    MOV.L   R0,@(14,GBR) ; WRITE 0x0000009B
    MOV     R4, R0
    MOV.L   R0,@(15,GBR) ; WRITE 0x0000D19B
    ;BRA    NEGTests

NEGTests:
    SETT
    MOV     #-23, R1
    NEG     R1, R0
    MOV.L   R0,@(16,GBR) ; WRITE 0-(-23)=23
    NEGC    R1, R0
    MOV.L   R0,@(17,GBR) ; WRITE 0-(-23)-T=22 where T=1
    BF      TestFail     ; borrow = 1
    CLRT
    MOV     #49, R1
    NEGC    R1, R0
    MOV.L   R0,@(18,GBR) ; WRITE 0-49-T=-49 where T=0
    BF      TestFail     ; borrow = 1
    CLRT
    MOV     #0, R1
    NEGC    R1, R0
    MOV.L   R0,@(19,GBR) ; WRITE 0-0-T=0 where T=0
    BT      TestFail     ; borrow = 0
    ;BRA    SUBTests


SUBTests:
    SETT
    MOV     #78, R0
    MOV     #11, R1
    SUB     R1, R0
    MOV.L   R0,@(20,GBR) ; WRITE 78-11=67
    MOV     #-3, R1
    SUB     R1, R0
    MOV.L   R0,@(21,GBR) ; WRITE 67-(-3)=70
    ;BRA    SUBCTests

SUBCTests:
    SETT
    MOV     #11, R1
    SUBC    R1, R0
    MOV.L   R0,@(22,GBR)    ; WRITE 70-11-T=58 where T=1
    BT      TestFail        ; borrow = 0
    CLRT
    MOV     #80,R1
    SUBC    R1, R0      
    MOV.L   R0,@(23,GBR)    ; WRITE 58-80-T=-22 where T=0
    BF      TestFail        ; borrow = 1
    ;BRA    SUBVTests

SUBVTests:
    MOV.L   @(2,GBR),R0
    MOV     #-1, R1
    SUBV    R0, R1
    MOV     R1, R0
    MOV.L   R0,@(24,GBR) ; WRITE 0xFFFFFFFF-0x7FFFFFFF=0x80000000
    BT      TestFail    ; overflow = 0
    MOV     #1, R1
    SUBV    R1, R0
    MOV.L   R0,@(25,GBR) ; WRITE 0x80000000-0x00000001=0x7FFFFFFF
    BF      TestFail    ; overflow = 1
    ;BT     InitCMPTests

InitCMPTests:
    MOV     #17, R3     ; set register values for comparison
    MOV     #-9, R4
    MOV     #17, R5
    MOV     #30, R6
    MOV     #0, R7
    ;BRA    CMPEQTest

CMPEQTest:
    MOV     #10, R0
    CMP/EQ  #11, R0     ; 11 = 10 (false)
    BT      TestFail
    MOV     #19, R0
    CMP/EQ  #19, R0     ; 19 = 19 (true)
    BF      TestFail
    CMP/EQ  R3, R4      ; 17 = 9 (false)
    BT      TestFail
    CMP/EQ  R3, R5      ; 17 = 17 (true)
    BF      TestFail
    ;BT     CMPHSTest

CMPHSTest:
    CMP/HS  R3, R5       ; 17 >= 17 (true)
    BF      TestFail
    CMP/HS  R4, R3       ; 17 >= -9 (unsigned) (false)
    BT      TestFail
    CMP/HS  R5, R6       ; 30 >= 17 (true)
    BF      TestFail
    ;BT     CMPGETest

CMPGETest:
    CMP/GE  R3, R5       ; 17 >= 17 (true)
    BF      TestFail
    CMP/GE  R4, R3       ; 17 >= -9 (true)
    BF      TestFail
    CMP/GE  R6, R5       ; 17 >= 30 (false)
    BT      TestFail
    ;BF     CMPHITest

CMPHITest:
    CMP/HI  R3, R5       ; 17 > 17 (false)
    BT      TestFail
    CMP/HI  R4, R3       ; 17 > -9 (unsigned) (false)
    BT      TestFail
    CMP/HI  R5, R6       ; 30 > 17 (true)
    BF      TestFail
    ;BT     CMPGTTest

CMPGTTest:
    CMP/HI  R3, R5       ; 17 > 17 (false)
    BT      TestFail
    CMP/HI  R4, R3       ; 17 > -9 (true)
    BF      TestFail
    CMP/HI  R5, R6       ; 30 > 17 (true)
    BF      TestFail
    ;BT     CMPPLTest

CMPPLTest:
    CMP/PL  R3  ; 17 > 0 (true)
    BF      TestFail
    CMP/PL  R4  ; -9 > 0 (false)
    BT      TestFail
    CMP/PL  R7  ; 0 > 0 (false)
    BT      TestFail
    ;BF     CMPPZTest

CMPPZTest:
    CMP/PZ  R3  ; 17 > 0 (true)
    BF      TestFail
    CMP/PZ  R4  ; -9 > 0 (false)
    BT      TestFail
    CMP/PZ  R7  ; 0 >= 0 (true)
    BF      TestFail
    ;BT     CMPSTRTest

CMPSTRTest:
    MOV.L   @(1,GBR),R0
    MOV     R0, R3
    MOV.L   @(3,GBR),R0
    MOV     R0, R4
    CMP/STR R3, R4      ; compare 0x5555D19B and 0x5437D134
    BF      TestFail    ; byte 1 (0xD1) matches
    ADD     #127, R4
    ADD     #127, R4
    CMP/STR R3, R4      ; compare 0x5555D19B and 5555D299
    BT      TestFail    ; no bytes match
    ;BF     TestSuccess

TestSuccess:
    MOV     #1, R0
    MOV.L   R0,@(26,GBR)
    BRA     TestEnd

TestFail:
    MOV     #0, R0
    MOV.L   R0,@(26,GBR)
    ;BRA     TestEnd

TestEnd:
    SLEEP

.data

Num0:   .long   0x40000000
Num1:   .long   0x5555D19B
Num2:   .long   0x7FFFFFFF
Num3:   .long   0x5437D134
    