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

    const trimmed = std.mem.trimEnd(u8, contents, "\n\r");
    const line_length = std.mem.indexOfAny(u8, trimmed, "\r\n") orelse unreachable;

    var index: usize = 0;

    while (index < line_length) {

        // Find column length

        var column_length: usize = 0;
        var line_iterator = std.mem.tokenizeAny(u8, trimmed, "\n\r");
        while (line_iterator.next()) |full_line| {
            const line = full_line[index..];
            const current_length = std.mem.indexOfScalar(u8, line, ' ') orelse line.len;
            column_length = @max(column_length, current_length);
        }

        // Populate column data

        var column = try column_list.addOne(allocator);
        column.numbers = .empty;

        line_iterator.reset();
        while (line_iterator.next()) |full_line| {
            const token = full_line[index .. index + column_length];
            const token_trimmed = std.mem.trim(u8, token, " ");

            if (line_iterator.peek() != null) {
                try column.numbers.append(allocator, .{
                    .slice = token,
                    .value = try std.fmt.parseUnsigned(u64, token_trimmed, 10),
                });
            } else {
                column.operation = switch (token[0]) {
                    '+' => MathOperation.add,
                    '*' => MathOperation.mul,
                    else => unreachable,
                };
            }
        }

        index += column_length + 1;
    }

    return column_list;
}
