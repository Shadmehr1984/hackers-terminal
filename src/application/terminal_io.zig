const std = @import("std");
const terminal_input = @import("terminal_input.zig");

/// Immediate-output adapter: preserve the command layer's synchronous writer
/// failure semantics while using the Zig 0.17 std.Io file API.
pub const ProcessWriter = struct {
    io: std.Io,
    file: std.Io.File,
    allocator: std.mem.Allocator,

    pub fn writeAll(self: *const ProcessWriter, bytes: []const u8) !void {
        try self.file.writeStreamingAll(self.io, bytes);
    }

    pub fn print(self: *const ProcessWriter, comptime format: []const u8, args: anytype) !void {
        const output = try std.fmt.allocPrint(self.allocator, format, args);
        defer self.allocator.free(output);
        try self.writeAll(output);
    }
};

/// Reads one command line, preserving the historical 511-byte limit.
///
/// Oversized lines are drained through their delimiter before returning
/// CommandDiscarded, so the following command remains aligned.
pub fn readLine(reader: *std.Io.Reader, output: anytype) !?[]u8 {
    const maybe_line = reader.takeDelimiter('\n') catch |err| switch (err) {
        error.StreamTooLong => {
            _ = reader.discardDelimiterInclusive('\n') catch |drain_err| switch (drain_err) {
                error.EndOfStream => 0,
                else => return drain_err,
            };
            try output.writeAll("Input too long. Command discarded.\n");
            return error.CommandDiscarded;
        },
        else => return err,
    };

    if (maybe_line) |line| {
        if (terminal_input.isOverlong(line)) {
            try output.writeAll("Input too long. Command discarded.\n");
            return error.CommandDiscarded;
        }
    }

    return maybe_line;
}
