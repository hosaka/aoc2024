const std = @import("std");
const List = std.ArrayList;

const splitScalar = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const concat = std.mem.concat;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Answer = struct {
    safe: u32,
    tolerated: u32,
};

pub fn isSafe(levels: []i32) bool {
    if (levels.len == 0) {
        return false;
    }
    // slide window in pairs, advancing by one
    var it = std.mem.window(i32, levels, 2, 1);
    const first = it.first();
    const decreasing = first[0] - first[1] > 0;
    it.reset(); // rewind the iterator

    while (it.next()) |slice| {
        const lhs: i32 = slice[0];
        const rhs: i32 = slice[1];
        if (decreasing) {
            if (lhs <= rhs) return false;
            if (lhs - rhs < 1 or lhs - rhs > 3) return false;
        } else {
            if (rhs <= lhs) return false;
            if (rhs - lhs < 1 or rhs - lhs > 3) return false;
        }
    }
    return true;
}

pub fn solve(input: []const u8) !Answer {
    var rows = splitScalar(u8, input, '\n');

    // PART 1

    // determine how many reports are safe
    var safe_reports: u32 = 0;
    var tolerated_reports: u32 = 0;
    var unsafe_reports = List([]i32).init(alloc);
    defer unsafe_reports.deinit();

    while (rows.next()) |row| {
        var levels = splitScalar(u8, row, ' ');

        var report = List(i32).init(alloc);
        defer report.deinit();

        while (levels.next()) |level| {
            const value = parseInt(i32, level, 10) catch continue;
            report.append(value) catch continue;
        }

        if (isSafe(report.items)) {
            safe_reports += 1;
        } else {
            try unsafe_reports.append(try alloc.dupe(i32, report.items));
        }
    }

    // PART 2

    // determine how many unsaafe reports can be tolerated
    for (unsafe_reports.items) |report| {
        var index: usize = 0;
        while (index < report.len) : (index += 1) {
            // mutate report by removing one level
            const mutated_report = concat(
                alloc,
                i32,
                &[_][]const i32{ report[0..index], report[index + 1 ..] },
            ) catch report;
            defer alloc.free(mutated_report);

            if (isSafe(mutated_report)) {
                tolerated_reports += 1;
                break;
            }
        }
    }

    return Answer{ .safe = safe_reports, .tolerated = safe_reports + tolerated_reports };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.safe});
    print("Part 2: {d}\n", .{answer.tolerated});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(2, answer.safe);
    try std.testing.expectEqual(4, answer.tolerated);
}
