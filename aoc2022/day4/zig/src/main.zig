const std = @import("std");

const BUF_SIZE = 64;

const Job = struct {
    start: u32,
    end: u32,

    pub fn span(self: Job) u32 {
        return self.end - self.start;
    }
};

const JobPair = struct {
    job1 : Job,
    job2 : Job,
};

fn does_job_contain_other(jp: JobPair) bool {
    return (jp.job1.start <= jp.job2.start and
           jp.job1.end >= jp.job2.end) or
          (jp.job2.start <= jp.job1.start and
           jp.job2.end >= jp.job1.end);
}

fn does_job_overlap(jp: JobPair) bool {
    return (std.math.max(jp.job1.end, jp.job2.end) - std.math.min(jp.job1.start, jp.job2.start)) <= jp.job1.span() + jp.job2.span();
}

fn line_to_job_pair(line: []u8) !JobPair {
    var tokenizer = std.mem.tokenize(u8, line, ",-");
    return JobPair {
        .job1 = Job {
            .start = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10),
            .end = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10),

        },
        .job2 = Job {
            .start = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10),
            .end = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10),
        },
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

    var buf: [BUF_SIZE]u8 = undefined;
    var sum: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const job_pair = try line_to_job_pair(line);
        if (does_job_overlap(job_pair)) {
            sum += 1;
        }
    }
    std.debug.print("{}\n", .{sum});
}

