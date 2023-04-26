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
    std.debug.print("  e_ident - ei_mag0-3 (4 bytes of magic number): ", .{});

    const ei_mag = "\x7fELF";
    for (ei_mag, buffer[0..4]) |should, is| {
        if (should == is) {
            std.debug.print("{x}", .{is});
        } else {
            std.debug.print("\nOH NO! Got {x} instead of {x}.\n", .{ is, should });
            std.os.exit(1);
        }
    }
    std.debug.print(" GOOD!\n", .{});

    // NEXT: byte 5 is 1: 32bit or 2: 64bit

    std.debug.print("program entry addr: 0x{x:0>2}{x:0>2}{x:0>2}{x:0>2}\n", .{
        buffer[27],
        buffer[26],
        buffer[25],
        buffer[24],
    });
}
