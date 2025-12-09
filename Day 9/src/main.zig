const std = @import("std");
const parsing = @import("parsing.zig");

fn computeArea(point1: parsing.Point, point2: parsing.Point) u64 {
    const distance_x = @abs(point1.x - point2.x) + 1;
    const distance_y = @abs(point1.y - point2.y) + 1;

    return distance_x * distance_y;
}

fn part1(point_list: parsing.PointList) u64 {
    var largest: u64 = 0;

    for (0..point_list.items.len) |i| {
        for (i + 1..point_list.items.len) |j| {
            const point1 = point_list.items[i];
            const point2 = point_list.items[j];

            const area = computeArea(point1, point2);
            largest = @max(largest, area);
        }
    }

    return largest;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input.txt");
    defer allocator.free(contents);

    // Parse
    var point_list = try parsing.parsePoints(allocator, contents);
    defer point_list.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(point_list)});
    //std.debug.print("[Part 2] Solution={}\n", .{part2(contents)});
}
