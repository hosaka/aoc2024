const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;

const tokenizeScalar = std.mem.tokenizeScalar;
const splitScalar = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const allocPrint = std.fmt.allocPrint;
const print = std.debug.print;
const concat = std.mem.concat;
const eql = std.mem.eql;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Answer = struct {
    calibration: u64,
    with_concat: u64,
};

fn isValidCalibration(expected: u64, operands: []u64, current: u64, index: usize) bool {
    if (index >= operands.len - 1) {
        return expected == current;
    }
    const next_index = index + 1;
    const sum_valid = isValidCalibration(expected, operands, current + operands[next_index], next_index);
    const mult_valid = isValidCalibration(expected, operands, current * operands[next_index], next_index);

    return sum_valid or mult_valid;
}

fn isValidCalibrationWithConcat(expected: u64, operands: []u64, current: u64, index: usize) !bool {
    if (index >= operands.len - 1) {
        return expected == current;
    }
    const next_index = index + 1;
    const lhs = try allocPrint(alloc, "{d}", .{current});
    const rhs = try allocPrint(alloc, "{d}", .{operands[next_index]});
    const concat_str = try concat(alloc, u8, &[_][]const u8{ lhs, rhs });
    const concat_num = try parseInt(u64, concat_str, 10);

    const sum_valid = try isValidCalibrationWithConcat(expected, operands, current + operands[next_index], next_index);
    const mult_valid = try isValidCalibrationWithConcat(expected, operands, current * operands[next_index], next_index);
    const concat_valid = try isValidCalibrationWithConcat(expected, operands, concat_num, next_index);

    return sum_valid or mult_valid or concat_valid;
}

pub fn solve(input: []const u8) !Answer {
    var rows = tokenizeScalar(u8, input, '\n');
    var equations = Map(u64, []u64).init(alloc);
    defer equations.deinit();

    while (rows.next()) |row| {
        var line = List(u64).init(alloc);
        defer line.deinit();

        var split = splitScalar(u8, row, ':');
        const value = split.next().?;
        const equation = try equations.getOrPut(try parseInt(u64, value, 10));

        var operands = tokenizeScalar(u8, split.next().?, ' ');
        while (operands.next()) |operand| {
            try line.append(try parseInt(u64, operand, 10));
        }

        equation.value_ptr.* = try line.toOwnedSlice();
    }

    var it = equations.iterator();
    var calibration: u64 = 0;
    var with_concat: u64 = 0;
    while (it.next()) |equation| {
        const expected = equation.key_ptr.*;
        const operands = equation.value_ptr.*;

        if (isValidCalibration(expected, operands, operands[0], 0)) {
            calibration += expected;
        }
        if (try isValidCalibrationWithConcat(expected, operands, operands[0], 0)) {
            with_concat += expected;
        }
    }
    return Answer{ .calibration = calibration, .with_concat = with_concat };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.calibration});
    print("Part 2: {d}\n", .{answer.with_concat});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(3749, answer.calibration);
    try std.testing.expectEqual(11387, answer.with_concat);
}
