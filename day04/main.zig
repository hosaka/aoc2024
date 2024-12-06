const std = @import("std");
const List = std.ArrayList;

const tokenizeScalar = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const eql = std.mem.eql;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Point = struct {
    x: isize,
    y: isize,
    fn add(self: *const Point, point: *const Point) Point {
        return Point{ .x = self.x + point.x, .y = self.y + point.y };
    }
};

// note: i have no idea how to use this or if it's even possible
// const DirectionType = enum(u8) { Up, Down, Left, Right, UpLeft, UpRight, DownLeft, DownRight };
// const Direction = union(DirectionType) {
//     up: Point = .{ .x = 0, .y = 0 },
// };

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
    mas: u32,
};

pub fn searchXmas(letters: List([]const u8), search_char: u8, position: Point, direction: Point) u32 {
    const current_char = getChar(letters, position);
    if (current_char == search_char) {
        const next = position.add(&direction);
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
            const next = start.add(&direction);
            counter += searchXmas(letters, 'M', next, direction);
        }
    }
    return counter;
}

pub fn countMas(letters: List([]const u8), starts: List(Point)) u32 {
    var counter: u32 = 0;
    for (starts.items) |start| {
        const a_char = getChar(letters, start) orelse continue;
        const top_left_char = getChar(letters, start.add(&AllDirections[4])) orelse continue;
        const down_right_char = getChar(letters, start.add(&AllDirections[7])) orelse continue;
        const top_right_char = getChar(letters, start.add(&AllDirections[5])) orelse continue;
        const down_left_char = getChar(letters, start.add(&AllDirections[6])) orelse continue;

        const tldr = [3]u8{ top_left_char, a_char, down_right_char };
        const trdl = [3]u8{ top_right_char, a_char, down_left_char };
        if ((eql(u8, &tldr, "MAS") or eql(u8, &tldr, "SAM")) and (eql(u8, &trdl, "MAS") or eql(u8, &trdl, "SAM"))) {
            counter += 1;
        }
    }
    return counter;
}

pub fn getChar(letters: List([]const u8), point: Point) ?u8 {
    if (0 > point.x or point.x >= letters.items.len) {
        return null;
    }
    const row = @as(usize, @intCast(point.x));

    if (0 > point.y or point.y >= letters.items[row].len) {
        return null;
    }
    const col = @as(usize, @intCast(point.y));
    return letters.items[row][col];
}

pub fn solve(input: []const u8) !Answer {
    var rows = tokenizeScalar(u8, input, '\n');

    var letters = List([]const u8).init(alloc);
    defer letters.deinit();
    var x_starts = List(Point).init(alloc);
    defer x_starts.deinit();
    var a_starts = List(Point).init(alloc);
    defer a_starts.deinit();

    var x: usize = 0;
    while (rows.next()) |row| {
        try letters.append(row);
        for (row, 0..) |letter, y| {
            if (letter == 'X') {
                try x_starts.append(.{ .x = @intCast(x), .y = @intCast(y) });
            } else if (letter == 'A') {
                try a_starts.append(.{ .x = @intCast(x), .y = @intCast(y) });
            }
        }
        x += 1;
    }

    // PART 1
    const xmas = countXmas(letters, x_starts);

    // PART 2
    const mas = countMas(letters, a_starts);

    return Answer{ .xmas = xmas, .mas = mas };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.xmas});
    print("Part 2: {d}\n", .{answer.mas});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(18, answer.xmas);
}
