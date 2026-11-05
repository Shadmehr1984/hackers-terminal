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

/// Static objective data shown to the player.
pub const MissionObjective = struct {
    kind: MissionObjectiveKind,
    description: []const u8,
    optional: bool = false,
    bonus_reward: u32 = 0,
};

/// Defines static contract data and its mutable completion flag.
pub const Mission = struct {
    id: []const u8,
    name: []const u8,
    target: []const u8,
    difficulty: MissionDifficulty,
    category: MissionCategory = .data_recovery,
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
};
