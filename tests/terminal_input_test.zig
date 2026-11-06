const std = @import("std");
const terminal_input = @import("../src/application/terminal_input.zig");

test "terminal input accepts the existing 511-byte maximum" {
    const accepted = [_]u8{'x'} ** terminal_input.max_line_length;
    try std.testing.expect(!terminal_input.isOverlong(&accepted));
}

test "terminal input rejects a 512-byte line" {
    const oversized = [_]u8{'x'} ** terminal_input.buffer_capacity;
    try std.testing.expect(terminal_input.isOverlong(&oversized));
}
