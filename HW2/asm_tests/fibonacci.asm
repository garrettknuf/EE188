;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                          Fibonacci Sequence Test                            ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    ADD     #4, R10
    MOV     R0, R10 ; 1024

FibInit:
    MOV     #0, R1  ; F(0)
    MOV     #1, R2  ; F(1)
    MOV     #10, R3 ; N = 10
    MOV.L   R1, @R10    ; store initial two numbers (0 and 1)
    ADD     #4, R10
    MOV.L   R2, @R10
    ADD     #4, R10

FibLoop:
    MOV     R1, R4  ; temp = F(n-2)
    ADD     R2, R4  ; F(n) = F(n-1) + F(n-2)
    MOV.L   R4, @R10    ; store result
    ADD     #4, R10
    MOV     R2, R1  ; Shift: R1 = R2
    MOV     R4, R2  ; R2 = F(n)
    DT      R3      ; counter -= 1
    BF      FibLoop
    NOP

TestEnd:
    END_SIM true
