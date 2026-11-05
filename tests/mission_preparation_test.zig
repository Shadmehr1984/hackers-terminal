const std = @import("std");
const game = @import("../src/game.zig");
const Player = @import("../src/player.zig").Player;
const UtilityEquipment = @import("../src/player.zig").UtilityEquipment;
const Mission = @import("../src/mission.zig").Mission;
const MissionState = @import("../src/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const mission_data = @import("../src/mission_data.zig");
const ModifierId = @import("../src/domain/mission_modifier.zig").ModifierId;

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
    _ = try game.runCommand(capture, line, player, missions, active, session, preparation);
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

test "accept without preparation is rejected by the shared command dispatcher" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "accept job-01", &player, &missions, &active, &session, &preparation);

    try std.testing.expect(active == null);
    try std.testing.expectEqual(MissionState.MissionProgress.inactive, session.progress);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Prepare a contract before launching it") != null);
}

test "board command is separate and leaves legacy missions command intact" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "board", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "CONTRACT BOARD") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Data Recovery") != null);

    capture.clear();
    try run(&capture, "missions", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "AVAILABLE CONTRACTS") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "CONTRACT BOARD") == null);
}

test "modifier command lists choices, selects one, rejects unknown IDs, and clears selection" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "modifier", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "prepare <id> first") != null);

    capture.clear();
    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "heightened-monitoring") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "security-sweep") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "hardened-encryption") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "+$50, +25 XP") != null);

    capture.clear();
    try run(&capture, "modifier security-sweep", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?ModifierId, .security_sweep), preparation.selected_modifier);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "[SELECTED] security-sweep") != null);

    capture.clear();
    try run(&capture, "modifier unknown-id", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?ModifierId, .security_sweep), preparation.selected_modifier);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Unknown modifier") != null);

    capture.clear();
    try run(&capture, "modifier none", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.selected_modifier == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "cleared") != null);
}

test "modifier selection rejects unavailable choices without changing current selection" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    missions[0].allowed_modifiers = &.{.security_sweep};
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "modifier security-sweep", &player, &missions, &active, &session, &preparation);
    try run(&capture, "modifier hardened-encryption", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?ModifierId, .security_sweep), preparation.selected_modifier);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "not available") != null);
}

test "accept snapshots the selected modifier and clears preparation; retry starts without it" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "modifier heightened-monitoring", &player, &missions, &active, &session, &preparation);
    try run(&capture, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?ModifierId, .heightened_monitoring), session.modifier);
    try std.testing.expect(preparation.selected_modifier == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Contract launched") != null);
    capture.clear();
    try run(&capture, "briefing", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Mission modifier: Heightened Monitoring") != null);

    session.reset();
    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(session.modifier == null);
}

test "successful modified contract pays the modifier bonus once alongside optional rewards" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "modifier hardened-encryption", &player, &missions, &active, &session, &preparation);
    try run(&capture, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move service", &player, &missions, &active, &session, &preparation);
    try run(&capture, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(&capture, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(&capture, "brute orion42", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move maintenance", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move service", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move corridor", &player, &missions, &active, &session, &preparation);
    try run(&capture, "move vault", &player, &missions, &active, &session, &preparation);
    try run(&capture, "buy decryptor", &player, &missions, &active, &session, &preparation);
    try run(&capture, "decrypt midnight", &player, &missions, &active, &session, &preparation);
    try run(&capture, "analyze ledger.enc", &player, &missions, &active, &session, &preparation);
    try run(&capture, "extract ledger.enc", &player, &missions, &active, &session, &preparation);

    try std.testing.expect(missions[0].completed);
    try std.testing.expect(active == null);
    try std.testing.expectEqual(@as(u32, 575), player.balance);
    try std.testing.expectEqual(@as(u32, 125), player.xp);
    try std.testing.expectEqual(@as(u32, 2), player.reputation);
    try std.testing.expect(session.modifier == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Optional objective bonus: +$125") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Mission modifier bonus: +$50, +25 XP") != null);

    try run(&capture, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 575), player.balance);
    try std.testing.expectEqual(@as(u32, 125), player.xp);
}

test "hidden objective content and rewards stay absent until discovery" {
    var player = Player{ .xp = 100 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare job-02", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "routing-header") == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Correlate the recovered routing header") == null);
    capture.clear();
    try run(&capture, "board", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "$500-$600") == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "$500-$600") == null);
}

test "inspect command reveals only the matching hidden fictional file objective" {
    var player = Player{ .xp = 100 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "prepare job-02", &player, &missions, &active, &session, &preparation);
    try run(&capture, "accept job-02", &player, &missions, &active, &session, &preparation);
    try run(&capture, "inspect wrong.log", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 0), session.objective_tracker.entries[5].state == .discovered);
    try run(&capture, "inspect routing-header.log", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@import("../src/domain/mission_objectives.zig").ObjectiveState.discovered, session.objective_tracker.stateOf("routing-header").?);
    capture.clear();
    try run(&capture, "objectives", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Correlate the recovered routing header") != null);
}
