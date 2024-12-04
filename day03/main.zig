const std = @import("std");
const List = std.ArrayList;

const splitScalar = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const Answer = struct { result: u32 };

const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "mul", .keyword_mul },
        .{ "do", .keyword_do },
        .{ "don't", .keyword_dont },
    });

    pub fn getKeyword(bytes: []const u8) ?Tag {
        return keywords.get(bytes);
    }

    pub const Tag = enum {
        invalid,
        identifier,
        comma,
        l_paren,
        r_paren,
        number_literal,
        eof,
        keyword_mul,
        keyword_do,
        keyword_dont,
    };
};

const Tokenizer = struct {
    buffer: [:0]const u8,
    index: usize,

    pub fn init(buffer: [:0]const u8) Tokenizer {
        return .{
            .buffer = buffer,
            .index = 0,
        };
    }

    pub fn dump(self: *Tokenizer, token: *const Token) void {
        print("{s} \"{s}\"\n", .{ @tagName(token.tag), self.buffer[token.loc.start..token.loc.end] });
    }

    pub fn next(self: *Tokenizer) Token {
        var state: State = .start;
        var result: Token = .{
            .tag = .eof,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };
        while (true) : (self.index += 1) {
            const c = self.buffer[self.index];
            switch (state) {
                .start => switch (c) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            result.tag = .invalid;
                            result.loc.start = self.index;
                            self.index += 1;
                            result.loc.end = self.index;
                            return result;
                        }
                        break;
                    },
                    'm', 'u', 'l', 'd', 'o', 'n', '\'', 't' => {
                        state = .identifier;
                        result.tag = .identifier;
                    },
                    ',' => {
                        result.tag = .comma;
                        self.index += 1;
                        break;
                    },
                    '(' => {
                        result.tag = .l_paren;
                        self.index += 1;
                        break;
                    },
                    ')' => {
                        result.tag = .r_paren;
                        self.index += 1;
                        break;
                    },
                    '0'...'9' => {
                        state = .int;
                        result.tag = .number_literal;
                    },
                    else => {
                        result.tag = .invalid;
                        result.loc.end = self.index;
                        self.index += 1;
                        return result;
                    },
                },
                .identifier => switch (c) {
                    'm', 'u', 'l', 'd', 'o', 'n', '\'', 't' => {},
                    else => {
                        if (Token.getKeyword(self.buffer[result.loc.start..self.index])) |tag| {
                            result.tag = tag;
                        }
                        break;
                    },
                },
                .int => switch (c) {
                    '0'...'9' => {},
                    else => break,
                },
            }
        }
        if (result.tag == .eof) {
            result.loc.start = self.index;
        }
        result.loc.end = self.index;
        return result;
    }

    pub fn span(self: *Tokenizer, lhs_token: Token, rhs_token: Token) []const u8 {
        return self.buffer[lhs_token.loc.start..rhs_token.loc.end];
    }

    const State = enum {
        start,
        int,
        identifier,
    };
};

pub fn solve(input: []const u8) !Answer {
    // create null terminated slice
    const buffer = try alloc.dupeZ(u8, input);
    var tokenizer = Tokenizer.init(buffer);
    var tokens = List(Token).init(alloc);
    defer tokens.deinit();

    var result_sum: u32 = 0;
    root: while (true) {
        const token = tokenizer.next();
        switch (token.tag) {
            .eof => break,
            .keyword_do => {
                tokenizer.dump(&token);
            },
            .keyword_dont => {
                tokenizer.dump(&token);
            },
            .keyword_mul => {
                while (true) {
                    const lparen = tokenizer.next();
                    switch (lparen.tag) {
                        .l_paren => {
                            while (true) {
                                const integer = tokenizer.next();
                                switch (integer.tag) {
                                    .number_literal => {},
                                    .comma => {
                                        while (true) {
                                            const rparen = tokenizer.next();
                                            switch (rparen.tag) {
                                                .number_literal => continue,
                                                .r_paren => {
                                                    const span = tokenizer.span(token, rparen);
                                                    // print("{s}\n", .{span});
                                                    var numbers = splitScalar(u8, span[4 .. span.len - 1], ',');
                                                    const lhs_number = numbers.next() orelse break;
                                                    const rhs_number = numbers.next() orelse break;
                                                    const lhs = try parseInt(i32, lhs_number, 10);
                                                    const rhs = try parseInt(i32, rhs_number, 10);
                                                    result_sum += @as(u32, @intCast(lhs * rhs));
                                                    continue :root;
                                                },
                                                else => continue :root,
                                            }
                                        }
                                    },
                                    else => continue :root,
                                }
                            }
                        },
                        else => continue :root,
                    }
                }
            },
            else => {},
        }
    }
    return Answer{ .result = result_sum };
}

pub fn main() !void {
    const answer = try solve(@embedFile("input.txt"));
    print("Part 1: {d}\n", .{answer.result});
}

test "test input" {
    const answer = try solve(@embedFile("test.txt"));
    try std.testing.expectEqual(161, answer.result);
}
