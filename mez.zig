const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var file = try std.fs.cwd().openFile("foo", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    var buffer = try allocator.alloc(u8, file_size);

    try file.reader().readNoEof(buffer);

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

    std.debug.print("ELF HEADER\n", .{});
    std.debug.print("  0-3 - four bytes of magic: ", .{});

    const magic = "\x7fELF";
    for (magic, buffer[0..4]) |should, is| {
        if (should == is) {
            std.debug.print("{x}", .{is});
        } else {
            std.debug.print("\nOH NO! Got {x} instead of {x}.\n", .{ is, should });
            std.os.exit(1);
        }
    }
    std.debug.print(" GOOD!\n", .{});

    // 32 bit?
    if (buffer[4] == 1){
        std.debug.print("  4 - 32-bit, as expected.\n", .{});
    } else {
        std.debug.print("\nOH NO! Got {x} instead of 1 for 32-bits.\n", .{buffer[4]});
        std.os.exit(1);
    }

    // little endian?
    if (buffer[5] == 1){
        std.debug.print("  5 - little-endian, as expected.\n", .{});
    } else {
        std.debug.print("\nOH NO! Got {x} instead of 1 for endianness.\n", .{buffer[5]});
        std.os.exit(1);
    }

    std.debug.print("24-27 - Program entry addr: 0x{x:0>2}{x:0>2}{x:0>2}{x:0>2}\n", .{
        buffer[27],
        buffer[26],
        buffer[25],
        buffer[24],
    });

    std.debug.print("28-31 - Program header offset (in this file): 0x{x:0>2}{x:0>2}{x:0>2}{x:0>2}\n", .{
        buffer[31],
        buffer[30],
        buffer[29],
        buffer[28],
    });

    std.debug.print("32-35 - Section header offset (in this file): 0x{x:0>2}{x:0>2}{x:0>2}{x:0>2}\n", .{
        buffer[35],
        buffer[34],
        buffer[33],
        buffer[32],
    });

    //      42-43 Size of an entry in the program header table
    std.debug.print("42-43 - Size of program header entries.: {d:0>2}{d:0>2} bytes\n", .{
        buffer[43],
        buffer[42],
    });

    //      44-45 Number of entries in the program header table
    std.debug.print("44-45 - Number of program entries: {d:0>2}{d:0>2}\n", .{
        buffer[45],
        buffer[44],
    });

	/*
	program headers
	 0-3 	Type of segment (see below)
			0 = null - ignore the entry
			1 = load - clear p_memsz bytes at p_vaddr to 0
					   then copy p_filesz bytes
					   from p_offset to p_vaddr
			2 = dynamic - requires dynamic linking
			3 = interp - file path to interpreter
			4 = note section
	4-7 	offset in the file, data for this segment (p_offset)
	8-11 	start to put this segment in virtual memory (p_vaddr)
	12-15 	Undefined for the System V ABI
	16-19 	Size of the segment in the file (p_filesz)
	20-23 	Size of the segment in memory (p_memsz)
	24-27 	Flags (see below)
	        1 = executable, 2 = writable, 4 = readable. 
	28-31 	The alignment for this section (must be a power of 2) 
	*/

}
