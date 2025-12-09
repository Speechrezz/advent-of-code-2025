const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const Point = struct {
    x: i64,
    y: i64,
};

pub const PointList = std.ArrayList(Point);

pub fn parsePoints(allocator: std.mem.Allocator, contents: []const u8) !PointList {
    var point_list: PointList = .empty;

    const trimmed = std.mem.trimEnd(u8, contents, " \n\r");
    var line_it = std.mem.tokenizeAny(u8, trimmed, "\n\r");

    while (line_it.next()) |line| {
        var comma_it = std.mem.splitScalar(u8, line, ',');

        try point_list.append(allocator, .{
            .x = std.fmt.parseInt(i64, comma_it.first(), 10) catch unreachable,
            .y = std.fmt.parseInt(i64, comma_it.rest(), 10) catch unreachable,
        });
    }

    return point_list;
}
