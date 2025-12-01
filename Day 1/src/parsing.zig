const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const Turn = union(enum) {
    left: i32,
    right: i32,
};

pub const TurnList = std.ArrayList(Turn);

pub fn parse(allocator: std.mem.Allocator, contents: []const u8) !TurnList {
    var turn_list = try TurnList.initCapacity(allocator, 0);

    var line_iterator = std.mem.splitScalar(u8, contents, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) break;

        const turn_amount = try std.fmt.parseInt(i32, line[1..], 10);
        if (line[0] == 'L') {
            try turn_list.append(allocator, .{ .left = turn_amount });
        } else {
            try turn_list.append(allocator, .{ .right = turn_amount });
        }
    }

    return turn_list;
}
