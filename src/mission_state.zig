const MissionObjective = @import("mission.zig").MissionObjective;
const MissionObjectiveKind = @import("mission.zig").MissionObjectiveKind;

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
    completed_objectives: u8 = 0,

    pub fn start(self: *MissionSession) void {
        self.progress = .accepted;
        self.connected = false;
        self.completed_objectives = 0;
    }

    pub fn reset(self: *MissionSession) void {
        self.progress = .inactive;
        self.connected = false;
        self.completed_objectives = 0;
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

    pub fn completeObjective(self: *MissionSession, kind: MissionObjectiveKind) void {
        const bit = @as(u8, 1) << @intCast(@intFromEnum(kind));
        self.completed_objectives |= bit;
    }

    pub fn isObjectiveComplete(self: MissionSession, kind: MissionObjectiveKind) bool {
        const bit = @as(u8, 1) << @intCast(@intFromEnum(kind));
        return (self.completed_objectives & bit) != 0;
    }

    pub fn allObjectivesComplete(self: MissionSession, objectives: []const MissionObjective) bool {
        for (objectives) |objective| {
            if (!objective.optional and !self.isObjectiveComplete(objective.kind)) return false;
        }
        return true;
    }
};
