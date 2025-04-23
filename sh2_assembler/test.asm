; Test Assembly code for SH-2 Assembler

CLRT
MOVT    R0
STC     VBR,R2
TAS.B   @R7
STS.L   PR,@-R2
LDC     R14,GBR     ; comment
LDC     R11,SR
JMP     @R2
LDC.L   @R5+,SR
BRAF    R13
EXTU.B  R9,R2
MOV.W   R1,@R14     ; comment 2
MOV.B   @R12+,R0
MOV.W   R4, @-R9
MOV.L   R1,@(R0, R6)
MOV.B   @(3,R2),R0
MOV.W   R0,@(12,R3)
MOV.L   @(-3,R7),R11
MOV.L   @(1,GBR),R0
MOVA    @(5,PC),R0
;BF      label1
;BRA     label2
MOV.W   @(-4,PC),R3
AND.B   #64,@(R0,GBR)
CMP/EQ  #-45,R9
TRAPA   #79