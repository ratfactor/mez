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


    std.debug.print("ELF HEADER\n", .{});
    std.debug.print("  e_ident - ei_mag0-3 (4 bytes of magic number): ", .{});

    const ei_mag = "\x7fELF";
    for (ei_mag, buffer[0..4]) |should, is| {
        if(should == is){
            std.debug.print("{x}", .{is});
        }
        else
        {
            std.debug.print("\nOH NO! Got {x} instead of {x}.\n", .{is, should});
            std.os.exit(1);
        }
    }
    std.debug.print(" GOOD!\n", .{});

    // NEXT: byte 5 is 1: 32bit or 2: 64bit

}
