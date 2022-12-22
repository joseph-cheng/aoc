const std = @import("std");

const GRID_SIZE = 1000;
const BUF_SIZE = 1024;

const Tile = enum {
    air,
    rock,
    sand,
};

const Grid = struct {
    items: [GRID_SIZE][GRID_SIZE]Tile,
    sand_x: usize,
    sand_y: usize,
    sand_at_rest: bool,
    sand_count: usize,
    floor_y: usize,

    pub fn init() Grid {
        return Grid{
            .items = blk: {
                var ret: [GRID_SIZE][GRID_SIZE]Tile = undefined;
                var i: usize = 0;
                var j: usize = 0;
                while (i < GRID_SIZE) : (i += 1) {
                    j = 0;
                    while (j < GRID_SIZE) : (j += 1) {
                        ret[i][j] = Tile.air;
                    }
                }
                break :blk ret;
            },
            .sand_x = 500,
            .sand_y = 0,
            .sand_at_rest = false,
            .sand_count = 0,
            .floor_y = 0,
        };
    }

    pub fn print(self: Grid) void {
        for (self.items[0..35]) |row| {
            for (row[480..520]) |item| {
                switch (item) {
                    .air => std.debug.print(".", .{}),
                    .rock => std.debug.print("#", .{}),
                    .sand => std.debug.print("O", .{}),
                }
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn parse_line(self: *Grid, line: []u8) !void {
        var tokenizer = std.mem.tokenize(u8, line, " -> ");
        var from = (tokenizer.next() orelse unreachable);
        var to: []const u8 = undefined;
        while (tokenizer.next()) |coords| {
            to.ptr = coords.ptr;
            to.len = coords.len;
            var from_tokenizer = std.mem.tokenize(u8, from, ",");
            var to_tokenizer = std.mem.tokenize(u8, to, ",");
            var from_x = try std.fmt.parseInt(usize, from_tokenizer.next() orelse "", 10);
            var from_y = try std.fmt.parseInt(usize, from_tokenizer.next() orelse "", 10);
            var to_x = try std.fmt.parseInt(usize, to_tokenizer.next() orelse "", 10);
            var to_y = try std.fmt.parseInt(usize, to_tokenizer.next() orelse "", 10);
            if (from_y + 2 > self.floor_y) {
                self.floor_y = from_y + 2;
            }
            if (to_y + 2 > self.floor_y) {
                self.floor_y = to_y + 2;
            }
            const x_diff: isize = if (from_x > to_x) -1 else (if (from_x < to_x) 1 else 0);
            const y_diff: isize = if (from_y > to_y) -1 else (if (from_y < to_y) 1 else 0);
            while (from_x != to_x or from_y != to_y) {
                self.items[from_y][from_x] = Tile.rock;
                from_x = @intCast(usize, @intCast(isize, from_x) + x_diff);
                from_y = @intCast(usize, @intCast(isize, from_y) + y_diff);
            }
            self.items[from_y][from_x] = Tile.rock;
            from = to;
        }
    }

    pub fn step(self: *Grid) bool {
        if (self.sand_at_rest) {
            self.sand_count += 1;
            if (self.sand_x == 500 and self.sand_y == 0) {
                return true;
            }
            self.sand_x = 500;
            self.sand_y = 0;
            self.sand_at_rest = false;
            return false;
        }
        var new_sand_x = self.sand_x;
        var new_sand_y = self.sand_y + 1;
        if (new_sand_y == self.floor_y) {
            // day 1
            // return true;

            // day 2
            self.sand_at_rest = true;
            return false;
        }
        if (self.items[new_sand_y][new_sand_x] != Tile.air) {
            new_sand_x -= 1;
        }
        if (self.items[new_sand_y][new_sand_x] != Tile.air) {
            new_sand_x += 2;
        }
        if (self.items[new_sand_y][new_sand_x] != Tile.air) {
            self.sand_at_rest = true;
            return false;
        }
        self.items[self.sand_y][self.sand_x] = Tile.air;
        self.items[new_sand_y][new_sand_x] = Tile.sand;
        self.sand_x = new_sand_x;
        self.sand_y = new_sand_y;
        return false;
    }
};

pub fn main() !void {
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

    var buf: [BUF_SIZE]u8 = undefined;
    var grid = Grid.init();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try grid.parse_line(line);
    }
    while (!grid.step()) {
        //grid.print();
        //std.time.sleep(1000 * 1000 * 10);
    }
    std.debug.print("{}\n", .{grid.sand_count});
}
