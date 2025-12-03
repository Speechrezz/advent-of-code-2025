const std = @import("std");
const parsing = @import("parsing.zig");

fn findLargest(bank: []const u8) struct { index: usize, digit: u8 } {
    var index: usize = 0;
    var largest: u8 = 0;
    for (bank, 0..) |char, i| {
        if (char > largest) {
            index = i;
            largest = char;
        }
    }

    return .{ .index = index, .digit = largest - '0' };
}

fn part1(contents: []const u8) u32 {
    var sum: u32 = 0;

    var bank_iterator = parsing.BankIterator.init(contents);
    while (bank_iterator.next()) |bank| {
        const first = findLargest(bank[0 .. bank.len - 1]);
        const second = findLargest(bank[first.index + 1 ..]);

        const joltage = @as(u32, @intCast(first.digit)) * 10 + @as(u32, @intCast(second.digit));
        sum += joltage;
    }

    return sum;
}

fn part2(contents: []const u8) u64 {
    var sum: u64 = 0;
    const batteries_per_bank = 12;

    var bank_iterator = parsing.BankIterator.init(contents);
    while (bank_iterator.next()) |bank| {
        var joltage: u64 = 0;
        var start_index: usize = 0;

        var batteries_remaining: usize = batteries_per_bank;
        while (batteries_remaining > 0) {
            defer batteries_remaining -= 1;

            const largest = findLargest(bank[start_index .. bank.len - batteries_remaining + 1]);
            start_index += largest.index + 1;

            joltage *= 10;
            joltage += @intCast(largest.digit);
        }

        sum += joltage;
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

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(contents)});
    std.debug.print("[Part 2] Solution={}\n", .{part2(contents)});
}
