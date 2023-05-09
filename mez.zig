const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var file = try std.fs.cwd().openFile("foo", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    var buffer = try allocator.alloc(u8, file_size);

    try file.reader().readNoEof(buffer);

    // Main Header
    // Adapted from excellent table at https://wiki.osdev.org/ELF
    //
    //   Position Value
    //  --------- --------------------------------------------------
    //        0-3 Magic number - 0x7F, then 'ELF' in ASCII
    //          4 bits: 1 = 32 bit, 2 = 64 bit
    //          5 endian: 1 = little endian, 2 = big endian
    //          6 ELF header version
    //          7 OS ABI - usually 0 for System V
    //       8-15 Unused/padding
    //      16-17 type: 1 = reloc., 2 = exec., 3 = shared, 4 = core
    //      18-19 Instruction set - see table below
    //      20-23 ELF Version
    //      24-27 Program entry position
    //      28-31 Program header table position
    //      32-35 Section header table position
    //      36-39 Flags - architecture dependent; see note below
    //      40-41 Header size
    //      42-43 Size of an entry in the program header table
    //      44-45 Number of entries in the program header table
    //      46-47 Size of an entry in the section header table
    //      48-49 Number of entries in the section header table
    //      50-51 Index in section header table with section names

    print("-----------------------------------------\n", .{});
    print("Main ELF Header\n", .{});
    print("  0-3 - four bytes of magic (0x7f,'ELF'): ", .{});

    const magic = "\x7fELF";
    for (magic, buffer[0..4]) |should, is| {
        if (should != is) {
            print("\nOH NO! Got {x} instead of {x}.\n", .{ is, should });
            std.os.exit(1);
        }
    }
    print("Matched!\n", .{});

    // 32 bit?
    if (buffer[4] == 1) {
        print("    4 - 32-bit, as expected.\n", .{});
    } else {
        print("\nOH NO! Got {x} instead of 1 for 32-bits.\n", .{buffer[4]});
        std.os.exit(1);
    }

    // little endian?
    if (buffer[5] == 1) {
        print("    5 - little-endian, as expected.\n", .{});
    } else {
        print("\nOH NO! Got {x} instead of 1 for endianness.\n", .{buffer[5]});
        std.os.exit(1);
    }

    const entry_addr = cast(u32, buffer[24..28]);
    print("24-27 - Program entry addr: 0x{x:0>8}\n", .{entry_addr});

    const ph_offset = cast(u32, buffer[28..32]);
    print("28-31 - Program header offset (in this file): 0x{x}\n", .{ph_offset});

    print("32-35 - Section header offset (in this file): 0x{x}\n", .{cast(u32, buffer[32..36])});

    //      40-41 Header size
    print("40-41 - Size of this header: {d} bytes\n", .{cast(u16, buffer[40..42])});


    //      42-43 Size of an entry in the program header table
    const ph_size = cast(u16, buffer[42..44]);
    print("42-43 - Size of program header entries: {d} bytes\n", .{ph_size});

    //      44-45 Number of entries in the program header table
    const ph_count = cast(u16, buffer[44..46]);
    print("44-45 - Number of program entries: {d}\n", .{ph_count});


    // Program headers
    // Adapted from excellent table at https://wiki.osdev.org/ELF
    //	 0-3 	Type of segment (see below)
    //			0 = null - ignore the entry
    //			1 = load - clear p_memsz bytes at p_vaddr to 0
    //					   then copy p_filesz bytes
    //					   from p_offset to p_vaddr
    //			2 = dynamic - requires dynamic linking
    //			3 = interp - file path to interpreter
    //			4 = note section
    //	4-7 	offset in file, data for this segment (p_offset)
    //	8-11 	start to put this segment in virtual mem (p_vaddr)
    //	12-15 	Undefined for the System V ABI
    //	16-19 	Size of the segment in the file (p_filesz)
    //	20-23 	Size of the segment in memory (p_memsz)
    //	24-27 	Flags (see below)
    //	        1 = executable, 2 = writable, 4 = readable.
    //	28-31 	The alignment for this section (must be power of 2)

    // Point to the first header offset
    var ph_pos = ph_offset;


    for(0..ph_count) |_|{
        print("-----------------------------------------\n", .{});
        print("Program Header @ 0x{x}\n", .{ph_pos});

        //	 0-3 	Type of segment
        const ph_type = cast(u32, buffer[ph_pos..ph_pos+4]);

        if (ph_type == 1)  {
            print("  Segment type: {d} ('load', as expected)\n", .{ph_type});
        }
    else{
            print("\nERROR: Expected segment type 1 ('load'), got {d} instead.\n", .{ph_type});
            printMem(buffer, ph_pos);
            std.os.exit(1);
        }

        //	4-7 	offset in file
        const seg_foffset = cast(u32, buffer[ph_pos+4..ph_pos+8]);
        print("  File offset: 0x{x}\n", .{seg_foffset});

        //	16-19 	Size of the segment in the file (p_filesz)
        const seg_fsize = cast(u32, buffer[ph_pos+16..ph_pos+20]);
        print("  File size: {d} bytes\n", .{seg_fsize});

        //	8-11 	start to put this segment in virtual mem (p_vaddr)
        const seg_moffset = cast(u32, buffer[ph_pos+8..ph_pos+12]);
        print("  Target memory start: 0x{x}\n", .{seg_moffset});

        //	20-23 	Size of the segment in memory (p_memsz)
        const seg_msize = cast(u32, buffer[ph_pos+20..ph_pos+24]);
        print("  Target memory size: {d} bytes\n", .{seg_msize});

        print(
            \\  Memory mapping:
            \\    +--------------------+     +--------------------+
            \\    | File               | ==> | Memory             |
            \\    |====================|     |====================|
            \\    | 0x{x: <7}          |     | 0x{x:0>8}         |
            \\    |   Load: {d: <7}    |     |   Alloc: {d: <7}   |
            \\    | 0x{x: <7}          |     | 0x{x:0>8}         |
            \\    +--------------------+     +--------------------+
            \\
        ,
            .{
                seg_foffset,
                seg_moffset,
                seg_fsize,
                seg_msize,
                seg_foffset+seg_fsize,
                seg_moffset+seg_msize,
            });

        // Move to next header
        ph_pos += ph_size;
    }


}

fn printMem(mem: []u8, pos: usize) void {
    const start=std.math.max(0, pos-4);
    const end=std.math.min(mem.len, pos+4);
    for(mem[start..end], start..end)|m,c|{
        if(c==pos){
            print("{x}: {x} <--- pos\n", .{c, m});
        }
        else{
            print("{x}: {x}\n", .{c, m});
        }
    }
}

fn cast(T: anytype, bytes: []u8) T {
    if(@sizeOf(T) != bytes.len){
            print("Mismatch for cast: type is {d} bytes but slice is {d}.\n", .{ @sizeOf(T), bytes.len });
            std.os.exit(1);
    }
    
    return @ptrCast(*align(1) const T, bytes).*;
}
