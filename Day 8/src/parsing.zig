const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub fn ncast(comptime T: type, value: anytype) T {
    const in_type = @typeInfo(@TypeOf(value));
    const out_type = @typeInfo(T);

    if (in_type == .int and out_type == .float) {
        return @floatFromInt(value);
    }
    if (in_type == .float and out_type == .int) {
        return @intFromFloat(value);
    }
    if (in_type == .int and out_type == .int) {
        return @intCast(value);
    }
    if (in_type == .float and out_type == .float) {
        return @floatCast(value);
    }
    @compileError("unexpected in_type '" ++ @typeName(@TypeOf(value)) ++ "' and out_type '" ++ @typeName(T) ++ "'");
}

fn square(x: anytype) @TypeOf(x) {
    return x * x;
}

pub const Position = struct {
    x: u32,
    y: u32,
    z: u32,
};

pub const Node = struct {
    position: Position,
};

pub const Connection = struct {
    node1: *Node,
    node2: *Node,
    distance: u64 = 0,

    pub fn computeDistance(self: *@This()) void {
        const x_distance = square(ncast(i64, self.node1.position.x) - ncast(i64, self.node2.position.x));
        const y_distance = square(ncast(i64, self.node1.position.y) - ncast(i64, self.node2.position.y));
        const z_distance = square(ncast(i64, self.node1.position.z) - ncast(i64, self.node2.position.z));

        // We only care about relative distances, don't need to sqrt
        //self.distance = @sqrt(x_distance + y_distance + z_distance);
        self.distance = ncast(u64, x_distance + y_distance + z_distance);
    }

    pub fn hasCommon(self: @This(), other: @This()) bool {
        return self.node1 == other.node1 or self.node1 == other.node2 or self.node2 == other.node1 or self.node2 == other.node2;
    }

    pub fn asc(_: void, a: Connection, b: Connection) bool {
        return a.distance < b.distance;
    }
};

fn appendIfNotThere(allocator: std.mem.Allocator, list: *std.ArrayList(*Node), node: *Node) !void {
    if (std.mem.indexOfScalar(*Node, list.items, node) == null) {
        try list.append(allocator, node);
    }
}

pub const Group = struct {
    connections: std.ArrayList(Connection) = .empty,
    node_count: u64 = 0,

    pub fn countNodes(self: *@This(), allocator: std.mem.Allocator) !void {
        var node_list: std.ArrayList(*Node) = .empty;
        defer node_list.deinit(allocator);

        for (self.connections.items) |connection| {
            try appendIfNotThere(allocator, &node_list, connection.node1);
            try appendIfNotThere(allocator, &node_list, connection.node2);
        }

        self.node_count = node_list.items.len;
    }
};
pub const GroupList = std.ArrayList(Group);

pub fn groupLenDesc(_: void, a: Group, b: Group) bool {
    return a.node_count > b.node_count;
}

pub const Graph = struct {
    node_list: std.ArrayList(Node) = .empty,
    connection_list: std.ArrayList(Connection) = .empty,
    group_list: GroupList = .empty,

    pub fn init(allocator: std.mem.Allocator, contents: []const u8) !@This() {
        var graph: @This() = .{};

        const trimmed = std.mem.trimEnd(u8, contents, " \r\n");
        var line_iterator = std.mem.tokenizeAny(u8, trimmed, "\r\n");

        while (line_iterator.next()) |line| {
            const position = textToPosition(line) orelse unreachable;
            try graph.node_list.append(allocator, .{ .position = position });
        }

        return graph;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.connection_list.deinit(allocator);
        self.node_list.deinit(allocator);

        for (self.group_list.items) |*group| {
            group.connections.deinit(allocator);
        }

        self.group_list.deinit(allocator);
    }

    fn textToPosition(text: []const u8) ?Position {
        var comma_iterator = std.mem.splitScalar(u8, text, ',');

        return .{
            .x = std.fmt.parseUnsigned(u32, comma_iterator.next() orelse return null, 10) catch return null,
            .y = std.fmt.parseUnsigned(u32, comma_iterator.next() orelse return null, 10) catch return null,
            .z = std.fmt.parseUnsigned(u32, comma_iterator.next() orelse return null, 10) catch return null,
        };
    }

    pub fn generateGroups(self: *@This(), allocator: std.mem.Allocator) !void {
        while (self.connection_list.items.len > 0) {
            var group: Group = .{};
            try group.connections.append(allocator, self.connection_list.pop() orelse unreachable);

            var search_index: usize = 0;
            while (search_index < group.connections.items.len) {
                defer search_index += 1;
                const connection_to_search = group.connections.items[search_index];

                // Search through list backwards
                const connection_len = self.connection_list.items.len;
                for (0..connection_len) |i| {
                    const index = connection_len - i - 1;
                    const connection = self.connection_list.items[index];

                    if (connection_to_search.hasCommon(connection)) {
                        try group.connections.append(allocator, self.connection_list.swapRemove(index));
                    }
                }
            }

            try group.countNodes(allocator);
            try self.group_list.append(allocator, group);
        }
    }

    fn isPartOfGroup(connection: Connection, group: Group) bool {
        for (group.connections.items) |connection_other| {
            if (connection.hasCommon(connection_other)) {
                return true;
            }
        }

        return false;
    }
};
