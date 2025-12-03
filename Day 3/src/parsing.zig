const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const BankIterator = struct {
    line_iterator: std.mem.SplitIterator(u8, .scalar),

    pub fn init(contents: []const u8) @This() {
        return .{
            .line_iterator = std.mem.splitScalar(u8, contents, '\n'),
        };
    }

    pub fn next(self: *@This()) ?[]const u8 {
        const next_line = self.line_iterator.next() orelse return null;
        if (next_line.len == 0) return null;

        return std.mem.trimEnd(u8, next_line, " \n\r");
    }
};
