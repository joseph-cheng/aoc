const std = @import("std");

const BUF_SIZE = 16;

//day 1
//const NUM_SEGMENTS = 2;
//day 2
const NUM_SEGMENTS = 10;

const Direction = enum {
    Up,
    Down,
    Left,
    Right,

    pub fn x(self: Direction) i32 {
        return switch (self) {
            .Up => 0,
            .Down => 0,
            .Left => -1,
            .Right => 1,
        };
    }

    pub fn y(self: Direction) i32 {
        return switch (self) {
            .Up => 1,
            .Down => -1,
            .Left => 0,
            .Right => 0,
        };
    }
};

const Instruction = struct {
    dir: Direction,
    distance: usize,
};

const ParseError = error{
    InvalidLine,
};

fn parse_line(line: []u8) !Instruction {
    var tokenizer = std.mem.tokenize(u8, line, " ");
    const instr = (tokenizer.next() orelse "")[0];

    const dir = switch (instr) {
        'U' => Direction.Up,
        'D' => Direction.Down,
        'L' => Direction.Left,
        'R' => Direction.Right,
        else => return ParseError.InvalidLine,
    };

    const distance = try std.fmt.parseInt(usize, tokenizer.next() orelse std.debug.panic("failed to parse distance\n", .{}), 10);
    return Instruction{
        .dir = dir,
        .distance = distance,
    };
}

const Pos = struct {
    x: i32,
    y: i32,
};

const State = struct {
    rope: [NUM_SEGMENTS]Pos,

    positions: std.AutoHashMap(Pos, u32),

    pub fn init(allocator: std.mem.Allocator) !State {
        return State {
            .rope = init: {
                var initial_value: [NUM_SEGMENTS]Pos = undefined;
                for (initial_value) |*pt| {
                    pt.* = Pos {.x =0, .y=0};
                }
                break :init initial_value;
            },
            .positions = std.AutoHashMap(Pos, u32).init(allocator),
        };
    }

    pub fn move(self: *State, dir: Direction) !void {
        self.rope[0].x += dir.x();
        self.rope[0].y += dir.y();
        for (self.rope[1..]) |*segment, i| {
            try resolve_rope(&self.rope[i], segment);
        }
        try self.positions.put(self.rope[NUM_SEGMENTS-1], (self.positions.get(self.rope[NUM_SEGMENTS-1]) orelse 0) + 1);
    }

    pub fn do_instr(self: *State, instr: Instruction) !void {
        var distance_left: usize = instr.distance;
        while (distance_left > 0) {
            try self.move(instr.dir);
            distance_left -= 1;
        }

    }
};

fn resolve_rope(first: *Pos, second: *Pos) !void {
    // if at least two away in any direction, move toward first in that direction
    if (try std.math.absInt(first.x - second.x) >= 2 or try std.math.absInt(first.y - second.y) >= 2) {
        if (first.x != second.x) {
            second.x += if (first.x < second.x) -1 else 1;
        }
        if (first.y != second.y) {
            second.y += if (first.y < second.y) -1 else 1;
        }
    }
}

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

    var state = try State.init(allocator);
    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', BUF_SIZE)) |line| {
        const instr = try parse_line(line);
        try state.do_instr(instr);
    }

    var iter = state.positions.keyIterator();
    var count: usize = 0;
    while (iter.next()) |_| {
        count += 1;
    }
    std.debug.print("{}\n", .{count});
}
