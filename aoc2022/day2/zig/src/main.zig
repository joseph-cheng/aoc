const std = @import("std");

const BUF_SIZE = 64;

const Play = enum {
    rock,
    paper,
    scissors,
};

const Outcome = enum {
    win,
    loss,
    draw,
};

const Match = struct {
    other: Play,
    self: Play,
};

const ReadError = error{
    UnknownSymbol,
};

fn char_to_play(char: u8) ReadError!Play {
    return switch (char) {
        'A', 'X' => Play.rock,
        'B', 'Y' => Play.paper,
        'C', 'Z' => Play.scissors,
        else => ReadError.UnknownSymbol,
    };
}

fn char_to_outcome(char: u8) ReadError!Outcome {
    return switch (char) {
        'X' => Outcome.loss,
        'Y' => Outcome.draw,
        'Z' => Outcome.win,
        else => ReadError.UnknownSymbol,
    };
}

fn line_to_match(line: []u8) ReadError!Match {
    var ret = Match{
        .other = undefined,
        .self = undefined,
    };
    ret.other = try char_to_play(line[0]);
    ret.self = switch (try char_to_outcome(line[2])) {
        .loss => switch (ret.other) {
            .rock => Play.scissors,
            .paper => Play.rock,
            .scissors => Play.paper,
        },
        .draw => ret.other,
        .win => switch (ret.other) {
            .rock => Play.paper,
            .paper => Play.scissors,
            .scissors => Play.rock,
        },
    };
    return ret;
}

fn get_points(m: Match) u32 {
    var points: u32 = switch (m.self) {
        .rock => 1,
        .paper => 2,
        .scissors => 3,
    };
    points += switch (m.other) {
        .rock => switch (m.self) {
            .rock => 3,
            .paper => 6,
            .scissors => 0,
        },
        .paper => switch (m.self) {
            .rock => 0,
            .paper => 3,
            .scissors => 6,
        },
        .scissors => switch (m.self) {
            .rock => 6,
            .paper => 0,
            .scissors => 3,
        },
    };
    return points;
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
    var sum: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        sum += get_points(try line_to_match(line));
    }
    std.debug.print("{}\n", .{sum});
}
