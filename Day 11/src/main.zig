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

    // std.debug.print("graph.node_start={}\n", .{graph.node_start});
    // for (graph.nodes.items) |node| {
    //     std.debug.print("node.name={s}, node.outputs={any}\n", .{ node.name, node.outputs.items });
    // }

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{dfs.search(&graph)});
}
