pub const MissionDifficulty = enum {
    easy,
    medium,
    hard,

    pub fn label(self: MissionDifficulty) []const u8 {
        return switch (self) {
            .easy => "Easy",
            .medium => "Medium",
            .hard => "Hard",
        };
    }
};

/// The gameplay event that completes a mission objective.
pub const MissionObjectiveKind = enum {
    scan_target,
    authenticate,
    decrypt_file,
    extract_file,
};

/// Static objective data shown to the player.
pub const MissionObjective = struct {
    kind: MissionObjectiveKind,
    description: []const u8,
};

pub const Mission = struct {
    id: []const u8,
    name: []const u8,
    target: []const u8,
    difficulty: MissionDifficulty,
    objectives: []const MissionObjective,
    password: []const u8,
    password_hint: []const u8,
    encrypted_file: []const u8,
    decryption_hint: []const u8,
    decryption_key: []const u8,
    reward: u32,
    xp_reward: u32,
    required_level: u32,
    completed: bool = false,
};
