const std = @import("std");
const parsing = @import("parsing.zig");

const Machine = parsing.Machine;
const BitVector = parsing.BitVector;
const Joltage = parsing.Joltage;

pub fn search(factory: *parsing.Factory) u64 {
    var sum: u64 = 0;

    const zeros: parsing.Joltage = [_]u32{0} ** 16;

    for (factory.machine_list.items, 0..) |*machine, i| {
        var best_count: u64 = std.math.maxInt(u64);
        const context: DfsContext = .{
            .machine = machine,
            .best_count = &best_count,
            .button_index = null,
            .joltage = zeros,
        };

        dfsStep(context);
        std.debug.print("[{}/{}] best_count={}\n", .{ i + 1, factory.machine_list.items.len, context.best_count.* });
        sum += context.best_count.*;
    }

    return sum;
}

const DfsContext = struct {
    machine: *Machine,
    best_count: *u64,
    button_index: ?usize,
    joltage: Joltage,
    count: u64 = 0,
};

fn dfsStep(context: DfsContext) void {
    // Update Joltage

    var joltage = context.joltage;
    var min_button_index: usize = 0;

    if (context.button_index) |button_index| {
        min_button_index = button_index;
        const button = context.machine.button_wiring.items[button_index];

        var is_equal = true;
        for (0..context.machine.num_lights) |i| {
            joltage[i] += @intCast(@intFromBool(button.readBit(@intCast(i))));

            if (joltage[i] > context.machine.joltage[i]) return; // Too much joltage
            is_equal &= joltage[i] == context.machine.joltage[i];
        }

        if (is_equal) {
            //std.debug.print("is_equal={}\n", .{context.count});
            context.best_count.* = context.count;
            return;
        }

        if (context.count >= context.best_count.*) return;
    }

    for (0..context.machine.button_wiring.items.len) |button_index| {
        //std.debug.print("button_index={}, min_button_index={}, button_group={any}\n", .{ button_index, min_button_index, button_group });
        if (!(button_index >= min_button_index)) continue;

        var new_context = context;

        new_context.button_index = button_index;
        new_context.joltage = joltage;
        new_context.count += 1;

        dfsStep(new_context);
    }
}
