const std = @import("std");
const mission_data = @import("../src/mission_data.zig");
const operation_data = @import("../src/catalog/operation_data.zig");
const operation_model = @import("../src/domain/operation.zig");
const OperationState = @import("../src/domain/operation_state.zig").OperationState;
const MissionSession = @import("../src/mission_state.zig").MissionSession;
const MissionPreparation = @import("../src/mission_state.zig").MissionPreparation;
const Player = @import("../src/player.zig").Player;
const game = @import("../src/game.zig");
const faction = @import("../src/domain/faction.zig");

const TestWriter = struct {
    pub fn writeAll(_: *@This(), _: []const u8) !void {}
    pub fn print(_: *@This(), comptime _: []const u8, _: anytype) !void {}
};

fn run(
    writer: *TestWriter,
    command: []const u8,
    player: *Player,
    missions: []@import("../src/mission.zig").Mission,
    active: *?usize,
    session: *MissionSession,
    preparation: *MissionPreparation,
) !void {
    _ = try game.runCommand(writer, command, player, missions, active, session, preparation);
}

fn runWithSaveDirectory(
    writer: *TestWriter,
    command: []const u8,
    player: *Player,
    missions: []@import("../src/mission.zig").Mission,
    active: *?usize,
    session: *MissionSession,
    preparation: *MissionPreparation,
    save_directory: std.fs.Dir,
) !void {
    _ = try game.runCommandWithSaveDirectory(writer, command, player, missions, active, session, preparation, save_directory);
}

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

test "operation start validates every stage before changing state and blocks standalone preparation" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var writer = TestWriter{};

    try run(&writer, "operation-start blackout-protocol", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(!preparation.operation_state.active);
    try std.testing.expect(preparation.mission_index == null);

    player.xp = 250;
    try run(&writer, "operation-start blackout-protocol", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.operation_state.active);
    try std.testing.expectEqual(@as(u8, 0), preparation.operation_state.stage_index);
    try std.testing.expectEqual(@as(?usize, 0), preparation.mission_index);

    try run(&writer, "prepare job-02", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 0), preparation.mission_index);
    try run(&writer, "cancel", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.operation_state.active);
    try std.testing.expectEqual(@as(?usize, 0), preparation.mission_index);
}

test "successful stage grants its fact and reveals only the next authored objective" {
    var player = Player{ .xp = 250 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var writer = TestWriter{};

    try run(&writer, "operation-start blackout-protocol", &player, &missions, &active, &session, &preparation);
    try run(&writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 0), active);

    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    session.completeObjective(.analyze_metadata);
    session.progress = .decrypted;
    session.current_node = "vault";
    for (missions[0].objectives) |objective| {
        if (!objective.optional and objective.kind != .extract_file) session.completeObjective(objective.kind);
    }

    try run(&writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(missions[0].completed);
    try std.testing.expect(preparation.operation_state.active);
    try std.testing.expectEqual(@as(u8, 1), preparation.operation_state.stage_index);
    try std.testing.expect(preparation.operation_state.hasFact(.maintenance_telemetry));
    try std.testing.expectEqual(@as(?usize, 1), preparation.mission_index);

    try run(&writer, "accept job-02", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 1), active);
    try std.testing.expectEqual(
        @import("../src/domain/mission_objectives.zig").ObjectiveState.discovered,
        session.objective_tracker.stateOf("routing-header").?,
    );

    session.progress = .decrypted;
    session.current_node = "mail-store";
    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);
    session.completeObjective(.analyze_metadata);
    try run(&writer, "extract mailbox.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.operation_state.hasFact(.routing_header));
    try std.testing.expectEqual(@as(u8, 2), preparation.operation_state.stage_index);
    try std.testing.expectEqual(@as(?usize, 2), preparation.mission_index);

    try run(&writer, "accept job-03", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 2), active);
    try std.testing.expectEqual(
        @import("../src/domain/mission_objectives.zig").ObjectiveState.discovered,
        session.objective_tracker.stateOf("relay-trace").?,
    );
}

test "compromised operation stage retries cleanly without losing earlier facts" {
    var player = Player{ .xp = 250 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var writer = TestWriter{};

    try run(&writer, "operation-start blackout-protocol", &player, &missions, &active, &session, &preparation);
    preparation.operation_state.grantFact(.maintenance_telemetry);
    try run(&writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    session.detection_level = 95;
    session.current_node = "service";

    try run(&writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(active == null);
    try std.testing.expect(preparation.operation_state.active);
    try std.testing.expectEqual(@as(u8, 0), preparation.operation_state.stage_index);
    try std.testing.expect(preparation.operation_state.hasFact(.maintenance_telemetry));
    try std.testing.expectEqual(@as(?usize, 0), preparation.mission_index);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);
}

test "replaying a completed stage does not pay rewards again" {
    var player = Player{ .xp = 250 };
    var missions = mission_data.defaultMissions();
    missions[0].completed = true;
    const original_balance = player.balance;
    const original_xp = player.xp;
    const original_reputation = player.reputation;
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var writer = TestWriter{};

    try run(&writer, "operation-start blackout-protocol", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(!preparation.operation_state.current_stage_reward_eligible);
    try run(&writer, "accept job-01", &player, &missions, &active, &session, &preparation);

    session.progress = .decrypted;
    session.current_node = "vault";
    for (missions[0].objectives) |objective| {
        if (!objective.optional and objective.kind != .extract_file) session.completeObjective(objective.kind);
    }
    try run(&writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);

    try std.testing.expectEqual(original_balance, player.balance);
    try std.testing.expectEqual(original_xp, player.xp);
    try std.testing.expectEqual(original_reputation, player.reputation);
    try std.testing.expect(preparation.operation_state.active);
    try std.testing.expectEqual(@as(u8, 1), preparation.operation_state.stage_index);
}

test "operation save uses the unchanged V3 layout with no active mission index" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var player = Player{ .xp = 250 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var writer = TestWriter{};
    try run(&writer, "operation-start blackout-protocol", &player, &missions, &active, &session, &preparation);
    try run(&writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.operation_state.active);
    try std.testing.expectEqual(@as(?usize, 0), active);

    try runWithSaveDirectory(&writer, "save", &player, &missions, &active, &session, &preparation, tmp.dir);

    // Saving an active operation omits the active mission from disk without
    // changing the live mission selection.
    try std.testing.expectEqual(@as(?usize, 0), active);

    const data = try tmp.dir.readFileAlloc(std.testing.allocator, "saves/player.sav", 4096);
    defer std.testing.allocator.free(data);
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    try std.testing.expectEqualStrings("HACKERS_TERMINAL_SAVE_V3", lines.next().?);
    inline for (0..8) |_| _ = lines.next().?;
    try std.testing.expectEqualStrings("-1", lines.next().?);
}

test "compromise on extraction also re-prepares the current operation stage" {
    var player = Player{ .xp = 250 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var writer = TestWriter{};

    try run(&writer, "operation-start blackout-protocol", &player, &missions, &active, &session, &preparation);
    try run(&writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    session.progress = .decrypted;
    session.current_node = "vault";
    session.detection_level = 95;
    for (missions[0].objectives) |objective| {
        if (!objective.optional and objective.kind != .extract_file) session.completeObjective(objective.kind);
    }

    try run(&writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(active == null);
    try std.testing.expect(preparation.operation_state.active);
    try std.testing.expectEqual(@as(u8, 0), preparation.operation_state.stage_index);
    try std.testing.expectEqual(@as(?usize, 0), preparation.mission_index);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try std.testing.expect(!missions[0].completed);
}

test "operation remains preauthorized when an earlier stage makes a later client hostile" {
    var player = Player{ .xp = 250, .reputation = 3 };
    var missions = mission_data.defaultMissions();
    missions[0].target_owner_faction = .black_veil;
    missions[3].target_owner_faction = .black_veil;
    missions[3].completed = true;
    missions[4].target_owner_faction = .black_veil;
    missions[4].completed = true;
    try std.testing.expectEqual(faction.Standing.wary, faction.playerStanding(.black_veil, player.reputation, &missions));

    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var writer = TestWriter{};

    try run(&writer, "operation-start blackout-protocol", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.operation_state.active);
    try run(&writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 0), active);

    session.progress = .decrypted;
    session.current_node = "vault";
    for (missions[0].objectives) |objective| {
        if (!objective.optional and objective.kind != .extract_file) session.completeObjective(objective.kind);
    }
    try run(&writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(missions[0].completed);
    try std.testing.expectEqual(faction.Standing.hostile, faction.playerStanding(.black_veil, player.reputation, &missions));
    try std.testing.expectEqual(@as(?usize, 1), preparation.mission_index);

    try run(&writer, "accept job-02", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 1), active);
    try std.testing.expect(preparation.operation_state.active);
}
