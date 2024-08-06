const std = @import("std");

pub fn readFile(filename: []const u8, allocator: *std.mem.Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    const mb = (1 << 10) << 10;
    const file_contents = try file.readToEndAlloc(allocator.*, 1 * mb);
    return file_contents;
}
