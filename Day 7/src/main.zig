const std = @import("std");
const parsing = @import("parsing.zig");

fn hasLaserAbove(diagram: *parsing.Diagram, x: usize, y: usize) u64 {
    const current = diagram.atCoords(x, y);
    if (current.* == parsing.Diagram.laser or current.* == parsing.Diagram.empty) {
        current.* = parsing.Diagram.laser;
        return 0;
    }
    // Is splitter
    diagram.atCoords(x - 1, y).* = parsing.Diagram.laser;
    diagram.atCoords(x + 1, y).* = parsing.Diagram.laser;
    return 1;
}

fn part1(diagram: *parsing.Diagram) u64 {
    var split_count: u64 = 0;
    var y: usize = 1;

    while (y < diagram.height) {
        defer y += 1;

        for (0..diagram.width) |x| {
            const above = diagram.atCoords(x, y - 1).*;

            if (above == parsing.Diagram.start or above == parsing.Diagram.laser) {
                split_count += hasLaserAbove(diagram, x, y);
            }
        }

        std.debug.print("[{}]\t\'{s}\' - count={}\n", .{ y, diagram.getLine(y), split_count });
    }

    return split_count;
}

fn part2(diagram: *parsing.Diagram) u64 {
    var split_count: u64 = 0;
    var y: usize = 1;

    while (y < diagram.height) {
        defer y += 1;

        for (0..diagram.width) |x| {
            const above = diagram.atCoords(x, y - 1).*;

            if (above == parsing.Diagram.start or above == parsing.Diagram.laser) {
                split_count += hasLaserAbove(diagram, x, y);
            }
        }

        std.debug.print("[{}]\t\'{s}\' - count={}\n", .{ y, diagram.getLine(y), split_count });
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
    std.debug.print("[Part 2] Solution={}\n", .{part2(&diagram_part2)});
}
