const std = @import("std");

const BUF_SIZE = 1024;

const Data = union(enum) {
    int: u32,
    list: std.ArrayList(Data),

    pub fn print(self: Data) void {
        switch (self) {
            .int => std.debug.print("{}", .{self.int}),
            .list => {
                std.debug.print("[", .{});
                for (self.list.items) |item| {
                    item.print();
                    std.debug.print(",", .{});
                }
                std.debug.print("]", .{});
            },
        }
    }
};

const ParseError  = error {
    cannot_find_token,
};

fn find_matching_bracket(str: []const u8) ParseError!usize {
    if (str[0] != '[') {
        return 0;
    }
    var depth: usize = 1;
    for (str[1..]) |char, i| {
        if (char == '[') {
            depth += 1;
        }
        if (char == ']') {
            depth -= 1;
        }
        if (depth == 0) {
            // off-by-one correction because we start from index 1
            return i+1;
        }
    }
    return ParseError.cannot_find_token;
}

fn find_end(str: []const u8) ParseError!usize {
    for (str) |char, i| {
        if (char == ',' or char == ']') {
            return i;
        }
    }
    return ParseError.cannot_find_token;
}

fn parse_data(str: []const u8, alloc: std.mem.Allocator) !Data {
    if (str[0] != '[') {
        return Data{ .int = try std.fmt.parseInt(u32, str, 10) };
    }
    //otherwise we have a list
    var ret = Data{ .list = std.ArrayList(Data).init(alloc) };
    var idx: usize = 1;
    // parse each element in turn
    while (idx < str.len - 1) {
        // if it's a list, find the matching brace and recursively parse
        if (str[idx] == '[') {
            const end = try find_matching_bracket(str[idx..]);
            try ret.list.append(try parse_data(str[idx..idx+end+1], alloc));
            idx = idx + end + 2;
        } else {
            const end = try find_end(str[idx..]);
            try ret.list.append(try parse_data(str[idx..idx+end], alloc));
            idx = idx + end + 1;
        }
    }
    return ret;
}

fn less_than(alloc: std.mem.Allocator, d1: Data, d2: Data) bool {
    const ret =  switch (d1) {
        .int => blk: {
            switch (d2) {
                .int => {
                    var ret: bool = false;
                    if (d1.int <= d2.int) {
                        ret = true;
                    } else {
                        ret = false;
                    }
                    break :blk ret;
                },
                .list => {
                    // wrap d1
                    var new_d1 = Data {.list = std.ArrayList(Data).init(alloc) };
                    new_d1.list.append(Data {.int = d1.int}) catch unreachable;
                    break :blk less_than(alloc, new_d1, d2);
                }
            }
        },

        .list => blk: {
            switch (d2) {
                .int =>  {
                    // wrap d2
                    var new_d2 = Data {.list = std.ArrayList(Data).init(alloc) };
                    new_d2.list.append(Data {.int = d2.int}) catch unreachable;
                    break :blk less_than(alloc, d1, new_d2);
                },
                .list =>  {
                    // compare each elemtn in turn
                    var idx: usize = 0;
                    while (idx < d1.list.items.len and idx < d2.list.items.len) : (idx += 1) {
                        const result = less_than(alloc, d1.list.items[idx], d2.list.items[idx]);
                        const other_result = less_than(alloc, d2.list.items[idx], d1.list.items[idx]);
                        if (result and other_result) {
                            continue;
                        }
                        break :blk result;
                    }
                    if (idx < d1.list.items.len and idx >= d2.list.items.len) {
                        break :blk false;
                    }
                    if (idx >= d1.list.items.len and idx < d2.list.items.len) {
                        break :blk true;
                    }
                    break :blk true;
                }
            }
        }
    };
    return ret;
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

    var idx: usize = 1;
    var count: usize = 0;
    var packets = std.ArrayList(Data).init(allocator);
    const first_div = try parse_data("[[2]]", allocator);
    const second_div = try parse_data("[[6]]", allocator);
    try packets.append(first_div);
    try packets.append(second_div);
    while (true) : (idx += 1){
        const left_str = try in_stream.readUntilDelimiterOrEof(&buf, '\n') orelse break;
        const left = try parse_data(left_str, allocator);
        try packets.append(left);
        const right_str = try in_stream.readUntilDelimiterOrEof(&buf, '\n') orelse break;
        const right = try parse_data(right_str, allocator);
        try packets.append(right);
        // day 1
        //if (less_than(allocator, left, right)) {
            //count += idx;
        //}

        _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n') orelse break;
    }
    std.sort.insertionSort(Data, packets.items, allocator, less_than);
    var first_div_loc : usize = 0;
    var second_div_loc: usize = 0;
    for (packets.items) |packet, i| {
        if (less_than(allocator, packet, first_div) and less_than(allocator, first_div, packet)) {
            first_div_loc = i + 1;
        }
        if (less_than(allocator, packet, second_div) and less_than(allocator, second_div, packet)) {
            second_div_loc = i + 1;
        }
    }

    std.debug.print("{}\n", .{first_div_loc * second_div_loc});
    std.debug.print("{}\n", .{count});


}
