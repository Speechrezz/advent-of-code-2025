const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1 << 24);
}

pub const MathOperation = enum { add, mul };

pub const Number = struct {
    slice: []const u8,
    value: u64,
};

pub const NumberList = std.ArrayList(Number);

pub const Column = struct {
    numbers: NumberList,
    operation: MathOperation,

    pub fn applyMathOperation(self: *const @This()) u64 {
        var result: u64 = 0;
        switch (self.operation) {
            .add => {
                for (self.numbers.items) |number| {
                    result += number.value;
                }
            },
            .mul => {
                result = 1;
                for (self.numbers.items) |number| {
                    result *= number.value;
                }
            },
        }

        return result;
    }
};

pub const ColumnList = std.ArrayList(Column);

pub fn deinitColumnList(allocator: std.mem.Allocator, list: *ColumnList) void {
    for (list.items) |*column| {
        column.numbers.deinit(allocator);
    }
    list.deinit(allocator);
}

pub fn parseColumns(allocator: std.mem.Allocator, contents: []const u8) !ColumnList {
    var column_list: ColumnList = .empty;

    const trimmed = std.mem.trimEnd(u8, contents, " \n\r");

    var line_iterator = std.mem.splitScalar(u8, trimmed, '\n');
    const first_line = std.mem.trimEnd(u8, line_iterator.first(), " \n\r");
    var first_iterator = std.mem.tokenizeScalar(u8, first_line, ' ');

    while (first_iterator.next()) |token| {
        var column: Column = undefined;
        column.numbers = .empty;
        std.debug.print("token1=\'{s}\'\n", .{token});
        try column.numbers.append(allocator, .{
            .slice = token,
            .value = try std.fmt.parseUnsigned(u64, token, 10),
        });

        try column_list.append(allocator, column);
    }

    std.debug.print("len={}\n", .{column_list.items.len});

    while (line_iterator.next()) |full_line| {
        const line = std.mem.trimEnd(u8, full_line, " \n\r");
        var token_iterator = std.mem.tokenizeScalar(u8, line, ' ');

        if (line_iterator.peek() != null) {
            var i: usize = 0;
            while (token_iterator.next()) |token| {
                defer i += 1;

                var numbers = &column_list.items[i].numbers;
                try numbers.append(allocator, .{
                    .slice = token,
                    .value = try std.fmt.parseUnsigned(u64, token, 10),
                });
            }
        } else {
            var i: usize = 0;
            while (token_iterator.next()) |token| {
                defer i += 1;

                switch (token[0]) {
                    '+' => column_list.items[i].operation = .add,
                    '*' => column_list.items[i].operation = .mul,
                    else => {},
                }
            }
        }
    }

    return column_list;
}
