const std = @import("std");

const BUF_SIZE = 1024;

const Forest = struct {
    trees: std.ArrayList(std.ArrayList(u8)),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Forest {
        return Forest{
            .trees = std.ArrayList(std.ArrayList(u8)).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn parse_line(self: *Forest, line: []u8) !void {
        var new_line = std.ArrayList(u8).init(self.allocator);
        for (line) |char| {
            try new_line.append(char - '0');
        }
        try self.trees.append(new_line);
    }

    pub fn visible(self: Forest, x: isize, y: isize) bool {
        const height = self.trees.items[@intCast(usize, y)].items[@intCast(usize, x)];
        var dirs: [4][2]i8 = .{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };

        for (dirs) |dir| {
            const x_diff = dir[0];
            const y_diff = dir[1];
            var xx = x + x_diff;
            var yy = y + y_diff;
            var found_block = false;
            while (xx >= 0 and xx < self.trees.items[0].items.len and yy >= 0 and yy < self.trees.items.len) {
                if (self.trees.items[@intCast(usize, yy)].items[@intCast(usize, xx)] >= height) {
                    found_block = true;
                    break;
                }
                xx += x_diff;
                yy += y_diff;
            }
            if (!found_block) {
                return true;
            }
        }
        return false;
    }

    pub fn viewing_score(self: Forest, x: isize, y: isize) usize {
        const height = self.trees.items[@intCast(usize, y)].items[@intCast(usize, x)];
        var dirs: [4][2]i8 = .{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };

        var score: usize = 1;
        for (dirs) |dir| {
            const x_diff = dir[0];
            const y_diff = dir[1];
            var xx = x + x_diff;
            var yy = y + y_diff;
            var found_block = false;
            var count : usize = 1;
            while (xx >= 0 and xx < self.trees.items[0].items.len and yy >= 0 and yy < self.trees.items.len) {
                if (self.trees.items[@intCast(usize, yy)].items[@intCast(usize, xx)] >= height) {
                    found_block = true;
                    break;
                }
                xx += x_diff;
                yy += y_diff;
                count += 1;
            }
            if (!found_block) {
                count -= 1;
            }
            score *= count;
        }
        return score;
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

    var forest = try Forest.init(allocator);

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', BUF_SIZE)) |line| {
        try forest.parse_line(line);
    }

    // day 1
    //var x: isize = 0;
    //var y: isize = 0;
    //var count: usize = 0;
    //while (y < forest.trees.items.len) {
    //    x = 0;
    //    while (x < forest.trees.items[@intCast(usize, y)].items.len) {
    //        if (forest.visible(x,y)) {
    //            count += 1;
    //            std.debug.print("+", .{});
    //        } else {
    //            std.debug.print(".", .{});
    //        }
    //        x += 1;
    //    }
    //    std.debug.print("\n", .{});
    //    y += 1;
    //}
    //std.debug.print("{}\n", .{count});

    //day 2
    var x: isize = 1;
    var y: isize = 1;
    var best_score: usize = 0;
    while (y < forest.trees.items.len - 1) {
        x = 1;
        while (x < forest.trees.items[@intCast(usize, y)].items.len - 1) {
            const viewing_score = forest.viewing_score(x,y);
            if (viewing_score > best_score) {

                std.debug.print("{} {} {}\n", .{x, y, viewing_score});
                best_score = viewing_score;
            }
            x += 1;
        }
        y += 1;
    }
    std.debug.print("{}\n", .{best_score});
}

