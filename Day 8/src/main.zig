const std = @import("std");
const parsing = @import("parsing.zig");

fn part1(allocator: std.mem.Allocator, graph: *parsing.Graph, num_connections: usize) !u64 {
    // Brute force: compute distances between every combination of 2 points

    const num_nodes = graph.node_list.items.len;
    const total_connections: usize = @divTrunc(num_nodes * (num_nodes - 1), 2);

    var connection_list = try std.ArrayList(parsing.Connection).initCapacity(allocator, total_connections);
    defer connection_list.deinit(allocator);

    for (0..num_nodes) |i| {
        for (i + 1..num_nodes) |j| {
            var connection: parsing.Connection = .{
                .node1 = &graph.node_list.items[i],
                .node2 = &graph.node_list.items[j],
            };

            connection.computeDistance();
            connection_list.appendAssumeCapacity(connection);
        }
    }

    // Sort connections based on distance
    std.sort.block(parsing.Connection, connection_list.items, {}, comptime parsing.Connection.asc);

    try graph.connection_list.appendSlice(allocator, connection_list.items[0..num_connections]);

    try graph.generateGroups(allocator);
    std.sort.block(parsing.Group, graph.group_list.items, {}, comptime parsing.groupLenDesc);

    var product: u64 = 1;
    for (graph.group_list.items[0..3]) |group| {
        product *= group.node_count;
    }

    return product;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input.txt");
    defer allocator.free(contents);

    // Build graph
    var graph = try parsing.Graph.init(allocator, contents);
    defer graph.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{try part1(allocator, &graph, 1000)});
    //std.debug.print("[Part 1] Solution={}\n", .{try part2(allocator, &graph, 1000)});
}
