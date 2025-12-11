const std = @import("std");
const parsing = @import("parsing.zig");

const Machine = parsing.Machine;
const BitVector = parsing.BitVector;
const Joltage = parsing.Joltage;

pub fn search(allocator: std.mem.Allocator, factory: *parsing.Factory) !u64 {
    var sum: u64 = 0;

    const zeros: parsing.Joltage = [_]u32{0} ** 16;

    for (factory.machine_list.items) |*machine| {
        var priority_joltages = try getJoltageIndicesByPriority(allocator, machine);
        defer priority_joltages.deinit(allocator);

        var priority_buttons = try getButtonIndicesByPriority(allocator, machine, priority_joltages.items);
        defer deinitButtonPriorityList(allocator, &priority_buttons);

        std.debug.print("joltage={any}, button={any}\n", .{ priority_joltages.items, priority_buttons.items });

        var best_count: u64 = std.math.maxInt(u64);
        const context: DfsContext = .{
            .machine = machine,
            .best_count = &best_count,
            .button_index = null,
            .joltage = zeros,
            .priority_joltages = priority_joltages.items,
            .priority_buttons = priority_buttons,
        };

        dfsStep(context);
        std.debug.print("best_count={}\n", .{context.best_count.*});
        sum += context.best_count.*;
    }

    return sum;
}

const DfsContext = struct {
    machine: *Machine,
    best_count: *u64,
    button_index: ?usize,
    joltage: Joltage,
    priority_level: usize = 0,
    priority_joltages: []const usize,
    priority_buttons: ButtonPriorityList,
    count: u64 = 0,

    pub fn getPriorityJoltage(self: *const @This()) usize {
        return self.priority_joltages[self.priority_level];
    }

    pub fn getButtonGroup(self: *const @This()) []const usize {
        return self.priority_buttons.items[self.priority_level].items;
    }

    pub fn isCurrentPriorityFulfilled(self: *const @This(), joltage: Joltage) bool {
        const priority_joltage = self.getPriorityJoltage();
        return joltage[priority_joltage] == self.machine.joltage[priority_joltage];
    }

    pub fn nextPriorityLevel(self: *@This()) bool {
        self.priority_level += 1;
        while (self.priority_level < self.priority_buttons.items.len) : (self.priority_level += 1) {
            if (self.getButtonGroup().len > 0) return true;
        }
        return false;
    }
};

fn dfsStep(input_context: DfsContext) void {
    var context = input_context;

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
            std.debug.print("is_equal={}\n", .{context.count});
            context.best_count.* = context.count;
            return;
        }

        if (context.count >= context.best_count.*) return;
    }

    if (context.isCurrentPriorityFulfilled(joltage)) {
        if (!context.nextPriorityLevel()) return; // No more priority levels
        //std.debug.print("count={}, nextPriority={}, button_group={any}, joltage={any}\n", .{ context.count, context.priority_level, context.getButtonGroup(), joltage });
        min_button_index = 0;
    }

    const button_group = context.getButtonGroup();

    for (button_group) |button_index| {
        //std.debug.print("button_index={}, min_button_index={}, button_group={any}\n", .{ button_index, min_button_index, button_group });
        if (!(button_index >= min_button_index)) continue;

        var new_context = context;

        new_context.button_index = button_index;
        new_context.joltage = joltage;
        new_context.count += 1;

        dfsStep(new_context);
    }
}

pub fn getJoltageIndicesByPriority(allocator: std.mem.Allocator, machine: *parsing.Machine) !std.ArrayList(usize) {
    var priority_indices = try std.ArrayList(usize).initCapacity(allocator, machine.num_lights);

    // Add all button wirings together
    var sum: parsing.Joltage = [_]u32{0} ** 16;

    for (machine.button_wiring.items) |button| {
        parsing.addButtonToJoltage(machine.num_lights, button, &sum);
    }

    // Sort joltage indices by priority.
    // We prioritize joltage indices which are associated with the fewest buttons

    while (priority_indices.items.len < machine.num_lights) {
        var best_index: usize = 0;
        var smallest_sum: u32 = std.math.maxInt(u32);
        var largest_joltage: u32 = 0;
        for (0..machine.num_lights) |i| {
            if (sum[i] < smallest_sum) {
                best_index = i;
                smallest_sum = sum[i];
                largest_joltage = machine.joltage[i];
            } else if (sum[i] == smallest_sum and machine.joltage[i] > largest_joltage) {
                best_index = i;
                largest_joltage = machine.joltage[i];
            }
        }

        sum[best_index] = std.math.maxInt(u32);
        priority_indices.appendAssumeCapacity(best_index);
    }

    return priority_indices;
}

const ButtonPriorityList = std.ArrayList(std.ArrayList(usize));
pub fn deinitButtonPriorityList(allocator: std.mem.Allocator, list: *ButtonPriorityList) void {
    for (list.items) |*group| {
        group.deinit(allocator);
    }
    list.deinit(allocator);
}

pub fn getButtonIndicesByPriority(
    allocator: std.mem.Allocator,
    machine: *parsing.Machine,
    joltage_priorities: []const usize,
) !ButtonPriorityList {
    // All button indices
    var remaining_buttons: std.ArrayList(usize) = .empty;
    defer remaining_buttons.deinit(allocator);
    try remaining_buttons.resize(allocator, machine.button_wiring.items.len);

    for (remaining_buttons.items, 0..) |*index, i| {
        index.* = i;
    }

    var button_priorities: ButtonPriorityList = .empty;

    for (joltage_priorities) |joltage_index| {
        var button_group: std.ArrayList(usize) = .empty;

        for (remaining_buttons.items) |button_index| {
            const button = machine.button_wiring.items[button_index];
            if (button.readBit(@intCast(joltage_index))) {
                try button_group.append(allocator, button_index);
            }
        }

        for (button_group.items) |button_index| {
            const index_to_remove = std.mem.indexOfScalar(usize, remaining_buttons.items, button_index).?;
            _ = remaining_buttons.swapRemove(index_to_remove);
        }

        try button_priorities.append(allocator, button_group);
        if (remaining_buttons.items.len == 0) break;
    }

    std.debug.assert(remaining_buttons.items.len == 0);

    return button_priorities;
}
