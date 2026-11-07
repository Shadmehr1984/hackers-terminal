const std = @import("std");
const mission_data = @import("../src/mission_data.zig");
const MissionObjectiveKind = @import("../src/mission.zig").MissionObjectiveKind;
const MissionSession = @import("../src/mission_state.zig").MissionSession;
const objective_tracker = @import("../src/domain/mission_objectives.zig");
const ObjectiveState = objective_tracker.ObjectiveState;
const Tracker = objective_tracker.Tracker;
const DiscoveryTrigger = objective_tracker.DiscoveryTrigger;

test "built-in objective catalogs have stable IDs and hidden optional entries" {
    const missions = mission_data.defaultMissions();
    const expected = [_]MissionObjectiveKind{ .scan_target, .authenticate, .decrypt_file, .extract_file };
    for (missions, 0..) |mission, mission_index| {
        try std.testing.expect(mission.hasValidObjectives());
        const extra_required: usize = if (mission_index == 4) 1 else 0;
        try std.testing.expectEqual(expected.len + extra_required + 2, mission.objectives.len);
        for (expected, 0..) |kind, index| {
            try std.testing.expectEqual(kind, mission.objectives[index].kind);
            try std.testing.expect(!mission.objectives[index].optional);
            try std.testing.expect(mission.objectives[index].id.len > 0);
        }
        const optional_index: usize = if (mission_index == 4) 5 else 4;
        const hidden_index = optional_index + 1;
        if (mission_index == 4) {
            try std.testing.expectEqual(MissionObjectiveKind.analyze_metadata, mission.objectives[4].kind);
            try std.testing.expectEqualStrings("verify-trail", mission.objectives[4].id);
            try std.testing.expect(!mission.objectives[4].optional);
        }
        try std.testing.expectEqual(MissionObjectiveKind.analyze_metadata, mission.objectives[optional_index].kind);
        try std.testing.expect(mission.objectives[optional_index].optional);
        try std.testing.expect(!mission.objectives[optional_index].hidden);
        try std.testing.expect(mission.objectives[hidden_index].optional);
        try std.testing.expect(mission.objectives[hidden_index].hidden);
        try std.testing.expect(mission.objectives[hidden_index].discovery_trigger != null);
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
    try std.testing.expectEqual(@as(u32, 0), try session.optionalReward(missions[0].objectives));
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
    try std.testing.expectEqual(@as(u32, 0), try session.optionalReward(missions[0].objectives));
    try std.testing.expect(!session.allOptionalObjectivesComplete(missions[0].objectives));

    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 0), session.discoverNode("maintenance", missions[0].objectives));
    session.completeObjective(.analyze_metadata);
    try std.testing.expectEqual(@as(u32, 75), try session.optionalReward(missions[0].objectives));
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
    try std.testing.expect(!session.objective_tracker.progressOf("maintenance-telemetry").?.revealed);
    try std.testing.expectEqual(ObjectiveState.discovered, session.objective_tracker.stateOf("scan-target").?);
    try std.testing.expect(!session.allOptionalObjectivesComplete(missions[0].objectives));

    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    session.markUncompletedOptionalObjectivesUnavailable();
    try std.testing.expectEqual(ObjectiveState.unavailable, session.objective_tracker.stateOf("maintenance-telemetry").?);
    try std.testing.expect(session.objective_tracker.progressOf("maintenance-telemetry").?.revealed);
}

test "optional reward accumulation rejects u32 overflow" {
    const Objective = struct {
        id: []const u8,
        kind: enum { analyze },
        optional: bool = true,
        bonus_reward: u32,
        hidden: bool = false,
        discovery_trigger: ?@import("../src/domain/mission_objectives.zig").DiscoveryTrigger = null,
    };
    const objectives = [_]Objective{
        .{ .id = "large", .kind = .analyze, .bonus_reward = std.math.maxInt(u32) },
        .{ .id = "overflow", .kind = .analyze, .bonus_reward = 1 },
    };
    var tracker = @import("../src/domain/mission_objectives.zig").Tracker{};
    try std.testing.expect(tracker.initialize(&objectives));
    try std.testing.expectEqual(@as(usize, 2), tracker.complete(@backingInt(@as(@TypeOf(objectives[0].kind), .analyze))));
    try std.testing.expectError(error.RewardOverflow, tracker.optionalReward());
}

test "tracker validates capacity identity and hidden objective invariants atomically" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan, analyze },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const valid = [_]Objective{
        .{ .id = "required", .kind = .scan },
        .{ .id = "secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .node = "vault" } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&valid));
    try std.testing.expectEqual(@as(u8, 2), tracker.count);
    try std.testing.expectEqual(ObjectiveState.discovered, tracker.stateOf("required").?);
    try std.testing.expectEqual(ObjectiveState.undiscovered, tracker.stateOf("secret").?);

    const duplicate = [_]Objective{
        .{ .id = "same", .kind = .scan },
        .{ .id = "same", .kind = .analyze },
    };
    try std.testing.expect(!tracker.initialize(&duplicate));
    try std.testing.expectEqual(@as(u8, 2), tracker.count);
    try std.testing.expectEqual(ObjectiveState.undiscovered, tracker.stateOf("secret").?);

    const invalid_hidden = [_]Objective{
        .{ .id = "secret", .kind = .analyze, .hidden = true },
    };
    try std.testing.expect(!tracker.initialize(&invalid_hidden));
    try std.testing.expectEqual(@as(u8, 2), tracker.count);
}

test "node file and action triggers are typed idempotent and independent" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan, analyze },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const objectives = [_]Objective{
        .{ .id = "node-secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .node = "vault" } },
        .{ .id = "file-secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .file = "trace.log" } },
        .{ .id = "action-secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .action = .scan_target } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&objectives));
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverNode("entry", &objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverNode("vault", &objectives));
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverNode("vault", &objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverFile("trace.log", &objectives));
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverFile("other.log", &objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverAction(.scan_target, &objectives));
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverAction(.scan_target, &objectives));
}

test "same event kind completes independently discovered objectives and rewards once" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan, analyze },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const objectives = [_]Objective{
        .{ .id = "visible-analysis", .kind = .analyze, .optional = true, .bonus_reward = 25 },
        .{ .id = "hidden-analysis", .kind = .analyze, .optional = true, .bonus_reward = 50, .hidden = true, .discovery_trigger = .{ .action = .scan_target } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverAction(.scan_target, &objectives));
    try std.testing.expectEqual(@as(usize, 2), tracker.complete(@backingInt(@as(@TypeOf(objectives[0].kind), .analyze))));
    try std.testing.expectEqual(ObjectiveState.completed, tracker.stateOf("visible-analysis").?);
    try std.testing.expectEqual(ObjectiveState.completed, tracker.stateOf("hidden-analysis").?);
    try std.testing.expectEqual(@as(u32, 75), try tracker.optionalReward());
    try std.testing.expect(tracker.allOptionalComplete());
    try std.testing.expectEqual(@as(usize, 0), tracker.complete(@backingInt(@as(@TypeOf(objectives[0].kind), .analyze))));
}

test "undiscovered optional objectives prevent reputation bonus and can become unavailable" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan, analyze },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const objectives = [_]Objective{
        .{ .id = "required", .kind = .scan },
        .{ .id = "secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .file = "secret.log" } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&objectives));
    try std.testing.expect(!tracker.allOptionalComplete());
    try std.testing.expect(!tracker.allRequiredComplete());
    try std.testing.expect(tracker.markUnavailable("secret"));
    try std.testing.expectEqual(ObjectiveState.unavailable, tracker.stateOf("secret").?);
    try std.testing.expect(!tracker.markUnavailable("secret"));
    try std.testing.expect(!tracker.allOptionalComplete());
    try std.testing.expectEqual(@as(u32, 0), try tracker.optionalReward());
}

test "tracker rejects catalogs above the 32 objective capacity" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    var too_many: [33]Objective = undefined;
    for (&too_many, 0..) |*objective, index| {
        objective.* = .{ .id = if (index == 0) "objective-0" else "objective", .kind = .scan };
    }
    var tracker = Tracker{};
    try std.testing.expect(!tracker.initialize(&too_many));
    try std.testing.expectEqual(@as(u8, 0), tracker.count);
}

test "tracker accepts exactly 32 independently identified objectives" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    var ids: [32][16]u8 = undefined;
    var catalog: [32]Objective = undefined;
    for (&catalog, 0..) |*objective, index| {
        const id = try std.fmt.bufPrint(&ids[index], "objective-{d}", .{index});
        objective.* = .{ .id = id, .kind = .scan };
    }
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&catalog));
    try std.testing.expectEqual(@as(u8, 32), tracker.count);
}

test "one-shot event completion makes undiscovered matching optional objectives unavailable" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const catalog = [_]Objective{
        .{ .id = "visible-scan", .kind = .scan },
        .{ .id = "late-scan", .kind = .scan, .optional = true, .hidden = true, .discovery_trigger = .{ .file = "late.log" } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&catalog));
    try std.testing.expectEqual(@as(usize, 1), tracker.complete(0));
    tracker.markOptionalUnavailableForKind(0);
    try std.testing.expectEqual(ObjectiveState.completed, tracker.stateOf("visible-scan").?);
    try std.testing.expectEqual(ObjectiveState.unavailable, tracker.stateOf("late-scan").?);
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverFile("late.log", &catalog));
}
