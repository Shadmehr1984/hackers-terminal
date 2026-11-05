const std = @import("std");
const Player = @import("../src/player.zig").Player;
const progression = @import("../src/progression.zig");

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
