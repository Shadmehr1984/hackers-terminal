const std = @import("std");
const terminal_io = @import("terminal_io");

const MemoryReader = struct {
    reader: std.Io.Reader,
    input: []const u8,
    offset: usize = 0,
    fail_after: ?usize = null,

    fn init(input: []const u8, buffer: []u8) MemoryReader {
        return .{
            .reader = .{
                .vtable = &.{ .stream = stream },
                .buffer = buffer,
                .seek = 0,
                .end = 0,
            },
            .input = input,
        };
    }

    fn stream(reader: *std.Io.Reader, writer: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
        const self: *MemoryReader = @fieldParentPtr("reader", reader);
        const remaining = self.input[self.offset..];
        if (remaining.len == 0) return error.EndOfStream;

        var count = @min(remaining.len, @backingInt(limit));
        if (self.fail_after) |fail_after| {
            if (self.offset >= fail_after) return error.ReadFailed;
            count = @min(count, fail_after - self.offset);
        }
        try writer.writeAll(remaining[0..count]);
        self.offset += count;
        return count;
    }
};

const CaptureWriter = struct {
    bytes: [128]u8 = undefined,
    len: usize = 0,
    fail: bool = false,

    pub fn writeAll(self: *CaptureWriter, bytes: []const u8) !void {
        if (self.fail) return error.WriteFailed;
        if (bytes.len > self.bytes.len - self.len) return error.WriteFailed;
        @memcpy(self.bytes[self.len..][0..bytes.len], bytes);
        self.len += bytes.len;
    }
};

test "511-byte command is accepted and the next line remains readable" {
    var input: [517]u8 = undefined;
    @memset(input[0..511], 'x');
    input[511] = '\n';
    @memcpy(input[512..], "exit\n");

    var buffer: [512]u8 = undefined;
    var reader = MemoryReader.init(&input, &buffer);
    var output = CaptureWriter{};

    const line = (try terminal_io.readLine(&reader.reader, &output)) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(usize, 511), line.len);
    try std.testing.expectEqualStrings("exit", (try terminal_io.readLine(&reader.reader, &output)).?);
    try std.testing.expect((try terminal_io.readLine(&reader.reader, &output)) == null);
    try std.testing.expectEqual(@as(usize, 0), output.len);
}

test "oversized line is drained before the following command" {
    var input: [518]u8 = undefined;
    @memset(input[0..512], 'x');
    input[512] = '\n';
    @memcpy(input[513..], "exit\n");

    var buffer: [512]u8 = undefined;
    var reader = MemoryReader.init(&input, &buffer);
    var output = CaptureWriter{};

    try std.testing.expectError(error.CommandDiscarded, terminal_io.readLine(&reader.reader, &output));
    try std.testing.expectEqualStrings("Input too long. Command discarded.\n", output.bytes[0..output.len]);
    try std.testing.expectEqualStrings("exit", (try terminal_io.readLine(&reader.reader, &output)).?);
    try std.testing.expect((try terminal_io.readLine(&reader.reader, &output)) == null);
}

test "read failure while draining an oversized line propagates" {
    var input: [518]u8 = undefined;
    @memset(input[0..512], 'x');
    input[512] = '\n';
    @memcpy(input[513..], "exit\n");

    var buffer: [512]u8 = undefined;
    var reader = MemoryReader.init(&input, &buffer);
    reader.fail_after = 514;
    var output = CaptureWriter{};

    try std.testing.expectError(error.ReadFailed, terminal_io.readLine(&reader.reader, &output));
}

test "output failure while reporting an oversized line propagates" {
    var input: [512]u8 = undefined;
    @memset(&input, 'x');

    var buffer: [512]u8 = undefined;
    var reader = MemoryReader.init(&input, &buffer);
    var output = CaptureWriter{ .fail = true };

    try std.testing.expectError(error.WriteFailed, terminal_io.readLine(&reader.reader, &output));
}

test "511-byte unterminated final line is returned before EOF" {
    var input: [511]u8 = undefined;
    @memset(&input, 'x');

    var buffer: [512]u8 = undefined;
    var reader = MemoryReader.init(&input, &buffer);
    var output = CaptureWriter{};

    const line = (try terminal_io.readLine(&reader.reader, &output)) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(usize, 511), line.len);
    try std.testing.expect((try terminal_io.readLine(&reader.reader, &output)) == null);
}

test "512-byte unterminated final line is rejected" {
    var input: [512]u8 = undefined;
    @memset(&input, 'x');

    var buffer: [512]u8 = undefined;
    var reader = MemoryReader.init(&input, &buffer);
    var output = CaptureWriter{};

    try std.testing.expectError(error.CommandDiscarded, terminal_io.readLine(&reader.reader, &output));
    try std.testing.expect((try terminal_io.readLine(&reader.reader, &output)) == null);
}

test "process stream adapters construct with std.Io" {
    var input_buffer: [16]u8 = undefined;
    var stdin = std.Io.File.stdin().readerStreaming(std.testing.io, &input_buffer);
    _ = &stdin;

    var stdout = terminal_io.ProcessWriter{
        .io = std.testing.io,
        .file = std.Io.File.stdout(),
        .allocator = std.testing.allocator,
    };
    try stdout.writeAll("");
    try stdout.print("", .{});
}
