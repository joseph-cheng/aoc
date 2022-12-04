const std = @import("std");

const BUF_SIZE = 256;

const ReadError = error{
    UnknownSymbol,
};

const Rucksack = struct {
    first_compartment: []u8,
    second_compartment: []u8,
};

const ElfGroup = struct {
    items: [3][]u8,
    num_elves: usize,
};

fn get_priority(item: u8) ReadError!u32 {
    return switch (item) {
        'a'...'z' => item - 'a' + 1,
        'A'...'Z' => item - 'A' + 27,
        else => ReadError.UnknownSymbol,
    };
}

fn get_common_item(r: Rucksack) ?u8 {
    for (r.first_compartment) |item1| {
        for (r.second_compartment) |item2| {
            if (item1 == item2) {
                return item1;
            }
        }
    }
    return null;
}

fn get_common_item_in_group(g: ElfGroup) ?u8 {
    for (g.items[0]) |item1| {
        for (g.items[1]) |item2| {
            // skip if the first two items don't match
            if (item1 != item2) {
                continue;
            }
            for (g.items[2]) |item3| {
                if (item1 == item2 and item2 == item3) {
                    return item1;
                }
            }
        }
    }
    return null;
}

fn line_to_rucksack(line: []u8) Rucksack {
    const midpoint = line.len / 2;
    return Rucksack{
        .first_compartment = line[0..midpoint],
        .second_compartment = line[midpoint..line.len],
    };
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

    var bufs: [3][BUF_SIZE]u8 = undefined;
    var sum: usize = 0;
    var group = ElfGroup{
        .items = undefined,
        .num_elves = 3,
    };
    var count: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&bufs[count % group.num_elves], '\n')) |line| {
        //const r: Rucksack = line_to_rucksack(line);
        //const common_item = get_common_item(r) orelse {
            //std.debug.print("no common item!\n", .{});
            //return;
        //};
        group.items[count % group.num_elves] = line;
        if (count % group.num_elves == 2) {
            const common_item = get_common_item_in_group(group) orelse {
                std.debug.print("no common item!\n", .{});
                return;
            };
            sum += try get_priority(common_item);
        }
        count += 1;
    }
    std.debug.print("{}\n", .{sum});
}
