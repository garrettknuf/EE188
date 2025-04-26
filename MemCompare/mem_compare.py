import sys
import re

def convert_to_16bit_patterns_from_file(filename):
    """
    Read in file with B.x, W.X, or L.x (byte, word, or long) where x is the value.
    Convert these into 16-bit binary strings and return a list of them.
    """
    # Regular expression to match B.x, w.x, l.x format
    pattern = re.compile(r'([Bwl])\.(\d+)')
    bit_positions = set()  # Use a set to avoid duplicates
    
    try:
        # Open the file and read its contents
        with open(filename, 'r') as file:
            text = file.read()
        
        # Find all occurrences of B.x, w.x, l.x
        matches = pattern.findall(text)
        print(matches)
        
        for match in matches:
            type_, position = match
            position = int(position)
            
            # Add the bit position to the set
            bit_positions.add(position)
        
        # Convert bit positions to 16-bit patterns
        bit_patterns = []
        for pos in bit_positions:
            if pos < 16:
                bit_pattern = 1 << pos  # Set the bit at the position
                # Convert to binary string, pad to 16 bits
                bit_patterns.append(f'{bit_pattern:016b}')
        
        return bit_patterns
    except FileNotFoundError:
        print(f"Error: The file '{filename}' was not found.")
        return []
    
def read_16bit_binary_file(filename):
    """Read a file containing 16-bit binary strings."""
    try:
        with open(filename, 'r') as file:
            # Read each line, strip any leading/trailing spaces and store as a list
            return [line.strip() for line in file.readlines()]
    except FileNotFoundError:
        print(f"Error: The file '{filename}' was not found.")
        return []

def compare_patterns(expected_patterns_file, actual_instructions_file):
    # Step 1: Get the expected 16-bit patterns from the first file
    expected_patterns = convert_to_16bit_patterns_from_file(expected_patterns_file)
    
    if not expected_patterns:
        print("No expected patterns to compare.")
        return
    
    # Step 2: Read the actual 16-bit binary instructions from the second file
    actual_instructions = read_16bit_binary_file(actual_instructions_file)
    
    if not actual_instructions:
        print("No actual instructions to compare.")
        return
    
    # Step 3: Compare each 16-bit instruction against expected patterns
    print("Comparing expected patterns with actual instructions:")
    for instruction in actual_instructions:
        if instruction in expected_patterns:
            print(f"Match: {instruction}")
        else:
            print(f"Mismatch: {instruction}")

# Entry point for the script
if __name__ == "__main__":

    # Check if the correct number of arguments is passed
    if len(sys.argv) != 3:
        print("Usage: python script.py <actual_instructions_file> <expected_patterns_file>")
        sys.exit(1)

    # Get the filenames from command-line arguments
    actual_instructions_file = sys.argv[1]
    expected_patterns_file = sys.argv[2]

    # Call the function to compare patterns
    compare_patterns(expected_patterns_file, actual_instructions_file)


