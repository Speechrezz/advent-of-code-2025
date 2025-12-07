const std = @import("std");
const parsing = @import("parsing.zig");

fn processLaserAbovePart1(diagram: *parsing.Diagram, x: usize, y: usize) u64 {
    const current = diagram.atCoords(x, y);

    if (current.* == parsing.Diagram.splitter) {
        diagram.atCoords(x - 1, y).* = parsing.Diagram.laser;
        diagram.atCoords(x + 1, y).* = parsing.Diagram.laser;
        return 1;
    }

    current.* = parsing.Diagram.laser;
    return 0;
}

fn part1(diagram: *parsing.Diagram) u64 {
    var split_count: u64 = 0;
    var y: usize = 1;

    while (y < diagram.height) {
        defer y += 1;

        for (0..diagram.width) |x| {
            const above = diagram.atCoords(x, y - 1).*;

            if (above == parsing.Diagram.start or above == parsing.Diagram.laser) {
                split_count += processLaserAbovePart1(diagram, x, y);
            }
        }
    }

    return split_count;
}

fn processLaserAbovePart2(diagram: *parsing.Diagram, laser_buffer: []u64, x: usize, y: usize) void {
    const index = diagram.coordsToIndex(x, y);
    const current = &diagram.data[index];

    const above_index = diagram.coordsToIndex(x, y - 1);
    const above_lasers: u64 = if (diagram.data[above_index] == parsing.Diagram.start) 1 else laser_buffer[above_index];

    if (current.* == parsing.Diagram.splitter) {
        const index_left = diagram.coordsToIndex(x - 1, y);
        const index_right = diagram.coordsToIndex(x + 1, y);

        diagram.data[index_left] = parsing.Diagram.laser;
        diagram.data[index_right] = parsing.Diagram.laser;

        laser_buffer[index_left] += above_lasers;
        laser_buffer[index_right] += above_lasers;
    } else {
        current.* = parsing.Diagram.laser;
        laser_buffer[index] += above_lasers;
    }
}

fn part2(allocator: std.mem.Allocator, diagram: *parsing.Diagram) !u64 {
    const laser_buffer = try allocator.alloc(u64, diagram.data.len);
    defer allocator.free(laser_buffer);
    for (laser_buffer) |*v| v.* = 0;

    var y: usize = 1;

    // Count number of lasers/paths that reached each position
    while (y < diagram.height) {
        defer y += 1;

        for (0..diagram.width) |x| {
            const above = diagram.atCoords(x, y - 1).*;

            if (above == parsing.Diagram.start or above == parsing.Diagram.laser) {
                processLaserAbovePart2(diagram, laser_buffer, x, y);
            }
        }
    }

    // Count number of paths that reached the last row
    var split_count: u64 = 0;
    for (laser_buffer[diagram.coordsToIndex(0, diagram.height - 1)..]) |v| {
        split_count += v;
    }

    return split_count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input.txt");
    defer allocator.free(contents);

    // Parse
    var diagram_part1 = try parsing.Diagram.init(allocator, contents);
    var diagram_part2 = try diagram_part1.clone(allocator);
    defer diagram_part1.deinit(allocator);
    defer diagram_part2.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&diagram_part1)});
    std.debug.print("[Part 2] Solution={}\n", .{try part2(allocator, &diagram_part2)});
}
