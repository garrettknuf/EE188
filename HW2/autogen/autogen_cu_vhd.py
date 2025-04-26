"""
Automatic code-generation for SH-2 Control Unit.

There are a large amount of control signals that need to be set for instruction
decoding for the control unit, so this script utilizes an excel spreadsheet with
all the control signals and their corresponding instruction to create code for
instruction decoding.
This script only inserts instruction decoding, so code needs to be written in
cu_template.vhd for everything else.

CUSignals.xlsx is the spreadsheet control control signals for each instruction.
Cells contain either a variable name or std_logic value.

The instruction decoding will replace the following line in the template file:
'-- <AUTO-GEN PLACEHOLDER (do not remove): Instruction decoding>'

Author: Garrett Knuf
Date:   21 Apr 2025
"""

import os
import pandas as pd

# Create dataframe from spreadsheets and use instructions (column 0) as the index
spreadsheet_file = '../autogen/CUSignals.xlsx'
df = pd.read_excel(spreadsheet_file, sheet_name="master", index_col=0)

# Create dictionary to store instructions
instruction_decoding = {}

# Iterate through each row (each instruction)
for index, row, in df.iterrows():
    # Convert the row to a dictionary of control signals and add it to dataframe
    control_signals = row.to_dict()
    instruction_decoding[index] = control_signals

# Format VHDL
vhdl_str = "process (all)\n"
vhdl_str += "\tbegin\n\t\t"
std_logic_signal_list = ['DAU_IncDecSel', 'DAU_PrePostSel']
integer_signal_list = ['PAU_SrcSel', 'PAU_OffsetSel', 'DAU_SrcSel', 'DAU_OffsetSel',
                       'DAU_IncDecBit', 'RegInSelCmd', 'RegASelCmd', 'RegBSelCmd',
                       'RegAxInSelCmd', 'RegA1SelCmd', 'RegA2SelCmd', 'RegOpSel']

for instruction, control_signals in instruction_decoding.items():
    vhdl_str += f"if std_match(IR, {instruction}) then\n"
    for signal, value in control_signals.items():
        value = control_signals.get(signal, 'X')

        if value == '-':
            if signal in std_logic_signal_list:
                value = "'-'"
            else:
                value = "(others => '-')"
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
vhdl_str += "\t end process;"

# with open('ir_decoding.vhdl', 'w') as f:
#     f.write(vhdl_str)

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
    
    # print(f"Successfully auto-generated code for '{dest_file}'")
    
except Exception as e:
    print(f"An error occurred: {e}")
