const std = @import("std");
const terminal_input = @import("../src/application/terminal_input.zig");

test "terminal input accepts the existing 511-byte maximum" {
    const accepted: [terminal_input.max_line_length]u8 = @splat('x');
    try std.testing.expect(!terminal_input.isOverlong(&accepted));
}

test "terminal input rejects a 512-byte line" {
    const oversized: [terminal_input.buffer_capacity]u8 = @splat('x');
    try std.testing.expect(terminal_input.isOverlong(&oversized));
}
