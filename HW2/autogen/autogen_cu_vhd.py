"""
Automatic code-generation for SH-2 Control Unit.

There are a large amount of control signals that need to be set for instruction
decoding for the control unit, so this script utilizes an excel spreadsheet with
all the control signals and their corresponding instruction to create code for
instruction decoding. This script only inserts instruction decoding, so code
needs to be written in cu_template.vhd for everything else. CUSignals.xlsx is
the spreadsheet deciding control signals for each instruction. Signals that are
integers need to be added to integer_signal_list. The 'master' is parsed for
instruction decoding, and the 'states' spreadsheet is parsed for signal decoding
for states other than the Normal state.

Spreadsheet expectations:
- Cells contain either signal names, '-', 'ignored', 'unused', 0, or 1.
- Integer signals must be listed in `integer_signal_list`.

The resulting file is also set to read-only permissions so that the user will
make future edits to cu_template.vhd instead of cu.vhd and will re-run script.

The instruction decoding will replace the following line in the template file:
'-- <AUTO-GEN PLACEHOLDER (do not remove or modify): Instruction decoding>'

Author: Garrett Knuf
Date:   21 Apr 2025
"""

import os
import pandas as pd

# Create dataframe from spreadsheets and use instructions (column 0) as the index
spreadsheet_file = '../autogen/CUSignals.xlsx'
normal_df = pd.read_excel(spreadsheet_file, sheet_name="master", index_col=0)
state_df = pd.read_excel(spreadsheet_file, sheet_name="states", index_col=0)

# Create dictionary to store instructions
instruction_decoding = {}
state_decoding = {}

# Iterate through each row (each instruction)
for index, row, in normal_df.iterrows():
    # Convert the row to a dictionary of control signals and add it to dataframe
    normal_control_signals = row.to_dict()
    instruction_decoding[index] = normal_control_signals

for index, row, in state_df.iterrows():
    # Convert the row to a dictionary of control signals and add it to dataframe
    state_control_signals = row.to_dict()
    state_decoding[index] = state_control_signals

# Format VHDL
vhdl_str = ""
std_logic_signal_list = ['DAU_IncDecSel', 'DAU_PrePostSel']
integer_signal_list = ['PAU_SrcSel', 'PAU_OffsetSel', 'DAU_SrcSel', 'DAU_OffsetSel',
                       'DAU_IncDecBit', 'RegInSel', 'RegASelCmd', 'RegBSelCmd',
                       'RegAxInDataSel', 'RegA1SelCmd', 'RegA2SelCmd', 'RegOpSel',
                       'DBOutSel', 'ABOutSel', 'DataAccessMode', 'DBInMode',
                       'TempRegSel', 'PAU_IncDecBit', 'SRSel',
                       'DAU_GBRSel', 'DAU_VBRSel', 'RegAxInSelCmd']

# Create normal instruction decoding
for instruction, normal_control_signals in instruction_decoding.items():
    vhdl_str += f"if std_match(IR, {instruction}) then\n"
    for signal, value in normal_control_signals.items():

        # Parse value (or ignore it if not)
        value = normal_control_signals.get(signal, 'X')
        if value == '-' or value == 'ignored' or value == 'unused':
            continue
        elif value == 0:
            # Choose either std_logic or integer for value zero
            if signal not in integer_signal_list:
                value = "'0'"
            else:
                value = "0"
        elif value == 1:
            # Choose either std_logic or integer for value one
            if signal not in integer_signal_list:
                value = "'1'"
            else:
                value = "1"

        # Add signal
        vhdl_str += f"\t\t\t{signal} <= {value};\n"
    
    # Add elsif
    vhdl_str += f"\t\tels"

# Finish instruction decoding
vhdl_str = vhdl_str[:-3] + "end if;\n" 

# Create signals for state decoding
vhdl_str += "\n\t\t-- State Decoding Autogen\n\t\t"
for state, state_control_signals in state_decoding.items():
    vhdl_str += f"if CurrentState = {state} then\n"
    for signal, value in state_control_signals.items():

        # Parse value (or ignore)
        value = state_control_signals.get(signal, 'X')
        if value == '-' or value == 'ignored' or value == 'unused':
            continue
        elif value == 0:
            if signal not in integer_signal_list:
                value = "'0'"
            else:
                value = "0"
        elif value == 1:
            if signal not in integer_signal_list:
                value = "'1'"
            else:
                value = "1"

        vhdl_str += f"\t\t\t{signal} <= {value};\n"
    vhdl_str += f"\t\tels"
vhdl_str = vhdl_str[:-3] + "end if;\n" 

# Set the paths for your source and destination files
src_file = '../autogen/cu_template.vhd'
dest_file = '../vhd/cu.vhd' 

# Placeholder in the file where the text will be inserted
placeholder = '-- <AUTO-GEN PLACEHOLDER (do not remove or modify): Instruction decoding>'

try:
    # Open the source file and read its contents
    with open(src_file, 'r') as f:
        content = f.read()
    
    # Check if the placeholder exists in the content
    if placeholder in content:
        # Replace the placeholder with the insert text
        content = content.replace(placeholder, vhdl_str)
    else:
        print(f"Warning: Placeholder '{placeholder}' not found in the file.")
    
    # Make sure the destination file is writable
    os.chmod(dest_file, 0o666)

    # Write the modified content to the destination file
    with open(dest_file, 'w') as f:
        f.write(content)

    # Change the destination file to read-only
    os.chmod(dest_file, 0o444)
    
except Exception as e:
    print(f"An error occurred: {e}")