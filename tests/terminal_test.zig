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
    const player = Player{};
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    session.detection_level = 25;
    session.current_node = "relay";
    session.traversal_count = 2;
    session.modifier = .security_sweep;
    var capture = Capture{};

    try terminal.printStatus(&capture, player, 0, &missions, 1, 100, session);

    const output = capture.output();
    try std.testing.expect(std.mem.indexOf(u8, output, "Active job:  Cold Storage (job-01)\n  Detection:") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Detection:   25/100 (Noticed)\n  Location:    relay\n  Traversals:  2\n  Modifier:    Security Sweep") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\\n") == null);
}

test "inactive status output uses line breaks" {
    const player = Player{};
    const missions = mission_data.defaultMissions();
    const session = MissionSession{};
    var capture = Capture{};

    try terminal.printStatus(&capture, player, null, &missions, 1, 100, session);

    const output = capture.output();
    try std.testing.expect(std.mem.indexOf(u8, output, "Active job:  none\n  Detection:   inactive") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\\n") == null);
}

test "contract board output shows category rewards status and lock reasons without puzzle intel" {
    const missions = mission_data.defaultMissions();
    var capture = Capture{};
    try terminal.printContractBoard(&capture, &missions, 1, 0, false);
    const output = capture.output();
    try std.testing.expect(std.mem.indexOf(u8, output, "CONTRACT BOARD") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Data Recovery") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "$300-$375 + 100 XP") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "AVAILABLE") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "LOCKED") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Requires level 2") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "orion42") == null);
    try std.testing.expect(std.mem.indexOf(u8, output, "midnight") == null);
}

test "contract board marks incomplete contracts unavailable while another is busy" {
    const missions = mission_data.defaultMissions();
    var capture = Capture{};
    try terminal.printContractBoard(&capture, &missions, 3, 3, true);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "UNAVAILABLE") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Finish or fail the active contract") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "EXCLUSIVE") == null);
}

test "objective output hides undiscovered objectives but retains revealed unavailable ones" {
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    session.markUncompletedOptionalObjectivesUnavailable();
    var capture = Capture{};
    try terminal.printObjectives(&capture, missions[0], session);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "maintenance telemetry signature") == null);

    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    session.markUncompletedOptionalObjectivesUnavailable();
    capture.len = 0;
    try terminal.printObjectives(&capture, missions[0], session);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "[!] [OPTIONAL] Recover the maintenance telemetry signature") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "(+$50)") != null);
}
