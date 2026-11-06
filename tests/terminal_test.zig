const std = @import("std");
const terminal = @import("../src/terminal.zig");
const Player = @import("../src/player.zig").Player;
const MissionState = @import("../src/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const mission_data = @import("../src/mission_data.zig");
const FactionId = @import("../src/domain/faction_id.zig").FactionId;
const operation_data = @import("../src/catalog/operation_data.zig");

const Capture = struct {
    buffer: [4096]u8 = undefined,
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

test "active status output uses line breaks and includes location" {
    const player = Player{};
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    session.detection_level = 25;
    session.current_node = "relay";
    session.traversal_count = 2;
    session.modifier = .security_sweep;
    var capture = Capture{};

    try terminal.printStatus(&capture, player, 0, &missions, 1, 100, session);

    const output = capture.output();
    try std.testing.expect(std.mem.indexOf(u8, output, "Active job:  Cold Storage (job-01)\n  Detection:") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Detection:   25/100 (Noticed)\n  Location:    relay\n  Traversals:  2\n  Modifier:    Security Sweep") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\\n") == null);
}

test "inactive status output uses line breaks" {
    const player = Player{};
    const missions = mission_data.defaultMissions();
    const session = MissionSession{};
    var capture = Capture{};

    try terminal.printStatus(&capture, player, null, &missions, 1, 100, session);

    const output = capture.output();
    try std.testing.expect(std.mem.indexOf(u8, output, "Active job:  none\n  Detection:   inactive") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\\n") == null);
}

test "contract board output shows category rewards status and lock reasons without puzzle intel" {
    const missions = mission_data.defaultMissions();
    var capture = Capture{};
    try terminal.printContractBoard(&capture, &missions, 1, 0, false, null, null);
    const output = capture.output();
    try std.testing.expect(std.mem.indexOf(u8, output, "CONTRACT BOARD") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Data Recovery") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "$300-$375 + 100 XP") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "AVAILABLE") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "LOCKED") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Requires level 2") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "orion42") == null);
    try std.testing.expect(std.mem.indexOf(u8, output, "midnight") == null);
}

test "contract board marks incomplete contracts unavailable while another is busy" {
    const missions = mission_data.defaultMissions();
    var capture = Capture{};
    try terminal.printContractBoard(&capture, &missions, 3, 3, true, null, null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "UNAVAILABLE") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Finish or fail the active contract") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "EXCLUSIVE") == null);
}

test "faction terminal views show all organizations and relationship details" {
    const missions = mission_data.defaultMissions();
    var capture = Capture{};
    try terminal.printFactions(&capture, 0, &missions);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "FACTION NETWORK") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Nexus Dynamics") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Helix Consortium") != null);

    capture.len = 0;
    try terminal.printFaction(&capture, FactionId.black_veil, 0, &missions);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Black Veil [black-veil]") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Helix Consortium: Rivals") != null);
}

test "objective output hides undiscovered objectives but retains revealed unavailable ones" {
    const missions = mission_data.defaultMissions();
    var session = MissionSession{};
    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    session.markUncompletedOptionalObjectivesUnavailable();
    var capture = Capture{};
    try terminal.printObjectives(&capture, missions[0], session);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "maintenance telemetry signature") == null);

    try std.testing.expect(session.startWithMission(.{}, null, missions[0].objectives));
    try std.testing.expectEqual(@as(usize, 1), session.discoverNode("maintenance", missions[0].objectives));
    session.markUncompletedOptionalObjectivesUnavailable();
    capture.len = 0;
    try terminal.printObjectives(&capture, missions[0], session);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "[!] [OPTIONAL] Recover the maintenance telemetry signature") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "(+$0)") == null);
}

test "Broker contact and offers hide intelligence for faction-locked contracts" {
    const player = Player{ .reputation = 2, .xp = 250 };
    var missions = mission_data.defaultMissions();
    missions[0].completed = true;
    missions[1].completed = true;
    var capture = Capture{};
    try terminal.printOffers(&capture, player, &missions, null, MissionSession{}, MissionState.MissionPreparation{});
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "intel-job-05") == null);
    capture.len = 0;
    try terminal.printContact(&capture, .broker, player, &missions, null, MissionSession{}, MissionState.MissionPreparation{});
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "Corporate Ghost") == null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "intel-job-03") != null);
}

test "operation views expose faction locks and preserve active-operation preauthorization" {
    var missions = mission_data.defaultMissions();
    missions[0].client_faction = .nexus_dynamics;
    missions[0].target_owner_faction = .null_syndicate;
    missions[0].completed = true;
    missions[1].completed = true;
    missions[2].opposing_faction = .nexus_dynamics;
    missions[2].completed = true;
    const player = Player{ .reputation = 0, .xp = 250 };
    var capture = Capture{};
    var preparation = MissionState.MissionPreparation{};

    try terminal.printOperations(&capture, player, &missions, preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "FACTION LOCKED") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "blocked by Nexus Dynamics") != null);

    capture.len = 0;
    try terminal.printOperationDetails(&capture, operation_data.blackout_protocol, player, &missions, false);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "client: Nexus Dynamics | standing: HOSTILE | FACTION LOCKED") != null);

    try std.testing.expect(preparation.operation_state.start(operation_data.blackout_protocol, true));
    capture.len = 0;
    try terminal.printOperations(&capture, player, &missions, preparation);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "IN PROGRESS | PREAUTHORIZED; current client standing: Nexus Dynamics (HOSTILE)") != null);

    capture.len = 0;
    try terminal.printOperationDetails(&capture, operation_data.blackout_protocol, player, &missions, true);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "client: Nexus Dynamics | standing: HOSTILE | PREAUTHORIZED") != null);

    capture.len = 0;
    try terminal.printOperationStatus(&capture, player, preparation, &missions);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "current standing: HOSTILE | PREAUTHORIZED at operation start") != null);
}

test "contract board reports reward overflow without aborting or displaying a wrapped amount" {
    const MissionObjective = @import("../src/domain/mission.zig").MissionObjective;
    var missions = mission_data.defaultMissions();
    const objectives = [_]MissionObjective{
        .{ .id = "first", .kind = .analyze_metadata, .description = "First", .optional = true, .bonus_reward = std.math.maxInt(u32) },
        .{ .id = "second", .kind = .analyze_metadata, .description = "Second", .optional = true, .bonus_reward = 1 },
    };
    missions[0].objectives = &objectives;
    var capture = Capture{};
    try terminal.printContractBoard(&capture, &missions, 1, 0, false);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "[job-01] Cold Storage — REWARD ERROR") != null);
    try std.testing.expect(std.mem.indexOf(u8, capture.output(), "maximum cash reward exceeds the supported range") != null);
}
