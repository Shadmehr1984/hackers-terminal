const std = @import("std");
const mission_state = @import("../src/mission_state.zig");

const MissionProgress = mission_state.MissionProgress;
const MissionSession = mission_state.MissionSession;

test "new session starts inactive and disconnected" {
    const session = MissionSession{};
    try std.testing.expectEqual(MissionProgress.inactive, session.progress);
    try std.testing.expect(!session.connected);
    try std.testing.expect(!session.hasScanned());
    try std.testing.expect(!session.isAuthenticated());
    try std.testing.expect(!session.isDecrypted());
}

test "start initializes an accepted mission" {
    var session = MissionSession{ .progress = .decrypted, .connected = true };
    session.start();
    try std.testing.expectEqual(MissionProgress.accepted, session.progress);
    try std.testing.expect(!session.connected);
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
    var session = MissionSession{ .progress = .decrypted, .connected = true };
    session.reset();
    try std.testing.expectEqual(MissionProgress.inactive, session.progress);
    try std.testing.expect(!session.connected);
    try std.testing.expect(!session.hasScanned());
    try std.testing.expect(!session.isAuthenticated());
    try std.testing.expect(!session.isDecrypted());
}
