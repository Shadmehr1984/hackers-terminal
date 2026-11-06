const std = @import("std");
const Player = @import("../src/player.zig").Player;
const progression = @import("../src/progression.zig");
const MissionState = @import("../src/domain/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const game = @import("../src/game.zig");
const MissionObjective = @import("../src/domain/mission.zig").MissionObjective;
const mission_data = @import("../src/catalog/mission_data.zig");

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

const TestWriter = struct {
    pub fn writeAll(_: @This(), _: []const u8) error{}!void {}
    pub fn print(_: @This(), comptime _: []const u8, _: anytype) error{}!void {}
};

const FailingWriter = struct {
    pub fn writeAll(_: @This(), _: []const u8) error{OutputFailure}!void {
        return error.OutputFailure;
    }

    pub fn print(_: @This(), comptime _: []const u8, _: anytype) error{OutputFailure}!void {
        return error.OutputFailure;
    }
};

test "modified completion bonus is paid once even if completion is re-entered" {
    var player = Player{};
    const missions = mission_data.defaultMissions();
    var session = MissionSession{ .modifier = .hardened_encryption };
    const writer = TestWriter{};

    try progression.completeMission(writer, &player, missions[0], &session);
    try std.testing.expectEqual(@as(u32, 600), player.balance);
    try std.testing.expectEqual(@as(u32, 125), player.xp);
    try std.testing.expectEqual(@as(u32, 1), player.reputation);
    try std.testing.expect(session.completion_reward_paid);

    try progression.completeMission(writer, &player, missions[0], &session);
    try std.testing.expectEqual(@as(u32, 600), player.balance);
    try std.testing.expectEqual(@as(u32, 125), player.xp);
    try std.testing.expectEqual(@as(u32, 1), player.reputation);

    session.reset();
    try std.testing.expect(!session.completion_reward_paid);
    try std.testing.expect(session.modifier == null);
}

test "authored hidden cash reward is paid exactly once on successful completion" {
    const missions = mission_data.defaultMissions();
    var mission = missions[0];
    var objectives: [6]MissionObjective = undefined;
    for (mission.objectives, 0..) |objective, index| objectives[index] = objective;
    objectives[5].bonus_reward = 50;
    mission.objectives = &objectives;

    var player = Player{};
    var session = MissionSession{};
    try std.testing.expect(session.startWithMission(.{}, null, &objectives));
    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);
    session.completeObjective(.extract_file);
    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", &objectives));
    session.completeObjective(.analyze_metadata);

    const writer = TestWriter{};
    try progression.completeMission(writer, &player, mission, &session);
    try std.testing.expectEqual(@as(u32, 675), player.balance);
    try std.testing.expectEqual(@as(u32, 100), player.xp);
    try std.testing.expectEqual(@as(u32, 2), player.reputation);

    try progression.completeMission(writer, &player, mission, &session);
    try std.testing.expectEqual(@as(u32, 675), player.balance);
    try std.testing.expectEqual(@as(u32, 100), player.xp);
    try std.testing.expectEqual(@as(u32, 2), player.reputation);
}

test "reward overflow leaves player and completion guard unchanged" {
    const missions = mission_data.defaultMissions();
    const writer = TestWriter{};

    var cash_player = Player{ .balance = std.math.maxInt(u32) };
    var cash_session = MissionSession{};
    try std.testing.expectError(
        error.RewardOverflow,
        progression.completeMission(writer, &cash_player, missions[0], &cash_session),
    );
    try std.testing.expectEqual(std.math.maxInt(u32), cash_player.balance);
    try std.testing.expectEqual(@as(u32, 0), cash_player.reputation);
    try std.testing.expectEqual(@as(u32, 0), cash_player.xp);
    try std.testing.expect(!cash_session.completion_reward_paid);

    var reputation_player = Player{ .balance = 100, .reputation = std.math.maxInt(u32) };
    var reputation_session = MissionSession{};
    try std.testing.expectError(
        error.RewardOverflow,
        progression.completeMission(writer, &reputation_player, missions[0], &reputation_session),
    );
    try std.testing.expectEqual(std.math.maxInt(u32), reputation_player.reputation);
    try std.testing.expectEqual(@as(u32, 100), reputation_player.balance);
    try std.testing.expectEqual(@as(u32, 0), reputation_player.xp);
    try std.testing.expect(!reputation_session.completion_reward_paid);

    var xp_player = Player{ .balance = 100, .xp = std.math.maxInt(u32) };
    var xp_session = MissionSession{};
    try std.testing.expectError(
        error.RewardOverflow,
        progression.completeMission(writer, &xp_player, missions[0], &xp_session),
    );
    try std.testing.expectEqual(std.math.maxInt(u32), xp_player.xp);
    try std.testing.expectEqual(@as(u32, 100), xp_player.balance);
    try std.testing.expectEqual(@as(u32, 0), xp_player.reputation);
    try std.testing.expect(!xp_session.completion_reward_paid);
}

test "mission remains active and optional objective state is preserved when payout overflows" {
    var player = Player{ .balance = std.math.maxInt(u32) };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    _ = try game.runCommand(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    _ = try game.runCommand(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    session.progress = .decrypted;
    session.current_node = "vault";
    for (missions[0].objectives) |objective| {
        if (!objective.optional and objective.kind != .extract_file) session.completeObjective(objective.kind);
    }
    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));

    _ = try game.runCommand(writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 0), active);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(std.math.maxInt(u32), player.balance);
    try std.testing.expect(!session.completion_reward_paid);
    try std.testing.expectEqual(.discovered, session.objective_tracker.stateOf("maintenance-telemetry").?);
    try std.testing.expectEqual(.discovered, session.objective_tracker.stateOf("analyze-metadata").?);
}

const FailOnSecondPrintWriter = struct {
    print_count: usize = 0,

    pub fn writeAll(_: *@This(), _: []const u8) error{OutputFailure}!void {}

    pub fn print(self: *@This(), comptime _: []const u8, _: anytype) error{OutputFailure}!void {
        self.print_count += 1;
        if (self.print_count == 2) return error.OutputFailure;
    }
};

test "mission optional objectives remain discovered when completion output fails" {
    var player = Player{ .balance = 100 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{ .progress = .decrypted, .current_node = "vault" };
    var preparation = MissionPreparation{};
    try std.testing.expect(session.initializeObjectives(missions[0].objectives));
    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);
    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    var writer = FailOnSecondPrintWriter{};

    try std.testing.expectError(
        error.OutputFailure,
        game.runCommand(&writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation),
    );

    try std.testing.expectEqual(@as(?usize, 0), active);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 100), player.balance);
    try std.testing.expect(!session.completion_reward_paid);
    try std.testing.expectEqual(.discovered, session.objective_tracker.stateOf("maintenance-telemetry").?);
    try std.testing.expectEqual(.discovered, session.objective_tracker.stateOf("analyze-metadata").?);
}

test "writer failure does not commit mission payout or completion guard" {
    const missions = mission_data.defaultMissions();
    var player = Player{ .balance = 100 };
    var session = MissionSession{};

    try std.testing.expectError(
        error.OutputFailure,
        progression.completeMission(FailingWriter{}, &player, missions[0], &session),
    );
    try std.testing.expectEqual(@as(u32, 100), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expect(!session.completion_reward_paid);
}

test "optional objective accumulation overflow leaves payout state unchanged" {
    const missions = mission_data.defaultMissions();
    var mission = missions[0];
    var objectives: [6]MissionObjective = undefined;
    for (mission.objectives, 0..) |objective, index| objectives[index] = objective;
    objectives[4].bonus_reward = std.math.maxInt(u32);
    objectives[5].bonus_reward = 1;
    objectives[5].hidden = false;
    objectives[5].discovery_trigger = null;
    mission.objectives = &objectives;

    var player = Player{ .balance = 100 };
    var session = MissionSession{};
    try std.testing.expect(session.startWithMission(.{}, null, mission.objectives));
    session.completeObjective(.analyze_metadata);
    try std.testing.expectError(
        error.RewardOverflow,
        progression.completeMission(TestWriter{}, &player, mission, &session),
    );
    try std.testing.expectEqual(@as(u32, 100), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expect(!session.completion_reward_paid);
}
