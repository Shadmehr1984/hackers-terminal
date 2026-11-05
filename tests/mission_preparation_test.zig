const std = @import("std");
const game = @import("../src/game.zig");
const Player = @import("../src/player.zig").Player;
const UtilityEquipment = @import("../src/player.zig").UtilityEquipment;
const Mission = @import("../src/mission.zig").Mission;
const MissionState = @import("../src/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const mission_data = @import("../src/mission_data.zig");

const Capture = struct {
    buffer: [8192]u8 = undefined,
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

fn run(capture: *Capture, line: []const u8, player: *Player, missions: []Mission, active: *?usize, session: *MissionSession, preparation: *MissionPreparation) !void {
    _ = try game.runCommandWithPreparation(capture, line, player, missions, active, session, preparation);
}

test "preparation reveals contract intel but keeps puzzle clues and answers hidden" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 0), preparation.mission_index);
    try std.testing.expect(active == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Password clue: undiscovered") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "orion42") == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "midnight") == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Cold Storage") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "vault-01.local") != null);
}

test "preparation validates unknown locked and completed contracts" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare missing", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.mission_index == null);
    capture.clear();
    try run(&capture, "prepare job-02", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.mission_index == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "locked") != null);
    player.xp = 100;
    missions[0].completed = true;
    capture.clear();
    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.mission_index == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "already completed") != null);
}

test "loadout selection validates ownership and launches only matching prepared contract" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "loadout silent-boots", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.selected_utility == null);
    try run(&capture, "buy silent-boots", &player, &missions, &active, &session, &preparation);
    try run(&capture, "loadout silent-boots", &player, &missions, &active, &session, &preparation);
    try run(&capture, "accept job-02", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(active == null);
    try std.testing.expectEqual(@as(?usize, 0), preparation.mission_index);
    try run(&capture, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 0), active);
    try std.testing.expect(preparation.mission_index == null);
    try std.testing.expectEqual(@as(?UtilityEquipment, .silent_boots), session.loadout.utility);
    try std.testing.expectEqual(@as(u2, 0), session.loadout.level);
}

test "cancel allows reprepare and active missions cannot be abandoned" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "cancel", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.mission_index == null);
    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "cancel", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 0), active);
    try std.testing.expectEqual(MissionState.MissionProgress.accepted, session.progress);
}

test "active loadout is snapshotted and ignores later persistent equipment changes" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "buy silent-boots", &player, &missions, &active, &session, &preparation);
    try run(&capture, "equip silent-boots", &player, &missions, &active, &session, &preparation);
    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 4), session.loadout.movementDetectionCost());

    player.equipment.setOwned(.signal_scrubber);
    player.equipment.equipped_utility = .signal_scrubber;
    try std.testing.expectEqual(@as(u8, 4), session.loadout.movementDetectionCost());
    try std.testing.expectEqual(@as(u8, 15), session.loadout.incorrectAuthenticationDetectionCost());
}
