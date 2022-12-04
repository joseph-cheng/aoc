const std = @import("std");

const BUF_SIZE = 1024;

fn get_next_sum(reader: anytype) !?u64 {
    var buf: [BUF_SIZE]u8 = undefined;
    var sum: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var val = std.fmt.parseInt(u64, line, 10) catch return sum;
        sum += val;
    }
    return null;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    if (!args.skip()) {
        return;
    }
    const filename = args.next() orelse {
        std.debug.print("please pass a filename", .{});
        return;
    };
    std.debug.print("{s}\n", .{filename});

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var calories_list = std.ArrayList(u64).init(allocator);
    defer calories_list.deinit();

    while (try get_next_sum(&in_stream)) |sum| {
        try calories_list.append(sum);
    } else {
        std.debug.print("finished!\n", .{});
    }
    std.sort.sort(u64, calories_list.items, {}, comptime std.sort.desc(u64));
    var total: usize = 0;
    for (calories_list.items[0..3]) |sum| {
        total += sum;
    }
    std.debug.print("{}\n", .{total});
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}
