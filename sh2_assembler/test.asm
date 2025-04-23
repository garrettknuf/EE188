; Test Assembly code for SH-2 Assembler

; ----------------------------  CODE SECTION ----------------------------------
.text

Main:
    CLRT
    MOVT    R0
    STC     VBR,R2
    TAS.B   @R7
    STS.L   PR,@-R2
    LDC     R14,GBR
    LDC     R11,SR
    JMP     @R2
    LDC.L   @R5+,SR
    BRAF    R13
    EXTU.B  R9,R2
Label1:
    MOV.W   R1,@R14
    MOV.B   @R12+,R0
    MOV.W   R4, @-R9
    BF      Label1
    MOV.L   R1,@(R0, R6)
    MOV.B   @(3,R2),R0
    MOV.W   R0,@(12,R3)
    BF      Label2
    MOV.L   @(-3,R7),R11
Label2:
    MOV.L   @(1,GBR),R0
    MOVA    @(5,PC),R0
    BRA     Label2
    MOV.W   @(-4,PC),R3
    AND.B   #64,@(R0,GBR)
    CMP/EQ  #-45,R9
    TRAPA   #79
    MOV     #0,R0
    SETT
    BT      Main

;------------------------------- DATA SECTION --------------------------------
.data

msg1: .ascii "hello"
num1: .word 42
list1: .byte 1, 2, 3