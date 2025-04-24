#!/bin/bash

GHDL="/mnt/c/eda/GHDL/bin/ghdl.exe"
GTKWAVE="/mnt/c/eda/gtkwave/bin/gtkwave.exe"
PYTHONEXEC="/mnt/c/Users/garre/AppData/Local/Microsoft/WindowsApps/python3.exe"

# Change executable path for George
for arg in "$@"; do
    if [ "$arg" == "--gore" ]; then
        GHDL="/usr/bin/ghdl"
        GTKWAVE="/usr/bin/gtkwave"
        PYTHONEXEC="/usr/bin/python3"
        echo "Hello Gore!"
        break
    fi
done

TB_NAME="tb_sh2_cpu"
WAVEFORM_NAME="SH2_CPU"
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
    "../vhd/cu.vhd"
    "../vhd/sh2_cpu.vhd"
    "../testbench/tb_sh2_cpu.vhd"
)

# Check for --hide argument to hide waveform display
VIEW_WAVEFORM=true
for arg in "$@"; do
    if [ "$arg" == "--hide" ]; then
        VIEW_WAVEFORM=false
        break
    fi
done

# Check for --autogen argument to autogencode
AUTOGEN=false
for arg in "$@"; do
    if [ "$arg" == "--autogen" ]; then
        AUTOGEN=true
        $PYTHONEXEC ../autogen/autogen_cu_vhd.py
        echo "CU Auto-gen complete"
        break
    fi
done

# Analyze
echo "Analyzing..."
for file in "${VHDL_FILES[@]}"; do
    #echo "Analyzing $file..."
    $GHDL -a --std=08 "$file"
done

# Elaborate
echo "Elaborating..."
$GHDL -e --std=08 $TB_NAME

# Run
echo "Running..."
$GHDL -r --std=08 $TB_NAME --vcd="$TB_NAME.vcd"

# Waveform viewer
if [ "$VIEW_WAVEFORM" == true ]; then
    if [ -f "../compile/$WAVEFORM_NAME.gtkw" ]; then
        $GTKWAVE "../compile/$WAVEFORM_NAME.gtkw"
    else
        $GTKWAVE "$TB_NAME.vcd"
    fi
fi