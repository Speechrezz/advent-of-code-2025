const std = @import("std");
const parsing = @import("parsing.zig");
const dfs = @import("dfs.zig");
const dfs2 = @import("dfs2.zig");

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
    //std.debug.print("[Part 2] Solution={}\n", .{try dfs.search(allocator, &factory)});
    std.debug.print("[Part 2] Solution={}\n", .{dfs2.search(&factory)});
}
