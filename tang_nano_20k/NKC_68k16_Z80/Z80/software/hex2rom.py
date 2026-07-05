#!/usr/bin/env python3
"""
Convert binary file to VHDL ROM file.
Similar to hex2rom utility, but for binary files.
"""

import argparse
import sys
from pathlib import Path


def bin2vhdl(input_file, output_file=None, entity_name="basic_rom", data_width=8, addr_width=13):
    """
    Convert binary file to VHDL ROM file.
    
    Args:
        input_file: Path to input binary file
        output_file: Path to output VHDL file (default: input_file.vhd)
        entity_name: Name of the VHDL entity (default: basic_rom)
        data_width: Width of data word in bits (default: 8)
        addr_width: Width of address in bits (default: 13)
    """
    
    # Read binary file
    try:
        with open(input_file, 'rb') as f:
            data = f.read()
    except IOError as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        return False
    
    # Set output filename if not specified
    if output_file is None:
        output_file = Path(input_file).stem + '.vhd'
    
    # Calculate ROM size based on data length and data width
    rom_size = (len(data) * 8 + data_width - 1) // data_width
    max_addr = rom_size - 1
    
    # Verify address width is sufficient
    if rom_size > 2 ** addr_width:
        print(f"Error: Address width {addr_width} bits can only address {2**addr_width} words, "
              f"but file contains {rom_size} words.", file=sys.stderr)
        return False
    
    # Generate VHDL file
    try:
        with open(output_file, 'w') as f:
            # Write header
            f.write("-- This file was generated with bin2vhdl\n\n")
            f.write("library IEEE;\n")
            f.write("use IEEE.std_logic_1164.all;\n")
            f.write("use IEEE.numeric_std.all;\n\n")
            
            # Write entity
            f.write(f"entity {entity_name} is\n")
            f.write("\tport(\n")
            f.write("\t\tClk\t: in std_logic;\n")
            f.write(f"\t\tA\t: in std_logic_vector({addr_width - 1} downto 0);\n")
            f.write(f"\t\tD\t: out std_logic_vector({data_width - 1} downto 0)\n")
            f.write("\t);\n")
            f.write(f"end {entity_name};\n\n")
            
            # Write architecture
            f.write(f"architecture rtl of {entity_name} is\n")
            f.write(f"\tsignal A_r : std_logic_vector({addr_width - 1} downto 0);\n")
            f.write("begin\n")
            
            # Address register process (synchronous)
            f.write("\tprocess (Clk)\n")
            f.write("\tbegin\n")
            f.write("\t\tif Clk'event and Clk = '1' then\n")
            f.write("\t\t\tA_r <= A;\n")
            f.write("\t\tend if;\n")
            f.write("\tend process;\n")
            
            # Data output process (combinational lookup table)
            f.write("\tprocess (A_r)\n")
            f.write("\tbegin\n")
            f.write("\t\tcase to_integer(unsigned(A_r)) is\n")
            
            # Generate case statements for each address
            byte_index = 0
            for addr in range(rom_size):
                # Extract bytes for this word
                word_value = 0
                bits_remaining = data_width
                shift = 0
                
                while bits_remaining > 0 and byte_index < len(data):
                    bits_in_byte = min(8, bits_remaining)
                    byte_val = data[byte_index]
                    
                    if bits_in_byte < 8:
                        # Use only the lower bits_in_byte bits
                        byte_val = byte_val & ((1 << bits_in_byte) - 1)
                    
                    word_value |= (byte_val << shift)
                    shift += bits_in_byte
                    bits_remaining -= bits_in_byte
                    byte_index += 1
                
                # Format the case statement
                binary_str = format(word_value, f'0{data_width}b')
                hex_addr = addr
                
                f.write(f"\t\twhen {addr:06d} => D <= \"{binary_str}\";\t-- 0x{hex_addr:04X}\n")
            
            # Write default case
            f.write(f"\t\twhen others => D <= \"{'-' * data_width}\";\n")
            
            f.write("\t\tend case;\n")
            f.write("\tend process;\n")
            f.write("end;\n")
        
        print(f"Successfully converted {input_file} to {output_file}")
        print(f"ROM size: {rom_size} words ({data_width}-bit words)")
        print(f"Address range: 0 to {max_addr} (0x{max_addr:04X})")
        return True
        
    except IOError as e:
        print(f"Error writing output file: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Convert binary file to VHDL ROM file'
    )
    parser.add_argument('input', help='Input binary file')
    parser.add_argument('-o', '--output', help='Output VHDL file (default: <input>.vhd)')
    parser.add_argument('-e', '--entity', default='basic_rom',
                        help='VHDL entity name (default: basic_rom)')
    parser.add_argument('-d', '--data-width', type=int, default=8,
                        help='Data width in bits (default: 8)')
    parser.add_argument('-a', '--addr-width', type=int, default=13,
                        help='Address width in bits (default: 13)')
    
    args = parser.parse_args()
    
    success = bin2vhdl(
        args.input,
        output_file=args.output,
        entity_name=args.entity,
        data_width=args.data_width,
        addr_width=args.addr_width
    )
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()