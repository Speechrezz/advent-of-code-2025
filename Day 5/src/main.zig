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

fn part2(allocator: std.mem.Allocator, database: *parsing.Database) !u64 {
    // Merge overlapping or touching ranges
    var merged_list: parsing.RangeList = .empty;
    defer merged_list.deinit(allocator);

    // Sorting by `Range.min` makes this easier
    std.sort.block(parsing.Range, database.range_list.items, {}, comptime parsing.Range.sortAsc());
    try merged_list.append(allocator, database.range_list.items[0]);

    for (database.range_list.items[1..]) |range| {
        const merged = &merged_list.items[merged_list.items.len - 1];

        if (merged.merge(&range)) |new_merged| { // Is overlapping
            merged.* = new_merged;
        } else { // NOT overlapping
            try merged_list.append(allocator, range);
        }
    }

    // Sum the lengths of the merged ranges
    var sum: u64 = 0;
    for (merged_list.items) |range| {
        sum += range.length();
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
    std.debug.print("[Part 2] Solution={}\n", .{try part2(allocator, &database)});
}
