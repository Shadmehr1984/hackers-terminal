const std = @import("std");
const mission_state = @import("../src/mission_state.zig");

const MissionProgress = mission_state.MissionProgress;
const MissionSession = mission_state.MissionSession;
const MissionPreparation = mission_state.MissionPreparation;
const ModifierId = @import("../src/domain/mission_modifier.zig").ModifierId;
const mission_data = @import("../src/catalog/mission_data.zig");

test "new session starts inactive and disconnected" {
    const session = MissionSession{};
    try std.testing.expectEqual(MissionProgress.inactive, session.progress);
    try std.testing.expect(!session.connected);
    try std.testing.expect(!session.hasScanned());
    try std.testing.expect(!session.isAuthenticated());
    try std.testing.expect(!session.isDecrypted());
}

test "start initializes an accepted mission" {
    var session = MissionSession{ .progress = .decrypted, .connected = true, .current_node = "stale-node" };
    session.start();
    try std.testing.expectEqual(MissionProgress.accepted, session.progress);
    try std.testing.expect(!session.connected);
    try std.testing.expect(session.current_node == null);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);
}

test "mission progress follows required stages" {
    var session = MissionSession{};
    session.start();

    session.markScanned();
    try std.testing.expectEqual(MissionProgress.scanned, session.progress);
    try std.testing.expect(session.hasScanned());

    session.markAuthenticated();
    try std.testing.expectEqual(MissionProgress.authenticated, session.progress);
    try std.testing.expect(session.isAuthenticated());

    session.markDecrypted();
    try std.testing.expectEqual(MissionProgress.decrypted, session.progress);
    try std.testing.expect(session.isDecrypted());
}

test "authentication cannot skip scanning" {
    var session = MissionSession{};
    session.start();
    session.markAuthenticated();
    try std.testing.expectEqual(MissionProgress.accepted, session.progress);
    try std.testing.expect(!session.isAuthenticated());
}

test "decryption cannot skip authentication" {
    var session = MissionSession{};
    session.start();
    session.markScanned();
    session.markDecrypted();
    try std.testing.expectEqual(MissionProgress.scanned, session.progress);
    try std.testing.expect(!session.isDecrypted());
}

test "disconnecting does not erase mission progress" {
    var session = MissionSession{};
    session.start();
    session.markScanned();
    session.connected = true;
    session.markAuthenticated();
    session.markDecrypted();
    session.connected = false;

    try std.testing.expect(!session.connected);
    try std.testing.expect(session.hasScanned());
    try std.testing.expect(session.isAuthenticated());
    try std.testing.expect(session.isDecrypted());
}

test "reset returns session to inactive" {
    var session = MissionSession{ .progress = .decrypted, .connected = true, .current_node = "vault", .traversal_count = 8 };
    session.reset();
    try std.testing.expectEqual(MissionProgress.inactive, session.progress);
    try std.testing.expect(!session.connected);
    try std.testing.expect(!session.hasScanned());
    try std.testing.expect(!session.isAuthenticated());
    try std.testing.expect(!session.isDecrypted());
    try std.testing.expect(session.current_node == null);
    try std.testing.expectEqual(@as(u32, 0), session.traversal_count);
}

test "detection starts quiet, changes bands at thresholds, and caps at 100" {
    var session = MissionSession{};
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try std.testing.expectEqual(mission_state.DetectionBand.quiet, session.detectionBand());

    session.addDetection(25);
    try std.testing.expectEqual(mission_state.DetectionBand.noticed, session.detectionBand());
    session.addDetection(25);
    try std.testing.expectEqual(mission_state.DetectionBand.traced, session.detectionBand());
    session.addDetection(25);
    try std.testing.expectEqual(mission_state.DetectionBand.critical, session.detectionBand());
    session.addDetection(100);
    try std.testing.expectEqual(@as(u8, 100), session.detection_level);
    try std.testing.expectEqual(mission_state.DetectionBand.compromised, session.detectionBand());
    session.addDetection(10);
    try std.testing.expectEqual(@as(u8, 100), session.detection_level);
}

test "starting and resetting a mission clear detection exposure" {
    var session = MissionSession{};
    session.addDetection(80);
    session.start();
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    session.addDetection(40);
    session.reset();
    try std.testing.expectEqual(@as(u8, 0), session.detection_level);
    try std.testing.expectEqual(mission_state.DetectionBand.quiet, session.detectionBand());
}

test "preparation selects only modifiers allowed by the prepared mission" {
    const missions = mission_data.defaultMissions();
    var preparation = MissionPreparation{};

    try std.testing.expect(preparation.selected_modifier == null);
    try std.testing.expect(preparation.selectModifier(missions[0], .heightened_monitoring));
    try std.testing.expectEqual(@as(?ModifierId, .heightened_monitoring), preparation.selected_modifier);

    var restricted = missions[0];
    restricted.allowed_modifiers = &.{.security_sweep};
    try std.testing.expect(!preparation.selectModifier(restricted, .hardened_encryption));
    try std.testing.expectEqual(@as(?ModifierId, .heightened_monitoring), preparation.selected_modifier);
    try std.testing.expect(preparation.selectModifier(restricted, .security_sweep));
    try std.testing.expectEqual(@as(?ModifierId, .security_sweep), preparation.selected_modifier);
}

test "clearing preparation also clears the selected modifier" {
    const missions = mission_data.defaultMissions();
    var preparation = MissionPreparation{};
    try std.testing.expect(preparation.selectModifier(missions[0], .security_sweep));
    preparation.clear();
    try std.testing.expect(preparation.mission_index == null);
    try std.testing.expect(preparation.selected_utility == null);
    try std.testing.expect(preparation.selected_modifier == null);
}

test "addDetection clamps an already out-of-range session to the compromise ceiling" {
    var session = MissionSession{ .detection_level = 101 };
    session.addDetection(1);
    try std.testing.expectEqual(@as(u8, 100), session.detection_level);
}
