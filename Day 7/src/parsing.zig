const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const Diagram = struct {
    data: []u8,
    width: usize,
    height: usize,

    pub const start = 'S';
    pub const empty = '.';
    pub const splitter = '^';
    pub const laser = '|';

    pub fn init(allocator: std.mem.Allocator, contents: []u8) !@This() {
        const trimmed = std.mem.trimEnd(u8, contents, " \n\r");
        const width = std.mem.indexOfAny(u8, trimmed, "\n\r") orelse unreachable;
        const height = std.mem.count(u8, trimmed, "\n") + 1;

        const data = try allocator.alloc(u8, width * height);

        var line_iterator = std.mem.tokenizeAny(u8, trimmed, "\n\r");
        var i: usize = 0;
        while (line_iterator.next()) |line| {
            defer i += width;
            @memcpy(data[i .. i + width], line);
        }

        return .{
            .data = data,
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn coordsToIndex(self: *const @This(), x: usize, y: usize) usize {
        std.debug.assert(x < self.width);
        std.debug.assert(y < self.height);
        return x + y * self.width;
    }

    pub fn indexToCoords(self: *const @This(), index: usize) struct { usize, usize } {
        return .{
            @mod(index, self.width),
            @divTrunc(index, self.width),
        };
    }

    pub fn atCoords(self: *@This(), x: usize, y: usize) *u8 {
        return &self.data[self.coordsToIndex(x, y)];
    }

    pub fn getLine(self: *const @This(), y: usize) []const u8 {
        const index = self.coordsToIndex(0, y);
        return self.data[index .. index + self.width];
    }
};
