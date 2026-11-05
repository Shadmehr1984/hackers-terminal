const std = @import("std");
const Player = @import("../src/player.zig").Player;
const progression = @import("../src/progression.zig");
const MissionSession = @import("../src/domain/mission_state.zig").MissionSession;
const mission_data = @import("../src/catalog/mission_data.zig");

test "player progression thresholds remain cumulative and predictable" {
    var player = Player{};
    try std.testing.expectEqual(@as(u32, 1), progression.playerLevel(player));
    try std.testing.expectEqual(@as(u32, 100), progression.xpForNextLevel(1));

    player.xp = 99;
    try std.testing.expectEqual(@as(u32, 1), progression.playerLevel(player));
    player.xp = 100;
    try std.testing.expectEqual(@as(u32, 2), progression.playerLevel(player));
    try std.testing.expectEqual(@as(u32, 250), progression.xpForNextLevel(2));

    player.xp = 249;
    try std.testing.expectEqual(@as(u32, 2), progression.playerLevel(player));
    player.xp = 250;
    try std.testing.expectEqual(@as(u32, 3), progression.playerLevel(player));
    try std.testing.expectEqual(@as(u32, 400), progression.xpForNextLevel(3));
}

const TestWriter = struct {
    pub fn writeAll(_: @This(), _: []const u8) error{}!void {}
    pub fn print(_: @This(), comptime _: []const u8, _: anytype) error{}!void {}
};

test "modified completion bonus is paid once even if completion is re-entered" {
    var player = Player{};
    const missions = mission_data.defaultMissions();
    var session = MissionSession{ .modifier = .hardened_encryption };
    const writer = TestWriter{};

    try progression.completeMission(writer, &player, missions[0], &session);
    try std.testing.expectEqual(@as(u32, 600), player.balance);
    try std.testing.expectEqual(@as(u32, 125), player.xp);
    try std.testing.expectEqual(@as(u32, 1), player.reputation);
    try std.testing.expect(session.completion_reward_paid);

    try progression.completeMission(writer, &player, missions[0], &session);
    try std.testing.expectEqual(@as(u32, 600), player.balance);
    try std.testing.expectEqual(@as(u32, 125), player.xp);
    try std.testing.expectEqual(@as(u32, 1), player.reputation);

    session.reset();
    try std.testing.expect(!session.completion_reward_paid);
    try std.testing.expect(session.modifier == null);
}
