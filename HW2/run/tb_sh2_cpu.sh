#!/bin/bash

# Stop script if any command fails
set -e

GHDL="/mnt/c/eda/GHDL/bin/ghdl.exe"
GTKWAVE="/mnt/c/eda/gtkwave/bin/gtkwave.exe"
PYTHONEXEC="/mnt/c/Users/garre/AppData/Local/Microsoft/WindowsApps/python3.exe"
ASSEMBLER="../../SH2Assembler/sh2_asm.py"
MEMCOMPARE="../../MemCompare/mem_compare.py"

# Include Assembly test files
ASM_FILES=(
    "../asm_tests/fibonacci.asm"
    "../asm_tests/arithmetic.asm"
    # "../asm_tests/logic.asm"
    # "../asm_tests/shift.asm"
    # "../asm_tests/branch.asm"
    # "../asm_tests/data_xfer.asm"
    # "../asm_tests/sys_ctrl.asm"
)

# Check for --gore to use executable path for George
for arg in "$@"; do
    if [ "$arg" == "--gore" ]; then
        GHDL="/usr/bin/ghdl"
        GTKWAVE="/usr/bin/gtkwave"
        break
    fi
done

# Check for --asm argument to assemble code
ASSEMBLE=false
for arg in "$@"; do
    if [ "$arg" == "--asm" ] || [ "$arg" == "--all" ]; then
        ASSEMBLE=true
        break
    fi
done

# Check for --autogen argument to autogenerate code
AUTOGEN=false
for arg in "$@"; do
    if [ "$arg" == "--autogen" ] || [ "$arg" == "--all" ]; then
        AUTOGEN=true
        break
    fi
done

# Check for --check argument to check memory contents
CHECK_MEM=false
for arg in "$@"; do
    if [ "$arg" == "--check" ] || [ "$arg" == "--all" ]; then
        CHECK_MEM=true
        break
    fi
done

# Check for --hide argument to hide waveform display
VIEW_WAVEFORM=true
for arg in "$@"; do
    if [ "$arg" == "--hide" ]; then
        VIEW_WAVEFORM=false
        break
    fi
done

# Include VHDL files
TB_NAME="tb_sh2_cpu"
WAVEFORM_NAME="tb_sh2_cpu"
VHDL_FILES=(
    "../vhd/generic/generic_const.vhd"
    "../vhd/generic/generic_alu.vhd"
    "../vhd/generic/generic_mau.vhd"
    "../vhd/generic/generic_reg.vhd"
    "../vhd/alu.vhd"
    "../vhd/dau.vhd"
    "../vhd/pau.vhd"
    "../vhd/reg.vhd"
    "../vhd/sr.vhd"
    "../vhd/opcode.vhd"
    "../vhd/cu.vhd"
    "../vhd/sh2_cpu.vhd"
    "../testbench/memory.vhd"
    "../testbench/tb_sh2_cpu.vhd"
)


# Check for --autogen argument to autogencode
if [ "$AUTOGEN" == true ]; then
    echo "Auto-generating control unit..."
    $PYTHONEXEC ../autogen/autogen_cu_vhd.py
    # echo "'cu_template.vhd' + 'CUSignals.xlsx' -> 'cu.vhd'"
fi

# Analyze
echo "Analyzing..."
for file in "${VHDL_FILES[@]}"; do
    # echo -e "\t$file..."
    $GHDL -a --std=08 "$file"
done

# Elaborate
echo "Elaborating..."
$GHDL -e --std=08 $TB_NAME

# Run multiple tests
for asm_file in "${ASM_FILES[@]}"; do
    # Get the base name of the file (e.g., 'fibonacci', 'arithmetic')
    base_name=$(basename "$asm_file" .asm)

    # Assemble code if enabled
    if [ "$ASSEMBLE" == true ]; then
        echo "Assembling '$base_name.asm'."

        # Create output file name
        output_file="../asm_tests/build/build.txt"

        # Run assembler 
        $PYTHONEXEC $ASSEMBLER "$asm_file" "$output_file"
        # done
    fi

    # Generate the corresponding output memory file (e.g., 'fibonacci.txt')
    mem_file0="../asm_tests/build/build_mem0.txt"
    mem_file1="../asm_tests/build/build_mem1.txt"

    # Check if the memory file exists before running
    if [[ -f "$mem_file0" && -f "$mem_file1" ]]; then
        echo "Running '$base_name.asm'..."
        
        # Run the simulation for each test case with the corresponding memory file
        $GHDL -r --std=08 $TB_NAME --vcd="$TB_NAME-$base_name.vcd" -gmem0_filepath="$mem_file0" -gmem1_filepath="$mem_file1"

        # Check memory contents
        if [ "$CHECK_MEM" == true ]; then
            echo "Verifying '$base_name.asm' memory contents..."
            $PYTHONEXEC $MEMCOMPARE $base_name
        fi

    else
        echo "Error: Memory file $memory_file does not exist. Skipping test."
    fi
done

# Waveform viewer
if [ "$VIEW_WAVEFORM" == true ]; then
    if [ -f "../run/$TB_NAME-$base_name.gtkw" ]; then
        $GTKWAVE "../run/$TB_NAME-$base_name.gtkw"
    else
        $GTKWAVE "../run/$TB_NAME-$base_name.vcd"
    fi
fi