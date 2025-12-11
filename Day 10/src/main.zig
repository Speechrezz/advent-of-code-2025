const std = @import("std");
const parsing = @import("parsing.zig");

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
    button_index: ?usize,
    joltage: parsing.Joltage,
    use_priority: bool = true,
    priority_joltage_index: usize,
    priority_button_index_list: []usize,
    remaining_button_index_list: []usize,
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
            context.best_count.* = context.count;
            return;
        }

        if (context.count >= context.best_count.*) return;
    }

    // If exhausted the priority buttons, then move onto the remaining buttons
    var use_priority = context.use_priority;
    var button_index_list: []usize = undefined;

    if (joltage[context.priority_joltage_index] == context.machine.joltage[context.priority_joltage_index]) {
        button_index_list = context.remaining_button_index_list;
        if (use_priority) {
            min_button_index = 0;
            use_priority = false;
        }
    } else {
        button_index_list = context.priority_button_index_list;
    }

    for (button_index_list) |button_index| {
        if (!(button_index >= min_button_index)) continue;

        var new_context = context;

        new_context.button_index = button_index;
        new_context.joltage = joltage;
        new_context.count += 1;
        new_context.use_priority = use_priority;

        dfsStep(new_context);
    }
}

fn findPriorityJoltageIndex(machine: *parsing.Machine) usize {
    var sum: parsing.Joltage = [_]u32{0} ** 16;

    for (machine.button_wiring.items) |button| {
        parsing.addButtonToJoltage(machine.num_lights, button, &sum);
    }

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

    return best_index;
}

fn createButtonLists(buffer: []usize, machine: *parsing.Machine, priority_joltage_index: usize) struct {
    std.ArrayList(usize),
    std.ArrayList(usize),
} {
    var priority_list = std.ArrayList(usize).initBuffer(buffer);

    for (machine.button_wiring.items, 0..) |button, i| {
        if (button.readBit(@intCast(priority_joltage_index))) {
            priority_list.appendAssumeCapacity(i);
        }
    }

    var remaining_list = std.ArrayList(usize).initBuffer(buffer[priority_list.items.len..]);
    for (machine.button_wiring.items, 0..) |button, i| {
        if (!button.readBit(@intCast(priority_joltage_index))) {
            remaining_list.appendAssumeCapacity(i);
        }
    }

    return .{ priority_list, remaining_list };
}

fn part2(factory: *parsing.Factory) u64 {
    var sum: u64 = 0;

    const zeros: parsing.Joltage = [_]u32{0} ** 16;

    for (factory.machine_list.items) |*machine| {
        var priority_buffer: [16]usize = undefined;
        const priority_joltage_index = findPriorityJoltageIndex(machine);
        const priority_list, const remaining_list = createButtonLists(
            &priority_buffer,
            machine,
            priority_joltage_index,
        );

        var best_count: u64 = std.math.maxInt(u64);
        const context: DfsContext = .{
            .machine = machine,
            .best_count = &best_count,
            .button_index = null,
            .priority_joltage_index = priority_joltage_index,
            .priority_button_index_list = priority_list.items,
            .remaining_button_index_list = remaining_list.items,
            .joltage = zeros,
        };

        dfsStep(context);
        std.debug.print("best_count={}, priority_joltage_index={}, priority={any}, remaining={any}\n", .{
            context.best_count.*,
            priority_joltage_index,
            priority_list.items,
            remaining_list.items,
        });
        sum += context.best_count.*;
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
    var factory = try parsing.Factory.init(allocator, contents);
    defer factory.deinit(allocator);

    // Solve
    std.debug.print("[Part 1] Solution={}\n", .{part1(&factory)});
    std.debug.print("[Part 2] Solution={}\n", .{part2(&factory)});
}
