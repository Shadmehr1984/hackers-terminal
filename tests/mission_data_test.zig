const std = @import("std");
const mission_data = @import("../src/mission_data.zig");
const MissionDifficulty = @import("../src/mission.zig").MissionDifficulty;
const ModifierId = @import("../src/domain/mission_modifier.zig").ModifierId;

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

test "each built-in mission has a valid distinct topology" {
    const missions = mission_data.defaultMissions();
    for (missions) |mission| {
        try std.testing.expect(mission.hasValidObjectives());
        try std.testing.expect(mission.topology != null);
        try std.testing.expect(mission.topology.?.isValid(std.testing.allocator));
    }
    try std.testing.expect(missions[0].topology.?.containsNode("maintenance"));
    try std.testing.expect(missions[1].topology.?.containsNode("records"));
    try std.testing.expect(missions[2].topology.?.containsNode("decoy"));
    try std.testing.expectEqual(@as(usize, 5), missions.len);
    try std.testing.expectEqualStrings("job-04", missions[3].id);
    try std.testing.expectEqualStrings("Ghost Signal", missions[3].name);
    try std.testing.expectEqual(@as(u32, 3), missions[3].required_level);
    try std.testing.expectEqual(@as(u32, 3), missions[3].required_reputation);
    try std.testing.expect(missions[3].requires_contact_offer);
    try std.testing.expect(missions[3].topology.?.containsNode("beacon"));
    try std.testing.expectEqualStrings("job-05", missions[4].id);
    try std.testing.expectEqualStrings("Corporate Ghost", missions[4].name);
    try std.testing.expectEqual(@as(u32, 2), missions[4].required_level);
    try std.testing.expectEqual(@as(u32, 2), missions[4].required_reputation);
    try std.testing.expect(!missions[4].requires_contact_offer);
    try std.testing.expectEqual(@as(u32, 1200), missions[4].reward);
    try std.testing.expectEqual(@as(u32, 275), missions[4].xp_reward);
    try std.testing.expect(missions[4].client_faction == .nexus_dynamics);
    try std.testing.expect(missions[4].target_owner_faction.? == .null_syndicate);
    try std.testing.expect(missions[4].topology.?.containsNode("mirror-node"));
    try std.testing.expect(missions[4].topology.?.areAdjacent("mirror-node", "data-vault"));
    try std.testing.expectEqual(@as(usize, 7), missions[4].objectives.len);
    try std.testing.expect(!std.mem.eql(u8, missions[0].topology.?.nodes[2].id, missions[1].topology.?.nodes[2].id) or
        !std.mem.eql(u8, missions[0].topology.?.nodes[2].label, missions[1].topology.?.nodes[2].label));
}

test "all five built-in contracts explicitly allow all three approved modifiers" {
    const missions = mission_data.defaultMissions();
    const expected = [_]ModifierId{ .heightened_monitoring, .security_sweep, .hardened_encryption };
    try std.testing.expectEqual(@as(usize, 5), missions.len);
    for (missions) |mission| {
        try std.testing.expectEqual(expected.len, mission.allowed_modifiers.len);
        for (expected) |modifier| {
            try std.testing.expect(mission.allowsModifier(modifier));
        }
    }
}
