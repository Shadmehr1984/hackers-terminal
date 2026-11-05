const std = @import("std");
const Player = @import("../src/player.zig").Player;
const Mission = @import("../src/mission.zig").Mission;
const MissionSession = @import("../src/mission_state.zig").MissionSession;
const MissionPreparation = @import("../src/mission_state.zig").MissionPreparation;
const mission_data = @import("../src/mission_data.zig");
const progression = @import("../src/progression.zig");
const contacts = @import("../src/contacts.zig");
const game = @import("../src/game.zig");

const Capture = struct {
    buffer: [8192]u8 = undefined,
    len: usize = 0,

    fn output(self: *const Capture) []const u8 {
        return self.buffer[0..self.len];
    }

    pub fn writeAll(self: *@This(), bytes: []const u8) error{NoSpaceLeft}!void {
        if (bytes.len > self.buffer.len - self.len) return error.NoSpaceLeft;
        @memcpy(self.buffer[self.len .. self.len + bytes.len], bytes);
        self.len += bytes.len;
    }

    pub fn print(self: *@This(), comptime format: []const u8, args: anytype) !void {
        const written = try std.fmt.bufPrint(self.buffer[self.len..], format, args);
        self.len += written.len;
    }
};

fn run(writer: anytype, line: []const u8, player: *Player, missions: []Mission, active: *?usize, session: *MissionSession, preparation: *MissionPreparation) !void {
    _ = try game.runCommand(writer, line, player, missions, active, session, preparation);
}

test "reputation tiers use the approved boundaries" {
    try std.testing.expectEqual(progression.ReputationTier.unknown, progression.reputationTier(0));
    try std.testing.expectEqual(progression.ReputationTier.recognized, progression.reputationTier(1));
    try std.testing.expectEqual(progression.ReputationTier.recognized, progression.reputationTier(2));
    try std.testing.expectEqual(progression.ReputationTier.trusted, progression.reputationTier(3));
    try std.testing.expectEqual(progression.ReputationTier.trusted, progression.reputationTier(4));
    try std.testing.expectEqual(progression.ReputationTier.elite, progression.reputationTier(5));
    try std.testing.expectEqualStrings("Elite", progression.reputationTier(99).label());
}

test "contact unlock thresholds and Fixer service pricing follow reputation tier" {
    try std.testing.expect(!contacts.isUnlocked(.broker, 0));
    try std.testing.expect(contacts.isUnlocked(.broker, 1));
    try std.testing.expect(!contacts.isUnlocked(.fixer, 2));
    try std.testing.expect(contacts.isUnlocked(.fixer, 3));
    try std.testing.expectEqual(@as(?u32, null), contacts.fixerServicePrice(2));
    try std.testing.expectEqual(@as(?u32, 100), contacts.fixerServicePrice(3));
    try std.testing.expectEqual(@as(?u32, 100), contacts.fixerServicePrice(4));
    try std.testing.expectEqual(@as(?u32, 75), contacts.fixerServicePrice(5));
}

test "mission completion grants one reputation and one extra for all optional objectives" {
    var missions = mission_data.defaultMissions();
    const mission = missions[0];
    var player = Player{};
    var session = MissionSession{};
    session.start();
    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);
    session.completeObjective(.decrypt_file);
    session.completeObjective(.extract_file);
    var capture = Capture{};

    try progression.completeMission(&capture, &player, mission, session);
    try std.testing.expectEqual(@as(u32, 1), player.reputation);

    player = Player{};
    session.completeObjective(.analyze_metadata);
    capture.len = 0;
    try progression.completeMission(&capture, &player, mission, session);
    try std.testing.expectEqual(@as(u32, 2), player.reputation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Reputation increased by 2") != null);
}

test "Broker intelligence charges once per purchase and reveals hints but not answers" {
    var player = Player{ .balance = 100, .reputation = 1, .xp = 100 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "deal intel-job-02", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 50), player.balance);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), missions[1].password_hint) != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), missions[1].decryption_hint) != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "copper17") == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "bluebird") == null);

    capture.len = 0;
    try run(&capture, "deal intel-job-04", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 50), player.balance);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Reputation 3") != null);
}

test "Fixer Detection service is gated, costs by tier, and can be used once per mission" {
    var player = Player{ .balance = 200, .reputation = 2 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{ .detection_level = 15 };
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "deal scrub-detection", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 200), player.balance);
    try std.testing.expectEqual(@as(u8, 15), session.detection_level);

    player.reputation = 3;
    try run(&capture, "deal scrub-detection", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 100), player.balance);
    try std.testing.expectEqual(@as(u8, 5), session.detection_level);
    try std.testing.expect(session.fixer_service_used);

    try run(&capture, "deal scrub-detection", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 100), player.balance);
    try std.testing.expectEqual(@as(u8, 5), session.detection_level);

    session.start();
    try std.testing.expect(!session.fixer_service_used);
}

test "Fixer Ghost Signal offer requires level and reputation and prepares appended contract" {
    var player = Player{ .reputation = 2, .xp = 250 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try std.testing.expectEqual(@as(usize, 4), missions.len);
    try std.testing.expectEqualStrings("job-04", missions[3].id);
    try run(&capture, "prepare job-04", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.mission_index == null);
    try run(&capture, "deal ghost-signal", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(preparation.mission_index == null);

    player.reputation = 3;
    try run(&capture, "deal ghost-signal", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 3), preparation.mission_index);
    try run(&capture, "accept job-04", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(?usize, 3), active);
    try std.testing.expectEqualStrings("entry", session.current_node.?);
}

test "contact and offer commands expose only currently unlocked opportunities" {
    var player = Player{ .reputation = 1, .xp = 100 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "contacts", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "[UNLOCKED] Information Broker") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "[LOCKED] Fixer") != null);

    capture.len = 0;
    try run(&capture, "offers", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "intel-job-02") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "ghost-signal") == null);
}

test "unaffordable Broker and Fixer deals leave player and session state unchanged" {
    var player = Player{ .balance = 49, .reputation = 1, .xp = 100 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{ .detection_level = 20 };
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "deal intel-job-02", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 49), player.balance);

    player.reputation = 3;
    player.balance = 99;
    try run(&capture, "deal scrub-detection", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 99), player.balance);
    try std.testing.expectEqual(@as(u8, 20), session.detection_level);
    try std.testing.expect(!session.fixer_service_used);
}

test "Fixer service rejects zero Detection and inactive missions without charging" {
    var player = Player{ .balance = 200, .reputation = 5 };
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    var capture = Capture{};

    try run(&capture, "deal scrub-detection", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 200), player.balance);
    try std.testing.expect(!session.fixer_service_used);

    session.detection_level = 25;
    active = null;
    try run(&capture, "deal scrub-detection", &player, &missions, &active, &session, &preparation);
    try std.testing.expectEqual(@as(u32, 200), player.balance);
    try std.testing.expectEqual(@as(u8, 25), session.detection_level);
    try std.testing.expect(!session.fixer_service_used);
}
