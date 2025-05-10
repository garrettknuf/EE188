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

InitGBR:                    ; set GBR to prepare writing to memory
    MOV     #100, R1          ; GBR = 
    MOV     #100, R2          ; GBR = 
    ADD     R2, R1
    MOV     #56, R2          ; GBR = 
    ADD     R2, R1
    SHLL    R1
    SHLL    R1
    ; MOV.L   #100, R1
    LDC     R1, GBR

ADDTests:
    SETT                ; t-bit should not affect result
    MOV     #30, R0
    MOV     #24, R1
    ADD     R1, R0      ; add reg to reg
    MOV.L   R0,@(0,GBR) ; [GBR+0] = 54
    ADD     #-5, R0     ; add imm to reg
    MOV.L   R0,@(1,GBR) ; [GBR+4] = 49

ADCTest:
    CLRT                ; add with carry (T = 0)
    MOV     #17, R0
    MOV     #22, R1
    ADDC    R1, R0      ; T = 0
    MOV.L   R0,@(2,GBR) ; [GBR+8] = 39
    BT      TestFail
    MOV     #-1, R0
    MOV     #53, R1
    ADDC    R1, R0      ; T = 1
    MOV.L   R0,@(3,GBR) ; [GBR+12] = 52
    BF      TestFail
    MOV     #0, R1
    ADDC    R1, R0
    MOV.L   R0,@(4,GBR) ; [GBR+16] = 53

ADDVTest:
    ; TODO

DTTest:


EXTTest:   
    MOV.L   @R10, R0    ; read in testing value
    ADD     #4, R10
    EXTS.B  R0, R1      ; sign extend byte
    EXTS.W  R0, R2      ; sign extend word
    EXTU.B  R0, R3      ; zero extend byte
    EXTU.B  R0, R4      ; zero extend word
    MOV.L   R0, @R11    ; WRITE = 
    ADD     #4, R11     
    MOV.L   R1, @R11    ; WRITE = 
    ADD     #4, R11     
    MOV.L   R2, @R11    ; WRITE = 
    ADD     #4, R11     
    MOV.L   R3, @R11    ; WRITE = 
    ADD     #4, R11     

NEGTest:
    SETT                ; set T=1
    MOV     #-23, R0
    NEG     R0, R1      ; 0-(-23) = 23      | test NEG
    NEGC    R0, R2      ; 0-(-23)-1 = 22    | test NEGC
    BT      TestFail
    MOV     #72, R0
    NEG     R0, R3      ; 0-72 = -72
    MOV.L   R0, @R11    ; WRITE = 23
    ADD     #4, R11     
    MOV.L   R1, @R11    ; WRITE = 22
    ADD     #4, R11     
    MOV.L   R1, @R11    ; WRITE = -72
    ADD     #4, R11  

SUBTest:

SUBCTest:

SUBVTest:


InitCMPTests:
    MOV     #17, R3     ; set register values for comparison
    MOV     #-9, R4
    MOV     #17, R5
    MOV     #30, R6
    MOV     #0, R7

CMPEQTest:
    MOV     #10, R0
    CMP/EQ  #11, R0     ; 11 = 0 (false)
    BT      TestFail
    MOV     #19, R0
    CMP/EQ  #19, R0     ; 19 = 19 (true)
    BF      TestFail
    CMP/EQ  R3, R4      ; 17 = 9 (false)
    BT      TestFail
    CMP/EQ  R3, R5      ; 17 = 17 (true)
    BF      TestFail

CMPHSTest:
    CMP/HS  R3, R5       ; 17 >= 17 (true)
    BF      TestFail
    CMP/HS  R4, R3       ; 17 >= -9 (unsigned) (false)
    BT      TestFail
    CMP/HS  R5, R6       ; 30 >= 17 (true)
    BF      TestFail

CMPGETest:
    CMP/GE  R3, R5       ; 17 >= 17 (true)
    BF      TestFail
    CMP/GE  R4, R3       ; 17 >= -9 (true)
    BF      TestFail
    CMP/GE  R6, R5       ; 17 >= 30 (false)
    BT      TestFail

CMPHITest:
    CMP/HI  R3, R5       ; 17 > 17 (false)
    BT      TestFail
    CMP/HI  R4, R3       ; 17 > -9 (unsigned) (false)
    BT      TestFail
    CMP/HI  R5, R6       ; 30 > 17 (true)
    BF      TestFail

CMPGTTest:
    CMP/HI  R3, R5       ; 17 > 17 (false)
    BT      TestFail
    CMP/HI  R4, R3       ; 17 > -9 (true)
    BF      TestFail
    CMP/HI  R5, R6       ; 30 > 17 (true)
    BF      TestFail

CMPPLTest:
    CMP/PL  R3  ; 17 > 0 (true)
    BF      TestFail
    CMP/PL  R4  ; -9 > 0 (false)
    BT      TestFail
    CMP/PL  R7  ; 0 > 0 (false)
    BT      TestFail

CMPPZTest:
    CMP/PZ  R3  ; 17 > 0 (true)
    BF      TestFail
    CMP/PZ  R4  ; -9 > 0 (false)
    BT      TestFail
    CMP/PZ  R7  ; 0 >= 0 (true)
    BF      TestFail

CMPSTRTest:
    MOV.L   @R10+, R0
    MOV.L   @R10+, R1
    CMP/STR R0, R1
    BF      TestFail
    MOV     #0, R1
    BT      TestFail

TestSuccess:
    MOV     #1, R0
    MOV.L   R0, @R11
    BRA     TestEnd

TestFail:
    MOV     #0, R0
    MOV.L   R0, @R11
    ;BRA     TestEnd

TestEnd:
    SLEEP

    