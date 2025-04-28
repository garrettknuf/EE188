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
            binary_values.append(bin_part)
    
    return binary_values

if __name__ == "__main__":



    # Check if the correct number of arguments is passed
    if len(sys.argv) != 4:
        print("Usage: python mem_compare.py <asm_build_file> <mem_dump_file> <expected_mem_file")
        sys.exit(1)

    asm_build_file = sys.argv[1]
    memory_dump_file = sys.argv[2]
    expected_memory_file = sys.argv[3]
    
    # asm_build_file = '../HW2/asm_tests/build/logic.txt'
    # memory_dump_file = '../HW2/asm_tests/mem_dump/dump.txt'
    # expected_memory_file = '../HW2/asm_tests/expected/logic_exp.txt'

    # Open assembly memory build
    with open(asm_build_file, "r") as asm_file:
        asm_build_text = asm_file.read()

    # Open memory dump after test
    with open(memory_dump_file, "r") as dump_file:
        mem_dump_text = dump_file.read()

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
                    # Parse the value
                    value = int(line[2:])
                    # Split 32-bit value into two 16-bit words
                    high = (value >> 16) & 0xFFFF
                    low = value & 0xFFFF
                    exp_value_list.append(f"{high:016b}")
                    exp_value_list.append(f"{low:016b}")
                elif line.startswith("W."):
                    value = int(line[2:])
                    exp_value_list.append(f"{value & 0xFFFF:016b}")
                elif line.startswith("B."):
                    value = int(line[2:])
                    # Expand 8-bit byte into a 16-bit word (typically zero-extend)
                    exp_value_list.append(f"{value & 0xFF:08b}".rjust(16, '0'))
                else:
                    print(f"Unknown line: {line}")

    # Move expected values into correct memory contents
    mem_arr = parse_memory(asm_build_text)
    for i, bin_str in enumerate(exp_value_list):
        mem_arr[start_addr//2 + i] = bin_str

    # Check memory contents match
    dump_arr = parse_memory(mem_dump_text)
    err_cnt = 0
    for i, bin in enumerate(mem_arr):
        if mem_arr[i] != dump_arr[i]:
            print(f"Error @ 0x{i * 2:04X}: {mem_arr[i]} != {dump_arr[i]}")
            err_cnt += 1

    # Output test results
    test_name = Path(asm_build_file).stem
    if err_cnt == 0:
        print(f"'{test_name}.asm' tests passed!")
    else:
        print(f"Tests failed: {err_cnt} errors.")

