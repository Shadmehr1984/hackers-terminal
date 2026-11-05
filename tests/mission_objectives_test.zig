const std = @import("std");
const mission_data = @import("../src/mission_data.zig");
const MissionObjectiveKind = @import("../src/mission.zig").MissionObjectiveKind;
const MissionSession = @import("../src/mission_state.zig").MissionSession;

test "each built-in mission defines required and optional objectives" {
    const missions = mission_data.defaultMissions();
    const expected = [_]MissionObjectiveKind{
        .scan_target,
        .authenticate,
        .decrypt_file,
        .extract_file,
    };

    for (missions) |mission| {
        try std.testing.expectEqual(expected.len + 1, mission.objectives.len);
        for (expected, 0..) |kind, index| {
            try std.testing.expectEqual(kind, mission.objectives[index].kind);
        }
    }
}

test "objective completion is tracked independently" {
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    session.start();

    try std.testing.expect(!session.allObjectivesComplete(missions[0].objectives));

    session.completeObjective(.scan_target);
    try std.testing.expect(session.isObjectiveComplete(.scan_target));
    try std.testing.expect(!session.isObjectiveComplete(.authenticate));
    try std.testing.expect(!session.allObjectivesComplete(missions[0].objectives));

    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);
    session.completeObjective(.extract_file);
    try std.testing.expect(session.allObjectivesComplete(missions[0].objectives));
}

test "starting and resetting a session clear objective progress" {
    var session = MissionSession{};
    session.start();
    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);

    session.start();
    try std.testing.expect(!session.isObjectiveComplete(.scan_target));
    try std.testing.expect(!session.isObjectiveComplete(.authenticate));

    session.completeObjective(.decrypt_file);
    session.reset();
    try std.testing.expect(!session.isObjectiveComplete(.decrypt_file));
}
