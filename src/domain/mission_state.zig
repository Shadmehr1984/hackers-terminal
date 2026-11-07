const MissionObjective = @import("mission.zig").MissionObjective;
const MissionObjectiveKind = @import("mission.zig").MissionObjectiveKind;
const objective_runtime = @import("mission_objectives.zig");
const UtilityEquipment = @import("player.zig").UtilityEquipment;
const Mission = @import("mission.zig").Mission;
const ModifierId = @import("mission_modifier.zig").ModifierId;
const OperationState = @import("operation_state.zig").OperationState;

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
    selected_modifier: ?ModifierId = null,
    operation_state: OperationState = .{},

    /// Selects a modifier only when the prepared contract explicitly allows it.
    /// A rejected selection leaves the current choice unchanged.
    pub fn selectModifier(self: *MissionPreparation, mission: Mission, modifier: ModifierId) bool {
        if (!mission.allowsModifier(modifier)) return false;
        self.selected_modifier = modifier;
        return true;
    }

    /// Clears the prepared contract, selected utility, and selected modifier.
    pub fn clear(self: *MissionPreparation) void {
        self.mission_index = null;
        self.selected_utility = null;
        self.selected_modifier = null;
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
    objective_tracker: objective_runtime.Tracker = .{},
    detection_level: u8 = 0,
    current_node: ?[]const u8 = null,
    traversal_count: u32 = 0,
    loadout: MissionLoadout = .{},
    modifier: ?ModifierId = null,
    completion_reward_paid: bool = false,
    fixer_service_used: bool = false,

    /// Starts a fresh accepted mission and clears transient run state.
    pub fn start(self: *MissionSession) void {
        self.progress = .accepted;
        self.connected = false;
        self.objective_tracker.reset();
        self.detection_level = 0;
        self.current_node = null;
        self.traversal_count = 0;
        self.loadout = .{};
        self.modifier = null;
        self.completion_reward_paid = false;
        self.fixer_service_used = false;
    }

    /// Starts a fresh mission with an immutable run-specific utility snapshot.
    pub fn startWithLoadout(self: *MissionSession, loadout: MissionLoadout) void {
        self.start();
        self.loadout = loadout;
    }

    /// Starts a fresh mission with an immutable run-specific utility and modifier snapshot.
    pub fn startWithModifier(self: *MissionSession, loadout: MissionLoadout, modifier: ?ModifierId) void {
        self.startWithLoadout(loadout);
        self.modifier = modifier;
    }

    /// Returns the mission session to its inactive default state.
    pub fn reset(self: *MissionSession) void {
        self.progress = .inactive;
        self.connected = false;
        self.objective_tracker.reset();
        self.detection_level = 0;
        self.current_node = null;
        self.traversal_count = 0;
        self.loadout = .{};
        self.modifier = null;
        self.completion_reward_paid = false;
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
        if (self.detection_level >= 100) {
            self.detection_level = 100;
            return;
        }
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

    /// Initializes the bounded objective state from the active mission catalog.
    pub fn initializeObjectives(self: *MissionSession, objectives: []const MissionObjective) bool {
        return self.objective_tracker.initialize(objectives);
    }

    /// Starts a run with its immutable loadout/modifier snapshots and authored objectives.
    pub fn startWithMission(
        self: *MissionSession,
        loadout: MissionLoadout,
        modifier: ?ModifierId,
        objectives: []const MissionObjective,
    ) bool {
        self.startWithModifier(loadout, modifier);
        return self.initializeObjectives(objectives);
    }

    /// Reveals hidden objectives triggered by reaching a fictional topology node.
    pub fn discoverNode(self: *MissionSession, node_id: []const u8, objectives: []const MissionObjective) usize {
        return self.objective_tracker.discoverNode(node_id, objectives);
    }

    /// Reveals hidden objectives triggered by inspecting a fictional evidence file.
    pub fn discoverFile(self: *MissionSession, file_id: []const u8, objectives: []const MissionObjective) usize {
        return self.objective_tracker.discoverFile(file_id, objectives);
    }

    /// Reveals hidden objectives triggered by a successful in-game action.
    pub fn discoverAction(self: *MissionSession, action: objective_runtime.DiscoveryAction, objectives: []const MissionObjective) usize {
        return self.objective_tracker.discoverAction(action, objectives);
    }

    /// Reveals an authored hidden optional objective by stable mission-local ID.
    pub fn revealObjectiveById(self: *MissionSession, id: []const u8, objectives: []const MissionObjective) bool {
        return self.objective_tracker.revealById(id, objectives);
    }

    /// Marks every currently discovered objective for the supplied event kind complete.
    pub fn completeObjective(self: *MissionSession, kind: MissionObjectiveKind) void {
        _ = self.objective_tracker.complete(@intCast(@backingInt(kind)));
    }

    /// Reports whether a discovered objective of this event kind still awaits completion.
    pub fn hasIncompleteObjective(self: MissionSession, kind: MissionObjectiveKind) bool {
        const value: u8 = @intCast(@backingInt(kind));
        for (self.objective_tracker.entries[0..self.objective_tracker.count]) |entry| {
            if (entry.kind == value and entry.state == .discovered) return true;
        }
        return false;
    }

    /// Marks optional objectives for a completed event kind unavailable if that event cannot recur.
    pub fn markOptionalObjectivesUnavailableForEvent(self: *MissionSession, kind: MissionObjectiveKind) void {
        self.objective_tracker.markOptionalUnavailableForKind(@intCast(@backingInt(kind)));
    }

    /// Marks incomplete optional objectives unavailable when the contract is ending.
    pub fn markUncompletedOptionalObjectivesUnavailable(self: *MissionSession) void {
        for (self.objective_tracker.entries[0..self.objective_tracker.count]) |*entry| {
            if (entry.optional and entry.state != .completed) entry.state = .unavailable;
        }
    }

    /// Reports whether at least one objective of this event kind is complete.
    pub fn isObjectiveComplete(self: MissionSession, kind: MissionObjectiveKind) bool {
        const value: u8 = @intCast(@backingInt(kind));
        for (self.objective_tracker.entries[0..self.objective_tracker.count]) |entry| {
            if (entry.kind == value and entry.state == .completed) return true;
        }
        return false;
    }

    /// Reports whether every required objective in the supplied contract is complete.
    pub fn allObjectivesComplete(self: MissionSession, _: []const MissionObjective) bool {
        return self.objective_tracker.allRequiredComplete();
    }

    /// Returns true only when at least one optional objective exists and all are complete.
    pub fn allOptionalObjectivesComplete(self: MissionSession, _: []const MissionObjective) bool {
        return self.objective_tracker.allOptionalComplete();
    }

    /// Sums the bonus cash for optional objectives completed during this run.
    pub fn optionalReward(self: MissionSession, _: []const MissionObjective) error{RewardOverflow}!u32 {
        return self.objective_tracker.optionalReward();
    }
};
