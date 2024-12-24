const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;

const print = std.debug.print;
const tokenizeScalar = std.mem.tokenizeScalar;
const sqrt = std.math.sqrt;
const pow = std.math.pow;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Answer = struct {
    antinodes: u32,
    with_harmonics: u32,
};

const Point = struct {
    x: isize,
    y: isize,
    fn add(self: *const Point, point: *const Point) Point {
        return Point{ .x = self.x + point.x, .y = self.y + point.y };
    }
    fn dist(self: *const Point, point: *const Point) f64 {
        const dist_x = self.x - point.x;
        const dist_y = self.y - point.y;
        return sqrt(@as(f64, @floatFromInt(pow(isize, dist_x, 2))) + @as(f64, @floatFromInt(pow(isize, dist_y, 2))));
    }
};

fn getAntennas(grid: [][]const u8) !Map(u8, List(Point)) {
    var antennas = Map(u8, List(Point)).init(alloc);
    for (grid, 0..) |row, x| {
        for (row, 0..) |char, y| {
            if (char != '.') {
                const antenna = try antennas.getOrPut(char);
                if (!antenna.found_existing) {
                    antenna.value_ptr.* = List(Point).init(alloc);
                }
                try antenna.value_ptr.*.append(.{ .x = @intCast(x), .y = @intCast(y) });
            }
        }
    }
    return antennas;
}

// todo: shouldn't we use a Set instead of a Map?
fn getAntinodes(grid: [][]const u8, antennas: Map(u8, List(Point))) !Map(Point, void) {
    var antinodes = Map(Point, void).init(alloc);
    var iter = antennas.iterator();
    while (iter.next()) |antenna| {
        const points = antenna.value_ptr.*.items;
        for (points, 0..) |current, i| {
            // if (points.len > 0) {
            //     _ = try antinodes.getOrPut(
            //         .{ .x = current.x, .y = current.y },
            //     );
            // }
            for (points[i + 1 ..]) |target| {
                // distances
                const dx = target.x - current.x;
                const dy = target.y - current.y;
                const dist = sqrt(@as(f64, @floatFromInt(pow(isize, dx, 2))) + @as(f64, @floatFromInt(pow(isize, dy, 2))));

                const u_vec: [2]f64 = .{
                    @as(f64, @floatFromInt(dx)) / dist,
                    @as(f64, @floatFromInt(dy)) / dist,
                };
                const delta_x = @round(u_vec[0] * dist);
                const delta_y = @round(u_vec[1] * dist);

                // current
                {
                    const antinode = Point{
                        .x = current.x - @as(isize, @intFromFloat(delta_x)),
                        .y = current.y - @as(isize, @intFromFloat(delta_y)),
                    };

                    if (isInBounds(grid, antinode)) {
                        _ = try antinodes.getOrPut(antinode);
                    }
                }

                // target
                {
                    const antinode = Point{
                        .x = target.x + @as(isize, @intFromFloat(delta_x)),
                        .y = target.y + @as(isize, @intFromFloat(delta_y)),
                    };

                    if (isInBounds(grid, antinode)) {
                        _ = try antinodes.getOrPut(antinode);
                    }
                }
            }
        }
    }
    return antinodes;
}

fn getAntinodesWithHarmonics(grid: [][]const u8, antennas: Map(u8, List(Point))) !Map(Point, void) {
    var antinodes = Map(Point, void).init(alloc);
    var iter = antennas.iterator();
    while (iter.next()) |antenna| {
        const points = antenna.value_ptr.*.items;
        for (points, 0..) |current, i| {
            // if (points.len > 0) {
            //     _ = try antinodes.getOrPut(
            //         .{ .x = current.x, .y = current.y },
            //     );
            // }
            for (points[i + 1 ..]) |target| {
                // distances
                const dx = target.x - current.x;
                const dy = target.y - current.y;
                const dist = sqrt(@as(f64, @floatFromInt(pow(isize, dx, 2))) + @as(f64, @floatFromInt(pow(isize, dy, 2))));

                const u_vec: [2]f64 = .{
                    @as(f64, @floatFromInt(dx)) / dist,
                    @as(f64, @floatFromInt(dy)) / dist,
                };
                const delta_x = @round(u_vec[0] * dist);
                const delta_y = @round(u_vec[1] * dist);

                // current
                {
                    var antinode = Point{
                        .x = current.x - @as(isize, @intFromFloat(delta_x)),
                        .y = current.y - @as(isize, @intFromFloat(delta_y)),
                    };

                    if (isInBounds(grid, antinode)) {
                        _ = try antinodes.getOrPut(antinode);

                        antinode.x = antinode.x - @as(isize, @intFromFloat(delta_x));
                        antinode.y = antinode.y - @as(isize, @intFromFloat(delta_y));
                    }
                }

                // target
                {
                    var antinode = Point{
                        .x = target.x + @as(isize, @intFromFloat(delta_x)),
                        .y = target.y + @as(isize, @intFromFloat(delta_y)),
                    };

                    if (isInBounds(grid, antinode)) {
                        _ = try antinodes.getOrPut(antinode);
                    }

                    antinode.x = antinode.x + @as(isize, @intFromFloat(delta_x));
                    antinode.y = antinode.y + @as(isize, @intFromFloat(delta_y));
                }
            }
        }
    }
    return antinodes;
}

fn isInBounds(grid: [][]const u8, point: Point) bool {
    // return point.x >= 0 and point.y >= 0 and point.x < @as(isize, @intCast(grid.len)) and point.y < @as(isize, @intCast(grid[0].len));
    if (0 > point.x or point.x >= grid.len) {
        return false;
    }
    const row = @as(usize, @intCast(point.x));
    if (0 > point.y or point.y >= grid[row].len) {
        return false;
    }
    return true;
}

pub fn solve(input: []const u8) !Answer {
    var rows = tokenizeScalar(u8, input, '\n');
    var grid = List([]const u8).init(alloc);
    defer grid.deinit();

    while (rows.next()) |row| {
        try grid.append(row);
    }

    const grid2d = try grid.toOwnedSlice();

    var antennas = try getAntennas(grid2d);
    defer {
        var it = antennas.iterator();
        while (it.next()) |antenna| {
            antenna.value_ptr.*.deinit();
        }
        antennas.deinit();
    }

    var antinodes = try getAntinodes(grid2d, antennas);
    defer antinodes.deinit();
    var with_harmonics = try getAntinodesWithHarmonics(grid2d, antennas);
    defer with_harmonics.deinit();

    return Answer{ .antinodes = antinodes.count(), .with_harmonics = with_harmonics.count() };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.antinodes});
    print("Part 2: {d}\n", .{answer.with_harmonics});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(14, answer.antinodes);
    try std.testing.expectEqual(34, answer.with_harmonics);
}
