const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

const values_to_strip = " \n\r";

fn getDimensions(contents: []const u8) struct { usize, usize } {
    var line_iterator = std.mem.splitScalar(u8, contents, '\n');

    const width = std.mem.trimEnd(u8, line_iterator.first(), values_to_strip).len;
    const height = std.mem.count(u8, contents, "\n") + 1;

    return .{ width, height };
}

pub const Diagram = struct {
    data: []const u8,
    width: i32,
    height: i32,

    const empty = '.';
    const rolls = '@';

    pub fn init(allocator: std.mem.Allocator, contents: []const u8) !@This() {
        const trimmed = std.mem.trimEnd(u8, contents, values_to_strip);

        const width, const height = getDimensions(trimmed);

        var data = try allocator.alloc(u8, width * height);

        var index: usize = 0;
        var line_iterator = std.mem.splitScalar(u8, trimmed, '\n');
        while (line_iterator.next()) |line| {
            defer index += width;

            const dest = data[index .. index + width];
            @memcpy(dest, std.mem.trimEnd(u8, line, values_to_strip));
        }

        return .{
            .data = data,
            .width = @intCast(width),
            .height = @intCast(height),
        };
    }

    pub fn deinit(self: *const @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn indexToCoords(self: *const @This(), index: usize) ?struct { x: i32, y: i32 } {
        if (index >= self.data.len) return null;

        const index_i32: i32 = @intCast(index);
        return .{
            .x = @mod(index_i32, self.width),
            .y = @divTrunc(index_i32, self.width),
        };
    }

    fn coordsToIndex(self: *const @This(), x: i32, y: i32) ?usize {
        if (x < 0 or y < 0) return null;
        if (x >= self.width or y >= self.height) return null;

        return @intCast(x + y * (self.width));
    }

    pub fn hasRolls(self: *const @This(), x: i32, y: i32) bool {
        const index = self.coordsToIndex(x, y) orelse return false;
        return self.data[index] == rolls;
    }

    pub fn iterator(self: *const @This()) RollsIterator {
        return .{ .diagram = self };
    }

    pub const RollsIterator = struct {
        diagram: *const Diagram,
        index: usize = 0,
        x: i32 = 0,
        y: i32 = 0,

        pub fn next(self: *@This()) bool {
            while (self.index < self.diagram.data.len) {
                defer self.index += 1;

                if (self.diagram.data[self.index] == Diagram.rolls) {
                    const coords = self.diagram.indexToCoords(self.index) orelse unreachable;
                    self.x = coords.x;
                    self.y = coords.y;

                    return true;
                }
            } else return false;
        }
    };
};
