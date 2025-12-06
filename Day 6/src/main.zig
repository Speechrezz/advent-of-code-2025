const std = @import("std");
const parsing = @import("parsing.zig");

fn part1(column_list: *parsing.ColumnList) u64 {
    var sum: u64 = 0;

    for (column_list.items) |column| {
        sum += column.applyMathOperation();
    }

    return sum;
}

fn charToDigit(char: u8) u8 {
    return char - '0';
}

fn part2(column_list: *parsing.ColumnList) u64 {
    var sum: u64 = 0;

    for (column_list.items) |column| {
        var result: u64 = if (column.operation == .add) 0 else 1;
        for (0..column.numbers.items[0].slice.len) |i| {
            var value: u64 = 0;
            for (column.numbers.items) |number| {
                const char = number.slice[i];
                if (!std.ascii.isDigit(char)) continue;

                value *= 10;
                value += @intCast(charToDigit(char));
            }

            switch (column.operation) {
                .add => result += value,
                .mul => result *= value,
            }
        }

        sum += result;
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
    var column_list = try parsing.parseColumns(allocator, contents);
    defer parsing.deinitColumnList(allocator, &column_list);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&column_list)});
    std.debug.print("[Part 2] Solution={}\n", .{part2(&column_list)});
}
