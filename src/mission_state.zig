const MissionObjective = @import("mission.zig").MissionObjective;
const MissionObjectiveKind = @import("mission.zig").MissionObjectiveKind;

pub const MissionProgress = enum {
    inactive,
    accepted,
    scanned,
    authenticated,
    decrypted,
};

pub const DetectionBand = enum {
    quiet,
    noticed,
    traced,
    critical,
    compromised,

    pub fn label(self: DetectionBand) []const u8 {
        return switch (self) {
            .quiet => "Quiet",
            .noticed => "Noticed",
            .traced => "Traced",
            .critical => "Critical",
            .compromised => "Compromised",
        };
    }
};

/// Runtime-only state for the active mission.
/// Progress is monotonic; connection status is independent so disconnecting
/// does not revoke authentication or decryption already achieved.
pub const MissionSession = struct {
    progress: MissionProgress = .inactive,
    connected: bool = false,
    completed_objectives: u8 = 0,
    detection_level: u8 = 0,
    current_node: ?[]const u8 = null,
    traversal_count: u32 = 0,

    pub fn start(self: *MissionSession) void {
        self.progress = .accepted;
        self.connected = false;
        self.completed_objectives = 0;
        self.detection_level = 0;
        self.current_node = null;
        self.traversal_count = 0;
    }

    pub fn reset(self: *MissionSession) void {
        self.progress = .inactive;
        self.connected = false;
        self.completed_objectives = 0;
        self.detection_level = 0;
        self.current_node = null;
        self.traversal_count = 0;
    }

    pub fn detectionBand(self: MissionSession) DetectionBand {
        return switch (self.detection_level) {
            0...24 => .quiet,
            25...49 => .noticed,
            50...74 => .traced,
            75...99 => .critical,
            else => .compromised,
        };
    }

    /// Adds simulated exposure and caps the level at 100.
    pub fn addDetection(self: *MissionSession, amount: u8) void {
        const remaining = 100 - self.detection_level;
        self.detection_level += @min(amount, remaining);
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

    pub fn optionalReward(self: MissionSession, objectives: []const MissionObjective) u32 {
        var reward: u32 = 0;
        for (objectives) |objective| {
            if (objective.optional and self.isObjectiveComplete(objective.kind)) {
                reward += objective.bonus_reward;
            }
        }
        return reward;
    }
};
