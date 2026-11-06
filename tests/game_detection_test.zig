const std = @import("std");
const game = @import("../src/game.zig");
const mission_data = @import("../src/mission_data.zig");
const MissionState = @import("../src/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const Player = @import("../src/player.zig").Player;
const Mission = @import("../src/mission.zig").Mission;
const ModifierId = @import("../src/domain/mission_modifier.zig").ModifierId;

const TestWriter = struct {
    pub fn writeAll(_: @This(), _: []const u8) error{}!void {}
    pub fn print(_: @This(), comptime _: []const u8, _: anytype) error{}!void {}
};

const FailOnPrintWriter = struct {
    calls: *usize,
    fail_on: usize,

    pub fn writeAll(_: @This(), _: []const u8) error{OutputFailure}!void {}

    pub fn print(self: @This(), comptime _: []const u8, _: anytype) error{OutputFailure}!void {
        self.calls.* += 1;
        if (self.calls.* == self.fail_on) return error.OutputFailure;
    }
};

fn run(writer: anytype, line: []const u8, player: *Player, missions: []Mission, active: *?usize, session: *MissionSession, preparation: *MissionPreparation) !void {
    _ = try game.runCommand(writer, line, player, missions, active, session, preparation);
}

test "risky actions increase exposure once while safe and invalid actions do not" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "scan wrong-target", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);

    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);

    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "disconnect", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);

    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "brute orion42", &player, &missions, &active, &session, &preparation);
    try run(writer, "brute orion42", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 20), session.detection_level);
    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);

    try run(writer, "buy decryptor", &player, &missions, &active, &session, &preparation);
    try run(writer, "decrypt wrong-key", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 40), session.detection_level);
    try run(writer, "decrypt midnight", &player, &missions, &active, &session, &preparation);
    try run(writer, "decrypt midnight", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 50), session.detection_level);

    try run(writer, "analyze ledger.enc", &player, &missions, &active, &session, &preparation);
    try run(writer, "analyze ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 55), session.detection_level);

    try run(writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(missions[0].completed);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
}

test "detection compromise fails contract, applies bounded penalty, and allows retry" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};

    const writer = TestWriter{};
    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);

    var attempt: u8 = 0;
    while (attempt < 6) : (attempt += 1) {
        try run(writer, "brute incorrect", &player, &missions, &active, &session, &preparation);
    }

    try std.testing.expect(active == null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 200), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try std.testing.expect(session.current_node == null);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 0), active);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
}

test "compromise penalty never makes player balance negative" {
    var player = Player{ .balance = 20 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    var attempt: u8 = 0;
    while (attempt < 6) : (attempt += 1) {
        try run(writer, "brute incorrect", &player, &missions, &active, &session, &preparation);
    }
    try std.testing.expectEqual(@as(u32, 0), player.balance);
}

test "extraction can trigger compromise before contract payout" {
    var player = Player{ .balance = 75 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{ .progress = .decrypted, .detection_level = 95, .current_node = "vault" };
    var preparation = MissionPreparation{};
    try std.testing.expect(session.initializeObjectives(missions[0].objectives));
    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);

    const writer = TestWriter{};
    try run(writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);

    try std.testing.expect(active == null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 25), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
}

test "topology rejects invalid movement without detection and charges every valid traversal" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqualStrings("entry", session.current_node.?);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);
    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqualStrings("entry", session.current_node.?);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqualStrings("service", session.current_node.?);
    try std.testing.expectEqual(@as(u8, 5), session.detection_level);
    try std.testing.expectEqual(@as(u32, 1), session.traversal_count);
    try run(writer, "move entry", &player, &missions, &active, &session, &preparation);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);
    try std.testing.expectEqual(@as(u32, 3), session.traversal_count);
}

test "all mission operations require their assigned topology locations" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);

    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "brute orion42", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(!session.connected);
    try std.testing.expect(!session.isAuthenticated());

    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "brute orion42", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(session.isAuthenticated());

    try run(writer, "buy decryptor", &player, &missions, &active, &session, &preparation);
    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try run(writer, "decrypt midnight", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(!session.isDecrypted());
    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);
    try run(writer, "decrypt midnight", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(session.isDecrypted());

    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try run(writer, "analyze ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(!session.isObjectiveComplete(.analyze_metadata));
    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);
    try run(writer, "analyze ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(session.isObjectiveComplete(.analyze_metadata));

    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try run(writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(active != null);
    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);
    try run(writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(missions[0].completed);
    try std.testing.expect(active == null);
    try std.testing.expect(session.current_node == null);
}

test "missions without topology preserve the original command flow" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    missions[0].topology = null;
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(session.current_node == null);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "brute orion42", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(session.isAuthenticated());
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);
}

test "topology movement reaching full detection triggers HT-001 failure and penalty" {
    var player = Player{ .balance = 90 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{ .detection_level = 95, .current_node = "service" };
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(active == null);
    try std.testing.expectEqual(@as(u32, 40), player.balance);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expect(session.current_node == null);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);
}

test "incorrect retries after authentication and decryption do not add detection" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "brute orion42", &player, &missions, &active, &session, &preparation);

    try std.testing.expect(session.isAuthenticated());
    const detection_after_authentication = session.detection_level;
    try run(writer, "brute wrong-password", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(detection_after_authentication, session.detection_level);
    try std.testing.expectEqual(@as(?usize, 0), active);

    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);
    try run(writer, "buy decryptor", &player, &missions, &active, &session, &preparation);
    try run(writer, "decrypt midnight", &player, &missions, &active, &session, &preparation);

    try std.testing.expect(session.isDecrypted());
    const detection_after_decryption = session.detection_level;
    try run(writer, "decrypt wrong-key", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(detection_after_decryption, session.detection_level);
    try std.testing.expectEqual(@as(?usize, 0), active);
}

test "heightened monitoring adds two after the utility-adjusted successful traversal cost" {
    var player = Player{};
    player.equipment.setOwned(.silent_boots);
    player.equipment.equipped_utility = .silent_boots;
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "modifier heightened-monitoring", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 6), session.detection_level);
    try std.testing.expectEqual(@as(u32, 1), session.traversal_count);

    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 6), session.detection_level);
    try std.testing.expectEqual(@as(u32, 1), session.traversal_count);
}

test "security sweep adds eight only after every third successful traversal" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "modifier security-sweep", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);

    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try run(writer, "move entry", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 10), session.detection_level);
    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 2), session.traversal_count);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 3), session.traversal_count);
    try std.testing.expectEqual(@as(u8, 23), session.detection_level);
}

test "security sweep does not run after the base traversal compromises the contract" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{
        .progress = .accepted,
        .detection_level = 95,
        .current_node = "service",
        .traversal_count = 2,
        .modifier = .security_sweep,
    };
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(active == null);
    try std.testing.expectEqual(@as(u32, 200), player.balance);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try std.testing.expect(session.modifier == null);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);
}

test "hardened encryption increases only incorrect decryption-key exposure" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "modifier hardened-encryption", &player, &missions, &active, &session, &preparation);
    try run(writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    try run(writer, "move service", &player, &missions, &active, &session, &preparation);
    try run(writer, "scan vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "connect vault-01.local", &player, &missions, &active, &session, &preparation);
    try run(writer, "brute orion42", &player, &missions, &active, &session, &preparation);
    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try run(writer, "move vault", &player, &missions, &active, &session, &preparation);
    try run(writer, "buy decryptor", &player, &missions, &active, &session, &preparation);
    try run(writer, "decrypt wrong-key", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 45), session.detection_level);

    try run(writer, "decrypt midnight", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 55), session.detection_level);
    try run(writer, "decrypt wrong-key", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u8, 55), session.detection_level);
}

test "modified contract compromise applies only the existing penalty and no modifier reward" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{
        .progress = .accepted,
        .detection_level = 95,
        .current_node = "service",
        .modifier = .hardened_encryption,
    };
    var preparation = MissionPreparation{};
    const writer = TestWriter{};

    try run(writer, "move corridor", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(active == null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 200), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expect(session.modifier == null);
}

test "modified extraction with incomplete required objectives does not pay rewards" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{
        .progress = .decrypted,
        .current_node = "vault",
        .modifier = .security_sweep,
    };
    var preparation = MissionPreparation{};
    const writer = TestWriter{};
    try std.testing.expect(session.initializeObjectives(missions[0].objectives));

    try run(writer, "extract ledger.enc", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(active != null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@import("../src/domain/mission_objectives.zig").ObjectiveState.undiscovered, session.objective_tracker.stateOf("maintenance-telemetry").?);
    try std.testing.expectEqual(@as(u32, 250), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expectEqual(@as(?ModifierId, .security_sweep), session.modifier);
}


test "failed movement output leaves topology and Detection state unchanged" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    const setup_writer = TestWriter{};

    try run(setup_writer, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try run(setup_writer, "accept job-01", &player, &missions, &active, &session, &preparation);
    session.detection_level = 20;

    var print_calls: usize = 0;
    const failing_writer = FailOnPrintWriter{ .calls = &print_calls, .fail_on = 2 };
    try std.testing.expectError(
        error.OutputFailure,
        run(failing_writer, "move service", &player, &missions, &active, &session, &preparation),
    );

    try std.testing.expectEqualStrings("entry", session.current_node.?);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);
    try std.testing.expectEqual(@as(u8, 20), session.detection_level);
    try std.testing.expectEqual(@as(?usize, 0), active);
}

test "failed Fixer output does not charge or consume the service" {
    var player = Player{ .reputation = 3 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{ .detection_level = 35 };
    var preparation = MissionPreparation{};
    const starting_balance = player.balance;

    var print_calls: usize = 0;
    const failing_writer = FailOnPrintWriter{ .calls = &print_calls, .fail_on = 1 };
    try std.testing.expectError(
        error.OutputFailure,
        run(failing_writer, "deal scrub-detection", &player, &missions, &active, &session, &preparation),
    );

    try std.testing.expectEqual(starting_balance, player.balance);
    try std.testing.expectEqual(@as(u8, 35), session.detection_level);
    try std.testing.expect(!session.fixer_service_used);
    try std.testing.expectEqual(@as(?usize, 0), active);
}
