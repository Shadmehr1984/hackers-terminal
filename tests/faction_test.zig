const std = @import("std");
const FactionId = @import("../src/domain/faction_id.zig").FactionId;
const faction = @import("../src/domain/faction.zig");
const faction_data = @import("../src/catalog/faction_data.zig");
const mission_data = @import("../src/catalog/mission_data.zig");
const contract_board = @import("../src/domain/contract_board.zig");

test "faction catalog contains seven unique complete profiles" {
    try std.testing.expect(faction_data.validate());
    try std.testing.expectEqual(@as(usize, 7), faction_data.all().len);
    for (faction_data.all()) |entry| {
        try std.testing.expect(FactionId.parse(entry.id.slug()) != null);
        try std.testing.expectEqual(entry.id, FactionId.parse(entry.id.slug()).?);
    }
}

test "authored faction relationships are symmetric and unspecified pairs are neutral" {
    try std.testing.expectEqual(faction.RelationshipKind.allied, faction_data.relationship(.nexus_dynamics, .iron_meridian));
    try std.testing.expectEqual(faction.RelationshipKind.allied, faction_data.relationship(.iron_meridian, .nexus_dynamics));
    try std.testing.expectEqual(faction.RelationshipKind.hostile, faction_data.relationship(.aegis_initiative, .nexus_dynamics));
    try std.testing.expectEqual(faction.RelationshipKind.neutral, faction_data.relationship(.nexus_dynamics, .helix_consortium));
    try std.testing.expectEqual(faction.RelationshipKind.allied, faction_data.relationship(.ghost_protocol, .ghost_protocol));
}

test "player standing is derived from reputation and completed contract outcomes" {
    var missions = mission_data.defaultMissions();
    try std.testing.expectEqual(faction.Standing.neutral, faction.playerStanding(.nexus_dynamics, 0, &missions));

    missions[0].completed = true;
    try std.testing.expectEqual(faction.Standing.trusted, faction.playerStanding(.aegis_initiative, 1, &missions));
    try std.testing.expectEqual(faction.Standing.wary, faction.playerStanding(.nexus_dynamics, 1, &missions));

    missions[1].completed = true;
    try std.testing.expectEqual(faction.Standing.hostile, faction.playerStanding(.nexus_dynamics, 2, &missions));
}

test "hostile client standing blocks contract board availability deterministically" {
    var missions = mission_data.defaultMissions();
    missions[0].completed = true;
    missions[1].completed = true;
    missions[2].client_faction = .nexus_dynamics;

    const context = contract_board.Context{
        .level = 3,
        .reputation = 2,
        .missions = &missions,
    };
    const first = contract_board.evaluate(missions[2], context);
    const second = contract_board.evaluate(missions[2], context);
    try std.testing.expectEqual(contract_board.Availability.faction_blocked, first.availability);
    try std.testing.expect(first.faction_locked);
    try std.testing.expectEqual(first.availability, second.availability);
    try std.testing.expectEqual(faction.Standing.hostile, first.player_standing);
}

test "built-in contracts declare valid and distinct client and target owner factions" {
    const missions = mission_data.defaultMissions();
    for (missions) |mission| {
        try std.testing.expect(mission.hasValidFactionLinks());
        try std.testing.expect(mission.target_owner_faction != null);
        try std.testing.expect(mission.target_owner_faction.? != mission.client_faction);
    }
}
