;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                           Shift Operation Tests                             ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   This file is an assembly test suite exercising SH-2 system shift type
;   instructions to verify correct operation of the following instructions:
;   - ROTL
;   - ROTR
;   - ROTCL
;   - ROTCR
;   - SHAL
;   - SHAR
;   - SHLL
;   - SHLR
;   - SHLL2/SHLR2
;   - SHLL8/SHLR8
;   - SHLL16/SHLR16
;
;   Test results are written to memory via the GBR base register and records
;   a final pass/fail code in memory at the end.
;
; Revision History:
;   28 Apr 25   Garrett Knuf    Initial revision.

;;------------------------------------------------------------------------------
;; Exception Vector Table
;;------------------------------------------------------------------------------
.vectable
;    PowerResetPC:           0x00000008  ; PC for power reset (0)
;    PowerResetSP:           0xFFFFFFFC  ; SP for power reset (1)

;;------------------------------------------------------------------------------
;; Code Section
;;------------------------------------------------------------------------------
.text

;;--------------------------------------------------------------------------
;; InitGBR: Set GBR to start of data buffer (0x400) via R0 shifts
;;--------------------------------------------------------------------------
InitGBR:                  ; calculate starting address of data segment
    MOV     #64, R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    SHLL    R0
    LDC     R0, GBR        ; GBR = 0x00000400 (1024)
    ; BRA   ROTTest

;;--------------------------------------------------------------------------
;; ROTTest: Test simple rotate left/right without carry
;;--------------------------------------------------------------------------
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
    ; BRA   ROTCTest

;;--------------------------------------------------------------------------
;; ROTCTest: Test rotate through carry (ROTCL/ROTCR)
;;--------------------------------------------------------------------------
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
    MOV.L   R0,@(10,GBR)    ; write ROTCR(T=1) Num0
    CLRT
    MOV.L   @(1,GBR),R0
    ROTCR   R0
    BF      TestFail
    MOV.L   R0,@(11,GBR)    ; write ROTCR(T=0) Num1
    ; BRA   SHATest

;;--------------------------------------------------------------------------
;; SHATest: Test arithmetic shifts (SHAL/SHAR)
;;--------------------------------------------------------------------------
SHATest:
    SETT
    MOV.L   @(0,GBR),R0
    SHAL    R0
    BT      TestFail
    MOV.L   R0,@(12,GBR)   ; write SHAL Num0
    CLRT
    MOV.L   @(1,GBR),R0
    SHAL    R0
    BF      TestFail
    MOV.L   R0,@(13,GBR)   ; write SHAL Num1
    SETT
    MOV.L   @(0,GBR),R0
    SHAR    R0
    BT      TestFail
    MOV.L   R0,@(14,GBR)   ; write SHAR Num0
    CLRT
    MOV.L   @(1,GBR),R0
    SHAR    R0
    BF      TestFail
    MOV.L   R0,@(15,GBR)   ; write SHAR Num1
    ; BRA   SHLTest

;;--------------------------------------------------------------------------
;; SHLTest: Test logical shifts (SHLL/SHLR)
;;--------------------------------------------------------------------------
SHLTest:
    SETT
    MOV.L   @(0,GBR),R0
    SHLL    R0
    BT      TestFail
    MOV.L   R0,@(16,GBR)   ; write SHAL Num0
    CLRT
    MOV.L   @(1,GBR),R0
    SHLL    R0
    BF      TestFail
    MOV.L   R0,@(17,GBR)   ; write SHAL Num1
    SETT
    MOV.L   @(0,GBR),R0
    SHLR    R0
    BT      TestFail
    MOV.L   R0,@(18,GBR)   ; write SHAR Num0
    SETT
    MOV.L   @(1,GBR),R0
    SHLR    R0
    BF      TestFail
    MOV.L   R0,@(19,GBR)   ; write SHAR Num1
    ; BRA   SHL2Test

;;--------------------------------------------------------------------------
;; SHL2/8/16 Tests: Test multi-bit shifts
;;--------------------------------------------------------------------------
SHL2Test:
    MOV.L   @(0,GBR),R0
    SHLL2   R0
    MOV.L   R0,@(20,GBR)   ; write SHLL2 Num0
    SHLR2   R0
    MOV.L   R0,@(21,GBR)   ; write SHLR2(SHLL2 Num0)
    ; BRA   SHL8Test

SHL8Test:
    MOV.L   @(0,GBR),R0
    SHLL8   R0
    MOV.L   R0,@(22,GBR)   ; write SHLL8 Num0
    SHLR8   R0
    MOV.L   R0,@(23,GBR)   ; write SHLR8(SHLL8 Num0)
    ; BRA   SHL16Test

SHL16Test:
    MOV.L   @(0,GBR),R0
    SHLL16  R0
    MOV.L   R0,@(24,GBR)   ; write SHLL16 Num0
    SHLR16  R0
    MOV.L   R0,@(25,GBR)   ; write SHLR16(SHLL16 Num0)
    ; BRA   TestSuccess

;;--------------------------------------------------------------------------
;; TestSuccess/Fail: Record final pass/fail flag at offset 26
;;--------------------------------------------------------------------------
TestSuccess:
    MOV     #1, R0
    MOV.L   R0,@(26,GBR) ; store SUCCESS (1)
    BRA     TestEnd

TestFail:
    MOV     #0, R0
    MOV.L   R0,@(26,GBR) ; store FAIL (0)
    ;BRA    TestEnd

TestEnd:
    SLEEP

;;------------------------------------------------------------------------------
;; Data Section: Test patterns
;;------------------------------------------------------------------------------
.data

Num0:   .long b00101010101111000101110101001010 ; MSB=0,LSB=0
Num1:   .long b10111011101111010111010111001011 ; MSB=1,LSB=1

