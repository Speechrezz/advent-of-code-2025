const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const Range = struct {
    start: u64,
    end: u64,
};

pub const RangeList = std.ArrayList(Range);

pub fn parse(allocator: std.mem.Allocator, contents: []const u8) !RangeList {
    var range_list = try RangeList.initCapacity(allocator, 0);
    const trimmed = std.mem.trimEnd(u8, contents, " \n\r");

    var comma_iterator = std.mem.splitScalar(u8, trimmed, ',');
    while (comma_iterator.next()) |id| {
        if (id.len == 0) break;

        var range: Range = undefined;
        var dash_iterator = std.mem.splitScalar(u8, id, '-');

        range.start = try std.fmt.parseInt(u64, dash_iterator.first(), 10);
        range.end = try std.fmt.parseInt(u64, dash_iterator.rest(), 10);

        try range_list.append(allocator, range);
    }

    return range_list;
}
