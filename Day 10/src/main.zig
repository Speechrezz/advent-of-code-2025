const std = @import("std");
const parsing = @import("parsing.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input copy.txt");
    defer allocator.free(contents);

    // Parse
    var factory = try parsing.Factory.init(allocator, contents);
    defer factory.deinit(allocator);

    std.debug.print("factory.len={}\n", .{factory.machine_list.items.len});

    // Solve
    //std.debug.print("[Part 1] Solution={}\n", .{part1(&floor)});
    //std.debug.print("[Part 2] Solution={}\n", .{part2(&floor)});
}
