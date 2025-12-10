const std = @import("std");
const parsing = @import("parsing.zig");

fn part1(floor: *parsing.Floor) u64 {
    return floor.area_list.items[0].size;
}

fn part2(floor: *parsing.Floor) u64 {
    for (floor.area_list.items) |area| {
        if (floor.isAreaInside(area)) {
            return area.size;
        }
    }

    std.debug.assert(false); // Should never reach here
    return 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input.txt");
    defer allocator.free(contents);

    // Parse
    var floor: parsing.Floor = undefined;
    try floor.init(allocator, contents);
    defer floor.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&floor)});
    std.debug.print("[Part 2] Solution={}\n", .{part2(&floor)});
}
