const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;

const tokenizeScalar = std.mem.tokenizeScalar;
const splitScalar = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const contains = std.mem.containsAtLeast;
const eql = std.mem.eql;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Answer = struct {
    middle_sum: i32,
    reordered_sum: i32,
};

pub fn solve(input: []const u8) !Answer {
    var rows = splitScalar(u8, input, '\n');

    // key is a page number and value is a
    // list of pages to be printed before it
    var rules = Map(i32, List(i32)).init(alloc);
    var pages = List([]i32).init(alloc);
    defer {
        var iter = rules.iterator();
        while (iter.next()) |rule| {
            rule.value_ptr.deinit();
        }
        rules.deinit();
        pages.deinit();
    }

    var parse_rules = true;
    while (rows.next()) |row| {
        if (eql(u8, row, "")) {
            parse_rules = false;
            continue;
        }

        if (parse_rules) {
            var rule_pair = tokenizeScalar(u8, row, '|');
            const rule = try rules.getOrPut(try parseInt(i32, rule_pair.next().?, 10));
            if (!rule.found_existing) {
                rule.value_ptr.* = List(i32).init(alloc);
            }
            try rule.value_ptr.*.append(try parseInt(i32, rule_pair.next().?, 10));
        } else {
            var page = List(i32).init(alloc);
            var page_list = tokenizeScalar(u8, row, ',');
            while (page_list.next()) |list| {
                try page.append(try parseInt(i32, list, 10));
            }
            try pages.append(try page.toOwnedSlice());
        }
    }

    var middle_sum: i32 = 0;
    var reordered_sum: i32 = 0;

    var wrong_order = false;
    for (pages.items) |page| {
        var index: usize = page.len - 1;
        while (index > 0) : (index -= 1) {
            var page_rule = rules.get(page[index]) orelse continue;

            // check the rest of the pages
            var remaining: usize = 0;
            while (remaining < page[0..index].len) {
                if (contains(i32, page_rule.items, 1, &[_]i32{page[remaining]})) {
                    // re-order the wrong page
                    const element = page[remaining];
                    page[remaining] = page[index];
                    page[index] = element;
                    wrong_order = true;

                    if (rules.get(element)) |next_rule| {
                        page_rule = next_rule;
                    }

                    continue;
                }
                remaining += 1;
            }
        }
        if (wrong_order) {
            reordered_sum += page[(page.len - 1) / 2];
            wrong_order = false;
        } else {
            // middle page number
            middle_sum += page[(page.len - 1) / 2];
        }
    }
    return Answer{ .middle_sum = middle_sum, .reordered_sum = reordered_sum };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.middle_sum});
    print("Part 2: {d}\n", .{answer.reordered_sum});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(143, answer.middle_sum);
    try std.testing.expectEqual(123, answer.reordered_sum);
}
