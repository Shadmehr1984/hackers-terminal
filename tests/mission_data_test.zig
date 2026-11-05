const std = @import("std");
const mission_data = @import("../src/mission_data.zig");
const MissionDifficulty = @import("../src/mission.zig").MissionDifficulty;

test "built-in missions have increasing difficulty" {
    const missions = mission_data.defaultMissions();

    try std.testing.expectEqual(MissionDifficulty.easy, missions[0].difficulty);
    try std.testing.expectEqual(MissionDifficulty.medium, missions[1].difficulty);
    try std.testing.expectEqual(MissionDifficulty.hard, missions[2].difficulty);
}

test "difficulty labels are player-facing" {
    try std.testing.expectEqualStrings("Easy", MissionDifficulty.easy.label());
    try std.testing.expectEqualStrings("Medium", MissionDifficulty.medium.label());
    try std.testing.expectEqualStrings("Hard", MissionDifficulty.hard.label());
}
