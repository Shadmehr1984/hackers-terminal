const std = @import("std");
const game = @import("../src/game.zig");
const mission_data = @import("../src/mission_data.zig");
const MissionSession = @import("../src/mission_state.zig").MissionSession;
const Player = @import("../src/player.zig").Player;

fn run(line: []const u8, player: *Player, missions: []@import("../src/mission.zig").Mission, active: *?usize, session: *MissionSession) !void {
    _ = try game.runCommand(std.io.null_writer, line, player, missions, active, session);
}

test "risky actions increase exposure once while safe and invalid actions do not" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};

    try run("accept job-01", &player, &missions, &active, &session);
    try run("scan wrong-target", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);

    try run("scan vault-01.local", &player, &missions, &active, &session);
    try run("scan vault-01.local", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 10), session.detection_level);

    try run("connect vault-01.local", &player, &missions, &active, &session);
    try run("disconnect", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 10), session.detection_level);

    try run("connect vault-01.local", &player, &missions, &active, &session);
    try run("brute orion42", &player, &missions, &active, &session);
    try run("brute orion42", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);

    try run("buy decryptor", &player, &missions, &active, &session);
    try run("decrypt midnight", &player, &missions, &active, &session);
    try run("decrypt midnight", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 25), session.detection_level);

    try run("analyze ledger.enc", &player, &missions, &active, &session);
    try run("analyze ledger.enc", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 30), session.detection_level);

    try run("extract ledger.enc", &player, &missions, &active, &session);
    try std.testing.expect(missions[0].completed);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
}

test "detection compromise fails contract, applies bounded penalty, and allows retry" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};

    try run("accept job-01", &player, &missions, &active, &session);
    try run("scan vault-01.local", &player, &missions, &active, &session);
    try run("connect vault-01.local", &player, &missions, &active, &session);

    var attempt: u8 = 0;
    while (attempt < 6) : (attempt += 1) {
        try run("brute incorrect", &player, &missions, &active, &session);
    }

    try std.testing.expect(active == null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 200), player.balance);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);

    try run("accept job-01", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(?usize, 0), active);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
}

test "compromise penalty never makes player balance negative" {
    var player = Player{ .balance = 20 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};

    try run("accept job-01", &player, &missions, &active, &session);
    try run("scan vault-01.local", &player, &missions, &active, &session);
    try run("connect vault-01.local", &player, &missions, &active, &session);
    var attempt: u8 = 0;
    while (attempt < 6) : (attempt += 1) {
        try run("brute incorrect", &player, &missions, &active, &session);
    }
    try std.testing.expectEqual(@as(u32, 0), player.balance);
}
