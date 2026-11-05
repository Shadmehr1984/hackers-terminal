const std = @import("std");
const mission_data = @import("../src/mission_data.zig");
const operation_data = @import("../src/catalog/operation_data.zig");
const operation_model = @import("../src/domain/operation.zig");
const OperationState = @import("../src/domain/operation_state.zig").OperationState;

test "blackout protocol validates against the built-in contract catalog" {
    const missions = mission_data.defaultMissions();
    try std.testing.expect(operation_data.blackout_protocol.validate(&missions));
    try std.testing.expectEqual(@as(usize, 3), operation_data.blackout_protocol.stages.len);
}

test "operation rejects duplicate and unknown stage references" {
    const missions = mission_data.defaultMissions();
    const duplicate_stages = [_]operation_model.OperationStage{
        .{ .mission_id = "job-01" },
        .{ .mission_id = "job-01" },
    };
    const duplicate = operation_model.Operation{
        .id = "duplicate",
        .name = "Duplicate",
        .description = "",
        .stages = &duplicate_stages,
    };
    try std.testing.expect(!duplicate.validate(&missions));

    const unknown_stages = [_]operation_model.OperationStage{.{ .mission_id = "missing" }};
    const unknown = operation_model.Operation{
        .id = "unknown",
        .name = "Unknown",
        .description = "",
        .stages = &unknown_stages,
    };
    try std.testing.expect(!unknown.validate(&missions));
}

test "operation state grants facts and advances one stage at a time" {
    const operation = operation_data.blackout_protocol;
    var state = OperationState{};
    try std.testing.expect(state.start(operation, true));
    try std.testing.expectEqual(@as(u8, 0), state.stage_index);
    state.grantFact(.maintenance_telemetry);
    try std.testing.expect(state.hasFact(.maintenance_telemetry));
    try std.testing.expect(!state.advance(operation, false));
    try std.testing.expectEqual(@as(u8, 1), state.stage_index);
    try std.testing.expect(!state.current_stage_reward_eligible);
    try std.testing.expect(!state.advance(operation, true));
    try std.testing.expectEqual(@as(u8, 2), state.stage_index);
    try std.testing.expect(state.advance(operation, false));
    try std.testing.expect(!state.active);
    try std.testing.expectEqualStrings("blackout-protocol", state.last_completed_operation_id);
}
