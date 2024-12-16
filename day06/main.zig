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
    obstructions: u32,
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

pub fn moveGuard(grid: *[][]u8, position: *Point, direction_index: usize) !GuardMove {
    const next = position.add(&AllDirections[direction_index]);

    // bounds check
    if (0 > next.x or next.x >= grid.len) {
        return GuardMove.Exit;
    }
    const row = @as(usize, @intCast(next.x));
    if (0 > next.y or next.y >= grid.*[row].len) {
        return GuardMove.Exit;
    }
    const col = @as(usize, @intCast(next.y));
    const next_cell = grid.*[row][col];

    // obstruction
    if (next_cell == '#') {
        grid.*[@intCast(position.x)][@intCast(position.y)] = GuardDirections[(direction_index + 1) % GuardDirections.len];
        return GuardMove.Obstruction;
    }

    // move guard
    grid.*[row][col] = grid.*[@intCast(position.x)][@intCast(position.y)];
    grid.*[@intCast(position.x)][@intCast(position.y)] = '.';

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

    const grid_copy = try alloc.alloc([]u8, grid.items.len);
    for (grid.items, 0..) |row, x| {
        grid_copy[x] = try std.mem.Allocator.dupe(alloc, u8, row);
    }

    // find guard position
    const guard_position = blk: {
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

    // PART 2
    // simulate guard movement
    var positions: u32 = 0;
    {
        var grid01 = try alloc.alloc([]u8, grid_copy.len);
        for (grid_copy, 0..) |row, x| {
            grid01[x] = try std.mem.Allocator.dupe(alloc, u8, row);
        }

        var movements = Map(Point, u8).init(alloc);
        defer movements.deinit();

        var pos = guard_position;
        _ = try movements.getOrPut(pos);

        var action: GuardMove = .Obstruction;
        while (action != .Exit) {
            const direction = indexOf(u8, &GuardDirections, grid01[@intCast(pos.x)][@intCast(pos.y)]) orelse std.math.maxInt(usize);
            switch (direction) {
                0, 1, 2, 3 => {
                    action = try moveGuard(&grid01, &pos, direction);
                },
                else => return error.NotFound,
            }
            if (action == .Advance) {
                _ = try movements.getOrPut(pos);
            }
        }
        positions = movements.count();
    }

    // PART 2
    // find possible obstructions
    var obstructions: u32 = 0;
    {
        var grid02 = try alloc.alloc([]u8, grid_copy.len);
        for (grid_copy, 0..) |row, x| {
            grid02[x] = try std.mem.Allocator.dupe(alloc, u8, row);
        }

        for (grid.items, 0..) |row, x| {
            for (row, 0..) |line, y| {
                for (grid02, 0..) |_, i| {
                    @memcpy(grid02[i], grid_copy[i]);
                }

                var movements = Map(Point, u8).init(alloc);
                defer movements.deinit();

                var pos = guard_position;
                _ = try movements.getOrPut(pos);

                if (line == '#' or line == '^') {
                    continue;
                }
                grid02[x][y] = '#';

                var action: GuardMove = .Obstruction;
                while (action != .Exit) {
                    const direction = indexOf(u8, &GuardDirections, grid02[@intCast(pos.x)][@intCast(pos.y)]) orelse std.math.maxInt(usize);
                    switch (direction) {
                        0, 1, 2, 3 => {
                            action = try moveGuard(&grid02, &pos, direction);
                        },
                        else => return error.NotFound,
                    }
                    if (action == .Advance) {
                        const movement = try movements.getOrPut(pos);
                        const test_direction = indexOf(u8, &GuardDirections, grid02[@intCast(pos.x)][@intCast(pos.y)]) orelse std.math.maxInt(usize);
                        if (movement.found_existing and movement.value_ptr.* == GuardDirections[test_direction]) {
                            obstructions += 1;
                        } else {
                            movement.value_ptr.* = grid02[@intCast(pos.x)][@intCast(pos.y)];
                        }
                    }
                }
            }
        }
    }

    return Answer{ .positions = positions, .obstructions = obstructions };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.positions});
    print("Part 2: {d}\n", .{answer.obstructions});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(41, answer.positions);
    try std.testing.expectEqual(6, answer.obstructions);
}
