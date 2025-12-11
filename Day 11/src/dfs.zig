const std = @import("std");
const parsing = @import("parsing.zig");

const Node = parsing.Node;
const Graph = parsing.Graph;

pub fn search(graph: *Graph) u64 {
    return dfsStep(graph.node_start);
}

pub fn dfsStep(node: *Node) u64 {
    var count: u64 = 0;

    for (node.outputs.items) |next_node_optional| {
        if (next_node_optional) |next_node| {
            count += dfsStep(next_node);
        } else {
            return 1;
        }
    }

    return count;
}
