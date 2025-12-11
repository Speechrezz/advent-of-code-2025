const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const BitVector = struct {
    bits: u16 = 0,

    pub fn bitCount(self: @This()) u16 {
        return @intCast(@popCount(self.bits));
    }

    pub fn enableBit(self: *@This(), i: u4) void {
        self.bits |= (@as(u16, 1) << i);
    }

    pub fn readBit(self: @This(), i: u4) bool {
        return (self.bits & (@as(u16, 1) << i)) != 0;
    }

    pub fn eql(self: @This(), other: @This()) bool {
        return self.bits == other.bits;
    }

    pub fn xor(self: @This(), other: @This()) @This() {
        return .{ .bits = self.bits ^ other.bits };
    }
};

pub const Lights = BitVector;
pub const ButtonWiring = std.ArrayList(BitVector);
pub const Joltage = [16]u32;

pub const Machine = struct {
    num_lights: usize = 0,
    lights: Lights = .{},
    button_wiring: ButtonWiring = .empty,
    joltage: Joltage = [_]u32{0} ** 16,

    pub fn init(allocator: std.mem.Allocator, line: []const u8) !@This() {
        var machine: Machine = .{};
        var space_iter = std.mem.splitScalar(u8, line, ' ');

        machine.parseLights(space_iter.first());

        while (space_iter.next()) |slice| {
            switch (slice[0]) {
                '(' => try machine.parseButtonWiring(allocator, slice),
                '{' => try machine.parseJoltage(slice),
                else => unreachable,
            }
        }

        return machine;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.button_wiring.deinit(allocator);
    }

    fn parseLights(self: *@This(), slice: []const u8) void {
        var i: u4 = 0;
        for (slice[1 .. slice.len - 1]) |char| {
            defer i += 1;
            if (char == '#') self.lights.enableBit(i);
        }

        self.num_lights = slice.len - 2;
    }

    fn parseButtonWiring(self: *@This(), allocator: std.mem.Allocator, slice: []const u8) !void {
        var button: BitVector = .{};

        var comma_iter = std.mem.splitScalar(u8, slice[1 .. slice.len - 1], ',');
        while (comma_iter.next()) |token| {
            const i = try std.fmt.parseUnsigned(u4, token, 10);
            button.enableBit(i);
        }

        try self.button_wiring.append(allocator, button);
    }

    fn parseJoltage(self: *@This(), slice: []const u8) !void {
        var comma_iter = std.mem.splitScalar(u8, slice[1 .. slice.len - 1], ',');
        var i: usize = 0;
        while (comma_iter.next()) |token| {
            defer i += 1;
            self.joltage[i] = try std.fmt.parseUnsigned(u32, token, 10);
        }
    }
};

pub const MachineList = std.ArrayList(Machine);

pub const Factory = struct {
    machine_list: MachineList = .empty,

    pub fn init(allocator: std.mem.Allocator, contents: []const u8) !@This() {
        var factory: Factory = .{};

        const trimmed = std.mem.trimEnd(u8, contents, " \n\r");
        var line_iter = std.mem.tokenizeAny(u8, trimmed, "\n\r");

        while (line_iter.next()) |line| {
            try factory.machine_list.append(allocator, try Machine.init(allocator, line));
        }

        return factory;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        for (self.machine_list.items) |*machine| {
            machine.deinit(allocator);
        }

        self.machine_list.deinit(allocator);
    }
};
