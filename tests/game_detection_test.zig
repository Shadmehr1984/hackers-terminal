const std = @import("std");
const game = @import("../src/game.zig");
const mission_data = @import("../src/mission_data.zig");
const MissionSession = @import("../src/mission_state.zig").MissionSession;
const Player = @import("../src/player.zig").Player;
const Mission = @import("../src/mission.zig").Mission;

const TestWriter = struct {
    pub fn writeAll(_: @This(), _: []const u8) error{}!void {}
    pub fn print(_: @This(), comptime _: []const u8, _: anytype) error{}!void {}
};

fn run(writer: anytype, line: []const u8, player: *Player, missions: []Mission, active: *?usize, session: *MissionSession) !void {
    _ = try game.runCommand(writer, line, player, missions, active, session);
}

test "risky actions increase exposure once while safe and invalid actions do not" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    const writer = TestWriter{};

    try run(writer, "accept job-01", &player, &missions, &active, &session);
    try run(writer, "scan wrong-target", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try run(writer, "move service", &player, &missions, &active, &session);

    try run(writer, "scan vault-01.local", &player, &missions, &active, &session);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);

    try run(writer, "connect vault-01.local", &player, &missions, &active, &session);
    try run(writer, "disconnect", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);

    try run(writer, "connect vault-01.local", &player, &missions, &active, &session);
    try run(writer, "brute orion42", &player, &missions, &active, &session);
    try run(writer, "brute orion42", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 20), session.detection_level);

    try run(writer, "buy decryptor", &player, &missions, &active, &session);
    try run(writer, "decrypt wrong-key", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 30), session.detection_level);
    try run(writer, "decrypt midnight", &player, &missions, &active, &session);
    try run(writer, "decrypt midnight", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 40), session.detection_level);

    try run(writer, "analyze ledger.enc", &player, &missions, &active, &session);
    try run(writer, "analyze ledger.enc", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 45), session.detection_level);

    try run(writer, "extract ledger.enc", &player, &missions, &active, &session);
    try std.testing.expect(missions[0].completed);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
}

test "detection compromise fails contract, applies bounded penalty, and allows retry" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};

    const writer = TestWriter{};
    try run(writer, "accept job-01", &player, &missions, &active, &session);
    try run(writer, "move service", &player, &missions, &active, &session);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session);

    var attempt: u8 = 0;
    while (attempt < 6) : (attempt += 1) {
        try run(writer, "brute incorrect", &player, &missions, &active, &session);
    }

    try std.testing.expect(active == null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 200), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);

    try run(writer, "accept job-01", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(?usize, 0), active);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
}

test "compromise penalty never makes player balance negative" {
    var player = Player{ .balance = 20 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    const writer = TestWriter{};

    try run(writer, "accept job-01", &player, &missions, &active, &session);
    try run(writer, "move service", &player, &missions, &active, &session);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session);
    var attempt: u8 = 0;
    while (attempt < 6) : (attempt += 1) {
        try run(writer, "brute incorrect", &player, &missions, &active, &session);
    }
    try std.testing.expectEqual(@as(u32, 0), player.balance);
}

test "extraction can trigger compromise before contract payout" {
    var player = Player{ .balance = 75 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{ .progress = .decrypted, .detection_level = 95, .current_node = "vault" };
    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);

    const writer = TestWriter{};
    try run(writer, "extract ledger.enc", &player, &missions, &active, &session);

    try std.testing.expect(active == null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 25), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
}


test "topology rejects invalid movement without detection and charges every valid traversal" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    const writer = TestWriter{};

    try run(writer, "accept job-01", &player, &missions, &active, &session);
    try std.testing.expectEqualStrings("entry", session.current_node.?);
    try run(writer, "move vault", &player, &missions, &active, &session);
    try std.testing.expectEqualStrings("entry", session.current_node.?);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try run(writer, "move service", &player, &missions, &active, &session);
    try std.testing.expectEqualStrings("service", session.current_node.?);
    try std.testing.expectEqual(@as(u8, 5), session.detection_level);
    try run(writer, "move entry", &player, &missions, &active, &session);
    try run(writer, "move service", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);
}

test "mission actions require their assigned topology locations" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    const writer = TestWriter{};

    try run(writer, "accept job-01", &player, &missions, &active, &session);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try run(writer, "move service", &player, &missions, &active, &session);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);
}
