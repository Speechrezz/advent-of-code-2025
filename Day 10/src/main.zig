const std = @import("std");
const parsing = @import("parsing.zig");
const bfs = @import("bfs.zig");

const Queue = bfs.Queue;

fn part1(factory: *parsing.Factory) u64 {
    var sum: u64 = 0;

    for (factory.machine_list.items) |machine| {
        const n: u4 = @intCast(machine.button_wiring.items.len);
        const total_subsets: parsing.BitVector = .{ .bits = @as(u16, 1) << n };

        var best_count: u16 = std.math.maxInt(u16);
        var subset: parsing.BitVector = .{};

        // Brute force search through every combo of buttons
        while (subset.bits < total_subsets.bits) : (subset.bits += 1) {
            const count = subset.bitCount();
            if (count >= best_count) continue;

            var lights: parsing.Lights = .{};

            for (machine.button_wiring.items, 0..) |button, i| {
                if (subset.readBit(@intCast(i))) {
                    lights.bits ^= button.bits;
                }
            }

            if (lights.eql(machine.lights)) {
                best_count = @min(best_count, count);
            }
        }

        sum += best_count;
    }

    return sum;
}

const DfsContext = struct {
    machine: *parsing.Machine,
    best_count: *u64,
    button: parsing.BitVector,
    joltage: parsing.Joltage,
    count: u64 = 0,
};

fn dfsStep(context: DfsContext) void {
    var joltage = context.joltage;

    var is_equal = true;
    for (0..context.machine.num_lights) |i| {
        joltage[i] += @intCast(@intFromBool(context.button.readBit(@intCast(i))));

        if (joltage[i] > context.machine.joltage[i]) return; // Too much joltage
        is_equal &= joltage[i] == context.machine.joltage[i];
    }

    if (is_equal) {
        context.best_count.* = context.count;
        return;
    }

    if (context.count >= context.best_count.*) return;

    for (context.machine.button_wiring.items) |next_button| {
        var new_context = context;

        new_context.button = next_button;
        new_context.joltage = joltage;
        new_context.count += 1;

        dfsStep(new_context);
    }
}

fn part2(factory: *parsing.Factory) u64 {
    var sum: u64 = 0;

    const joltage: parsing.Joltage = [_]u32{0} ** 16;

    for (factory.machine_list.items) |*machine| {
        var best_count: u64 = std.math.maxInt(u64);
        const context: DfsContext = .{
            .machine = machine,
            .best_count = &best_count,
            .button = parsing.BitVector{},
            .joltage = joltage,
        };

        dfsStep(context);
        std.debug.print("best_count={}\n", .{context.best_count.*});
        sum += context.best_count.*;
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
    var factory = try parsing.Factory.init(allocator, contents);
    defer factory.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&factory)});
    std.debug.print("[Part 2] Solution={}\n", .{part2(&factory)});
}
