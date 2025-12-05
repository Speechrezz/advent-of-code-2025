const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const Range = struct {
    min: u64,
    max: u64,

    pub fn difference(self: *const @This()) u64 {
        return self.max - self.min;
    }

    pub fn isInRange(self: *const @This(), id: u64) bool {
        return self.min <= id and id <= self.max;
    }

    pub fn overlap(self: *const @This(), other: *const @This()) ?@This() {
        const start = @max(self.min, other.min);
        const end = @min(self.max, other.max);

        if (start > end) return null;

        return .{
            .min = start,
            .max = end,
        };
    }
};

pub const RangeList = std.ArrayList(Range);
pub const IdList = std.ArrayList(u64);

pub const Database = struct {
    range_list: RangeList,
    id_list: IdList,

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.range_list.deinit(allocator);
        self.id_list.deinit(allocator);
    }
};

pub fn parseDatabase(allocator: std.mem.Allocator, contents: []const u8) !Database {
    const trimmed = std.mem.trimEnd(u8, contents, " \n\r");
    var line_iterator = std.mem.splitScalar(u8, trimmed, '\n');

    var range_list: RangeList = .empty;
    var id_list: IdList = .empty;

    // Parse ranges
    while (line_iterator.next()) |full_line| {
        const line = std.mem.trimEnd(u8, full_line, " \r");
        if (line.len == 0) break;

        var dash_iterator = std.mem.splitScalar(u8, line, '-');

        try range_list.append(allocator, .{
            .min = try std.fmt.parseUnsigned(u64, dash_iterator.first(), 10),
            .max = try std.fmt.parseUnsigned(u64, dash_iterator.rest(), 10),
        });
    }

    // Parse ID's
    while (line_iterator.next()) |full_line| {
        const line = std.mem.trimEnd(u8, full_line, " \r");

        try id_list.append(allocator, try std.fmt.parseUnsigned(u64, line, 10));
    }

    return .{
        .range_list = range_list,
        .id_list = id_list,
    };
}
