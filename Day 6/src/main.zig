const std = @import("std");
const parsing = @import("parsing.zig");

fn part1(column_list: *parsing.ColumnList) u64 {
    var sum: u64 = 0;

    for (column_list.items) |column| {
        sum += column.applyMathOperation();
    }

    return sum;
}

fn part2(allocator: std.mem.Allocator, column_list: *parsing.ColumnList) u64 {
    var temp_buffer = try std.ArrayList(u64).initCapacity(allocator, column_list.items[0].numbers.items.len);
    defer temp_buffer.deinit(allocator);
    var work_buffer = temp_buffer.items;

    var sum: u64 = 0;

    for (column_list.items) |column| {
        column
    }

    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input copy.txt");
    defer allocator.free(contents);

    // Parse
    var column_list = try parsing.parseColumns(allocator, contents);
    defer parsing.deinitColumnList(allocator, &column_list);

    for (column_list.items, 0..) |column, i| {
        std.debug.print("[{}] op={}, items={any}\n", .{ i, column.operation, column.numbers.items });
    }

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&column_list)});
    std.debug.print("[Part 2] Solution={}\n", .{part2(allocator, &column_list)});
}
