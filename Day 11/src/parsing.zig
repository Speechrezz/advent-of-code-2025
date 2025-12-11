const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const CountsPart2 = struct {
    paths: u64 = 0,
    valid: u64 = 0,
    dac: u64 = 0,
    fft: u64 = 0,

    pub fn addFrom(self: *@This(), other: @This()) void {
        self.paths += other.paths;
        self.valid += other.valid;
        self.dac += other.dac;
        self.fft += other.fft;
    }
};

pub const Node = struct {
    name: [3]u8 = undefined,
    outputs: std.ArrayList(?*Node) = .empty,
    counts: ?CountsPart2 = null,

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.outputs.deinit(allocator);
    }

    pub fn nameEql(self: @This(), name: []const u8) bool {
        return std.mem.eql(u8, &self.name, name);
    }
};

pub const Graph = struct {
    nodes: std.ArrayList(Node) = .empty,

    pub fn init() @This() {
        return .{};
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        for (self.nodes.items) |*node| {
            node.deinit(allocator);
        }
        self.nodes.deinit(allocator);
    }

    pub fn build(self: *@This(), allocator: std.mem.Allocator, contents: []const u8) !void {
        const trimmed = std.mem.trimEnd(u8, contents, " \n\r");
        var line_iter = std.mem.tokenizeAny(u8, trimmed, "\n\r");

        // Initialize node list
        while (line_iter.next()) |line| {
            const name = line[0..3];
            try self.nodes.append(allocator, .{ .name = name.* });
        }

        // Update each node's outputs
        var i: usize = 0;
        line_iter.reset();
        while (line_iter.next()) |line| {
            defer i += 1;
            const current_node = &self.nodes.items[i];

            const first_space_index = std.mem.indexOfScalar(u8, line, ' ').?;
            const outputs_text = line[first_space_index + 1 ..];

            var space_iter = std.mem.splitScalar(u8, outputs_text, ' ');
            while (space_iter.next()) |output_name| {
                try current_node.outputs.append(allocator, self.findNode(output_name));
            }
        }
    }

    pub fn buildInverse(self: *@This(), allocator: std.mem.Allocator, contents: []const u8) !void {
        const trimmed = std.mem.trimEnd(u8, contents, " \n\r");
        var line_iter = std.mem.tokenizeAny(u8, trimmed, "\n\r");

        // Initialize node list
        while (line_iter.next()) |line| {
            const name = line[0..3];
            try self.nodes.append(allocator, .{ .name = name.* });
        }

        try self.nodes.append(allocator, .{ .name = "out".* });

        // Update each node's outputs
        var i: usize = 0;
        line_iter.reset();
        while (line_iter.next()) |line| {
            defer i += 1;
            const next_node = &self.nodes.items[i];
            const next_node_optional = if (next_node.nameEql("svr")) null else next_node;

            const first_space_index = std.mem.indexOfScalar(u8, line, ' ').?;
            const outputs_text = line[first_space_index + 1 ..];

            var space_iter = std.mem.splitScalar(u8, outputs_text, ' ');
            while (space_iter.next()) |input_name| {
                const current_node = self.findNode(input_name).?;
                try current_node.outputs.append(allocator, next_node_optional);
            }
        }
    }

    pub fn findNode(self: *const @This(), name: []const u8) ?*Node {
        for (self.nodes.items) |*node| {
            if (node.nameEql(name)) {
                return node;
            }
        }

        return null;
    }
};
