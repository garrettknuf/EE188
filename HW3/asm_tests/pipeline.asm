;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                                Pipeling Test                                ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description :
;   
;
; Revision History:
;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
;; InitDataSegAddr: Compute data buffer base and set R10
;;   - Use R0 to build 0x400 (64 << 4 shifts)
;;   - Skip first word (4 bytes) by advancing R10
;;   - R10 points at first storage location for F(0)
;;--------------------------------------------------------------------------
InitDataSegAddr:
    MOV     #4, R0      ; Load the start of the data segment into R0 (1024)
    SHLL8   R0          ; Multiply 4 by 256 to arrive at 1024 (8 shifts left)
    MOV     R0, R10     ; R10 = 0x00000400 (base of data buffer)

TestWriting:
    MOV     #15, R0
    MOV     #27, R1
    MOV     #63, R2
    MOV.L   R0, @R10    ; WRITE 15
    ADD     #4, R10
    MOV     R10, R11
    ADD     #4, R11
    MOV.L   R1, @R10    ; WRITE 27
    MOV.L   R2, @R11    ; Write 63 immediately after another write

TestReading:


TestBranching:
    ; tested in branch.asm

TestEnd:
    SLEEP
