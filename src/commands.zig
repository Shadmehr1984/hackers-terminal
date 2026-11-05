const std = @import("std");

pub const ParsedCommand = struct {
    name: []const u8,
    argument: []const u8,
};

/// Splits an input line into a command name and its first argument.
/// Additional tokens are intentionally ignored to preserve the current parser behavior.
pub fn parse(line: []const u8) ?ParsedCommand {
    var tokens = std.mem.tokenizeScalar(u8, line, ' ');
    const name = tokens.next() orelse return null;
    const argument = tokens.next() orelse "";
    return .{
        .name = name,
        .argument = argument,
    };
}


test "parse returns null for empty input" {
    const testing = @import("std").testing;
    try testing.expect(parse("") == null);
    try testing.expect(parse("   ") == null);
}

test "parse extracts command without an argument" {
    const testing = @import("std").testing;
    const parsed = parse("help") orelse return error.TestUnexpectedResult;
    try testing.expectEqualStrings("help", parsed.name);
    try testing.expectEqualStrings("", parsed.argument);
}

test "parse extracts command and first argument" {
    const testing = @import("std").testing;
    const parsed = parse("scan vault-01.local") orelse return error.TestUnexpectedResult;
    try testing.expectEqualStrings("scan", parsed.name);
    try testing.expectEqualStrings("vault-01.local", parsed.argument);
}

test "parse ignores additional arguments to preserve current behavior" {
    const testing = @import("std").testing;
    const parsed = parse("scan vault-01.local --verbose") orelse return error.TestUnexpectedResult;
    try testing.expectEqualStrings("scan", parsed.name);
    try testing.expectEqualStrings("vault-01.local", parsed.argument);
}

test "parse skips repeated spaces between tokens" {
    const testing = @import("std").testing;
    const parsed = parse("   connect    vault-01.local   ") orelse return error.TestUnexpectedResult;
    try testing.expectEqualStrings("connect", parsed.name);
    try testing.expectEqualStrings("vault-01.local", parsed.argument);
}
