const std = @import("std");
const BUF_SIZE = 4096;
//day 1
//const PACKET_MARKER_SIZE = 4;
//day 2
const PACKET_MARKER_SIZE = 14;

fn check_if_unique(line: []const u8) bool {
    var chars_seen : u32 = 0;
    var bit: u32 = 1;
    for (line) |char| {
        if ((chars_seen & (bit << (char - 'a'))) > 0) {
            return false;
        }
        chars_seen |= (1 << (char - 'a'));
    }
    return true;
}

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
    var line = try in_stream.readUntilDelimiterOrEof(&buf, '\n') orelse "";
    var idx: usize = 0;
    while (idx < line.len - PACKET_MARKER_SIZE) {
        if (check_if_unique(line[idx..idx + PACKET_MARKER_SIZE])) {
            std.debug.print("{}\n", .{idx + PACKET_MARKER_SIZE});
            break;
        }
        idx += 1;
    }
}
