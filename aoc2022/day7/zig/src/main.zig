const std = @import("std");

const BUF_SIZE = 128;
const MAX_SIZE = 100000;
const FREE_SPACE_NEEDED = 30000000;
const DISK_SPACE = 70000000;

const Directory = struct {
    name: []const u8,
    allocator: std.mem.Allocator,
    parent: ?*Directory,
    child_directories: std.StringHashMap(*Directory),
    child_files: std.StringHashMap(u32),
    size: u32,

    pub fn init(name: []const u8, parent: ?*Directory, allocator: std.mem.Allocator) !*Directory {
        const new = try allocator.create(Directory);
        new.name = name;
        new.allocator = allocator;
        new.parent = parent;
        new.child_directories = std.StringHashMap(*Directory).init(allocator);
        new.child_files = std.StringHashMap(u32).init(allocator);
        new.size = 0;
        return new;
    }

    pub fn deinit(self: *Directory) void {
        self.allocator.free(self.name);
        var iter = self.child_directories.valueIterator();
        while (iter.next()) |child_directory| {
            Directory.deinit(child_directory.*);
        }
        self.child_directories.deinit();
        self.child_files.deinit();
    }

    pub fn calculate_size(self: *Directory) u32 {
        var dir_iter = self.child_directories.valueIterator();
        while (dir_iter.next()) |child_directory| {
            self.size += Directory.calculate_size(child_directory.*);
        }
        var file_iter = self.child_files.valueIterator();
        while (file_iter.next()) |size| {
            self.size += size.*;
        }
        return self.size;
    }

    pub fn apply(self: *Directory, comptime T: type, func: *const fn (*Directory, T) void, param: T) void {
        func(self, param);
        var iter = self.child_directories.valueIterator();
        while (iter.next()) |child_directory| {
            Directory.apply(child_directory.*, T, func, param);
        }
    }
};

const CommandType = enum {
    LS,
    CD,
};

const Command = struct {
    cmd_type: CommandType,
    name: []const u8,
};

const ParseError = error{
    InvalidLine,
};

fn parse_cmd(line: []u8) !Command {
    if (line[0] != '$') {
        return ParseError.InvalidLine;
    }

    var tokenizer = std.mem.tokenize(u8, line, " ");
    _ = tokenizer.next();
    const cmd = tokenizer.next() orelse "";
    if (std.mem.eql(u8, cmd, "ls")) {
        return Command{
            .cmd_type = .LS,
            .name = undefined,
        };
    } else {
        return Command{
            .cmd_type = .CD,
            .name = tokenizer.next() orelse "",
        };
    }
}

fn print_if_smaller_than(dir: *Directory, max_size: u32) void {
    if (dir.size <= max_size) {
        std.debug.print("{}\n", .{dir.size});
    }
}

fn print_if_greater_than(dir: *Directory, min_size: u32) void {
    if (dir.size >= min_size) {
        std.debug.print("{}\n", .{dir.size});
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

    var in_ls = false;
    const root_name = try std.fmt.allocPrint(allocator, "{s}", .{"/"});
    const root = try Directory.init(root_name, null, allocator);
    defer root.deinit();
    var current_directory = root;
    _ = try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', BUF_SIZE);
    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', BUF_SIZE)) |line| {
        if (in_ls and line[0] == '$') {
            in_ls = false;
        }
        if (!in_ls) {
            const command = try parse_cmd(line);
            if (command.cmd_type == .LS) {
                in_ls = true;
            } else {
                if (std.mem.eql(u8, command.name, "..")) {
                    current_directory = current_directory.parent orelse current_directory;
                } else {
                    current_directory = current_directory.child_directories.get(command.name) orelse std.debug.panic("directory {s} does not exist", .{command.name});
                }
            }
        } else {
            var tokenizer = std.mem.tokenize(u8, line, " ");
            if (line[0] == 'd') {
                _ = tokenizer.next();
                const dir_name = tokenizer.next() orelse "";
                const child_dir = try Directory.init(dir_name, current_directory, allocator);
                try current_directory.child_directories.putNoClobber(dir_name, child_dir);
            } else {
                const file_size = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10);
                const file_name = tokenizer.next() orelse "";
                try current_directory.child_files.put(file_name, file_size);
            }
        }
    }

    //day 1
    //_ = root.calculate_size();
    //root.apply(u32, print_if_smaller_than, 100000);
    
    //day 2
    const used_space = root.calculate_size();
    const space_needed = FREE_SPACE_NEEDED - (DISK_SPACE - used_space);
    root.apply(u32, print_if_greater_than, space_needed);
}
