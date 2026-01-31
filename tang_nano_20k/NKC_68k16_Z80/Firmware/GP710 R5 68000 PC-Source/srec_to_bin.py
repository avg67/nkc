#!/usr/bin/env python3
"""
convert_srec_to_bin.py

Convert a Motorola S-record (SREC / .s19 / .S68 / .srec) file to a flat binary image,
similar to what `srec_cat input.srec -o output.bin -binary` does.

Usage:
    python convert_srec_to_bin.py input.srec output.bin [options]

Options:
    --start ADDR     : Force output start address (hex, e.g. 0x8000). Default = lowest data address.
    --end ADDR       : Force output end address (hex, e.g. 0x8FFF). Default = highest data address.
    --fill BYTE      : Fill byte for gaps (hex byte, default 0xFF).
    --trim           : Trim leading and trailing fill bytes from the generated output.
    --max-bytes N    : Maximum allowed output size in bytes (default 100_000_000). Use --force to override.
    --force          : Ignore max-bytes safety check.
    -v / --verbose   : Verbose logging.
    -h / --help      : Show help.

Example:
    python convert_srec_to_bin.py gp710r5.S68 gp710r5.bin
"""
from pathlib import Path
import argparse
import sys
import re

DEFAULT_MAX_BYTES = 100_000_000  # 100 MB

RE_SREC = re.compile(r'^[ \t]*([sS])([0-9a-fA-F])\s*([0-9a-fA-F]*)\s*$')

def parse_srec_line(line):
    """
    Parse a single S-record line.
    Returns tuple (rectype:int, address:int or None, data:bytes, checksum:int) or raises ValueError.
    """
    line = line.strip()
    if not line:
        return None
    if not line[0] in ('S', 's'):
        raise ValueError("Line does not start with 'S'")
    if len(line) < 4:
        raise ValueError("Line too short")

    rectype = line[1]
    if not rectype.isdigit():
        raise ValueError("Invalid record type")

    # After 'S' and rectype, the rest are hex digits (byte count, address, data, checksum)
    hexpart = line[2:].strip()
    if len(hexpart) % 2 != 0:
        raise ValueError("Odd number of hex digits in record")

    try:
        raw = bytes.fromhex(hexpart)
    except Exception as e:
        raise ValueError(f"Invalid hex in record: {e}")

    if len(raw) < 2:
        raise ValueError("Record too short (needs at least count and checksum)")

    count = raw[0]
    # Verify count matches remaining bytes
    if count != len(raw) - 1:
        # len(raw)-1 omits checksum; count includes address+data+checksum => expected len(raw) == count+1
        # Some files might include extra whitespace, but hex parsing should correct for that.
        # Provide warning but continue if smaller/greater mismatch would break parsing.
        raise ValueError(f"Byte count mismatch: count={count} but record has {len(raw)-1} bytes after count")

    checksum = raw[-1]
    body = raw[1:-1]  # address+data

    # Determine address length by record type
    rectype_num = int(rectype)
    if rectype_num in (0, 1, 5, 9):  # S0,S1,S5,S9 -> 2-byte address for S1 & S9; S0,S5 use as appropriate
        # S1 and S9 use 2-byte addresses; S0 has 2-byte address (typically 0), S5 count record uses 2 bytes address/count
        addr_len = 2 if rectype_num in (1,9,5,0) else 2
    elif rectype_num == 2 or rectype_num == 8:  # S2,S8 -> 3-byte
        addr_len = 3
    elif rectype_num == 3 or rectype_num == 7:  # S3,S7 -> 4-byte
        addr_len = 4
    else:
        # For unknown types (e.g., S4, S6) attempt to deduce: if body len >= 4 use 4, elif >=3 use 3 else 2
        if len(body) >= 4:
            addr_len = 4
        elif len(body) >= 3:
            addr_len = 3
        else:
            addr_len = 2

    if addr_len > len(body):
        raise ValueError("Address length larger than body")

    addr_bytes = body[:addr_len]
    data_bytes = body[addr_len:]

    # Validate checksum: checksum == (~(sum(count + body)) & 0xFF)
    s = count + sum(body)
    calc_checksum = (~s) & 0xFF
    if calc_checksum != checksum:
        raise ValueError(f"Checksum mismatch: calculated 0x{calc_checksum:02X} != record 0x{checksum:02X}")

    address = int.from_bytes(addr_bytes, byteorder='big') if addr_len > 0 else None

    return rectype_num, address, bytes(data_bytes), checksum

def read_srec_file(path, verbose=False):
    """
    Parse an SREC file and return a list of (address, data_bytes) segments and optional start address from S7/S8/S9.
    """
    segments = []  # list of (address, data_bytes)
    start_address = None
    lineno = 0
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for rawline in f:
            lineno += 1
            line = rawline.strip()
            if not line:
                continue
            if not line[0] in ('S', 's'):
                # ignore non-S lines but warn
                if verbose:
                    print(f"Warning: skipping non-S line {lineno}: {line}", file=sys.stderr)
                continue
            try:
                parsed = parse_srec_line(line)
            except ValueError as e:
                raise ValueError(f"{path}:{lineno}: {e}")

            if parsed is None:
                continue
            rectype, address, data, checksum = parsed

            if rectype in (1, 2, 3):
                if address is None:
                    raise ValueError(f"{path}:{lineno}: Data record without address")
                if data:
                    segments.append((address, data))
                    if verbose:
                        print(f"Data record S{rectype}: addr=0x{address:X} len={len(data)}", file=sys.stderr)
            elif rectype in (7, 8, 9):
                # Start address record
                if address is not None:
                    start_address = address
                    if verbose:
                        print(f"Start address record S{rectype}: start=0x{address:X}", file=sys.stderr)
            else:
                # S0 (header), S5 (count), others: ignore
                if verbose:
                    print(f"Ignoring record S{rectype} at {path}:{lineno}", file=sys.stderr)
    return segments, start_address

def build_image(segments, out_start=None, out_end=None, fill=0xFF, verbose=False):
    """
    Given segments list of (address, data_bytes), build a contiguous bytearray from out_start to out_end.
    If out_start/out_end are None, they will be derived from the segments (min/max addresses).
    Returns (bytearray_image, start_address).
    """
    if not segments:
        raise ValueError("No data segments found in SREC")

    min_addr = min(a for a, d in segments)
    max_addr = max(a + len(d) - 1 for a, d in segments)

    if out_start is None:
        out_start = min_addr
    if out_end is None:
        out_end = max_addr

    if out_end < out_start:
        raise ValueError("Output end address is less than start address")

    size = out_end - out_start + 1
    image = bytearray([fill]) * size

    for addr, data in segments:
        seg_start = addr
        seg_end = addr + len(data) - 1
        if seg_end < out_start or seg_start > out_end:
            # Segment outside requested range: skip
            if verbose:
                print(f"Skipping segment at 0x{seg_start:X}-0x{seg_end:X} (outside output range)", file=sys.stderr)
            continue
        # determine insertion indices
        insert_from = max(seg_start, out_start)
        insert_to = min(seg_end, out_end)
        src_offset = insert_from - seg_start
        dst_offset = insert_from - out_start
        length = insert_to - insert_from + 1
        image[dst_offset:dst_offset+length] = data[src_offset:src_offset+length]
        if verbose:
            print(f"Placed {length} bytes at 0x{insert_from:X} (image offset {dst_offset})", file=sys.stderr)

    return image, out_start

def parse_hex_arg(s):
    if s is None:
        return None
    s = s.strip().lower()
    if s.startswith('0x'):
        s = s[2:]
    return int(s, 16)

def main():
    p = argparse.ArgumentParser(description="Convert SREC (.srec/.s19/.S68) to binary.")
    p.add_argument('input', help='Input SREC file')
    p.add_argument('output', help='Output binary file')
    p.add_argument('--start', help='Force output start address (hex)', default=None)
    p.add_argument('--end', help='Force output end address (hex)', default=None)
    p.add_argument('--fill', help='Fill byte for gaps (hex byte, default 0xFF)', default='0xFF')
    p.add_argument('--trim', help='Trim leading/trailing fill bytes from output', action='store_true')
    p.add_argument('--max-bytes', type=int, default=DEFAULT_MAX_BYTES, help=f'Maximum output bytes before refusing (default {DEFAULT_MAX_BYTES})')
    p.add_argument('--force', action='store_true', help='Ignore the max-bytes safety limit')
    p.add_argument('-v', '--verbose', action='store_true', help='Verbose')
    args = p.parse_args()

    inp = Path(args.input)
    out = Path(args.output)
    if not inp.exists():
        print(f"Input file not found: {inp}", file=sys.stderr)
        sys.exit(2)

    try:
        fill_byte = parse_hex_arg(args.fill)
        if fill_byte is None or not (0 <= fill_byte <= 0xFF):
            raise ValueError("Fill must be a byte value (0x00..0xFF)")
    except Exception as e:
        print(f"Invalid --fill value: {e}", file=sys.stderr)
        sys.exit(2)

    try:
        segments, start_addr_from_record = read_srec_file(inp, verbose=args.verbose)
    except ValueError as e:
        print(f"Error parsing SREC: {e}", file=sys.stderr)
        sys.exit(3)

    if not segments:
        print("No data records found in SREC file. Nothing to write.", file=sys.stderr)
        sys.exit(4)

    out_start = parse_hex_arg(args.start) if args.start else None
    out_end = parse_hex_arg(args.end) if args.end else None

    try:
        image, image_start = build_image(segments, out_start=out_start, out_end=out_end, fill=fill_byte, verbose=args.verbose)
    except ValueError as e:
        print(f"Error building image: {e}", file=sys.stderr)
        sys.exit(5)

    # Optional trimming
    if args.trim:
        # trim leading
        left = 0
        while left < len(image) and image[left] == fill_byte:
            left += 1
        right = len(image)
        while right > left and image[right-1] == fill_byte:
            right -= 1
        if left >= right:
            print("After trimming no data remains (all fill). Nothing to write.", file=sys.stderr)
            sys.exit(6)
        image = image[left:right]
        image_start += left
        if args.verbose:
            print(f"Trimmed image to offsets {left}-{right-1}, new start 0x{image_start:X}", file=sys.stderr)

    if len(image) > args.max_bytes and not args.force:
        print(f"Refusing to write {len(image)} bytes (>{args.max_bytes}). Use --force to override.", file=sys.stderr)
        sys.exit(7)

    try:
        # Ensure parent exists
        out.parent.mkdir(parents=True, exist_ok=True)
        with open(out, 'wb') as f:
            f.write(image)
    except Exception as e:
        print(f"Failed to write output file: {e}", file=sys.stderr)
        sys.exit(8)

    print(f"Wrote {len(image)} bytes to {out} (start address 0x{image_start:X})")
    if start_addr_from_record is not None:
        print(f"Start address record in SREC: 0x{start_addr_from_record:X}")
    sys.exit(0)

if __name__ == '__main__':
    main()