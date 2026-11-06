const std = @import("std");
const game = @import("../src/game.zig");
const rival = @import("../src/domain/rival.zig");
const rival_data = @import("../src/catalog/rival_data.zig");
const rival_simulation = @import("../src/domain/rival_simulation.zig");
const faction_data = @import("../src/catalog/faction_data.zig");
const mission_data = @import("../src/mission_data.zig");
const MissionState = @import("../src/mission_state.zig");
const Player = @import("../src/player.zig").Player;

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

test "rival catalog contains five unique profiles with valid faction mission and objective references" {
    const missions = mission_data.defaultMissions();
    try std.testing.expect(rival_data.validate(&missions));
    try std.testing.expectEqual(@as(usize, 5), rival_data.all().len);
    for (rival_data.all()) |entry| {
        try std.testing.expect(faction_data.find(entry.faction) != null);
        try std.testing.expectEqual(entry.id, rival.RivalId.parse(entry.id.slug()).?);
        try std.testing.expect(rival_data.forMission(entry.mission_id) != null);
    }
}

test "rival contest status is deterministic across dormant contesting rival-ahead and outpaced states" {
    var missions = mission_data.defaultMissions();
    const patchwork = rival_data.find(.patchwork).?;
    try std.testing.expectEqual(rival.RivalStatus.contesting, rival_simulation.status(patchwork, &missions, 1, 0, null, null));

    const ghost = rival_data.find(.ghost_operator).?;
    try std.testing.expectEqual(rival.RivalStatus.dormant, rival_simulation.status(ghost, &missions, 1, 0, null, null));

    var tracker = @import("../src/domain/mission_objectives.zig").Tracker{};
    try std.testing.expect(tracker.initialize(missions[0].objectives));
    try std.testing.expectEqual(rival.RivalId.patchwork, rival_simulation.resolveAfterDecryption("job-01", &tracker).?);
    try std.testing.expectEqual(@import("../src/domain/mission_objectives.zig").ObjectiveState.unavailable, tracker.stateOf("maintenance-telemetry").?);
    try std.testing.expectEqual(rival.RivalStatus.rival_ahead, rival_simulation.status(patchwork, &missions, 1, 0, "job-01", &tracker));

    try std.testing.expect(tracker.initialize(missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverNode("maintenance", missions[0].objectives));
    try std.testing.expect(rival_simulation.resolveAfterDecryption("job-01", &tracker) == null);
    try std.testing.expectEqual(rival.RivalStatus.outpaced, rival_simulation.status(patchwork, &missions, 1, 0, "job-01", &tracker));

    missions[0].completed = true;
    try std.testing.expectEqual(rival.RivalStatus.outpaced, rival_simulation.status(patchwork, &missions, 1, 0, null, null));
}

test "rivals commands list five dossiers and inspect one without exposing puzzle answers" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = null;
    var session = MissionState.MissionSession{};
    var preparation = MissionState.MissionPreparation{};
    var capture = Capture{};

    _ = try game.runCommand(&capture, "rivals", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "RIVAL NETWORK") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Ghost Operator") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Redshift") != null);
    try std.testing.expectEqual(@as(usize, 5), std.mem.count(u8, capture.output(), "Contest:"));

    capture.len = 0;
    _ = try game.runCommand(&capture, "rival null-byte", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Null Byte [null-byte]") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "cloudburst") == null);
}

test "decrypting before discovering contested optional evidence lets the rival claim only that opportunity" {
    var player = Player{};
    player.equipment.has_decryptor = true;
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionState.MissionSession{ .progress = .authenticated, .current_node = "vault" };
    var preparation = MissionState.MissionPreparation{};
    try std.testing.expect(session.initializeObjectives(missions[0].objectives));
    var capture = Capture{};

    _ = try game.runCommand(&capture, "decrypt midnight", &player, &missions, &active, &session, &preparation);

    try std.testing.expect(session.isDecrypted());
    try std.testing.expectEqual(@import("../src/domain/mission_objectives.zig").ObjectiveState.unavailable, session.objective_tracker.stateOf("maintenance-telemetry").?);
    try std.testing.expectEqual(@as(?usize, 0), active);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "[RIVAL AHEAD] Patchwork") != null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 0), player.balance - 250);
}
