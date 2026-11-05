const std = @import("std");
const Player = @import("../src/player.zig").Player;
const UtilityEquipment = @import("../src/player.zig").UtilityEquipment;
const shop = @import("../src/shop.zig");
const save = @import("../src/save.zig");
const game = @import("../src/game.zig");
const mission_data = @import("../src/mission_data.zig");
const MissionState = @import("../src/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const Mission = @import("../src/mission.zig").Mission;

const TestWriter = struct {
    pub fn writeAll(_: @This(), _: []const u8) error{}!void {}
    pub fn print(_: @This(), comptime _: []const u8, _: anytype) error{}!void {}
};

fn run(line: []const u8, player: *Player, missions: []Mission, active: *?usize, session: *MissionSession, preparation: *MissionPreparation) !void {
    _ = try game.runCommand(TestWriter{}, line, player, missions, active, session, preparation);
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
    player.balance = 250;
    try shop.upgradeItem(writer, &player, "silent-boots");
    try std.testing.expectEqual(@as(u2, 2), player.equipment.level(.silent_boots));
    try std.testing.expectEqual(@as(u8, 2), player.equipment.movementDetectionCost());
    try std.testing.expectEqual(@as(u32, 0), player.balance);
    player.balance = 1000;
    try shop.upgradeItem(writer, &player, "silent-boots");
    try std.testing.expectEqual(@as(u32, 1000), player.balance);
    try shop.equipItem(writer, &player, "signal-scrubber");
    try std.testing.expect(player.equipment.isEquipped(.silent_boots));
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

test "equipment and mission loadout share the same Detection cost profiles" {
    const levels = [_]u2{ 0, 1, 2 };
    const movement_costs = [_]u8{ 4, 3, 2 };
    const authentication_costs = [_]u8{ 12, 9, 6 };

    for (levels, 0..) |level, index| {
        try std.testing.expectEqual(movement_costs[index], UtilityEquipment.silent_boots.movementDetectionCost(level));
        try std.testing.expectEqual(authentication_costs[index], UtilityEquipment.signal_scrubber.incorrectAuthenticationDetectionCost(level));

        var equipment = @import("../src/player.zig").Equipment{};
        equipment.setOwned(.silent_boots);
        equipment.equipped_utility = .silent_boots;
        equipment.setLevel(.silent_boots, level);
        const movement_loadout = MissionState.MissionLoadout{ .utility = .silent_boots, .level = level };
        try std.testing.expectEqual(movement_loadout.movementDetectionCost(), equipment.movementDetectionCost());
        try std.testing.expectEqual(movement_costs[index], equipment.movementDetectionCost());

        equipment.setOwned(.signal_scrubber);
        equipment.equipped_utility = .signal_scrubber;
        equipment.setLevel(.signal_scrubber, level);
        const authentication_loadout = MissionState.MissionLoadout{ .utility = .signal_scrubber, .level = level };
        try std.testing.expectEqual(authentication_loadout.incorrectAuthenticationDetectionCost(), equipment.incorrectAuthenticationDetectionCost());
        try std.testing.expectEqual(authentication_costs[index], equipment.incorrectAuthenticationDetectionCost());
    }

    const no_utility = MissionState.MissionLoadout{};
    const wrong_movement_utility = MissionState.MissionLoadout{ .utility = .signal_scrubber, .level = 2 };
    const wrong_authentication_utility = MissionState.MissionLoadout{ .utility = .silent_boots, .level = 2 };
    try std.testing.expectEqual(@as(u8, 5), no_utility.movementDetectionCost());
    try std.testing.expectEqual(@as(u8, 15), no_utility.incorrectAuthenticationDetectionCost());
    try std.testing.expectEqual(@as(u8, 5), wrong_movement_utility.movementDetectionCost());
    try std.testing.expectEqual(@as(u8, 15), wrong_authentication_utility.incorrectAuthenticationDetectionCost());

    var equipment = @import("../src/player.zig").Equipment{};
    equipment.setOwned(.signal_scrubber);
    equipment.equipped_utility = .signal_scrubber;
    try std.testing.expectEqual(@as(u8, 5), equipment.movementDetectionCost());
    equipment.setOwned(.silent_boots);
    equipment.equipped_utility = .silent_boots;
    try std.testing.expectEqual(@as(u8, 15), equipment.incorrectAuthenticationDetectionCost());

    const launch_snapshot = MissionState.MissionLoadout{ .utility = .silent_boots, .level = 1 };
    equipment.equipped_utility = .signal_scrubber;
    equipment.setLevel(.signal_scrubber, 2);
    try std.testing.expectEqual(@as(u8, 3), launch_snapshot.movementDetectionCost());
    try std.testing.expectEqual(@as(u8, 6), equipment.incorrectAuthenticationDetectionCost());
}

test "Silent Boots reduce movement Detection and Signal Scrubber reduces failed authentication" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    try run("buy silent-boots", &player, &missions, &active, &session, &preparation);
    try run("equip silent-boots", &player, &missions, &active, &session, &preparation);
    try run("prepare job-01", &player, &missions, &active, &session, &preparation);
    try run("accept job-01", &player, &missions, &active, &session, &preparation);
    try run("move service", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 4), session.detection_level);

    player.balance = 100;
    try run("buy signal-scrubber", &player, &missions, &active, &session, &preparation);
    try run("equip signal-scrubber", &player, &missions, &active, &session, &preparation);
    try run("scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run("connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run("brute incorrect", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 29), session.detection_level);
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
    try std.testing.expect(player.equipment.isEquipped(.signal_scrubber));
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

test "unknown save versions are rejected without mutating existing state" {
    var player = Player{};
    player.balance = 321;
    player.reputation = 7;
    player.xp = 99;
    player.equipment.setOwned(.silent_boots);
    player.equipment.equipped_utility = .silent_boots;
    player.equipment.silent_boots_level = 1;
    var missions = mission_data.defaultMissions();
    missions[0].completed = true;

    const result = save.loadGameFromBytes("HACKERS_TERMINAL_SAVE_V4\n999\n", &player, &missions);

    try std.testing.expect(result == null);
    try std.testing.expectEqual(@as(u32, 321), player.balance);
    try std.testing.expectEqual(@as(u32, 7), player.reputation);
    try std.testing.expectEqual(@as(u32, 99), player.xp);
    try std.testing.expect(player.equipment.owns(.silent_boots));
    try std.testing.expect(player.equipment.isEquipped(.silent_boots));
    try std.testing.expectEqual(@as(u2, 1), player.equipment.level(.silent_boots));
    try std.testing.expect(missions[0].completed);

    try std.testing.expect(save.loadGameFromBytes("not-a-save-format\n", &player, &missions) == null);
}

test "active mission is validated against completion flags loaded from the same save" {
    var completed_missions = mission_data.defaultMissions();
    const inconsistent_v3 =
        "HACKERS_TERMINAL_SAVE_V3\n" ++
        "100\n0\n0\n0\n0\n0\n0\n0\n0\n1\n0\n0\n";
    var completed_player = Player{};
    const completed_active = save.loadGameFromBytes(inconsistent_v3, &completed_player, &completed_missions);
    try std.testing.expect(completed_active == null);
    try std.testing.expect(completed_missions[0].completed);

    var incomplete_missions = mission_data.defaultMissions();
    const valid_v3 =
        "HACKERS_TERMINAL_SAVE_V3\n" ++
        "100\n0\n0\n0\n0\n0\n0\n0\n1\n0\n0\n";
    var incomplete_player = Player{};
    const incomplete_active = save.loadGameFromBytes(valid_v3, &incomplete_player, &incomplete_missions);
    try std.testing.expectEqual(@as(?usize, 1), incomplete_active);
    try std.testing.expect(!incomplete_missions[1].completed);
}

test "save writes and replaces a V3 file in an isolated directory" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var player = Player{};
    player.balance = 777;
    player.reputation = 3;
    player.xp = 250;
    player.equipment.setOwned(.silent_boots);
    player.equipment.equipped_utility = .silent_boots;
    player.equipment.silent_boots_level = 2;
    var missions = mission_data.defaultMissions();
    missions[0].completed = true;
    missions[3].completed = true;

    try save.saveGameToDirectory(tmp.dir, player, &missions, null);
    player.balance = 888;
    missions[0].completed = false;
    try save.saveGameToDirectory(tmp.dir, player, &missions, null);

    const data = try tmp.dir.readFileAlloc(std.testing.allocator, "saves/player.sav", 4096);
    defer std.testing.allocator.free(data);
    try std.testing.expect(std.mem.startsWith(u8, data, "HACKERS_TERMINAL_SAVE_V3\n"));
    var restored_player = Player{};
    var restored_missions = mission_data.defaultMissions();
    _ = save.loadGameFromBytes(data, &restored_player, &restored_missions);
    try std.testing.expectEqual(@as(u32, 888), restored_player.balance);
    try std.testing.expectEqual(@as(u32, 3), restored_player.reputation);
    try std.testing.expectEqual(@as(u32, 250), restored_player.xp);
    try std.testing.expect(restored_player.equipment.owns(.silent_boots));
    try std.testing.expectEqual(@as(u2, 2), restored_player.equipment.level(.silent_boots));
    try std.testing.expect(!restored_missions[0].completed);
    try std.testing.expect(restored_missions[3].completed);
    try std.testing.expectError(error.FileNotFound, tmp.dir.openFile("saves/player.sav.tmp", .{}));
}

test "failed save staging leaves the previous save untouched" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var player = Player{};
    player.balance = 123;
    const missions = mission_data.defaultMissions();
    try save.saveGameToDirectory(tmp.dir, player, &missions, null);

    try tmp.dir.makePath("saves/player.sav.tmp");
    player.balance = 999;
    if (save.saveGameToDirectory(tmp.dir, player, &missions, null)) |_| {
        return error.ExpectedSaveWriteFailure;
    } else |_| {}

    const data = try tmp.dir.readFileAlloc(std.testing.allocator, "saves/player.sav", 4096);
    defer std.testing.allocator.free(data);
    var restored_player = Player{};
    var restored_missions = mission_data.defaultMissions();
    _ = save.loadGameFromBytes(data, &restored_player, &restored_missions);
    try std.testing.expectEqual(@as(u32, 123), restored_player.balance);
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

test "older three-contract save completion flags leave appended Ghost Signal incomplete" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    missions[3].completed = true;
    const old_v3 =
        "HACKERS_TERMINAL_SAVE_V3\n" ++
        "900\n3\n250\n1\n0\n0\n0\n0\n-1\n1\n0\n1\n";
    _ = save.loadGameFromBytes(old_v3, &player, &missions);
    try std.testing.expect(missions[0].completed);
    try std.testing.expect(!missions[1].completed);
    try std.testing.expect(missions[2].completed);
    try std.testing.expect(!missions[3].completed);
}

test "truncated and malformed saves are rejected without mutating live state" {
    var player = Player{ .balance = 321, .reputation = 7, .xp = 99 };
    player.equipment.setOwned(.silent_boots);
    player.equipment.equipped_utility = .silent_boots;
    player.equipment.silent_boots_level = 1;
    var missions = mission_data.defaultMissions();
    missions[0].completed = true;

    const truncated_saves = [_][]const u8{
        "HACKERS_TERMINAL_SAVE_V3\n",
        "HACKERS_TERMINAL_SAVE_V3\n1000\n",
        "HACKERS_TERMINAL_SAVE_V2\n1000\n7\n",
        "HACKERS_TERMINAL_SAVE_V1\n1000\n7\n1\n",
    };
    for (truncated_saves) |data| {
        try std.testing.expect(save.loadGameFromBytes(data, &player, &missions) == null);
        try std.testing.expectEqual(@as(u32, 321), player.balance);
        try std.testing.expectEqual(@as(u32, 7), player.reputation);
        try std.testing.expectEqual(@as(u32, 99), player.xp);
        try std.testing.expect(player.equipment.isEquipped(.silent_boots));
        try std.testing.expectEqual(@as(u2, 1), player.equipment.level(.silent_boots));
        try std.testing.expect(missions[0].completed);
    }

    const malformed =
        "HACKERS_TERMINAL_SAVE_V3\n" ++
        "999\n8\n100\n1\n3\n2\n2\n1\n-1\n0\n0\ninvalid-flag\n";
    try std.testing.expect(save.loadGameFromBytes(malformed, &player, &missions) == null);
    try std.testing.expectEqual(@as(u32, 321), player.balance);
    try std.testing.expectEqual(@as(u32, 7), player.reputation);
    try std.testing.expectEqual(@as(u32, 99), player.xp);
    try std.testing.expect(player.equipment.isEquipped(.silent_boots));
    try std.testing.expectEqual(@as(u2, 1), player.equipment.level(.silent_boots));
    try std.testing.expect(missions[0].completed);
}
