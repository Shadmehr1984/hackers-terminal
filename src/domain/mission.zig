const ModifierId = @import("mission_modifier.zig").ModifierId;
const FactionId = @import("faction_id.zig").FactionId;
const objective_runtime = @import("mission_objectives.zig");

/// Re-exports the static topology type used by mission definitions.
pub const Topology = @import("topology.zig").Topology;

/// Describes presentation difficulty; it does not modify gameplay rules.
pub const MissionDifficulty = enum {
    easy,
    medium,
    hard,

    /// Returns the title-case label displayed for this difficulty.
    pub fn label(self: MissionDifficulty) []const u8 {
        return switch (self) {
            .easy => "Easy",
            .medium => "Medium",
            .hard => "Hard",
        };
    }
};

/// Broad gameplay category used to organize contracts on the Contract Board.
pub const MissionCategory = enum {
    data_recovery,
    intelligence,
    extraction,
    infiltration,

    /// Returns the player-facing category label.
    pub fn label(self: MissionCategory) []const u8 {
        return switch (self) {
            .data_recovery => "Data Recovery",
            .intelligence => "Intelligence",
            .extraction => "Extraction",
            .infiltration => "Infiltration",
        };
    }
};

/// The gameplay event that completes a mission objective.
pub const MissionObjectiveKind = enum {
    scan_target,
    authenticate,
    decrypt_file,
    extract_file,
    analyze_metadata,
};

/// Static objective data shown only after its visibility condition is met.
pub const MissionObjective = struct {
    /// Stable mission-local identity, independent of the completion event kind.
    id: []const u8 = "",
    kind: MissionObjectiveKind,
    description: []const u8,
    optional: bool = false,
    bonus_reward: u32 = 0,
    hidden: bool = false,
    discovery_trigger: ?objective_runtime.DiscoveryTrigger = null,
};

/// Defines static contract data and its mutable completion flag.
pub const Mission = struct {
    id: []const u8,
    name: []const u8,
    target: []const u8,
    difficulty: MissionDifficulty,
    category: MissionCategory = .data_recovery,
    /// Faction commissioning this contract; this identity is static catalog data.
    client_faction: FactionId = .ghost_protocol,
    /// Faction that owns the contract target, when applicable.
    target_owner_faction: ?FactionId = null,
    /// Additional faction whose interests are directly opposed by this contract.
    opposing_faction: ?FactionId = null,
    /// Static catalog allowlist; an empty list means no modifiers are available.
    allowed_modifiers: []const ModifierId = &.{},
    objectives: []const MissionObjective,
    topology: ?*const Topology = null,
    password: []const u8,
    password_hint: []const u8,
    encrypted_file: []const u8,
    decryption_hint: []const u8,
    decryption_key: []const u8,
    reward: u32,
    xp_reward: u32,
    required_level: u32,
    required_reputation: u32 = 0,
    requires_contact_offer: bool = false,
    completed: bool = false,

    /// Validates objective capacity, stable IDs, and hidden-objective constraints.
    pub fn hasValidObjectives(self: Mission) bool {
        var tracker = objective_runtime.Tracker{};
        return tracker.initialize(self.objectives);
    }

    /// Validates that faction links do not point back to the commissioning faction.\n    pub fn hasValidFactionLinks(self: Mission) bool {\n        if (self.target_owner_faction) |owner| {\n            if (owner == self.client_faction) return false;\n        }\n        if (self.opposing_faction) |opposing| {\n            if (opposing == self.client_faction) return false;\n        }\n        return true;\n    }\n\n    /// Reports whether this contract explicitly allows the supplied modifier.
    pub fn allowsModifier(self: Mission, modifier: ModifierId) bool {
        for (self.allowed_modifiers) |allowed| {
            if (allowed == modifier) return true;
        }
        return false;
    }
};
