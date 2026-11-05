const std = @import("std");
const commands = @import("../src/commands.zig");

test "parse returns null for empty input" {
    try std.testing.expect(commands.parse("") == null);
    try std.testing.expect(commands.parse("   ") == null);
}

test "parse extracts command without an argument" {
    const parsed = commands.parse("help") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("help", parsed.name);
    try std.testing.expectEqualStrings("", parsed.argument);
}

test "parse extracts command and first argument" {
    const parsed = commands.parse("scan vault-01.local") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("scan", parsed.name);
    try std.testing.expectEqualStrings("vault-01.local", parsed.argument);
}

test "parse ignores additional arguments to preserve current behavior" {
    const parsed = commands.parse("scan vault-01.local --verbose") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("scan", parsed.name);
    try std.testing.expectEqualStrings("vault-01.local", parsed.argument);
}

test "parse skips repeated spaces between tokens" {
    const parsed = commands.parse("   connect    vault-01.local   ") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("connect", parsed.name);
    try std.testing.expectEqualStrings("vault-01.local", parsed.argument);
}
