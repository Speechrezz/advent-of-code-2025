const std = @import("std");
const parsing = @import("parsing.zig");

const Node = parsing.Node;
const Graph = parsing.Graph;

// Part 1

pub fn searchPart1(graph: *Graph) u64 {
    return dfsStepPart1(graph.findNode("you").?);
}

pub fn dfsStepPart1(node: *Node) u64 {
    var count: u64 = 0;

    for (node.outputs.items) |next_node_optional| {
        if (next_node_optional) |next_node| {
            count += dfsStepPart1(next_node);
        } else { // Reached end
            return 1;
        }
    }

    return count;
}

// Part 2

const CountsPart2 = parsing.CountsPart2;

pub fn searchPart2(graph: *Graph) u64 {
    const counts = dfsStepPart2(graph.findNode("svr").?);
    return counts.valid;
}

fn intFromBool(comptime T: type, v: bool) T {
    return @intCast(@intFromBool(v));
}

pub fn dfsStepPart2(node: *Node) CountsPart2 {
    if (node.counts) |counts| { // Already visited
        return counts;
    }

    node.counts = .{};
    const counts = &node.counts.?;

    const is_dac = node.nameEql("dac");
    const is_fft = node.nameEql("fft");

    for (node.outputs.items) |next_node_optional| {
        if (next_node_optional) |next_node| {
            const next_counts = dfsStepPart2(next_node);
            counts.dac += intFromBool(u64, is_dac) * next_counts.paths;
            counts.fft += intFromBool(u64, is_fft) * next_counts.paths;

            if (is_dac) {
                counts.valid += next_counts.fft;
            } else if (is_fft) {
                counts.valid += next_counts.dac;
            } else {
                counts.addFrom(next_counts);
            }
        } else {
            counts.paths += 1;
        }
    }

    return counts.*;
}
