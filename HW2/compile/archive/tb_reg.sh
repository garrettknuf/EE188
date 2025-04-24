#!/bin/bash

GHDL="/mnt/c/eda/GHDL/bin/ghdl.exe"
GTKWAVE="/mnt/c/eda/gtkwave/bin/gtkwave.exe"

TB_NAME="tb_reg"
WAVEFORM_NAME="RegArray"
VHDL_FILES=(
    "../vhd/generic/generic_const.vhd"
    "../vhd/generic/generic_reg.vhd"
    "../vhd/reg.vhd"
    "../testbench/tb_reg.vhd"
)

# Check for --hide argument to hide waveform display
VIEW_WAVEFORM=true
for arg in "$@"; do
    if [ "$arg" == "--hide" ]; then
        VIEW_WAVEFORM=false
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