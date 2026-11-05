const std = @import("std");
const Player = @import("../src/player.zig").Player;
const UtilityEquipment = @import("../src/player.zig").UtilityEquipment;
const shop = @import("../src/shop.zig");
const save = @import("../src/save.zig");
const game = @import("../src/game.zig");
const mission_data = @import("../src/mission_data.zig");
const MissionSession = @import("../src/mission_state.zig").MissionSession;
const Mission = @import("../src/mission.zig").Mission;

const TestWriter = struct {
    pub fn writeAll(_: @This(), _: []const u8) error{}!void {}
    pub fn print(_: @This(), comptime _: []const u8, _: anytype) error{}!void {}
};

fn run(line: []const u8, player: *Player, missions: []Mission, active: *?usize, session: *MissionSession) !void {
    _ = try game.runCommand(TestWriter{}, line, player, missions, active, session);
}

test "utility purchase equip and upgrades enforce ownership and funds" {
    var player = Player{};
    const writer = TestWriter{};
    try shop.equipItem(writer, &player, "silent-boots");
    try std.testing.expect(player.equipment.equipped_utility == null);

    try shop.buyItem(writer, &player, "silent-boots");
    try std.testing.expect(player.equipment.owns(.silent_boots));
    try std.testing.expectEqual(@as(u32, 150), player.balance);
    try shop.buyItem(writer, &player, "silent-boots");
    try std.testing.expectEqual(@as(u32, 150), player.balance);

    try shop.equipItem(writer, &player, "silent-boots");
    try std.testing.expectEqual(@as(u8, 4), player.equipment.movementDetectionCost());
    try shop.upgradeItem(writer, &player, "silent-boots");
    try std.testing.expectEqual(@as(u2, 1), player.equipment.level(.silent_boots));
    try std.testing.expectEqual(@as(u8, 3), player.equipment.movementDetectionCost());
    try std.testing.expectEqual(@as(u32, 0), player.balance);

    try shop.upgradeItem(writer, &player, "silent-boots");
    try std.testing.expectEqual(@as(u2, 1), player.equipment.level(.silent_boots));
    try shop.equipItem(writer, &player, "signal-scrubber");
    try std.testing.expect(player.equipment.equipped_utility == .silent_boots);
}

test "signal scrubber modifiers apply only while equipped" {
    var equipment = @import("../src/player.zig").Equipment{};
    try std.testing.expectEqual(@as(u8, 15), equipment.incorrectAuthenticationDetectionCost());
    equipment.setOwned(.signal_scrubber);
    equipment.equipped_utility = .signal_scrubber;
    try std.testing.expectEqual(@as(u8, 12), equipment.incorrectAuthenticationDetectionCost());
    equipment.setLevel(.signal_scrubber, 1);
    try std.testing.expectEqual(@as(u8, 9), equipment.incorrectAuthenticationDetectionCost());
    equipment.setLevel(.signal_scrubber, 2);
    try std.testing.expectEqual(@as(u8, 6), equipment.incorrectAuthenticationDetectionCost());
    equipment.equipped_utility = .silent_boots;
    try std.testing.expectEqual(@as(u8, 15), equipment.incorrectAuthenticationDetectionCost());
}

test "Silent Boots reduce movement Detection and Signal Scrubber reduces failed authentication" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    try run("buy silent-boots", &player, &missions, &active, &session);
    try run("equip silent-boots", &player, &missions, &active, &session);
    try run("accept job-01", &player, &missions, &active, &session);
    try run("move service", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 4), session.detection_level);

    player.balance = 100;
    try run("buy signal-scrubber", &player, &missions, &active, &session);
    try run("equip signal-scrubber", &player, &missions, &active, &session);
    try run("scan vault-01.local", &player, &missions, &active, &session);
    try run("connect vault-01.local", &player, &missions, &active, &session);
    try run("brute incorrect", &player, &missions, &active, &session);
    try std.testing.expectEqual(@as(u8, 26), session.detection_level);
}

test "V3 save restores utilities while V2 V1 and legacy saves migrate without utilities" {
    var missions = mission_data.defaultMissions();
    var player = Player{};
    const v3 =
        "HACKERS_TERMINAL_SAVE_V3\n" ++
        "777\n3\n250\n1\n3\n2\n2\n1\n-1\n0\n0\n0\n";
    _ = save.loadGameFromBytes(v3, &player, &missions);
    try std.testing.expectEqual(@as(u32, 777), player.balance);
    try std.testing.expect(player.equipment.has_decryptor);
    try std.testing.expect(player.equipment.owns(.silent_boots));
    try std.testing.expect(player.equipment.owns(.signal_scrubber));
    try std.testing.expect(player.equipment.equipped_utility == .signal_scrubber);
    try std.testing.expectEqual(@as(u2, 2), player.equipment.level(.silent_boots));
    try std.testing.expectEqual(@as(u2, 1), player.equipment.level(.signal_scrubber));

    const old_saves = [_][]const u8{
        "HACKERS_TERMINAL_SAVE_V2\n500\n2\n100\n1\n-1\n0\n0\n0\n",
        "HACKERS_TERMINAL_SAVE_V1\n400\n1\n1\n-1\n1\n0\n0\n",
        "350\n4\n1\n0\n1\n0\n",
    };
    for (old_saves) |data| {
        var old_player = Player{};
        var old_missions = mission_data.defaultMissions();
        _ = save.loadGameFromBytes(data, &old_player, &old_missions);
        try std.testing.expect(old_player.equipment.has_decryptor);
        try std.testing.expectEqual(@as(u2, 0), old_player.equipment.owned_utilities);
        try std.testing.expect(old_player.equipment.equipped_utility == null);
    }
    var v1_player = Player{};
    var v1_missions = mission_data.defaultMissions();
    _ = save.loadGameFromBytes(old_saves[1], &v1_player, &v1_missions);
    try std.testing.expectEqual(v1_missions[0].xp_reward, v1_player.xp);
}

test "invalid V3 equipment references are normalized" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    const data = "HACKERS_TERMINAL_SAVE_V3\n100\n0\n0\n0\n0\n1\n2\n2\n-1\n0\n0\n0\n";
    _ = save.loadGameFromBytes(data, &player, &missions);
    try std.testing.expect(player.equipment.equipped_utility == null);
    try std.testing.expectEqual(@as(u2, 0), player.equipment.silent_boots_level);
    try std.testing.expectEqual(@as(u2, 0), player.equipment.signal_scrubber_level);
}

test "equipment enum catalog remains stable" {
    try std.testing.expectEqual(@as(u8, 0), @intFromEnum(UtilityEquipment.silent_boots));
    try std.testing.expectEqual(@as(u8, 1), @intFromEnum(UtilityEquipment.signal_scrubber));
}
