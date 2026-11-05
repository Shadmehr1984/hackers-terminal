const std = @import("std");
const terminal = @import("../src/terminal.zig");
const Player = @import("../src/player.zig").Player;
const MissionSession = @import("../src/mission_state.zig").MissionSession;
const mission_data = @import("../src/mission_data.zig");

const Capture = struct {
    buffer: [4096]u8 = undefined,
    len: usize = 0,

    fn output(self: *const Capture) []const u8 {
        return self.buffer[0..self.len];
    }

    pub fn writeAll(self: *@This(), bytes: []const u8) error{NoSpaceLeft}!void {
        if (bytes.len > self.buffer.len - self.len) return error.NoSpaceLeft;
        @memcpy(self.buffer[self.len .. self.len + bytes.len], bytes);
        self.len += bytes.len;
    }

    pub fn print(self: *@This(), comptime format: []const u8, args: anytype) !void {
        const written = try std.fmt.bufPrint(self.buffer[self.len..], format, args);
        self.len += written.len;
    }
};

test "active status output uses line breaks and includes location" {
    var player = Player{};
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    session.detection_level = 25;
    session.current_node = "relay";
    session.traversal_count = 2;
    var capture = Capture{};

    try terminal.printStatus(&capture, player, 0, &missions, 1, 100, session);

    const output = capture.output();
    try std.testing.expect(std.mem.indexOf(u8, output, "Active job:  Cold Storage (job-01)\n  Detection:") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Detection:   25/100 (Noticed)\n  Location:    relay\n  Traversals:  2") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\\n") == null);
}

test "inactive status output uses line breaks" {
    var player = Player{};
    const missions = mission_data.defaultMissions();
    const session = MissionSession{};
    var capture = Capture{};

    try terminal.printStatus(&capture, player, null, &missions, 1, 100, session);

    const output = capture.output();
    try std.testing.expect(std.mem.indexOf(u8, output, "Active job:  none\n  Detection:   inactive") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\\n") == null);
}
