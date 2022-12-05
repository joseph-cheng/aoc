const std = @import("std");

const BUF_SIZE = 1024;

const State = struct {
    stacks: std.ArrayList(std.ArrayList(u8)),

    pub fn move(self: *State, from: u32, to: u32, count: u32) !void {
        //day 1
        //var moved_so_far: u32 = 0;
        //while (moved_so_far < count) {
            //const item = self.stacks.items[from].pop();
            //try self.stacks.items[to].append(item);
            //moved_so_far += 1;
        //}
        

        //day 2
        var from_stack = self.stacks.items[from];
        var moved_items = self.stacks.items[from].items[from_stack.items.len - count..from_stack.items.len];
        var moved_so_far: u32 = 0;
        while (moved_so_far < count) {
            _ = self.stacks.items[from].pop();
            moved_so_far += 1;
        }
        try self.stacks.items[to].appendSlice(moved_items);
        
    }
    pub fn parse_line(self: *State, line: []u8) !bool {
        var ii: usize = 0;
        for (line) |char| {
            if (ii % 4 == 1) {
                if (char != ' ' and (char < 'A' or char > 'Z')) {
                    return false;
                }
                if (char != ' ') {
                    while (ii / 4 >= self.stacks.items.len) {
                        try self.stacks.append(std.ArrayList(u8).init(self.stacks.allocator));
                    }
                    try self.stacks.items[ii / 4].append(char);
                }
            }
            ii += 1;
        }
        return true;
    }

    pub fn create(reader: anytype, allocator: std.mem.Allocator) !State {
        var self = State{
            .stacks = std.ArrayList(std.ArrayList(u8)).init(allocator),
        };
        var buf: [BUF_SIZE]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (!(try self.parse_line(line))) {
                break;
            }
        }
        var count: usize = 0;
        // now reverse the lists
        for (self.stacks.items) |stack| {
            var new = std.ArrayList(u8).init(allocator);
            var ii : usize = 0;
            while (ii < stack.items.len) {
                try new.append(stack.items[stack.items.len - 1 - ii]);
                ii += 1;
            }
            stack.deinit();
            self.stacks.items[count] = new;
            count += 1;
        }
        // skip the last newline
        _ = try reader.readUntilDelimiterOrEof(&buf, '\n');

        return self;
    }

    pub fn parse_instruction(self: *State, line: []u8) !void {
        var tokenizer = std.mem.tokenize(u8, line, " ");
        _ = tokenizer.next();
        var count = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10);
        _ = tokenizer.next();
        var from = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10) - 1;
        _ = tokenizer.next();
        var to = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10) - 1;

        try self.move(from, to, count);
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

    var state = try State.create(in_stream, allocator);

    var buf: [BUF_SIZE]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try state.parse_instruction(line);
    }
        for (state.stacks.items) |stack| {
            for (stack.items) |item| {
                std.debug.print("{c}", .{item});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
}
