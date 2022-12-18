const std = @import("std");

//day 1
//const ROUND_COUNT = 20;
//const WORRY_DECREASE_FACTOR = 3;

//day 2
const ROUND_COUNT = 10000;
const WORRY_DECREASE_FACTOR = 1;

const BUF_SIZE = 1024;

const Op = enum {
    mul,
    add,
};

const Value = union(enum) {
    int: u64,
    old,

    pub fn get(self: Value, old: u64) u64 {
        return switch (self) {
            .int => |int_val| int_val,
            .old => old,
        };
    }
};

const Expr = struct {
    op: Op,
    left: Value,
    right: Value,

    pub fn evaluate(self: Expr, old: u64) u64 {
        return switch (self.op) {
            Op.mul => self.left.get(old) * self.right.get(old),
            Op.add => self.left.get(old) + self.right.get(old),
        };
    }
};

const Monkey = struct {
    id: u8,
    items: std.ArrayList(u64),
    operation: Expr,
    divisible_test: u64,
    true_monkey: u8,
    false_monkey: u8,

    inspect_count: u64,

    pub fn init(allocator: std.mem.Allocator, reader: anytype) !?Monkey {
        var ret = Monkey{
            .id = undefined,
            .items = std.ArrayList(u64).init(allocator),
            .operation = undefined,
            .divisible_test = undefined,
            .true_monkey = undefined,
            .false_monkey = undefined,
            .inspect_count = 0,
        };
        var buf: [BUF_SIZE]u8 = undefined;

        // parse id
        var line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
        const id = try std.fmt.parseInt(u8, line[7..8], 10);
        ret.id = id;

        // parse starting items
        line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
        line = line[18..];
        var tokenizer = std.mem.tokenize(u8, line, ", ");
        while (tokenizer.next()) |item| {
            try ret.items.append(try std.fmt.parseInt(u64, item, 10));
        }

        //parse operation
        line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
        line = line[19..];
        tokenizer = std.mem.tokenize(u8, line, " ");
        var left = std.fmt.parseInt(u64, tokenizer.next() orelse unreachable, 10) catch null;
        var left_v: Value = undefined;
        if (left) |left_int| {
            left_v = Value{ .int = left_int };
        } else {
            left_v = Value.old;
        }

        var op_tok = tokenizer.next() orelse unreachable;
        var op: Op = undefined;
        if (op_tok[0] == '+') {
            op = .add;
        } else if (op_tok[0] == '*') {
            op = .mul;
        } else {
            unreachable;
        }
        var right = std.fmt.parseInt(u64, tokenizer.next() orelse unreachable, 10) catch null;
        var right_v: Value = undefined;
        if (right) |right_int| {
            right_v = Value{ .int = right_int };
        } else {
            right_v = Value.old;
        }

        ret.operation = Expr{
            .op = op,
            .left = left_v,
            .right = right_v,
        };

        // parse test
        line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
        line = line[21..];
        ret.divisible_test = try std.fmt.parseInt(u64, line, 10);

        // parse true monkey
        line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
        line = line[29..];
        ret.true_monkey = try std.fmt.parseInt(u8, line, 10);

        // parse false monkey
        line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
        line = line[30..];
        ret.false_monkey = try std.fmt.parseInt(u8, line, 10);

        return ret;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var args = std.process.args();
    if (!args.skip()) {
        return;
    }
    const filename = args.next() orelse {
        std.debug.print("please pass a filename\n", .{});
        return;
    };

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var monkeys = std.ArrayList(Monkey).init(allocator);
    var buf: [BUF_SIZE]u8 = undefined;
    var modulo: u64 = 1;
    while (try Monkey.init(allocator, in_stream)) |monkey| {
        modulo *= monkey.divisible_test;
        try monkeys.append(monkey);
        _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n') orelse break;
    }

    var round: u64 = 0;
    while (round < ROUND_COUNT) {
        for (monkeys.items) |*monkey| {
            while (monkey.items.items.len > 0) {
                var worry = monkey.items.orderedRemove(0);
                worry = monkey.operation.evaluate(worry);
                worry %= modulo;
                worry /= WORRY_DECREASE_FACTOR;
                if (worry % monkey.divisible_test == 0) {
                    try monkeys.items[monkey.true_monkey].items.append(worry);
                } else {
                    try monkeys.items[monkey.false_monkey].items.append(worry);
                }
                monkey.inspect_count += 1;
            }
        }
        round += 1;
    }

    for (monkeys.items) |monkey| {
        std.debug.print("{}\n", .{monkey.inspect_count});
    }

    return;
}
