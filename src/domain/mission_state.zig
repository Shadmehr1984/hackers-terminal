const MissionObjective = @import("mission.zig").MissionObjective;
const MissionObjectiveKind = @import("mission.zig").MissionObjectiveKind;
const UtilityEquipment = @import("player.zig").UtilityEquipment;

/// A temporary, per-contract equipment snapshot. It never changes player inventory.
pub const MissionLoadout = struct {
    utility: ?UtilityEquipment = null,
    level: u2 = 0,

    /// Returns the movement exposure cost from this run's captured loadout.
    pub fn movementDetectionCost(self: MissionLoadout) u8 {
        if (self.utility) |utility| return utility.movementDetectionCost(self.level);
        return 5;
    }

    /// Returns the authentication exposure cost from this run's captured loadout.
    pub fn incorrectAuthenticationDetectionCost(self: MissionLoadout) u8 {
        if (self.utility) |utility| return utility.incorrectAuthenticationDetectionCost(self.level);
        return 15;
    }
};

/// Runtime-only preparation state; no part of this is serialized.
pub const MissionPreparation = struct {
    mission_index: ?usize = null,
    selected_utility: ?UtilityEquipment = null,

    /// Clears the prepared contract and selected utility.
    pub fn clear(self: *MissionPreparation) void {
        self.mission_index = null;
        self.selected_utility = null;
    }
};

/// Represents the monotonic progress stage of the active mission.
pub const MissionProgress = enum {
    inactive,
    accepted,
    scanned,
    authenticated,
    decrypted,
};

/// Classifies the current simulated Detection exposure range.
pub const DetectionBand = enum {
    quiet,
    noticed,
    traced,
    critical,
    compromised,

    /// Returns the player-facing label for this exposure band.
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

    /// Starts a fresh accepted mission and clears transient run state.
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

    /// Starts a fresh mission with an immutable run-specific utility snapshot.
    pub fn startWithLoadout(self: *MissionSession, loadout: MissionLoadout) void {
        self.start();
        self.loadout = loadout;
    }

    /// Returns the mission session to its inactive default state.
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

    /// Returns the exposure band for the current Detection level.
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

    /// Reports whether the scan stage has been completed.
    pub fn hasScanned(self: MissionSession) bool {
        return switch (self.progress) {
            .scanned, .authenticated, .decrypted => true,
            .inactive, .accepted => false,
        };
    }

    /// Reports whether authentication has been completed.
    pub fn isAuthenticated(self: MissionSession) bool {
        return switch (self.progress) {
            .authenticated, .decrypted => true,
            .inactive, .accepted, .scanned => false,
        };
    }

    /// Reports whether decryption has been completed.
    pub fn isDecrypted(self: MissionSession) bool {
        return self.progress == .decrypted;
    }

    /// Advances an accepted mission to the scanned stage.
    pub fn markScanned(self: *MissionSession) void {
        if (self.progress == .accepted) self.progress = .scanned;
    }

    /// Advances a scanned mission to the authenticated stage.
    pub fn markAuthenticated(self: *MissionSession) void {
        if (self.progress == .scanned) {
            self.progress = .authenticated;
        }
    }

    /// Advances an authenticated mission to the decrypted stage.
    pub fn markDecrypted(self: *MissionSession) void {
        if (self.isAuthenticated()) self.progress = .decrypted;
    }

    /// Marks the specified objective kind complete for this run.
    pub fn completeObjective(self: *MissionSession, kind: MissionObjectiveKind) void {
        const bit = @as(u8, 1) << @intCast(@intFromEnum(kind));
        self.completed_objectives |= bit;
    }

    /// Reports whether the specified objective kind is complete.
    pub fn isObjectiveComplete(self: MissionSession, kind: MissionObjectiveKind) bool {
        const bit = @as(u8, 1) << @intCast(@intFromEnum(kind));
        return (self.completed_objectives & bit) != 0;
    }

    /// Reports whether every required objective in the supplied contract is complete.
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

    /// Sums the bonus cash for completed optional objectives.
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
