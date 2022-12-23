const std = @import("std");

const START = 0;
const END = 4000000 + 1;

const BUF_SIZE = 1024;

const Pos = struct {
    x: i64,
    y: i64,

    pub fn dist(self: Pos, other: Pos) !i64 {
        return try std.math.absInt((self.x - other.x)) + try std.math.absInt((self.y - other.y));
    }
};

const Range = struct {
    start: i64,
    end: i64,

    pub fn less_than(ctx: Checker, self: Range, other: Range) bool {
        _ = ctx;
        return (self.start < other.start);
    }
};

const Checker = struct {
    sensors: std.ArrayList(Pos),
    beacons: std.ArrayList(Pos),

    pub fn init(alloc: std.mem.Allocator) Checker {
        return Checker{
            .sensors = std.ArrayList(Pos).init(alloc),
            .beacons = std.ArrayList(Pos).init(alloc),
        };
    }

    pub fn parse_line(self: *Checker, line: []u8) !void {
        var tokenizer = std.mem.tokenize(u8, line, "=,:");
        _ = tokenizer.next();
        const sensor_x = try std.fmt.parseInt(i64, tokenizer.next() orelse unreachable, 10);
        _ = tokenizer.next();
        const sensor_y = try std.fmt.parseInt(i64, tokenizer.next() orelse unreachable, 10);

        const sensor = Pos{ .x = sensor_x, .y = sensor_y };

        _ = tokenizer.next();
        const beacon_x = try std.fmt.parseInt(i64, tokenizer.next() orelse unreachable, 10);
        _ = tokenizer.next();
        const beacon_y = try std.fmt.parseInt(i64, tokenizer.next() orelse unreachable, 10);
        const beacon = Pos{ .x = beacon_x, .y = beacon_y };

        try self.sensors.append(sensor);
        try self.beacons.append(beacon);
    }

    fn get_range(self: Checker, i: usize, row: i64) ?Range {
        const sensor = self.sensors.items[i];
        const beacon = self.beacons.items[i];
        const distance = sensor.dist(beacon) catch unreachable;
        const row_dist = std.math.absInt(sensor.y - row) catch unreachable;
        const range_middle_x = sensor.x;
        const range_radius = distance - row_dist;

        if (range_radius < 0) {
            return null;
        }
        const ret = Range{
            .start = range_middle_x - range_radius,
            .end = range_middle_x + range_radius,
        };
        return ret;
    }

    pub fn get_excluded_count(self: Checker, row: i64) u32 {
        var ranges = std.ArrayList(Range).init(self.sensors.allocator);
        defer ranges.deinit();
        for (self.sensors.items) |_, i| {
            if (self.get_range(i, row)) |range| {
                ranges.append(range) catch unreachable;
            }
        }

        std.sort.sort(Range, ranges.items, self, Range.less_than);
        if (ranges.items.len == 0) {
            return 0;
        }

        const reduced_ranges = remove_overlap(ranges);
        defer reduced_ranges.deinit();

        var count: u32 = 0;
        for (reduced_ranges.items) |range| {
            if (range.end < END) {
                std.debug.print("{} {}\n", .{ range.end + 1, row });
            }
            count += @intCast(u32, (range.end - range.start + 1));
        }
        return count;
    }
};

fn remove_overlap(ranges: std.ArrayList(Range)) std.ArrayList(Range) {
    // assumes ranges is sorted by start
    var reduced = std.ArrayList(Range).init(ranges.allocator);
    var current_range = ranges.items[0];
    for (ranges.items[1..]) |range| {
        if (range.start > current_range.end + 1) {
            reduced.append(current_range) catch unreachable;
            current_range = range;
        } else {
            if (range.end > current_range.end) {
                current_range.end = range.end;
            }
        }
    }
    reduced.append(current_range) catch unreachable;
    return reduced;
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

    var buf: [BUF_SIZE]u8 = undefined;

    var checker = Checker.init(allocator);
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try checker.parse_line(line);
    }

    var count: u64 = 0;
    var row: u32 = START;
    while (row < END) : (row += 1) {
        if (row % 100000 == 0) {
            std.debug.print("{}\n", .{row});
        }
        const c = checker.get_excluded_count(row);
        count += c;
    }
    std.debug.print("{}\n", .{count});
}
