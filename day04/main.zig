const std = @import("std");
const List = std.ArrayList;

const tokenizeScalar = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Point = struct { x: isize, y: isize };

const AllDirections = [_]Point{
    .{ .x = 0, .y = -1 }, // up
    .{ .x = 0, .y = 1 }, // down
    .{ .x = -1, .y = 0 }, // left
    .{ .x = 1, .y = 0 }, // right
    .{ .x = -1, .y = -1 }, // up left
    .{ .x = 1, .y = -1 }, // up right
    .{ .x = -1, .y = 1 }, // down left
    .{ .x = 1, .y = 1 }, // down right
};

const Answer = struct {
    xmas: u32,
};

pub fn searchXmas(letters: List([]const u8), search_char: u8, position: Point, direction: Point) u32 {
    if (0 > position.x or position.x >= letters.items.len) {
        return 0;
    }
    const row = @as(usize, @intCast(position.x));

    if (0 > position.y or position.y >= letters.items[row].len) {
        return 0;
    }
    const col = @as(usize, @intCast(position.y));

    const current_char = letters.items[row][col];

    if (current_char == search_char) {
        const next = Point{
            .x = position.x + direction.x,
            .y = position.y + direction.y,
        };
        if (current_char == 'M') {
            return searchXmas(letters, 'A', next, direction);
        } else if (current_char == 'A') {
            return searchXmas(letters, 'S', next, direction);
        } else if (current_char == 'S') {
            return 1; // found all letters
        }
    }
    return 0;
}

pub fn countXmas(letters: List([]const u8), starts: List(Point)) u32 {
    var counter: u32 = 0;
    for (starts.items) |start| {
        for (AllDirections) |direction| {
            const next = Point{ .x = start.x + direction.x, .y = start.y + direction.y };
            counter += searchXmas(letters, 'M', next, direction);
        }
    }
    return counter;
}

pub fn solve(input: []const u8) !Answer {
    var rows = tokenizeScalar(u8, input, '\n');

    var letters = List([]const u8).init(alloc);
    defer letters.deinit();
    var starts = List(Point).init(alloc);
    defer starts.deinit();

    var x: usize = 0;
    while (rows.next()) |row| {
        try letters.append(row);
        for (row, 0..) |letter, y| {
            if (letter == 'X') {
                try starts.append(.{ .x = @intCast(x), .y = @intCast(y) });
            }
        }
        x += 1;
    }

    // PART 1
    const xmas = countXmas(letters, starts);
    return Answer{ .xmas = xmas };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.xmas});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(18, answer.xmas);
}
