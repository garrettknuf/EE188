"""
Memory Comparison for RAM contents.

Compares expected memory values from an SH-2 assembly test case against the actual
memory contents dumped during simulation from memory.vhd.

Usage:
    python mem_compare.py <test_name>

Where <test_name> refers to the base name (without extension) of the test case file,
used to locate the expected memory output file:
    ../asm_tests/expected/<test_name>_exp.txt

Expected input files:
- ../asm_tests/build/build_mem0.txt    # Program memory from assembler
- ../asm_tests/build/build_mem1.txt    # Data memory from assembler
- ../asm_tests/mem_dump/dump0.txt      # Program memory from simulation
- ../asm_tests/mem_dump/dump1.txt      # Data memory from simulation

This script supports:
- Parsing binary strings from assembler output and memory dumps.
- Parsing expected values in 8-bit (B.), 16-bit (W.), or 32-bit (L.) format.
- Comparing each memory byte and reporting mismatches.

The program memory checking feature was removed, in this current implementation,
only data memory is compared with the memory contents dumped.

Author: Garrett Knuf
Date:   26 Apr 2025
"""

import sys
from pathlib import Path

def parse_memory(memory_text):
    """
    Read in memory contents generated from assembly build (1 per line). Lines read
    in should be 16-bit binary strings. Whitespace is removed and a colon indicates
    that it and every character after is a comment.
    Example input:
        1110000001000000	; 0x00000050 : MOV     #64, R0
    Output:
        ['11100000','01000000']
    """
    binary_values = []
    
    for line in memory_text.strip().splitlines():
        # Split at semicolon to remove comments
        parts = line.split(';')
        bin_part = parts[0].strip()
        
        # Only process non-empty binary parts
        if bin_part:
            binary_values.append(bin_part[:8])
            binary_values.append(bin_part[8:])
    
    return binary_values


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

# Main loop
if __name__ == "__main__":

    # Check if the correct number of arguments is passed
    if len(sys.argv) != 2:
        print("Usage: python mem_compare.py <test_name>")
        sys.exit(1)

    # Assembly build output (program memory)
    asm_build_file = f"../asm_tests/build/build_mem0.txt"

    # Assembly build output (data memory)
    data_build_file = f"../asm_tests/build/build_mem1.txt"

    # Expected data memory file
    expected_memory_file = f"../asm_tests/expected/{sys.argv[1]}_exp.txt"

    # Actual memory contents dumped during simulation
    memory_dump_file0 = f"../asm_tests/mem_dump/dump0.txt"  # Program memory
    memory_dump_file1 = f"../asm_tests/mem_dump/dump1.txt"  # Data memory

    # Open assembly memory build
    with open(asm_build_file, "r") as asm_file:
        asm_build_text = asm_file.read()

    # Open memory dump after test
    with open(memory_dump_file0, "r") as dump_file0:
        mem_dump_text0 = dump_file0.read()
    with open(memory_dump_file1, "r") as dump_file1:
        mem_dump_text1 = dump_file1.read()

    # Open expected data file
    start_addr = 0
    exp_value_list = []
    with open(expected_memory_file, "r") as exp_file:
        for line_num, line in enumerate(exp_file):
            line = line.split(';', 1)[0].strip()
            if line_num == 0:
                addr_str = line.split(": ")[1]
                start_addr = int(addr_str, 16)
            else:
                if line.startswith("L."):
                    value = parse_value(line[2:])  # 32-bit value
                    # Split into four 8-bit chunks (big endian: MSB first)
                    for shift in (24, 16, 8, 0):
                        byte = (value >> shift) & 0xFF
                        exp_value_list.append(f"{byte:08b}")
                elif line.startswith("W."):
                    value = parse_value(line[2:])  # 16-bit value
                    for shift in (8, 0):
                        byte = (value >> shift) & 0xFF
                        exp_value_list.append(f"{byte:08b}")
                elif line.startswith("B."):
                    value = parse_value(line[2:])  # 8-bit value
                    exp_value_list.append(f"{value & 0xFF:08b}")
                else:
                    print(f"Unknown line: {line}")

        # Move expected values into correct memory contents
        mem_arr = []
        for i, bin_str in enumerate(exp_value_list):
            mem_arr.append(bin_str)

        # Check memory contents match
        dump_arr1 = parse_memory(mem_dump_text1)
        err_cnt = 0
        for i, bin in enumerate(mem_arr):
            if mem_arr[i] != dump_arr1[i]:
                print(f"Error @ 0x{i+1024:04X} - expected {mem_arr[i]} - actual {dump_arr1[i]}")
                err_cnt += 1

        # Output test results
        test_name = Path(asm_build_file).stem
        if err_cnt == 0:
            print(f"'{sys.argv[1]}.asm' tests passed!")
        else:
            print(f"Tests failed: {err_cnt} errors.")
