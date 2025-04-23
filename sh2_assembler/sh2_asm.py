"""
SH-2 Assembler
"""

import re

# Convert n in Rn to integer value
REGISTER_MAP = {
    f"R{i}": i for i in range(16)
}

# Table of instructions
INSTRUCTION_SET = {
    # 0 format
    # Table A.23
    ("CLRT", ()):   lambda : 0x0008,
    ("CLRMAC", ()): lambda : 0x0028,
    ("DIV0U", ()):  lambda : 0x0019,
    ("NOP", ()):    lambda : 0x0009,
    ("RTE", ()):    lambda : 0x0029,
    ("RTS", ()):    lambda : 0x000B,
    ("SETT", ()):   lambda : 0x0018,
    ("SLEEP", ()):  lambda : 0x001B,

    # n Format (Direct Register Addressing)
    # Table A.24
    ("CMP/PL", ("reg",)) :   lambda rn: 0x4015 | (rn << 8),
    ("CMP/PZ", ("reg",)) :   lambda rn: 0x4011 | (rn << 8),
    ("DT", ("reg",)) :       lambda rn: 0x4010 | (rn << 8),
    ("MOVT", ("reg",)) :     lambda rn: 0x4029 | (rn << 8),
    ("ROTL", ("reg",)) :     lambda rn: 0x4004 | (rn << 8),
    ("ROTR", ("reg",)) :     lambda rn: 0x4005 | (rn << 8),
    ("ROTCL", ("reg",)) :    lambda rn: 0x4024 | (rn << 8),
    ("ROTCR", ("reg",)) :    lambda rn: 0x4025 | (rn << 8),
    ("SHAL", ("reg",)) :     lambda rn: 0x4020 | (rn << 8),
    ("SHAR", ("reg",)) :     lambda rn: 0x4021 | (rn << 8),
    ("SHLL", ("reg",)) :     lambda rn: 0x4000 | (rn << 8),
    ("SHLR", ("reg",)) :     lambda rn: 0x4001 | (rn << 8),
    ("SHLL2", ("reg",)) :    lambda rn: 0x4008 | (rn << 8),
    ("SHLR2", ("reg",)) :    lambda rn: 0x4009 | (rn << 8),
    ("SHLL8", ("reg",)) :    lambda rn: 0x4018 | (rn << 8),
    ("SHLR8", ("reg",)) :    lambda rn: 0x4019 | (rn << 8),
    ("SHLL16", ("reg",)) :   lambda rn: 0x4028 | (rn << 8),
    ("SHLR16", ("reg",)) :   lambda rn: 0x4029 | (rn << 8),

    # n Format (Direct Register Addressing (Store with Control and System Registers)
    # Table A.25
    ("STC", ("sr", "reg")) :    lambda reg, rn: 0x0002 | (rn << 8),
    ("STC", ("gbr", "reg")) :   lambda reg, rn: 0x0012 | (rn << 8),
    ("STC", ("vbr", "reg")) :   lambda reg, rn: 0x0022 | (rn << 8),
    ("STS", ("pr", "reg")) :    lambda reg, rn: 0x002A | (rn << 8),

    # n Format Indirect Register Addressing
    # Table A.26
    ("TAS.B", ("mem",)) :    lambda rn: 0x401B | (rn << 8),

    # n Format Pre Decrement Indirect Register
    # Table A.27
    ("STC.L", ("sr", "dec")):   lambda reg, rn: 0x4003 | (rn << 8),
    ("STC.L", ("gbr", "dec")):  lambda reg, rn: 0x4013 | (rn << 8),
    ("STC.L", ("vbr", "dec")):  lambda reg, rn: 0x4023 | (rn << 8),
    ("STS.L", ("pr", "dec")):   lambda reg, rn: 0x4022 | (rn << 8),

    # m Format Direct Register Addressing (Load with Control and System Registers)
    # Table A.28
    ("LDC", ("reg", "sr")):     lambda rm, reg: 0x400E | (rm << 8),
    ("LDC", ("reg", "gbr")):    lambda rm, reg: 0x401E | (rm << 8),
    ("LDC", ("reg", "vbr")):    lambda rm, reg: 0x402E | (rm << 8),
    ("LDC", ("reg", "pr")):     lambda rm, reg: 0x402A | (rm << 8),

    # m Format Indirect Register
    # Table A.29
    ("JMP", ("mem",)):   lambda rm: 0x402B | (rm << 8),
    ("JSR", ("mem",)):   lambda rm: 0x400B | (rm << 8),

    # m Format Post Increment Indirect Register
    # Table A.30
    ("LDC.L", ("inc", "sr")):   lambda rm, sr:  0x4007 | (rm << 8),
    ("LDC.L", ("inc", "gbr")):  lambda rm, gbr: 0x4017 | (rm << 8),
    ("LDC.L", ("inc", "vbr")):  lambda rm, vbr: 0x4027 | (rm << 8),
    ("LDC.L", ("inc", "pr")):   lambda rm, pr:  0x4026 | (rm << 8),

    # m Format PC Relative Addressing with Rm
    # Table A.31
    ("BRAF", ("reg",)):  lambda rm: 0x0023 | (rm << 8),
    ("BSRF", ("reg",)):  lambda rm: 0x0003 | (rm << 8),

    # nm Format Direct Register Addressing
    # Table A.32
    ("ADD", ("reg", "reg")):        lambda rm, rn: 0x300C | (rn << 8) | (rm << 4),
    ("ADDC", ("reg", "reg")):       lambda rm, rn: 0x300E | (rn << 8) | (rm << 4),
    ("ADDV", ("reg", "reg")):       lambda rm, rn: 0x300F | (rn << 8) | (rm << 4),
    ("AND", ("reg", "reg")):        lambda rm, rn: 0x2009 | (rn << 8) | (rm << 4),
    ("CMP/EQ", ("reg", "reg")):     lambda rm, rn: 0x3000 | (rn << 8) | (rm << 4),
    ("CMP/HS", ("reg", "reg")):     lambda rm, rn: 0x3002 | (rn << 8) | (rm << 4),
    ("CMP/GE", ("reg", "reg")):     lambda rm, rn: 0x3003 | (rn << 8) | (rm << 4),
    ("CMP/HI", ("reg", "reg")):     lambda rm, rn: 0x3006 | (rn << 8) | (rm << 4),
    ("CMP/GT", ("reg", "reg")):     lambda rm, rn: 0x3007 | (rn << 8) | (rm << 4),
    ("CMP/STR", ("reg", "reg")):    lambda rm, rn: 0x200C | (rn << 8) | (rm << 4),
    ("EXTS.B", ("reg", "reg")):     lambda rm, rn: 0x600E | (rn << 8) | (rm << 4),
    ("EXTS.W", ("reg", "reg")):     lambda rm, rn: 0x600F | (rn << 8) | (rm << 4),
    ("EXTU.B", ("reg", "reg")):     lambda rm, rn: 0x600C | (rn << 8) | (rm << 4),
    ("EXTU.W", ("reg", "reg")):     lambda rm, rn: 0x600D | (rn << 8) | (rm << 4),
    ("MOV", ("reg", "reg")):        lambda rm, rn: 0x6003 | (rn << 8) | (rm << 4),
    ("NEG", ("reg", "reg")):        lambda rm, rn: 0x600B | (rn << 8) | (rm << 4),
    ("NEGC", ("reg", "reg")):       lambda rm, rn: 0x600A | (rn << 8) | (rm << 4),
    ("OR", ("reg", "reg")):         lambda rm, rn: 0x200B | (rn << 8) | (rm << 4),
    ("SUBC", ("reg", "reg")):       lambda rm, rn: 0x300A | (rn << 8) | (rm << 4),
    ("SUBV", ("reg", "reg")):       lambda rm, rn: 0x300B | (rn << 8) | (rm << 4),
    ("SWAP.B", ("reg", "reg")):     lambda rm, rn: 0x6008 | (rn << 8) | (rm << 4),
    ("SWAP.W", ("reg", "reg")):     lambda rm, rn: 0x6009 | (rn << 8) | (rm << 4),
    ("TST", ("reg", "reg")):        lambda rm, rn: 0x2008 | (rn << 8) | (rm << 4),
    ("XOR", ("reg", "reg")):        lambda rm, rn: 0x200A | (rn << 8) | (rm << 4),
    ("XTRCT", ("reg", "reg")):      lambda rm, rn: 0x200D | (rn << 8) | (rm << 4),
    
    # nm Format Indirect Register Addressing
    # Table A.33
    ("MOV.B", ("reg", "mem")):  lambda rm, rn: 0x2000 | (rn << 8) | (rm << 4),
    ("MOV.W", ("reg", "mem")):  lambda rm, rn: 0x2001 | (rn << 8) | (rm << 4),
    ("MOV.L", ("reg", "mem")):  lambda rm, rn: 0x2002 | (rn << 8) | (rm << 4),
    ("MOV.B", ("reg", "mem")):  lambda rm, rn: 0x6000 | (rn << 8) | (rm << 4),
    ("MOV.W", ("reg", "mem")):  lambda rm, rn: 0x6001 | (rn << 8) | (rm << 4),
    ("MOV.L", ("reg", "mem")):  lambda rm, rn: 0x6002 | (rn << 8) | (rm << 4),

    # nm Format Post Increment Indirect Register (Multiply/Accumulate Operation)
    # Table A.34

    # nm Post Increment Indirect Register
    # Table A.35
    ("MOV.B", ("inc", "reg")):  lambda rm, rn: 0x6004 | (rn << 8) | (rm << 4),
    ("MOV.W", ("inc", "reg")):  lambda rm, rn: 0x6005 | (rn << 8) | (rm << 4),
    ("MOV.L", ("inc", "reg")):  lambda rm, rn: 0x6006 | (rn << 8) | (rm << 4),

    # nm Format Pre Decrement Indirect Register
    # Table A.36
    ("MOV.B", ("reg", "dec")):  lambda rm, rn: 0x2004 | (rn << 8) | (rm << 4),
    ("MOV.W", ("reg", "dec")):  lambda rm, rn: 0x2005 | (rn << 8) | (rm << 4),
    ("MOV.L", ("reg", "dec")):  lambda rm, rn: 0x2006 | (rn << 8) | (rm << 4),

    # nm Format Indirect Indexed Register
    # Table A.37
    ("MOV.B", ("reg", "r0_indexed")): lambda rm, rn: 0x0004 | (rn << 8) | (rm << 4),
    ("MOV.W", ("reg", "r0_indexed")): lambda rm, rn: 0x0005 | (rn << 8) | (rm << 4),
    ("MOV.L", ("reg", "r0_indexed")): lambda rm, rn: 0x0006 | (rn << 8) | (rm << 4),
    ("MOV.B", ("r0_indexed", "reg")): lambda rm, rn: 0x000C | (rn << 8) | (rm << 4),
    ("MOV.W", ("r0_indexed", "reg")): lambda rm, rn: 0x000D | (rn << 8) | (rm << 4),
    ("MOV.L", ("r0_indexed", "reg")): lambda rm, rn: 0x000E | (rn << 8) | (rm << 4),

    # md Format
    # Table A.38
    ("MOV.B", ("indexed", "reg")): lambda index, rn: 0x8400 | (index[1] << 4) | (index[0] & 0x000F),
    ("MOV.B", ("indexed", "reg")): lambda index, rn: 0x8500 | (index[1] << 4) | (index[0] & 0x000F),

    # nd4 Format
    ("MOV.B", ("reg", "indexed")): lambda r0, index: 0x8000 | (index[1] << 4) | (index[0] & 0x000F),
    ("MOV.W", ("reg", "indexed")): lambda r0, index: 0x8100 | (index[1] << 4) | (index[0] & 0x000F),

    # nmd Format
    # Table A.40
    ("MOV.L", ("reg", "indexed")): lambda rm, index: 0x1000 | (index[1] << 8) | (rm << 4) | (index[0] & 0x000F),
    ("MOV.L", ("indexed", "reg")): lambda index, rn: 0x1000 | (rn << 8) | (index[1] << 4) | (index[0] & 0x000F),

    # d Format Indirect GBR with Displacement
    # Table A.41
    ("MOV.B", ("reg", "indexed_gbr")): lambda r0, d: 0xC000 | (d & 0x00FF),
    ("MOV.W", ("reg", "indexed_gbr")): lambda r0, d: 0xC001 | (d & 0x00FF),
    ("MOV.L", ("reg", "indexed_gbr")): lambda r0, d: 0xC002 | (d & 0x00FF),
    ("MOV.B", ("indexed_gbr", "reg")): lambda d, r0: 0xC400 | (d & 0x00FF),
    ("MOV.W", ("indexed_gbr", "reg")): lambda d, r0: 0xC500 | (d & 0x00FF),
    ("MOV.L", ("indexed_gbr", "reg")): lambda d, r0: 0xC600 | (d & 0x00FF),

    # d Format PC Relative with Displacement
    # Table A.42
    ("MOVA", ("indexed_pc", "reg")): lambda d, r0: 0xC700 | (d & 0x00FF),

    # d Format PC Relative Addressing
    # Table A.43
    # TODO

    # d12 Format
    # Table A.44
    # TODO

    # nd8 Format
    # Table A.45
    ("MOV.W", ("indexed_pc", "reg")): lambda d, rn: 0x9000 | (rn << 8) | (d & 0x00FF),
    ("MOV.W", ("indexed_pc", "reg")): lambda d, rn: 0xD000 | (rn << 8) | (d & 0x00FF),

    # i Format Indirect Indexed GBR Addressing
    # Table A.46
    ("AND.B", ("imm", "indexed_r0_gbr")):  lambda imm, nil: 0xCD00 | (imm & 0x00FF),
    ("OR.B", ("imm", "indexed_r0_gbr")):   lambda imm, nil: 0xCF00 | (imm & 0x00FF),
    ("TST.B", ("imm", "indexed_r0_gbr")):  lambda imm, nil: 0xCC00 | (imm & 0x00FF),
    ("XOR.B", ("imm", "indexed_r0_gbr")):  lambda imm, nil: 0xCE00 | (imm & 0x00FF),

    # i Format Immediate Addressing (Arithmetic Logical Operation with Direct Register)
    # Table A.47
    ("AND", ("imm", "reg")):    lambda imm, reg: 0xC900 | (imm & 0x00FF),
    ("CMP/EQ", ("imm", "reg")): lambda imm, reg: 0x8800 | (imm & 0x00FF),
    ("OR", ("imm", "reg")):     lambda imm, reg: 0xCB00 | (imm & 0x00FF),
    ("TST", ("imm", "reg")):    lambda imm, reg: 0xC800 | (imm & 0x00FF),
    ("XOR", ("imm", "reg")):    lambda imm, reg: 0xCA00 | (imm & 0x00FF),

    # i Format Immediate Addressing (Specify Exception Processing Vector)
    # Table A.48
    ("TRAPA", ("imm",)):    lambda imm: 0xC300 | (imm & 0x00FF),

    # ni Format
    # Table A.49
    ("ADD", ("imm", "reg")):    lambda imm, rn: 0x7000 | (rn << 8) | (imm & 0x00FF),
    ("MOV", ("imm", "reg")):    lambda imm, rn: 0xE000 | (rn << 8) | (imm & 0x00FF),

}

def parse_operand(op):
    op = op.strip().upper()
    # Immediate value (e.g., #10, #-5)
    if re.match(r"#-?\d+", op):
        return "imm", int(op[1:], 0)

    # Pre-decrement (e.g., @-R4)
    if re.match(r"@-R\d+", op):
        reg = REGISTER_MAP[op[2:]]
        return "dec", reg

    # Post-increment (e.g., @R3+)
    if re.match(r"@R\d+\+", op):
        reg = REGISTER_MAP[op[1:-1]]
        return "inc", reg

    # Indirect (e.g., @R3)
    if re.match(r"@R\d+", op):
        reg = REGISTER_MAP[op[1:]]
        return "mem", reg

    # Indexed displacement with register (e.g., @(4, R2))
    match = re.match(r"@\(([-+]?\d+),\s*R(\d+)\)", op)
    if match:
        disp = int(match.group(1), 0)
        reg = int(match.group(2))
        return "indexed", (disp, reg)
    
    # Indexed displacement with GBR (e.g., @(4, GBR))
    match_gbr = re.match(r"@\(([-+]?\d+),\s*GBR\)", op)
    if match_gbr:
        disp = int(match_gbr.group(1), 0)  # Handle the displacement (support for base 0)
        return "indexed_gbr", disp  # GBR doesn't need a register number
    
    # Indexed displacement with R0 and GBR (e.g., @(R0, GBR))
    match_r0_gbr = re.match(r"@\((R0),\s*GBR\)", op)
    if match_r0_gbr:
        return "indexed_r0_gbr", None
    
    # Indexed displacement with PC (e.g., @(4, PC))
    match_pc = re.match(r"@\(([-+]?\d+),\s*PC\)", op)
    if match_pc:
        disp = int(match_pc.group(1), 0)  # Handle the displacement (support for base 0)
        return "indexed_pc", disp  # PC doesn't need a register number

    
    # Indexed indirect with R0: @(R0, Rn)
    match = re.match(r"@\(\s*R0\s*,\s*R(\d+)\s*\)", op)
    if match:
        rn = int(match.group(1))
        return "r0_indexed", rn

    # Register direct (e.g., R7)
    if re.match(r"R\d+", op):
        return "reg", REGISTER_MAP[op]
    
    # Special registers
    if op == "SR":
        return "sr", None
    if op == "GBR":
        return "gbr", None
    if op == "VBR":
        return "vbr", None
    if op == "PR":
        return "pr", None
    if op == "PC":
        return "pc", None

    # Fallback: probably a label or symbolic address (e.g., jump target)
    return "label", op
    
def assemble_instruction(line):
    # Remove comments and strip white space
    line = line.split(';')[0].strip()
    
    if not line or line == '':
        return None

    tokens = line.split(None, 1)
    opcode = tokens[0].upper()
    operands = []

    if len(tokens) > 1:
        # Split operands by commas, preserve grouping like @(disp,PC)
        raw_operands = re.findall(r'@?\([^)]*\)|[^,]+', tokens[1])
        operands = [op.strip() for op in raw_operands]

    # print(operands)

    parsed_operands = [parse_operand(op) for op in operands]
    operand_types = tuple(op_type for op_type, _ in parsed_operands)

    # print(parsed_operands)

    key = (opcode, operand_types)

    # print(key)
    if key not in INSTRUCTION_SET:
        raise ValueError(f"Unsupported instruction: {opcode} {operand_types}")

    operand_values = [value for _, value in parsed_operands]
    # print(operand_values)

    return INSTRUCTION_SET[key](*operand_values)


if __name__ == '__main__':

    with open('test.asm', 'r') as asm_file:
        lines = asm_file.readlines()
        
        with open('output.txt', 'w') as out_file:

            addr = 0
            for line_num, line in enumerate(lines):
                asm = assemble_instruction(line)
                if asm:
                    out_file.write(format(asm, '016b'))
                    out_file.write(f'\t; 0x{addr:08X} : ')
                    out_file.write(f'{lines[line_num][:-1]}')
                    out_file.write('\n')
                    addr += 2

        print('Assembled.')
