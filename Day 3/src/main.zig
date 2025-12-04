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

fn calculateJoltage(contents: []const u8, batteries_per_bank: usize) u64 {
    var sum: u64 = 0;

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
    std.debug.print("[Part 1] Solution={}\n", .{calculateJoltage(contents, 2)});
    std.debug.print("[Part 2] Solution={}\n", .{calculateJoltage(contents, 12)});
}
