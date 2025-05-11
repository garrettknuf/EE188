;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           Shift Operation Tests                             ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file tests shift operations for the SH-2 CPU.
;
; The tests are 
;
; Revision History:
;   28 Apr 25   Garrett Knuf    Initial revision.

.vectable
    PowerResetPC:           0x00000008  ; PC for power reset (0)
    PowerResetSP:           0xFFFFFFFC  ; SP for power reset (1)

.text

InitDataSegAddr:            ; calculate starting address of data segment
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    LDC     R0, GBR         ; GBR = 0x00000400 (1024)

ROTTest:
    MOV.L   @(0,GBR),R0
    ROTL    R0
    BT      TestFail
    MOV.L   R0,@(4,GBR)    ; write ROTL Num0
    MOV.L   @(1,GBR),R0
    ROTL    R0
    BF      TestFail
    MOV.L   R0,@(5,GBR)    ; write ROTL Num1
    MOV.L   @(0,GBR),R0
    ROTR    R0
    BT      TestFail
    MOV.L   R0,@(6,GBR)    ; write ROTR Num0
    MOV.L   @(1,GBR),R0
    ROTR    R0
    BF      TestFail
    MOV.L   R0,@(7,GBR)    ; write ROTR Num1

ROTCTest:
    SETT
    MOV.L   @(0,GBR),R0
    ROTCL   R0
    BT      TestFail
    MOV.L   R0,@(8,GBR)    ; write ROTCL(T=1) Num0
    CLRT                    
    MOV.L   @(1,GBR),R0
    ROTCL   R0
    BF      TestFail
    MOV.L   R0,@(9,GBR)    ; write ROTCL(T=0) Num1
    SETT
    MOV.L   @(0,GBR),R0
    ROTCR   R0
    BT      TestFail
    MOV.L   R0,@(8,GBR)    ; write ROTCR(T=1) Num0
    CLRT
    MOV.L   @(1,GBR),R0
    ROTCR   R0
    BF      TestFail
    MOV.L   R0,@(9,GBR)    ; write ROTCR(T=0) Num1

SHATest:
    SETT
    MOV.L   @(0,GBR),R0
    SHAL    R0
    BT      TestFail
    MOV.L   R0,@(10,GBR)   ; write SHAL Num0
    CLRT
    MOV.L   @(1,GBR),R0
    SHAL    R0
    BF      TestFail
    MOV.L   R0,@(11,GBR)   ; write SHAL Num1
    SETT
    MOV.L   @(0,GBR),R0
    SHAR    R0
    BT      TestFail
    MOV.L   R0,@(12,GBR)   ; write SHAR Num0
    CLRT
    MOV.L   @(1,GBR),R0
    SHAR    R0
    BT      TestFail
    MOV.L   R0,@(13,GBR)   ; write SHAR Num1

SHLTest:
    SETT
    MOV.L   @(0,GBR),R0
    SHLL    R0
    BT      TestFail
    MOV.L   R0,@(10,GBR)   ; write SHAL Num0
    CLRT
    MOV.L   @(1,GBR),R0
    SHLL    R0
    BF      TestFail
    MOV.L   R0,@(11,GBR)   ; write SHAL Num1
    SETT
    MOV.L   @(0,GBR),R0
    SHLR    R0
    BT      TestFail
    MOV.L   R0,@(12,GBR)   ; write SHAR Num0
    SETT
    MOV.L   @(1,GBR),R0
    SHLR    R0
    BT      TestFail
    MOV.L   R0,@(13,GBR)   ; write SHAR Num1

SHL2Test:
    MOV.L   @(0,GBR),R0
    SHLL2   R0
    MOV.L   R0,@(14,GBR)   ; write SHLL2 Num0
    SHLR2   R0
    MOV.L   R0,@(15,GBR)   ; write SHLR2(SHLL2 Num0)

SHL8Test:
    MOV.L   @(0,GBR),R0
    SHLL8   R0
    MOV.L   R0,@(16,GBR)   ; write SHLL8 Num0
    SHLR8   R0
    MOV.L   R0,@(17,GBR)   ; write SHLR8(SHLL8 Num0)

SHL16Test:
    MOV.L   @(0,GBR),R0
    SHLL16  R0
    MOV.L   R0,@(18,GBR)   ; write SHLL16 Num0
    SHLR16  R0
    MOV.L   R0,@(19,GBR)   ; write SHLR16(SHLL16 Num0)

TestSuccess:
    MOV     #1, R9
    MOV.L   R9,@R10 ; store SUCCESS (1)
    BRA     TestEnd

TestFail:
    MOV     #0, R9
    MOV.L   R9,@R10 ; store FAIL (0)
    ;BRA    TestEnd

TestEnd:
    SLEEP

.data

Num0:   .long b00101010101111000101110101001010 ; MSB=0,LSB=0
Num1:   .long b10111011101111010111010111001011 ; MSB=1,LSB=1





