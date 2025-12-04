const std = @import("std");
const parsing = @import("parsing.zig");

fn countAdjacent(iterator: *const parsing.Diagram.RollsIterator) u64 {
    var sum: u64 = 0;
    var i: i32 = -1;
    while (i <= 1) : (i += 1) {
        var j: i32 = -1;
        while (j <= 1) : (j += 1) {
            if (i == 0 and j == 0) continue;

            const x = iterator.x + i;
            const y = iterator.y + j;
            sum += @intCast(@intFromBool(iterator.diagram.hasRolls(x, y)));
        }
    }

    return sum;
}

fn part1(diagram: *const parsing.Diagram) u64 {
    var sum: u64 = 0;

    var rolls_iterator = diagram.iterator();
    while (rolls_iterator.next()) {
        if (countAdjacent(&rolls_iterator) < 4) {
            sum += 1;
        }
    }

    return sum;
}

fn part2(allocator: std.mem.Allocator, diagram: *parsing.Diagram) !u64 {
    var working_buffer = try allocator.alloc(u8, diagram.data.len);
    defer allocator.free(working_buffer);
    @memcpy(working_buffer, diagram.data);

    var sum: u64 = 0;

    while (true) {
        var local_sum: u64 = 0;
        var rolls_iterator = diagram.iterator();
        while (rolls_iterator.next()) {
            if (countAdjacent(&rolls_iterator) < 4) {
                local_sum += 1;
                working_buffer[rolls_iterator.getIndex()] = parsing.Diagram.empty;
            }
        }

        if (local_sum == 0) break;
        sum += local_sum;
        @memcpy(diagram.data, working_buffer); // Update diagram buffer
    }

    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input.txt");
    defer allocator.free(contents);

    // Parse
    var diagram = try parsing.Diagram.init(allocator, contents);
    defer diagram.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&diagram)});
    std.debug.print("[Part 2] Solution={}\n", .{try part2(allocator, &diagram)});
}
