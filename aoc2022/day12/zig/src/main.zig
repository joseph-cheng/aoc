const std = @import("std");

const BUF_SIZE = 128;

const Node = struct {
    height: u8,
    num_connections: u8,
    connections: [4]*Node,
    end: bool,
    flag: bool,
    parent: ?*Node,
};

fn parse_map(alloc: std.mem.Allocator, reader: anytype, start_out: **Node) !std.ArrayList(*Node) {
    var nodes = std.ArrayList(*Node).init(alloc);
    var buf: [BUF_SIZE]u8 = undefined;
    var cols: usize = 0;
    var rows: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (cols == 0) {
            cols = line.len;
        }
        for (line) |char| {
            var node = try alloc.create(Node);
            node.height = switch (char) {
                'S' => 0,
                'E' => 'z' - 'a',
                else => char - 'a',
            };
            node.num_connections = 0;
            if (char == 'E') {
                node.end = true;
            } else {
                node.end = false;
            }
            if (char == 'S') {
                start_out.* = node;
            }
            node.flag = false;
            node.parent = null;
            try nodes.append(node);
        }
        rows += 1;
    }
    for (nodes.items) |node, i| {
        const row = i / cols;
        const col = i % cols;
        if (col != 0) {
            const other = nodes.items[row * cols + col - 1];

            if (other.height <= node.height + 1) {
                node.connections[node.num_connections] = other;
                node.num_connections += 1;
            }
        }
        if (col != cols - 1) {
            const other = nodes.items[row * cols + col + 1];
            if (other.height <= node.height + 1) {
                node.connections[node.num_connections] = other;
                node.num_connections += 1;
            }
        }

        if (row != 0) {
            const other = nodes.items[(row - 1) * cols + col];
            if (other.height <= node.height + 1) {
                node.connections[node.num_connections] = other;
                node.num_connections += 1;
            }
        }

        if (row != rows - 1) {
            const other = nodes.items[(row + 1) * cols + col];
            if (other.height <= node.height + 1) {
                node.connections[node.num_connections] = other;
                node.num_connections += 1;
            }
        }
    }
    return nodes;
}

fn reset(nodes: std.ArrayList(*Node)) void {
    for (nodes.items) |node| {
        node.flag = false;
        node.parent = null;
    }
}

fn bfs(alloc: std.mem.Allocator, start: *Node) !?*Node {
    var queue : std.TailQueue(*Node) =  std.TailQueue(*Node) {
        .first = null,
        .last = null,
        .len = 0,
    };
    var queue_node = try alloc.create(std.TailQueue(*Node).Node);
    start.flag = true;
    queue_node.data = start;
    queue.append(queue_node);
    while (queue.len != 0) {
        var n_wrap = queue.popFirst() orelse unreachable;
        defer alloc.destroy(n_wrap);
        const n = n_wrap.data;
        if (n.end) {
            return n;
        }
        for (n.connections[0..n.num_connections]) |m| {
            if (!m.flag) {
                m.flag = true;
                m.parent = n;
                queue_node = try alloc.create(std.TailQueue(*Node).Node);
                queue_node.data = m;
                queue.append(queue_node);
            }
        }
    }
    return null;
}

fn traceback(end: *Node) u32 {
    var count: u32 = 0;
    var node = end;
    while (node.parent) |parent| {
        node = parent;
        count += 1;
    }
    return count;
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

    var start : *Node = undefined;

    // day 1
    //_ = try parse_map(allocator, in_stream, &start);
    //var end = try bfs(allocator, start) orelse unreachable;
    //const path_length = traceback(end);
    //std.debug.print("{}\n", .{path_length});

    // day 2

    const nodes = try parse_map(allocator, in_stream, &start);
    var smallest : u32 = 999999;
    for (nodes.items) |node| {
        if (node.height != 0) {
            continue;
        }
        var end = try bfs(allocator, node) orelse continue;
        const path_length = traceback(end);
        if (path_length < smallest) {
            smallest = path_length;
        }
        std.debug.print("{}\n", .{path_length});
        reset(nodes);
    }
    std.debug.print("{}\n", .{smallest});



}

