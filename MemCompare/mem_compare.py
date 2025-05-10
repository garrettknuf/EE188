import sys
from pathlib import Path

def parse_memory(memory_text):
    """ Read in memory contents generated from assembly build """
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
    val = val.strip()
    if val.startswith("b"):  # Binary literal
        return int(val[1:], 2)
    elif val.startswith("0x"):  # Hexadecimal
        return int(val, 16)
    else:  # Decimal
        return int(val)

if __name__ == "__main__":

    # Check if the correct number of arguments is passed
    if len(sys.argv) != 2:
        print("Usage: python mem_compare.py <test_name>")
        sys.exit(1)

    asm_build_file = f"../asm_tests/build/build_mem0.txt"
    data_build_file = f"../asm_tests/build/build_mem1.txt"
    expected_memory_file = f"../asm_tests/expected/{sys.argv[1]}_exp.txt"
    memory_dump_file0 = f"../asm_tests/mem_dump/dump0.txt"
    memory_dump_file1 = f"../asm_tests/mem_dump/dump1.txt"

    # Open assembly memory build
    with open(asm_build_file, "r") as asm_file:
        asm_build_text = asm_file.read()

    # Open memory dump after test
    with open(memory_dump_file0, "r") as dump_file0:
        mem_dump_text0 = dump_file0.read()

    with open(memory_dump_file1, "r") as dump_file1:
        mem_dump_text1 = dump_file1.read()

    # Open expect data file
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
    # mem_arr = parse_memory(asm_build_text)
    mem_arr = []
    for i, bin_str in enumerate(exp_value_list):
        mem_arr.append(bin_str)

    # Check memory contents match
    # dump_arr0 = parse_memory(mem_dump_text0)
    dump_arr1 = parse_memory(mem_dump_text1)
    # dump_arr0.extend(dump_arr1)
    err_cnt = 0
    for i, bin in enumerate(mem_arr):
        if mem_arr[i] != dump_arr1[i]:
            print(f"Error @ 0x{i+1024:04X} - expected {mem_arr[i]} - actual {dump_arr1[i]}")
            err_cnt += 1

    # Output test results
    test_name = Path(asm_build_file).stem
    if err_cnt == 0:
        print(f"'{test_name[:-5]}.asm' tests passed!")
    else:
        print(f"Tests failed: {err_cnt} errors.")

