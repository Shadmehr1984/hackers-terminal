const MissionObjective = @import("mission.zig").MissionObjective;
const MissionObjectiveKind = @import("mission.zig").MissionObjectiveKind;
const UtilityEquipment = @import("player.zig").UtilityEquipment;

/// A temporary, per-contract equipment snapshot. It never changes player inventory.
pub const MissionLoadout = struct {
    utility: ?UtilityEquipment = null,
    level: u2 = 0,

    pub fn movementDetectionCost(self: MissionLoadout) u8 {
        if (self.utility) |utility| return utility.movementDetectionCost(self.level);
        return 5;
    }

    pub fn incorrectAuthenticationDetectionCost(self: MissionLoadout) u8 {
        if (self.utility) |utility| return utility.incorrectAuthenticationDetectionCost(self.level);
        return 15;
    }
};

/// Runtime-only preparation state; no part of this is serialized.
pub const MissionPreparation = struct {
    mission_index: ?usize = null,
    selected_utility: ?UtilityEquipment = null,

    pub fn clear(self: *MissionPreparation) void {
        self.mission_index = null;
        self.selected_utility = null;
    }
};

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
    loadout: MissionLoadout = .{},
    fixer_service_used: bool = false,

    pub fn start(self: *MissionSession) void {
        self.progress = .accepted;
        self.connected = false;
        self.completed_objectives = 0;
        self.detection_level = 0;
        self.current_node = null;
        self.traversal_count = 0;
        self.loadout = .{};
        self.fixer_service_used = false;
    }

    pub fn startWithLoadout(self: *MissionSession, loadout: MissionLoadout) void {
        self.start();
        self.loadout = loadout;
    }

    pub fn reset(self: *MissionSession) void {
        self.progress = .inactive;
        self.connected = false;
        self.completed_objectives = 0;
        self.detection_level = 0;
        self.current_node = null;
        self.traversal_count = 0;
        self.loadout = .{};
        self.fixer_service_used = false;
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

    /// Returns true only when the mission has at least one optional objective
    /// and every optional objective has been completed.
    pub fn allOptionalObjectivesComplete(self: MissionSession, objectives: []const MissionObjective) bool {
        var found_optional = false;
        for (objectives) |objective| {
            if (!objective.optional) continue;
            found_optional = true;
            if (!self.isObjectiveComplete(objective.kind)) return false;
        }
        return found_optional;
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
