const std = @import("std");
const parsing = @import("parsing.zig");

const dial_limit = 100;

fn part1(turn_list: *const parsing.TurnList) usize {
    var dial_position: i32 = 50;
    var result: u32 = 0;

    for (turn_list.items) |turn| {
        const turn_amount = switch (turn) {
            .left => |amount| -amount,
            .right => |amount| amount,
        };

        dial_position = @mod(dial_position + turn_amount, dial_limit);
        result += @intCast(@intFromBool(dial_position == 0));
    }

    return result;
}

fn part2Old(turn_list: *const parsing.TurnList) usize {
    var dial_position: i32 = 50;
    var result: u32 = 0;
    var increment: i32 = undefined;

    for (turn_list.items) |turn| {
        const turn_amount = switch (turn) {
            .left => |amount| blk: {
                increment = -1;
                break :blk -amount;
            },
            .right => |amount| blk: {
                increment = 1;
                break :blk amount;
            },
        };

        var i: i32 = 0;
        while (i != turn_amount) {
            defer i += increment;
            dial_position = @mod(dial_position + increment, dial_limit);
            result += @intCast(@intFromBool(dial_position == 0));
        }
    }

    return result;
}

fn part2(turn_list: *const parsing.TurnList) usize {
    var dial_position: i32 = 50;
    var result: u32 = 0;

    for (turn_list.items) |turn| {
        const turn_amount = switch (turn) {
            .left => |amount| -amount,
            .right => |amount| amount,
        };

        const was_zero = dial_position == 0;

        const offset_position = turn_amount + dial_position;
        result += @abs(offset_position) / dial_limit;

        dial_position = @mod(offset_position, dial_limit);
        result += @intCast(@intFromBool(offset_position <= 0 and !was_zero));
    }

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the file
    const contents = try parsing.readFile(allocator, "input.txt");
    defer allocator.free(contents);

    // Parse
    var turn_list = try parsing.parse(allocator, contents);
    defer turn_list.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&turn_list)});
    std.debug.print("[Part 2] Solution={}\n", .{part2(&turn_list)});
}
