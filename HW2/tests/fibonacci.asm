;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                             ;
;                    Fibonacci Sequence Test                                  ;
;                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.text

FibInit:
    MOV     #0, R1  ; F(0)
    MOV     #1, R2  ; F(1)
    MOV     #10, R3 ; N = 10

FibLoop:
    MOV     R1, R4  ; temp = F(n-2)
    ADD     R2, R4  ; F(n) = F(n-1) + F(n-2)
    MOV     R2, R1  ; Shift: R1 = R2
    MOV     R4, R2  ; R2 = F(n)
    DT      R3      ; counter -= 1
    BF      FibLoop