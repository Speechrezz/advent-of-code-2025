const std = @import("std");
const parsing = @import("parsing.zig");

fn isInvalidPart1(value: u64) u64 {
    var buf: [64]u8 = undefined;

    const str = std.fmt.bufPrint(&buf, "{}", .{value}) catch unreachable;

    if (@mod(str.len, 2) == 1) {
        return 0;
    }

    const slice_len: usize = @divTrunc(str.len, 2);
    const slice1 = str[0..slice_len];
    const slice2 = str[slice_len..];

    return value * @as(u64, @intCast(@intFromBool(std.mem.eql(u8, slice1, slice2))));
}

fn part1(range_list: *parsing.RangeList) u64 {
    var sum: u64 = 0;

    for (range_list.items) |range| {
        var value = range.start;
        while (value <= range.end) {
            sum += isInvalidPart1(value);
            value += 1;
        }
    }

    return sum;
}

fn isInvalidPart2(value: u64) u64 {
    var buf: [64]u8 = undefined;

    const str = std.fmt.bufPrint(&buf, "{}", .{value}) catch unreachable;

    const max_slice_len: usize = @divTrunc(str.len, 2);
    var slice_len: usize = 1;
    while (slice_len <= max_slice_len) {
        defer slice_len += 1;

        if (@mod(str.len, slice_len) != 0) continue;

        const first_slice = str[0..slice_len];

        var i = slice_len;

        while (i < str.len) {
            defer i += slice_len;

            const slice = str[i..(i + slice_len)];

            if (!std.mem.eql(u8, slice, first_slice))
                break;
        } else {
            return value;
        }
    }

    return 0;
}

fn part2(range_list: *parsing.RangeList) u64 {
    var sum: u64 = 0;

    for (range_list.items) |range| {
        var value = range.start;
        while (value <= range.end) {
            sum += isInvalidPart2(value);
            value += 1;
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
    var range_list = try parsing.parse(allocator, contents);
    defer range_list.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&range_list)});
    std.debug.print("[Part 2] Solution={}\n", .{part2(&range_list)});
}
