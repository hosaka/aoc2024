const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;

const tokenizeScalar = std.mem.tokenizeScalar;
const indexOf = std.mem.indexOfScalar;
const print = std.debug.print;
const contains = std.mem.containsAtLeast;
const eql = std.mem.eql;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Answer = struct {
    positions: u32,
};

const Point = struct {
    x: isize,
    y: isize,
    fn add(self: *const Point, point: *const Point) Point {
        return Point{ .x = self.x + point.x, .y = self.y + point.y };
    }
};

const AllDirections = [_]Point{
    .{ .x = -1, .y = 0 }, // up
    .{ .x = 0, .y = 1 }, // right
    .{ .x = 1, .y = 0 }, // down
    .{ .x = 0, .y = -1 }, // left
};

const GuardDirections = [_]u8{ '^', '>', 'v', '<' };

const GuardMove = enum {
    Advance,
    Obstruction,
    Exit,
};

pub fn moveGuard(grid: *List([]u8), position: *Point, direction_index: usize) !GuardMove {
    const next = position.add(&AllDirections[direction_index]);

    // bounds check
    if (0 > next.x or next.x >= grid.items.len) {
        return GuardMove.Exit;
    }
    const row = @as(usize, @intCast(next.x));
    if (0 > next.y or next.y >= grid.items[row].len) {
        return GuardMove.Exit;
    }
    const col = @as(usize, @intCast(next.y));
    const next_cell = grid.items[row][col];

    // obstruction
    if (next_cell == '#') {
        grid.items[@intCast(position.x)][@intCast(position.y)] = GuardDirections[(direction_index + 1) % GuardDirections.len];
        return GuardMove.Obstruction;
    }

    // move guard
    grid.items[row][col] = grid.items[@intCast(position.x)][@intCast(position.y)];
    grid.items[@intCast(position.x)][@intCast(position.y)] = '.';

    position.* = next;

    return GuardMove.Advance;
}

pub fn solve(input: []const u8) !Answer {
    var rows = tokenizeScalar(u8, input, '\n');
    var grid = List([]u8).init(alloc);
    defer grid.deinit();

    while (rows.next()) |row| {
        var line = List(u8).init(alloc);
        for (row) |char| {
            try line.append(char);
        }
        try grid.append(try line.toOwnedSlice());
    }

    // find guard position
    var guard_position = blk: {
        for (grid.items, 0..) |row, x| {
            for (row, 0..) |line, y| {
                if (contains(u8, &GuardDirections, 1, &[_]u8{line})) {
                    break :blk Point{ .x = @intCast(x), .y = @intCast(y) };
                }
            }
        }
        return error.NotFound;
    };
    print("Guard at {any}\n", .{guard_position});

    var movements = Map(Point, u8).init(alloc);
    defer movements.deinit();
    _ = try movements.getOrPut(guard_position);

    // simulate guard movement
    var action: GuardMove = .Obstruction;
    while (action != .Exit) {
        const direction = indexOf(u8, &GuardDirections, grid.items[@intCast(guard_position.x)][@intCast(guard_position.y)]) orelse std.math.maxInt(usize);
        switch (direction) {
            0, 1, 2, 3 => {
                action = try moveGuard(&grid, &guard_position, direction);
            },
            else => return error.NotFound,
        }
        if (action == .Advance) {
            _ = try movements.getOrPut(guard_position);
        }
    }
    return Answer{ .positions = movements.count() };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.positions});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(41, answer.positions);
}
