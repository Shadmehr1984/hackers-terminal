pub const MissionProgress = enum {
    inactive,
    accepted,
    scanned,
    authenticated,
    decrypted,
};

/// Runtime-only state for the active mission.
/// Progress is monotonic; connection status is independent so disconnecting
/// does not revoke authentication or decryption already achieved.
pub const MissionSession = struct {
    progress: MissionProgress = .inactive,
    connected: bool = false,

    pub fn start(self: *MissionSession) void {
        self.progress = .accepted;
        self.connected = false;
    }

    pub fn reset(self: *MissionSession) void {
        self.progress = .inactive;
        self.connected = false;
    }

    pub fn hasScanned(self: MissionSession) bool {
        return switch (self.progress) {
            .scanned, .authenticated, .decrypted => true,
            .inactive, .accepted => false,
        };
    }

    pub fn isAuthenticated(self: MissionSession) bool {
        return switch (self.progress) {
            .authenticated, .decrypted => true,
            .inactive, .accepted, .scanned => false,
        };
    }

    pub fn isDecrypted(self: MissionSession) bool {
        return self.progress == .decrypted;
    }

    pub fn markScanned(self: *MissionSession) void {
        if (self.progress == .accepted) self.progress = .scanned;
    }

    pub fn markAuthenticated(self: *MissionSession) void {
        if (self.progress == .scanned) {
            self.progress = .authenticated;
        }
    }

    pub fn markDecrypted(self: *MissionSession) void {
        if (self.isAuthenticated()) self.progress = .decrypted;
    }
};


test "new session starts inactive and disconnected" {
    const testing = @import("std").testing;
    const session = MissionSession{};
    try testing.expectEqual(MissionProgress.inactive, session.progress);
    try testing.expect(!session.connected);
    try testing.expect(!session.hasScanned());
    try testing.expect(!session.isAuthenticated());
    try testing.expect(!session.isDecrypted());
}

test "start initializes an accepted mission" {
    const testing = @import("std").testing;
    var session = MissionSession{ .progress = .decrypted, .connected = true };
    session.start();
    try testing.expectEqual(MissionProgress.accepted, session.progress);
    try testing.expect(!session.connected);
}

test "mission progress follows required stages" {
    const testing = @import("std").testing;
    var session = MissionSession{};
    session.start();

    session.markScanned();
    try testing.expectEqual(MissionProgress.scanned, session.progress);
    try testing.expect(session.hasScanned());

    session.markAuthenticated();
    try testing.expectEqual(MissionProgress.authenticated, session.progress);
    try testing.expect(session.isAuthenticated());

    session.markDecrypted();
    try testing.expectEqual(MissionProgress.decrypted, session.progress);
    try testing.expect(session.isDecrypted());
}

test "authentication cannot skip scanning" {
    const testing = @import("std").testing;
    var session = MissionSession{};
    session.start();
    session.markAuthenticated();
    try testing.expectEqual(MissionProgress.accepted, session.progress);
    try testing.expect(!session.isAuthenticated());
}

test "decryption cannot skip authentication" {
    const testing = @import("std").testing;
    var session = MissionSession{};
    session.start();
    session.markScanned();
    session.markDecrypted();
    try testing.expectEqual(MissionProgress.scanned, session.progress);
    try testing.expect(!session.isDecrypted());
}

test "disconnecting does not erase mission progress" {
    const testing = @import("std").testing;
    var session = MissionSession{};
    session.start();
    session.markScanned();
    session.connected = true;
    session.markAuthenticated();
    session.markDecrypted();
    session.connected = false;

    try testing.expect(!session.connected);
    try testing.expect(session.hasScanned());
    try testing.expect(session.isAuthenticated());
    try testing.expect(session.isDecrypted());
}

test "reset returns session to inactive" {
    const testing = @import("std").testing;
    var session = MissionSession{ .progress = .decrypted, .connected = true };
    session.reset();
    try testing.expectEqual(MissionProgress.inactive, session.progress);
    try testing.expect(!session.connected);
    try testing.expect(!session.hasScanned());
    try testing.expect(!session.isAuthenticated());
    try testing.expect(!session.isDecrypted());
}
