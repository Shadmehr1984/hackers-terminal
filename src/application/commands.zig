const std = @import("std");

/// Contains the parsed command name and its optional first argument.
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
