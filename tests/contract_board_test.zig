const std = @import("std");
const board = @import("../src/domain/contract_board.zig");
const mission_data = @import("../src/catalog/mission_data.zig");

test "board derives available and locked states with exact requirement flags" {
    const missions = mission_data.defaultMissions();
    const first = board.evaluate(missions[0], .{ .level = 1, .reputation = 0 });
    try std.testing.expectEqual(board.Availability.available, first.availability);
    try std.testing.expect(!first.level_locked);
    try std.testing.expect(!first.reputation_locked);

    const second = board.evaluate(missions[1], .{ .level = 1, .reputation = 0 });
    try std.testing.expectEqual(board.Availability.locked, second.availability);
    try std.testing.expect(second.level_locked);
    try std.testing.expect(!second.reputation_locked);

    const fourth = board.evaluate(missions[3], .{ .level = 1, .reputation = 0 });
    try std.testing.expectEqual(board.Availability.locked, fourth.availability);
    try std.testing.expect(fourth.level_locked);
    try std.testing.expect(fourth.reputation_locked);
}

test "exclusive contracts become visible as exclusive only after requirements" {
    const missions = mission_data.defaultMissions();
    const entry = board.evaluate(missions[3], .{ .level = 3, .reputation = 3 });
    try std.testing.expectEqual(board.Availability.exclusive, entry.availability);
}

test "busy state makes incomplete contracts unavailable but completed takes precedence" {
    var missions = mission_data.defaultMissions();
    const context = board.Context{ .level = 3, .reputation = 3, .another_contract_busy = true };
    try std.testing.expectEqual(board.Availability.unavailable, board.evaluate(missions[0], context).availability);
    missions[1].completed = true;
    try std.testing.expectEqual(board.Availability.completed, board.evaluate(missions[1], context).availability);
}

test "maximum reward includes every optional objective bonus only" {
    const missions = mission_data.defaultMissions();
    try std.testing.expectEqual(@as(u32, 375), board.maximumReward(missions[0]));
    try std.testing.expectEqual(@as(u32, 600), board.maximumReward(missions[1]));
    try std.testing.expectEqual(@as(u32, 925), board.maximumReward(missions[2]));
    try std.testing.expectEqual(@as(u32, 1275), board.maximumReward(missions[3]));
    try std.testing.expectEqual(@as(u32, 1400), board.maximumReward(missions[4]));
}

test "built-in contracts retain their intended board categories" {
    const missions = mission_data.defaultMissions();
    try std.testing.expectEqual(@as(usize, 5), missions.len);
    try std.testing.expectEqualStrings("Data Recovery", missions[0].category.label());
    try std.testing.expectEqualStrings("Intelligence", missions[1].category.label());
    try std.testing.expectEqualStrings("Extraction", missions[2].category.label());
    try std.testing.expectEqualStrings("Infiltration", missions[3].category.label());
    try std.testing.expectEqualStrings("Infiltration", missions[4].category.label());
}
