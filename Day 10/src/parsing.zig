const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const Lights = std.ArrayList(bool);
pub const ButtonWiring = std.ArrayList(std.ArrayList(u32));
pub const Joltage = std.ArrayList(u32);

pub const Machine = struct {
    lights: Lights = .empty,
    button_wiring: ButtonWiring = .empty,
    joltage: Joltage = .empty,

    pub fn init(allocator: std.mem.Allocator, line: []const u8) !@This() {
        var machine: Machine = .{};
        var space_iter = std.mem.splitScalar(u8, line, ' ');

        try machine.parseLights(allocator, space_iter.first());

        while (space_iter.next()) |slice| {
            switch (slice[0]) {
                '(' => try machine.parseButtonWiring(allocator, slice),
                '{' => try machine.parseJoltage(allocator, slice),
                else => unreachable,
            }
        }

        return machine;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        for (self.button_wiring.items) |*button| {
            button.deinit(allocator);
        }

        self.lights.deinit(allocator);
        self.button_wiring.deinit(allocator);
        self.joltage.deinit(allocator);
    }

    fn parseLights(self: *@This(), allocator: std.mem.Allocator, slice: []const u8) !void {
        for (slice[1 .. slice.len - 1]) |char| {
            try self.lights.append(allocator, char == '#');
        }
    }

    fn parseButtonWiring(self: *@This(), allocator: std.mem.Allocator, slice: []const u8) !void {
        var button: std.ArrayList(u32) = .empty;

        var comma_iter = std.mem.splitScalar(u8, slice[1 .. slice.len - 1], ',');
        while (comma_iter.next()) |token| {
            try button.append(allocator, try std.fmt.parseUnsigned(u32, token, 10));
        }

        try self.button_wiring.append(allocator, button);
    }

    fn parseJoltage(self: *@This(), allocator: std.mem.Allocator, slice: []const u8) !void {
        var comma_iter = std.mem.splitScalar(u8, slice[1 .. slice.len - 1], ',');
        while (comma_iter.next()) |token| {
            try self.joltage.append(allocator, try std.fmt.parseUnsigned(u32, token, 10));
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
