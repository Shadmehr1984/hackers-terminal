const std = @import("std");
const game = @import("../src/application/game.zig");
const Player = @import("../src/domain/player.zig").Player;
const Mission = @import("../src/domain/mission.zig").Mission;
const MissionSession = @import("../src/domain/mission_state.zig").MissionSession;
const MissionPreparation = @import("../src/domain/mission_state.zig").MissionPreparation;
const ObjectiveState = @import("../src/domain/mission_objectives.zig").ObjectiveState;
const faction = @import("../src/domain/faction.zig");
const mission_data = @import("../src/catalog/mission_data.zig");

const Capture = struct {
    buffer: [32768]u8 = undefined,
    len: usize = 0,
    fn clear(self: *Capture) void {
        self.len = 0;
    }

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

fn run(
    capture: *Capture,
    line: []const u8,
    player: *Player,
    missions: []Mission,
    active: *?usize,
    session: *MissionSession,
    preparation: *MissionPreparation,
) !void {
    const keep_running = try game.runCommand(capture, line, player, missions, active, session, preparation);
    try std.testing.expect(keep_running);
}

test "Corporate Ghost remains faction-locked until Quiet Exit, then completes its full route" {
    var player = Player{ .balance = 10000, .reputation = 2, .xp = 250 };
    player.equipment.has_decryptor = true;
    var missions = mission_data.defaultMissions();
    missions[0].completed = true;
    missions[1].completed = true;
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try std.testing.expectEqual(
        faction.Standing.hostile,
        faction.playerStanding(.nexus_dynamics, player.reputation, &missions),
    );
    try run(&capture, "prepare job-05", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.mission_index == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Contract access denied") != null);
    capture.clear();
    try run(&capture, "deal intel-job-05", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 10000), player.balance);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Contract access denied") != null);

    // Quiet Exit grants +1 Reputation without changing either Nexus-owned flag.
    capture.clear();
    try run(&capture, "prepare job-03", &player, &missions, &active, &session, &preparation);
    try run(&capture, "accept job-03", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move relay-a", &player, &missions, &active, &session, &preparation);
    try run(&capture, "scan relay-03.local", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move relay-core", &player, &missions, &active, &session, &preparation);
    try run(&capture, "connect relay-03.local", &player, &missions, &active, &session, &preparation);
    try run(&capture, "brute northstar", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move transfer", &player, &missions, &active, &session, &preparation);
    try run(&capture, "decrypt afterhours", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move exit", &player, &missions, &active, &session, &preparation);
    try run(&capture, "extract manifest.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(missions[2].completed);
    try std.testing.expectEqual(@as(u32, 3), player.reputation);
    try std.testing.expectEqual(
        faction.Standing.wary,
        faction.playerStanding(.nexus_dynamics, player.reputation, &missions),
    );
    try std.testing.expect(missions[0].completed);
    try std.testing.expect(missions[1].completed);

    capture.clear();
    try run(&capture, "prepare job-05", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 4), preparation.mission_index);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Corporate Ghost") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "mirror-fragment") == null);
    try run(&capture, "accept job-05", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 4), active);

    try run(&capture, "move gateway", &player, &missions, &active, &session, &preparation);
    try run(&capture, "scan relay-05.local", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move auth-core", &player, &missions, &active, &session, &preparation);
    try run(&capture, "connect relay-05.local", &player, &missions, &active, &session, &preparation);
    try run(&capture, "brute vaultkeeper", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move audit-hub", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move data-vault", &player, &missions, &active, &session, &preparation);
    try run(&capture, "decrypt auditlog", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move mirror-node", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(
        @as(?ObjectiveState, .discovered),
        session.objective_tracker.stateOf("mirror-fragment"),
    );
    try run(&capture, "move data-vault", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move audit-hub", &player, &missions, &active, &session, &preparation);
    try run(&capture, "analyze access-ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "matching objectives completed") != null);
    try std.testing.expectEqual(
        @as(?ObjectiveState, .completed),
        session.objective_tracker.stateOf("verify-trail"),
    );
    try std.testing.expectEqual(
        @as(?ObjectiveState, .completed),
        session.objective_tracker.stateOf("analyze-metadata"),
    );
    try std.testing.expectEqual(
        @as(?ObjectiveState, .completed),
        session.objective_tracker.stateOf("mirror-fragment"),
    );
    try run(&capture, "move data-vault", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move exit-relay", &player, &missions, &active, &session, &preparation);
    try run(&capture, "extract access-ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(missions[4].completed);
    try std.testing.expect(active == null);
    try std.testing.expectEqual(@as(u32, 12200), player.balance);
    try std.testing.expectEqual(@as(u32, 725), player.xp);
    try std.testing.expectEqual(@as(u32, 5), player.reputation);
}
