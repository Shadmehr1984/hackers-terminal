const std = @import("std");
const game = @import("../src/game.zig");
const mission_data = @import("../src/mission_data.zig");
const MissionState = @import("../src/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const Player = @import("../src/player.zig").Player;
const Mission = @import("../src/mission.zig").Mission;

const TestWriter = struct {
    pub fn writeAll(_: @This(), _: []const u8) error{}!void {}
    pub fn print(_: @This(), comptime _: []const u8, _: anytype) error{}!void {}
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
