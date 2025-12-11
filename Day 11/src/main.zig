const std = @import("std");
const parsing = @import("parsing.zig");
const dfs = @import("dfs.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input.txt");
    defer allocator.free(contents);

    // Parse
    var graph = parsing.Graph.init();
    defer graph.deinit(allocator);
    try graph.build(allocator, contents);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{dfs.searchPart1(&graph)});
    std.debug.print("[Part 2] Solution={}\n", .{dfs.searchPart2(&graph)});
}
