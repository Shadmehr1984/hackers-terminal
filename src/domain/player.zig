/// Identifies a utility upgrade and owns its pure Detection-cost profile.
pub const UtilityEquipment = enum(u8) {
    silent_boots = 0,
    signal_scrubber = 1,

    /// Returns the player-facing name of this utility.
    pub fn label(self: UtilityEquipment) []const u8 {
        return switch (self) {
            .silent_boots => "Silent Boots",
            .signal_scrubber => "Signal Scrubber",
        };
    }

    /// Returns the stable command token used to identify this utility.
    pub fn commandName(self: UtilityEquipment) []const u8 {
        return switch (self) {
            .silent_boots => "silent-boots",
            .signal_scrubber => "signal-scrubber",
        };
    }

    /// Returns the simulated Detection cost for one successful topology move.
    /// Only Silent Boots modify movement exposure.
    pub fn movementDetectionCost(self: UtilityEquipment, level: u2) u8 {
        return switch (self) {
            .silent_boots => switch (level) {
                0 => 4,
                1 => 3,
                else => 2,
            },
            .signal_scrubber => 5,
        };
    }

    /// Returns the simulated Detection cost for an incorrect authentication.
    /// Only Signal Scrubber modifies authentication exposure.
    pub fn incorrectAuthenticationDetectionCost(self: UtilityEquipment, level: u2) u8 {
        return switch (self) {
            .silent_boots => 15,
            .signal_scrubber => switch (level) {
                0 => 12,
                1 => 9,
                else => 6,
            },
        };
    }
};

/// Stores persistent equipment ownership, selection, and upgrade levels.
pub const Equipment = struct {
    has_decryptor: bool = false,
    owned_utilities: u2 = 0,
    equipped_utility: ?UtilityEquipment = null,
    silent_boots_level: u2 = 0,
    signal_scrubber_level: u2 = 0,

    /// Reports whether the player owns the specified utility.
    pub fn owns(self: Equipment, utility: UtilityEquipment) bool {
        const bit = @as(u2, 1) << @intCast(@intFromEnum(utility));
        return (self.owned_utilities & bit) != 0;
    }

    /// Marks the specified utility as owned.
    pub fn setOwned(self: *Equipment, utility: UtilityEquipment) void {
        const bit = @as(u2, 1) << @intCast(@intFromEnum(utility));
        self.owned_utilities |= bit;
    }

    /// Reports whether the specified utility occupies the active utility slot.
    pub fn isEquipped(self: Equipment, utility: UtilityEquipment) bool {
        return if (self.equipped_utility) |equipped| equipped == utility else false;
    }

    /// Returns the stored upgrade level for the specified utility.
    pub fn level(self: Equipment, utility: UtilityEquipment) u2 {
        return switch (utility) {
            .silent_boots => self.silent_boots_level,
            .signal_scrubber => self.signal_scrubber_level,
        };
    }

    /// Sets the stored upgrade level for the specified utility.
    pub fn setLevel(self: *Equipment, utility: UtilityEquipment, value: u2) void {
        switch (utility) {
            .silent_boots => self.silent_boots_level = value,
            .signal_scrubber => self.signal_scrubber_level = value,
        }
    }

    /// Returns the movement exposure cost from the currently equipped utility.
    pub fn movementDetectionCost(self: Equipment) u8 {
        if (self.equipped_utility) |utility| {
            return utility.movementDetectionCost(self.level(utility));
        }
        return 5;
    }

    /// Returns the authentication exposure cost from the currently equipped utility.
    pub fn incorrectAuthenticationDetectionCost(self: Equipment) u8 {
        if (self.equipped_utility) |utility| {
            return utility.incorrectAuthenticationDetectionCost(self.level(utility));
        }
        return 15;
    }
};

/// Represents the persistent player profile and its equipment.
pub const Player = struct {
    handle: []const u8 = "ghost",
    balance: u32 = 250,
    reputation: u32 = 0,
    xp: u32 = 0,
    equipment: Equipment = .{},
};
