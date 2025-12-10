const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const Point = struct {
    x: i64,
    y: i64,

    pub fn eql(self: @This(), other: @This()) bool {
        return self.x == other.x and self.y == other.y;
    }
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

pub const Area = struct {
    point1: Point,
    point2: Point,
    size: u64 = 0,

    pub fn init(point1: Point, point2: Point) @This() {
        const distance_x = @abs(point1.x - point2.x) + 1;
        const distance_y = @abs(point1.y - point2.y) + 1;

        return .{
            .point1 = point1,
            .point2 = point2,
            .size = distance_x * distance_y,
        };
    }
};

pub const AreaList = std.ArrayList(Area);

pub fn generateSortedAreaList(allocator: std.mem.Allocator, point_list: PointList) !AreaList {
    var area_list: AreaList = .empty;

    for (0..point_list.items.len) |i| {
        for (i + 1..point_list.items.len) |j| {
            try area_list.append(
                allocator,
                Area.init(
                    point_list.items[i],
                    point_list.items[j],
                ),
            );
        }
    }

    std.sort.block(
        Area,
        area_list.items,
        {},
        comptime struct {
            pub fn inner(_: void, a: Area, b: Area) bool {
                return a.size > b.size;
            }
        }.inner,
    );

    return area_list;
}

pub const Floor = struct {
    point_list: PointList,
    area_list: AreaList,

    pub fn init(self: *@This(), allocator: std.mem.Allocator, contents: []const u8) !void {
        self.point_list = try parsePoints(allocator, contents);
        self.area_list = try generateSortedAreaList(allocator, self.point_list);
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.point_list.deinit(allocator);
        self.area_list.deinit(allocator);
    }

    fn getIncrement(start: i64, end: i64) i64 {
        if (start == end) return 0;

        const distance = end - start;
        return @divTrunc(distance, (@as(i64, @intCast(@abs(distance)))));
    }

    fn isPointInsideRectangle(point: Point, top_left: Point, bottom_right: Point) bool {
        const check_x = top_left.x < point.x and point.x < bottom_right.x;
        const check_y = top_left.y < point.y and point.y < bottom_right.y;
        return check_x and check_y;
    }

    pub fn isAreaInside(self: *const @This(), area: Area) bool {
        const top_left: Point = .{
            .x = @min(area.point1.x, area.point2.x),
            .y = @min(area.point1.y, area.point2.y),
        };

        const bottom_right: Point = .{
            .x = @max(area.point1.x, area.point2.x),
            .y = @max(area.point1.y, area.point2.y),
        };

        // Travel along line formed by the two points.
        // If any part of this line is inside the area, then the area has to be invalid.
        var prev_point = self.point_list.getLast();
        for (self.point_list.items) |current_point| {
            const increment_x = getIncrement(prev_point.x, current_point.x);
            const increment_y = getIncrement(prev_point.y, current_point.y);

            var point = prev_point;
            while (!point.eql(current_point)) {
                defer {
                    point.x += increment_x;
                    point.y += increment_y;
                }

                if (isPointInsideRectangle(point, top_left, bottom_right)) {
                    return false;
                }
            }

            prev_point = current_point;
        }

        return true;
    }
};
