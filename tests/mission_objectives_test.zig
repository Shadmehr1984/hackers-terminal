const std = @import("std");
const mission_data = @import("../src/mission_data.zig");
const MissionObjectiveKind = @import("../src/mission.zig").MissionObjectiveKind;
const MissionSession = @import("../src/mission_state.zig").MissionSession;
const ObjectiveState = @import("../src/domain/mission_objectives.zig").ObjectiveState;

test "built-in objective catalogs have stable IDs and hidden optional entries" {
    const missions = mission_data.defaultMissions();
    const expected = [_]MissionObjectiveKind{ .scan_target, .authenticate, .decrypt_file, .extract_file };
    for (missions) |mission| {
        try std.testing.expect(mission.hasValidObjectives());
        try std.testing.expectEqual(expected.len + 2, mission.objectives.len);
        for (expected, 0..) |kind, index| {
            try std.testing.expectEqual(kind, mission.objectives[index].kind);
            try std.testing.expect(!mission.objectives[index].optional);
            try std.testing.expect(mission.objectives[index].id.len > 0);
        }
        try std.testing.expectEqual(MissionObjectiveKind.analyze_metadata, mission.objectives[4].kind);
        try std.testing.expect(mission.objectives[4].optional);
        try std.testing.expect(!mission.objectives[4].hidden);
        try std.testing.expect(mission.objectives[5].optional);
        try std.testing.expect(mission.objectives[5].hidden);
        try std.testing.expect(mission.objectives[5].discovery_trigger != null);
    }
}

test "required objective completion is tracked by stable identity" {
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    try std.testing.expect(!session.allObjectivesComplete(missions[0].objectives));

    session.completeObjective(.scan_target);
    try std.testing.expect(session.isObjectiveComplete(.scan_target));
    try std.testing.expect(!session.isObjectiveComplete(.authenticate));
    try std.testing.expect(!session.allObjectivesComplete(missions[0].objectives));

    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);
    session.completeObjective(.extract_file);
    try std.testing.expect(session.allObjectivesComplete(missions[0].objectives));
    try std.testing.expectEqual(@as(u32, 0), session.optionalReward(missions[0].objectives));
}

test "visible and hidden objectives reset to their authored initial states" {
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    try std.testing.expectEqual(ObjectiveState.discovered, session.objective_tracker.stateOf("scan-target").?);
    try std.testing.expectEqual(ObjectiveState.undiscovered, session.objective_tracker.stateOf("maintenance-telemetry").?);
    session.completeObjective(.scan_target);
    try std.testing.expect(session.isObjectiveComplete(.scan_target));

    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    try std.testing.expectEqual(ObjectiveState.discovered, session.objective_tracker.stateOf("scan-target").?);
    try std.testing.expectEqual(ObjectiveState.undiscovered, session.objective_tracker.stateOf("maintenance-telemetry").?);
    session.reset();
    try std.testing.expectEqual(@as(u8, 0), session.objective_tracker.count);
}

test "hidden objectives are optional, discoverable and reward only after discovery and completion" {
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    try std.testing.expect(session.allObjectivesComplete(missions[0].objectives) == false);
    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);
    session.completeObjective(.extract_file);
    try std.testing.expect(session.allObjectivesComplete(missions[0].objectives));
    try std.testing.expectEqual(@as(u32, 0), session.optionalReward(missions[0].objectives));
    try std.testing.expect(!session.allOptionalObjectivesComplete(missions[0].objectives));

    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 0), session.discoverNode("maintenance", missions[0].objectives));
    session.completeObjective(.analyze_metadata);
    try std.testing.expectEqual(@as(u32, 125), session.optionalReward(missions[0].objectives));
    try std.testing.expect(session.allOptionalObjectivesComplete(missions[0].objectives));
}

test "file and action discovery triggers are isolated from unrelated events" {
    const missions = mission_data.defaultMissions();
    var paper = MissionSession{};
    try std.testing.expect(paper.startWithMission(.{}, null, missions[1].objectives));
    try std.testing.expectEqual(@as(usize, 0), paper.discoverFile("wrong.log", missions[1].objectives));
    try std.testing.expectEqual(@as(usize, 1), paper.discoverFile("routing-header.log", missions[1].objectives));
    try std.testing.expectEqual(@as(usize, 0), paper.discoverFile("routing-header.log", missions[1].objectives));

    var quiet = MissionSession{};
    try std.testing.expect(quiet.startWithMission(.{}, null, missions[2].objectives));
    try std.testing.expectEqual(@as(usize, 1), quiet.discoverAction(.scan_target, missions[2].objectives));
    try std.testing.expectEqual(@as(usize, 0), quiet.discoverAction(.scan_target, missions[2].objectives));
}

test "uncompleted optional objectives become unavailable only when the contract ends" {
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    session.markUncompletedOptionalObjectivesUnavailable();
    try std.testing.expectEqual(ObjectiveState.unavailable, session.objective_tracker.stateOf("maintenance-telemetry").?);
    try std.testing.expectEqual(ObjectiveState.discovered, session.objective_tracker.stateOf("scan-target").?);
    try std.testing.expect(!session.allOptionalObjectivesComplete(missions[0].objectives));

    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    session.markUncompletedOptionalObjectivesUnavailable();
    try std.testing.expectEqual(ObjectiveState.unavailable, session.objective_tracker.stateOf("maintenance-telemetry").?);
}
