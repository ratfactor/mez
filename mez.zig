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
    std.debug.print("  4 bytes of magic: ", .{});

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
        std.debug.print("  32-bit, as expected.\n", .{});
    } else {
        std.debug.print("\nOH NO! Got {x} instead of 1 for 32-bits.\n", .{buffer[4]});
        std.os.exit(1);
    }

    // little endian?
    if (buffer[5] == 1){
        std.debug.print("  little-endian, as expected.\n", .{});
    } else {
        std.debug.print("\nOH NO! Got {x} instead of 1 for endianness.\n", .{buffer[5]});
        std.os.exit(1);
    }

    std.debug.print("Program entry addr: 0x{x:0>2}{x:0>2}{x:0>2}{x:0>2}\n", .{
        buffer[27],
        buffer[26],
        buffer[25],
        buffer[24],
    });

    std.debug.print("Program header offset (in this file): 0x{x:0>2}{x:0>2}{x:0>2}{x:0>2}\n", .{
        buffer[34],
        buffer[33],
        buffer[32],
        buffer[31],
    });

    std.debug.print("Section header offset (in this file): 0x{x:0>2}{x:0>2}{x:0>2}{x:0>2}\n", .{
        buffer[35],
        buffer[36],
        buffer[37],
        buffer[38],
    });
}
