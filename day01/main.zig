const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;

const splitSeq = std.mem.splitSequence;
const splitScalar = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Answer = struct {
    distance: u32,
    similarity: u32,
};

fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

pub fn solve(input: []const u8) !Answer {
    _ = std.mem.split(u8, input, "\n");
    var rows = splitScalar(u8, input, '\n');
    var left_list = List([]const u8).init(alloc);
    defer left_list.deinit();
    var right_list = List([]const u8).init(alloc);
    defer right_list.deinit();

    // PART 1

    // split the rows into two lists
    while (rows.next()) |row| {
        var sides = splitSeq(u8, row, "   ");
        try left_list.append(sides.next() orelse break);
        try right_list.append(sides.next() orelse break);
    }
    _ = left_list.pop(); // last null

    // sort both lists
    sort([]const u8, left_list.items, {}, lessThan);
    sort([]const u8, right_list.items, {}, lessThan);

    var distance: u32 = 0;
    for (left_list.items, right_list.items) |left, right| {
        distance += @abs(try parseInt(i32, left, 10) - try parseInt(i32, right, 10));
    }

    // PART 2
    var right_scores = Map(i32, u32).init(alloc);
    defer right_scores.deinit();

    // count number of item appearances in the right list
    for (right_list.items) |item| {
        const value = try parseInt(i32, item, 10);
        const result = try right_scores.getOrPut(value);
        if (!result.found_existing) {
            result.value_ptr.* = 1;
        } else {
            result.value_ptr.* += 1;
        }
    }

    // sum up similarity between items in left list and right list scores
    var similarity: u32 = 0;
    for (left_list.items) |item| {
        const value = try parseInt(i32, item, 10);
        const result = right_scores.get(value) orelse 0;
        similarity += @as(u32, @intCast(value)) * result;
    }
    return Answer{ .distance = distance, .similarity = similarity };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.distance});
    print("Part 2: {d}\n", .{answer.similarity});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(answer.distance, 11);
    try std.testing.expectEqual(answer.similarity, 31);
}
