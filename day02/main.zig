const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;

const splitSeq = std.mem.splitSequence;
const splitScalar = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;

const Answer = struct {
    x: u32,
};

pub fn solve(input: []const u8) !Answer {
    _ = splitScalar(u8, input, '\n');
    return Answer{ .x = 42 };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.x});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(answer.x, 42);
}
