const std = @import("std");
const game = @import("../src/game.zig");
const rival = @import("../src/domain/rival.zig");
const Mission = @import("../src/domain/mission.zig").Mission;
const MissionObjective = @import("../src/domain/mission.zig").MissionObjective;
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
    try std.testing.expect(rival_simulation.resolveAfterDecryption(patchwork, &tracker));
    try std.testing.expectEqual(@import("../src/domain/mission_objectives.zig").ObjectiveState.unavailable, tracker.stateOf("maintenance-telemetry").?);
    try std.testing.expectEqual(rival.RivalStatus.rival_ahead, rival_simulation.status(patchwork, &missions, 1, 0, "job-01", &tracker));

    try std.testing.expect(tracker.initialize(missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverNode("maintenance", missions[0].objectives));
    try std.testing.expect(!rival_simulation.resolveAfterDecryption(patchwork, &tracker));
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
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Null Byte") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Glasswire") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Patchwork") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Redshift") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "relay-trace") == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "maintenance-telemetry") == null);

    capture.len = 0;
    _ = try game.runCommand(&capture, "rival null-byte", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Null Byte [null-byte]") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "cloudburst") == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "mirror-fragment") == null);

    capture.len = 0;
    _ = try game.runCommand(&capture, "board", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Rival: Patchwork | CONTESTING") != null);

    capture.len = 0;
    _ = try game.runCommand(&capture, "prepare job-01", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "RIVAL INTELLIGENCE: Patchwork") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "maintenance-side signal") != null);
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

    capture.len = 0;
    _ = try game.runCommand(&capture, "board", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Rival: Patchwork | RIVAL AHEAD") != null);

    capture.len = 0;
    _ = try game.runCommand(&capture, "briefing", &player, &missions, &active, &session, &preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "The rival secured this optional intelligence for the current run.") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "may be contested before decrypting") == null);
    try std.testing.expect(!missions[0].completed);
    try std.testing.expectEqual(@as(u32, 250), player.balance);
    try std.testing.expectEqual(@as(u32, 0), player.xp);
    try std.testing.expectEqual(@as(u32, 0), player.reputation);
    try std.testing.expectEqual(@as(u8, 10), session.detection_level);

    session.completeObjective(.scan_target);
    session.completeObjective(.authenticate);
    session.completeObjective(.extract_file);
    try std.testing.expect(session.allObjectivesComplete(missions[0].objectives));
}

test "decryption compromise resets the run without awarding the rival side opportunity" {
    var player = Player{};
    player.equipment.has_decryptor = true;
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionState.MissionSession{
        .progress = .authenticated,
        .detection_level = 95,
        .current_node = "vault",
    };
    var preparation = MissionState.MissionPreparation{};
    try std.testing.expect(session.initializeObjectives(missions[0].objectives));
    var capture = Capture{};

    _ = try game.runCommand(&capture, "decrypt midnight", &player, &missions, &active, &session, &preparation);

    try std.testing.expect(active == null);
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "[RIVAL AHEAD]") == null);
    try std.testing.expect(!missions[0].completed);
}

test "active briefing reports when the player outpaces the rival before decryption" {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    var active: ?usize = 0;
    var session = MissionState.MissionSession{ .progress = .authenticated, .current_node = "maintenance" };
    var preparation = MissionState.MissionPreparation{};
    try std.testing.expect(session.initializeObjectives(missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    var capture = Capture{};

    _ = try game.runCommand(&capture, "briefing", &player, &missions, &active, &session, &preparation);

    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Status: OUTPACED") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "You found the contested intelligence first.") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "may be contested before decrypting") == null);
}


test "all five rival contests honor their authored node file and action discovery triggers" {
    const missions = mission_data.defaultMissions();
    for (rival_data.all()) |entry| {
        var selected_mission: ?Mission = null;
        for (missions) |mission| {
            if (std.mem.eql(u8, mission.id, entry.mission_id)) {
                selected_mission = mission;
                break;
            }
        }
        try std.testing.expect(selected_mission != null);
        const mission = selected_mission.?;
        var contested_objective: ?MissionObjective = null;
        for (mission.objectives) |objective| {
            if (std.mem.eql(u8, objective.id, entry.objective_id)) {
                contested_objective = objective;
                break;
            }
        }
        try std.testing.expect(contested_objective != null);
        const objective = contested_objective.?;
        try std.testing.expect(objective.discovery_trigger != null);
        const trigger = objective.discovery_trigger.?;

        var player_first_tracker = @import("../src/domain/mission_objectives.zig").Tracker{};
        try std.testing.expect(player_first_tracker.initialize(mission.objectives));
        switch (trigger) {
            .node => |node_id| try std.testing.expectEqual(@as(usize, 1), player_first_tracker.discoverNode(node_id, mission.objectives)),
            .file => |file_id| try std.testing.expectEqual(@as(usize, 1), player_first_tracker.discoverFile(file_id, mission.objectives)),
            .action => |action| try std.testing.expectEqual(@as(usize, 1), player_first_tracker.discoverAction(action, mission.objectives)),
        }
        try std.testing.expect(!rival_simulation.resolveAfterDecryption(entry, &player_first_tracker));
        try std.testing.expectEqual(
            @import("../src/domain/mission_objectives.zig").ObjectiveState.discovered,
            player_first_tracker.stateOf(entry.objective_id).?,
        );

        var rival_first_tracker = @import("../src/domain/mission_objectives.zig").Tracker{};
        try std.testing.expect(rival_first_tracker.initialize(mission.objectives));
        try std.testing.expect(rival_simulation.resolveAfterDecryption(entry, &rival_first_tracker));
        try std.testing.expectEqual(
            @import("../src/domain/mission_objectives.zig").ObjectiveState.unavailable,
            rival_first_tracker.stateOf(entry.objective_id).?,
        );
    }
}
