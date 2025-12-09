const std = @import("std");
const parsing = @import("parsing.zig");

fn part1(allocator: std.mem.Allocator, graph: *parsing.Graph, num_connections: usize) !u64 {
    // Brute force: compute distances between every combination of 2 points

    const num_nodes = graph.node_list.items.len;
    const total_connections: usize = @divTrunc(num_nodes * (num_nodes - 1), 2);

    var connection_list = try std.ArrayList(parsing.Connection).initCapacity(allocator, total_connections);
    defer connection_list.deinit(allocator);

    // Create every possible connection
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

    // Generate groups of connections, sorted based on size
    try graph.generateGroups(allocator);
    std.sort.block(parsing.Group, graph.group_list.items, {}, comptime parsing.groupLenDesc);

    var product: u64 = 1;
    for (graph.group_list.items[0..3]) |group| {
        product *= group.nodes.items.len;
    }

    return product;
}

fn part2(allocator: std.mem.Allocator, graph: *parsing.Graph) !u64 {

    // Connect groups until there is only 1 group
    var connection: parsing.Connection = undefined;

    while (graph.group_list.items.len > 1) {
        const group_len = graph.group_list.items.len;

        // Find shortest connection between 2 groups
        var group1_index: u64 = undefined;
        var group2_index: u64 = undefined;

        connection.distance = std.math.maxInt(u64);

        for (0..group_len) |i| {
            for (i + 1..group_len) |j| {
                const group1 = graph.group_list.items[i];
                const group2 = graph.group_list.items[j];

                const new_connection = group1.findShortestConnection(group2);
                if (new_connection.distance < connection.distance) {
                    connection = new_connection;
                    group1_index = i;
                    group2_index = j;
                }
            }
        }

        // Merge two shortest groups
        var group_to_merge = graph.group_list.swapRemove(group2_index);
        try graph.group_list.items[group1_index].merge(allocator, &group_to_merge);
    }

    return @as(u64, @intCast(connection.node1.position.x)) * @as(u64, @intCast(connection.node2.position.x));
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
    std.debug.print("[Part 2] Solution={}\n", .{try part2(allocator, &graph)});
}
