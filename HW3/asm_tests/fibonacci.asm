;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                          Fibonacci Sequence Test                            ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description :
;   Calculates the Fibonacci sequence F(0)..F(N) on the SH-2 CPU, storing
;   each term sequentially in memory. Uses registers R1 and R2 as the
;   two most recent Fibonacci values, R3 as the loop counter, and R10 as
;   the data buffer pointer. Terminates by halting the CPU.
;
; Workflow:
;   1. Initialize R0 to base address of data buffer (0x400 via shifts)
;   2. Set R10 to point at buffer start (skip header word)
;   3. Initialize F(0)=0 in R1, F(1)=1 in R2, N in R3
;   4. Store initial terms to memory
;   5. Loop: compute next term in R4, store, rotate registers, decrement
;   6. Continue until counter expires, then halt
;
; Revision History:
;   15 May 25   George Ore     Documented Fibonacci sequence test
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
    ADD     #4, R10     ; Skip header word in buffer
    MOV     R0, R10     ; R10 = 0x00000400 (base of data buffer)

;;--------------------------------------------------------------------------
;; FibInit: Initialize Fibonacci registers and store F(0), F(1)
;;--------------------------------------------------------------------------
FibInit:
    MOV     #0, R1  ; F(0)
    MOV     #1, R2  ; F(1)
    MOV     #10, R3 ; N = 10
    MOV.L   R1, @R10    ; store initial two numbers (0 and 1)
    ADD     #4, R10
    MOV.L   R2, @R10
    ADD     #4, R10

;;--------------------------------------------------------------------------
;; FibLoop: Generate next Fibonacci term until R3 underflows
;;   - R4 = R1 + R2
;;   - Store R4, shift R1=R2, R2=R4
;;   - DT R3 and branch if not zero
;;--------------------------------------------------------------------------
FibLoop:
    MOV     R1, R4  ; temp = F(n-2)
    ADD     R2, R4  ; F(n) = F(n-1) + F(n-2)
    MOV.L   R4, @R10    ; store result
    ADD     #4, R10
    MOV     R2, R1  ; Shift: R1 = R2
    MOV     R4, R2  ; R2 = F(n)
    DT      R3      ; counter -= 1
    BF      FibLoop

;;--------------------------------------------------------------------------
;; TestEnd: Halt CPU when sequence generation complete
;;--------------------------------------------------------------------------
TestEnd:
    SLEEP
