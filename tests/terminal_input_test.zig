const std = @import("std");
const terminal_input = @import("../src/application/terminal_input.zig");

test "terminal input accepts the existing 511-byte maximum" {
    var accepted: [terminal_input.max_line_length]u8 = undefined;
    @memset(&accepted, 'x');
    try std.testing.expect(!terminal_input.isOverlong(&accepted));
}

test "terminal input rejects a 512-byte line" {
    var oversized: [terminal_input.buffer_capacity]u8 = undefined;
    @memset(&oversized, 'x');
    try std.testing.expect(terminal_input.isOverlong(&oversized));
}
