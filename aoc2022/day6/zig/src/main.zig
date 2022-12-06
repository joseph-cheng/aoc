const std = @import("std");
const BUF_SIZE = 4096;
//day 1
//const PACKET_MARKER_SIZE = 4;
//day 2
const PACKET_MARKER_SIZE = 14;

fn check_if_unique(line: []const u8, allocator: std.mem.Allocator) !bool {
    var map = std.AutoHashMap(u8, bool).init(allocator);
    for (line) |char| {
        if (map.get(char) orelse false) {
            return false;
        }
        try map.put(char, true);
    }
    return true;
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
    var line = try in_stream.readUntilDelimiterOrEof(&buf, '\n') orelse "";
    var idx: usize = 0;
    while (idx < line.len - PACKET_MARKER_SIZE) {
        if (try check_if_unique(line[idx..idx + PACKET_MARKER_SIZE], allocator)) {
            std.debug.print("{}\n", .{idx + PACKET_MARKER_SIZE});
            break;
        }
        idx += 1;
    }
}
