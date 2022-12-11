const std = @import("std");

const BUF_SIZE = 32;

const InstructionType = enum {
    Nop,
    Add,
};

const Instruction = struct {
    instr_type: InstructionType,
    data: i32,
};

const VM = struct {
    cycle: u32,
    reg: i32,
    on_cycle: *const fn (*VM) void,

    pub fn init(on_cycle: *const fn (*VM) void) VM {
        return VM{
            .cycle = 0,
            .reg = 1,
            .on_cycle = on_cycle,
        };
    }

    pub fn do_instr(self: *VM, instr: Instruction) void {
        switch (instr.instr_type) {
            .Nop => {
                self.cycle += 1;
                self.on_cycle(self);
            },
            .Add => {
                self.cycle += 1;
                self.on_cycle(self);
                self.cycle += 1;
                self.on_cycle(self);
                self.reg += instr.data;
            },
        }
    }
};

fn parse_line(line: []u8) !Instruction {
    var tokenizer = std.mem.tokenize(u8, line, " ");
    const instr = tokenizer.next() orelse "";
    if (instr[0] == 'n') {
        return Instruction{
            .instr_type = .Nop,
            .data = undefined,
        };
    } else {
        return Instruction{
            .instr_type = .Add,
            .data = try std.fmt.parseInt(i32, tokenizer.next() orelse std.debug.panic("no number on add\n", .{}), 10),
        };
    }
}

// day 1
//var sum: i32 = 0;
//fn check_strength(vm: *VM) void {
//    if (vm.cycle == 20 or
//        vm.cycle == 60 or
//        vm.cycle == 100 or
//        vm.cycle == 140 or
//        vm.cycle == 180 or
//        vm.cycle == 220)
//    {
//        const strength = @intCast(i32, vm.cycle) * vm.reg;
//        sum += strength;
//        std.debug.print("{}\n", .{strength});
//    }
//}

// day 2
fn draw_pixel(vm: *VM) void {
    const x = (vm.cycle - 1) % 40;
    if (x >= vm.reg - 1 and x <= vm.reg + 1) {
        std.debug.print("#", .{});
    } else {
        std.debug.print(".", .{});
    }
    if (vm.cycle % 40 == 0) {
        std.debug.print("\n", .{});
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

    var vm = VM.init(draw_pixel);
    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', BUF_SIZE)) |line| {
        const instr = try parse_line(line);
        vm.do_instr(instr);
    }


    // day 1
    // std.debug.print("{}\n", .{sum});

}
