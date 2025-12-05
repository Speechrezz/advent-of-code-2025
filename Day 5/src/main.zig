const std = @import("std");
const parsing = @import("parsing.zig");

fn part1(database: *parsing.Database) u64 {
    var sum: u64 = 0;

    for (database.id_list.items) |id| {
        for (database.range_list.items) |range| {
            if (range.isInRange(id)) {
                sum += 1;
                break;
            }
        }
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
    var database = try parsing.parseDatabase(allocator, contents);
    defer database.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&database)});
    //std.debug.print("[Part 2] Solution={}\n", .{try part2(allocator, &diagram)});
}
