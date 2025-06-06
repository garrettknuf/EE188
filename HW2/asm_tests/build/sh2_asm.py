"""
SH-2 Assembler

This file is a tool designated to translate SH-2 assembly language source code
into executably binary machine code. It parses the input assembly file, resolves
symbols and labels, encodes instructions according the the SH-2 instruction set
architecture in the SH-2 Programming Manual (1996), and produces a binary string
output file suitable for loading into an SH-2 simulator. Assembled code is in
big-endian format.

Usage:
    python sh2_assembler.py <input_file.asm> <output_file.bin>

Architecture:
    -Lexer/Parser: reads input file line-by-line, tokenizes instructions and
     operands, and construction internal instruction representations.
    -Symbol Table: Maintains label definitions and reference to support forward
     and backward label usage.
    -Encoder : Converts each parsed instruction into its binary machine code
     according to SH-2 encoding rules.
    -Assembler passes: (1) parses instruction, records labels, and instruction
     addresses (2) resolves label addresses, finalizes instruction encodings,
     and writes output.

Directives:
    .text : Marks the beginning of the program code section. Contains the SH-2
            instructions that will be assembled into executable machine code.
    .data : Defines pre-initialized data section. The variables can be specified
            as .byte, .word, .long.
    .vectable : Defines the exception and interrupt vector table. This section
                holds the vector addresses used by the CPU. Entries are specified
                as labels paired with their corresponding 32-bit handler addresses.

Author: Garrett Knuf
Date: April 25 2025
"""

import re
import sys
import struct
import math
import os

# Convert n in Rn to integer value
REGISTER_MAP = {
    f"R{i}": i for i in range(16)
}

# Table of instructions (referenced from SuperH RISC Engine SH-1/SH-2 Programming
# Manual)
INSTRUCTION_SET = {
    # 0 format
    # Table A.23
    ("CLRT", ()):   lambda : 0x0008,
    ("CLRMAC", ()): lambda : 0x0028,
    ("DIV0U", ()):  lambda : 0x0019,
    ("NOP", ()):    lambda : 0x0009,
    ("RTE", ()):    lambda : 0x002B,
    ("RTS", ()):    lambda : 0x000B,
    ("SETT", ()):   lambda : 0x0018,
    ("SLEEP", ()):  lambda : 0x001B,

    # n Format (Direct Register Addressing)
    # Table A.24
    ("CMP/PL", ("reg",)) :   lambda rn: 0x4015 | (rn << 8),
    ("CMP/PZ", ("reg",)) :   lambda rn: 0x4011 | (rn << 8),
    ("DT", ("reg",)) :       lambda rn: 0x4010 | (rn << 8),
    ("MOVT", ("reg",)) :     lambda rn: 0x0029 | (rn << 8),
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
    ("LDS", ("reg", "pr")):     lambda rm, reg: 0x402A | (rm << 8),

    # m Format Indirect Register
    # Table A.29
    ("JMP", ("mem",)):   lambda rm: 0x402B | (rm << 8),
    ("JSR", ("mem",)):   lambda rm: 0x400B | (rm << 8),

    # m Format Post Increment Indirect Register
    # Table A.30
    ("LDC.L", ("inc", "sr")):   lambda rm, sr:  0x4007 | (rm << 8),
    ("LDC.L", ("inc", "gbr")):  lambda rm, gbr: 0x4017 | (rm << 8),
    ("LDC.L", ("inc", "vbr")):  lambda rm, vbr: 0x4027 | (rm << 8),
    ("LDS.L", ("inc", "pr")):   lambda rm, pr:  0x4026 | (rm << 8),

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
    ("NOT", ("reg", "reg")):        lambda rm, rn: 0x6007 | (rn << 8) | (rm << 4),
    ("OR", ("reg", "reg")):         lambda rm, rn: 0x200B | (rn << 8) | (rm << 4),
    ("SUB", ("reg", "reg")):        lambda rm, rn: 0x3008 | (rn << 8) | (rm << 4),
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
    ("MOV.B", ("mem", "reg")):  lambda rm, rn: 0x6000 | (rn << 8) | (rm << 4),
    ("MOV.W", ("mem", "reg")):  lambda rm, rn: 0x6001 | (rn << 8) | (rm << 4),
    ("MOV.L", ("mem", "reg")):  lambda rm, rn: 0x6002 | (rn << 8) | (rm << 4),

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
    ("MOV.W", ("indexed", "reg")): lambda index, rn: 0x8500 | (index[1] << 4) | (index[0] & 0x000F),

    # nd4 Format
    ("MOV.B", ("reg", "indexed")): lambda r0, index: 0x8000 | (index[1] << 4) | (index[0] & 0x000F),
    ("MOV.W", ("reg", "indexed")): lambda r0, index: 0x8100 | (index[1] << 4) | (index[0] & 0x000F),

    # nmd Format
    # Table A.40
    ("MOV.L", ("reg", "indexed")): lambda rm, index: 0x1000 | (index[1] << 8) | (rm << 4) | (index[0] & 0x000F),
    ("MOV.L", ("indexed", "reg")): lambda index, rn: 0x5000 | (rn << 8) | (index[1] << 4) | (index[0] & 0x000F),

    # d Format Indirect GBR with Displacement
    # Table A.41
    ("MOV.B", ("reg", "indexed_gbr")): lambda r0, d: 0xC000 | (d & 0x00FF),
    ("MOV.W", ("reg", "indexed_gbr")): lambda r0, d: 0xC100 | (d & 0x00FF),
    ("MOV.L", ("reg", "indexed_gbr")): lambda r0, d: 0xC200 | (d & 0x00FF),
    ("MOV.B", ("indexed_gbr", "reg")): lambda d, r0: 0xC400 | (d & 0x00FF),
    ("MOV.W", ("indexed_gbr", "reg")): lambda d, r0: 0xC500 | (d & 0x00FF),
    ("MOV.L", ("indexed_gbr", "reg")): lambda d, r0: 0xC600 | (d & 0x00FF),

    # d Format PC Relative with Displacement
    # Table A.42
    ("MOVA", ("indexed_pc", "reg")): lambda d, r0: 0xC700 | (d & 0x00FF),

    # d Format PC Relative Addressing
    # Table A.43
    ("BF", ("label",)):     lambda label: 0x8B00,
    ("BF/S", ("label",)):   lambda label: 0x8F00,
    ("BT", ("label",)):     lambda label: 0x8900,
    ("BT/S", ("label",)):   lambda label: 0x8D00,

    # d12 Format
    # Table A.44
    ("BRA", ("label",)):    lambda label: 0xA000,
    ("BSR", ("label",)):    lambda label: 0xB000,

    # nd8 Format
    # Table A.45
    ("MOV.W", ("indexed_pc", "reg")): lambda d, rn: 0x9000 | (rn << 8) | (d & 0x00FF),
    ("MOV.L", ("indexed_pc", "reg")): lambda d, rn: 0xD000 | (rn << 8) | (d & 0x00FF),

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

# Create list of labels during first pass for later assingments
label_dict = {}

# Create list of relative branches during first pass for later assignment
pc_rel_branch_list = []

def parse_operand(op):
    """
    Parses a single operand string from SH-2 assembly syntax and classifies it.

    Operand types
    - Immediate values (e.g., "#10")
    - Pre-decrement and post-increment addressing (e.g., "@-R4", "@R3+")
    - Register indirect and indexed (e.g., "@R3", "@(4, R2)")
    - GBR/PC-based indexed (e.g., "@(4, GBR)")
    - Register direct (e.g., "R7")
    - Special registers (e.g., "SR", "GBR", "VBR", "PR", "PC")
    - Symbolic labels or unresolved expressions (fallback case)

    Args:
        op (str): The operand string to parse.

    Returns:
        tuple: A tuple of the form (type, value), where:
            - type (str): The operand type identifier, e.g., "imm", "reg", "label".
            - value: The operand value(s)
    """
    op = op.strip().upper()
    op = re.sub(r"\s+", "", op)  # remove whitespace
    
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
    match = re.match(r"@\s*\(\s*([-+]?\d+)\s*,\s*R(\d+)\s*\)", op)
    if match:
        disp = int(match.group(1), 0)
        reg = int(match.group(2))
        return "indexed", (disp, reg)
    
    # Indexed displacement with GBR (e.g., @(4, GBR))
    match_gbr = re.match(r"@\s*\(\s*([-+]?\d+)\s*,\s*GBR\s*\)", op)
    if match_gbr:
        disp = int(match_gbr.group(1), 0)  # Handle the displacement
        return "indexed_gbr", disp
    
    # Indexed displacement with R0 and GBR (e.g., @(R0, GBR))
    match_r0_gbr = re.match(r"@\s*\(\s*R0\s*,\s*GBR\s*\)", op)
    if match_r0_gbr:
        return "indexed_r0_gbr", None
    
    # Indexed displacement with PC (e.g., @(4, PC))
    match_pc = re.match(r"@\s*\(\s*([-+]?\d+)\s*,\s*PC\s*\)", op)
    if match_pc:
        disp = int(match_pc.group(1), 0)    # Handle the displacement
        return "indexed_pc", disp

    # Indexed indirect with R0: @(R0, Rn)
    match = re.match(r"@\s*\(\s*R0\s*,\s*R(\d+)\s*\)", op)
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

    # Otherwise probably a label or symbolic address (e.g., jump target)
    return "label", op
    

def assemble_instruction(line, addr):
    """
    Assembles a single line of SH-2 assembly code into bytecode. Removes
    comments and unneccessary whitespace, tokenizes opcode and operands, parses
    operands into types and values using parse_operands, looks up encoding from
    INSTRUCTION_SET table, tracks label defintions and PC-relative branch
    instructions.

    Args:
        line (str): a single line of assembly code
        addr (int): current instruction address in the program

    Returns:
        int or None: 16-bit machine instruction as integer, or if not a valid
                     instruction, None
    """

    # Remove comments and strip white space
    line = line.split(';')[0].strip()

    # Do not handle empty lines
    if not line or line == '':
        return None

    # Tokenize instruction
    tokens = line.split(None, 1)
    opcode = tokens[0].upper()
    operands = []

    if len(tokens) > 1:
        # Split operands by commas, preserve grouping like @(disp,PC)
        raw_operands = re.findall(r'@?\([^)]*\)|[^,]+', tokens[1])
        operands = [op.strip() for op in raw_operands]

    # Parse each operands for its type and value
    parsed_operands = [parse_operand(op) for op in operands]

    # Extract only operand types to determine the instruction format
    operand_types = tuple(op_type for op_type, _ in parsed_operands)

    # Form the key used to look up instruction in INSTRUCTION_SET table
    key = (opcode, operand_types)

    # If a label is found, save it, and return None
    if re.match(r'^\s*([A-Za-z_][A-Za-z0-9_]*):\s*$', opcode):
        label_dict[opcode[:-1]] = addr
        return None

    # Check instruction is valid
    if key not in INSTRUCTION_SET:
        raise ValueError(f"Unsupported instruction: {opcode} {operand_types}\n{line}")

    # Extract operand values for table lookup
    operand_values = [value for _, value in parsed_operands]

    # Defer encoding PC-relative branches until all labels are known (temporarily
    # just save that this branch exists)
    if opcode in ['BF', 'BF/S', 'BT', 'BT/S', 'BRA','BSR']:
        pc_rel_branch_list.append((opcode, operand_values, addr))

    # Lookup bytecode in table
    return INSTRUCTION_SET[key](*operand_values)


def parse_value(val):
    """
    Parses a string representing a numer value in binary, hexadecimal, or decimal
    format.

    Support formats:
    - Binary: prefixed with 'b' (e.g., 'b1010')
    - Hexadecimal: prefixed with '0x' (e.g., '0x1F')
    - Decimal: unprefixed (e.g., '42')
    """
    val = val.strip()
    if val.startswith("b"):  # Binary literal
        return int(val[1:], 2)
    elif val.startswith("0x"):  # Hexadecimal
        return int(val, 16)
    else:  # Decimal
        return int(val)

def parse_data(line):
    """
    Parses a line from the .data section and returns a list of binary string
    representations. Strips comments. Data is big-endian.
    Recognizes the following directives: .byte, .word, .long types.

    Args:
        line (str): A single line from the .data section.

    Returns:
        list[str]: A list of binary string representations of the data (8 or 16 bits wide),
                   or None if the line is not a valid data directive.
    """

    data = bytearray()  # Uses binary data as bytes
    labels = {}         # Label dictionary (local)

    # Skip empty lines or comments headers
    line = line.strip()
    if not line or line.startswith(';') or line == ".data":
        return None
    
    # Remove inline comments
    line = line.split(';')[0].strip()
    
    # Extract label and directive
    label_match = re.match(r'(\w+):\s*(\.\w+)\s+(.*)', line)
    if not label_match:
        return None
    
    # Track label's offset if needed outside function
    label, directive, value = label_match.groups()

    # Track output format
    isbyte = False

    # .byte each value becomes one byte
    if directive == ".byte":
        data.extend(parse_value(v) & 0xFF for v in value.split(','))
        isbyte = True

    # .word each value becomes two bytes
    elif directive == ".word":
        for v in value.split(','):
            intval = parse_value(v)
            # Convert to unsigned 16-bit if negative
            if intval < 0:
                intval = (1 << 16) + intval  # Two's complement
            data.extend(struct.pack('>H', intval))

    # .long each value becomes foure bytes
    elif directive == ".long":
        for v in value.split(','):
            intval = parse_value(v)
            # Convert to unsigned 32-bit if negative
            if intval < 0:
                intval = (1 << 32) + intval  # Two's complement
            data.extend(struct.pack('>I', intval))
            
    else:
        raise ValueError(f"Unknown directive: {directive}")
    
    # Create final list of binary strings
    binary_strs = []
    if not isbyte:
        # Pad to 16-bit boundary if needed
        if len(data) % 2 != 0:
            data.append(0)

        # Convert to 16-bit binary strings
        for i in range(0, len(data), 2):
            high = data[i]
            low = data[i + 1]
            word = (high << 8) | low
            binary_strs.append(f"{word:016b}")
    else:
        # Convert to 8-bit binary strings otherwise
        for byte in data:
            binary_strs.append(f"{byte:08b}")      
    
    return binary_strs


# Main loop
if __name__ == '__main__':

    # Make sure input and output files provided
    if len(sys.argv) < 2:
        print("Usage: python3 sh2_asm.py <asm_file>")
        sys.exit(1)

    # Code Sections
    SEG_UNKNOWN = 0
    SEG_TEXT = 1
    SEG_DATA = 2
    SEG_VEC_TABLE = 3

    # List of text lines to output
    chunk0_output = []
    chunk1_output = []
    chunk2_output = []
    chunk3_output = []

    # Address of chunks
    CHUNK0_ADDR = 1024*0
    CHUNK1_ADDR = 1024*1
    CHUNK2_ADDR = 1024*2 # not used
    CHUNK3_ADDR = 1024*3 # not used
    CHUNK_SIZE = 1024

    # Used to combine bytes into words for output
    between_bytes = False

    # Read assembly file
    with open(sys.argv[1], 'r') as asm_file:
        lines = asm_file.readlines()

        addr = 0            # current memory address in segment
        seg = SEG_UNKNOWN   # current segment being parsed
        data_arr = []       # stores binary strings for data segment
        vector_words = []   # stores binary lines for vector table

        # Iterate through all lines of file
        for line_num, line in enumerate(lines):

            # Change code section if directive is found
            if len(line.split()) > 0 and line.split()[0] == '.text':
                seg = SEG_TEXT
                continue
            elif len(line.split())> 0 and line.split()[0] == '.data':
                seg = SEG_DATA
                continue
            elif len(line.split())> 0 and line.split()[0] == '.vectable':
                seg = SEG_VEC_TABLE
                continue

            # Parse vector table
            if seg == SEG_VEC_TABLE:
                if not line or line.startswith(';'):
                    continue  # skip empty or comment lines
                line = line.split(';')[0].strip()  # remove inline comment
                parts = line.split(':')
                if len(parts) < 2:
                    continue
                address_part = parts[1].strip().split()[0]  # Get '0x00000020'
                address_int = int(address_part, 16)         # Convert hex to int
                address_bin = format(address_int, '032b')   # Convert int to 32-bit binary string
                vector_words.append(address_bin[:16] + '\t; ' + parts[0] + '\n')
                vector_words.append(address_bin[16:] + '\n')

            # Parse program code
            if seg == SEG_TEXT:
                asm = assemble_instruction(line, addr)
                if asm:
                    text = format(asm, '016b') + f'\t; 0x{addr + len(vector_words)*2:08X} : ' + \
                            f"{(lines[line_num].lstrip())}".rstrip('\n') + '\n'
                    chunk0_output.append(text)
                    addr += 2   # Advances by 2 bytes per instruction

            # Parse data segment
            elif seg == SEG_DATA:
                data = parse_data(line)
                if data:
                    if len(data[0]) == 8:   # is byte
                        if not between_bytes:
                            temp_byte = data[0]
                        else:
                            # Combine two bytes into a word for output
                            data_arr.append([temp_byte + data[0]])
                        between_bytes = not between_bytes
                    else:
                        data_arr.append(data)

        # Pad code segment with 0s up to the chunk size
        addr += 2*len(vector_words)
        while addr < CHUNK0_ADDR + CHUNK_SIZE:
            chunk0_output.append(f'{format(0x0000, "016b")}\t; 0x{addr:08X} : 0x00\n')
            addr += 2

        # Add data segment with appropriate comments
        addr = CHUNK1_ADDR
        for var in data_arr:
            for word in var: 
                dec_val = int(word, 2)
                hex_val = hex(dec_val)
                left_byte = int(word[:8], 2)
                right_byte = int(word[8:16], 2)
                chunk1_output.append(f"{word}\t; 0x{addr:08X} : {left_byte}," +
                                    f"{right_byte} / {dec_val} / {hex_val}\n")
                addr += 2

        # Pad data segment with zeros
        while addr < CHUNK1_ADDR + CHUNK_SIZE:
            chunk1_output.append(f'{format(0x0000, "016b")}\t; 0x{addr:08X} : 0x00\n')
            addr += 2

    # Handle PC relative branches
    for branch in pc_rel_branch_list:
        # Calculate signed displacement
        branch_instr_addr = branch[2]
        label_addr = label_dict[branch[1][0]]
        offset = label_addr - branch_instr_addr
        offset = (int)(offset / 2)
        new_line = ''

        # Add displacement to instruction
        if branch[0] in ['BF', 'BF/S', 'BT', 'BT/S']:
            # 8-bit displacement
            output_bin = format(offset & 0x00FF, '08b')
            for i in range(8, 16):
                old_line = chunk0_output[(int)(branch_instr_addr / 2)]
                new_line = old_line[0:8] + output_bin + old_line[16:]
        elif branch[0] in ['BRA', 'BSR']:
            # 12-bit displacement
            output_bin = format(offset & 0x0FFF, '012b')
            for i in range(4, 16):
                old_line = chunk0_output[(int)(branch_instr_addr / 2)]
                new_line = old_line[0:4] + output_bin + old_line[16:]
        
        chunk0_output[(int)(branch_instr_addr / 2)] = new_line

    # Write to output files
    output_file_basename =  os.path.splitext(os.path.basename(sys.argv[1]))[0]
    output_file_path = '../asm_tests/build/'

    # Write program memory code
    with open(output_file_path + "build_mem0.txt", 'w') as out_file:
        for word in vector_words:
            out_file.write(word)
        for line in chunk0_output:
            out_file.write(line)

    # Write data memory code
    with open(output_file_path  + "build_mem1.txt", 'w') as out_file:
        for line in chunk1_output:
            out_file.write(line)
