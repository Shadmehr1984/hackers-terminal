pub const UtilityEquipment = enum(u8) {
    silent_boots = 0,
    signal_scrubber = 1,
    pub fn label(self: UtilityEquipment) []const u8 {
        return switch (self) { .silent_boots => "Silent Boots", .signal_scrubber => "Signal Scrubber" };
    }
    pub fn commandName(self: UtilityEquipment) []const u8 {
        return switch (self) { .silent_boots => "silent-boots", .signal_scrubber => "signal-scrubber" };
    }
};
pub const Equipment = struct {
    has_decryptor: bool = false,
    owned_utilities: u2 = 0,
    equipped_utility: ?UtilityEquipment = null,
    silent_boots_level: u2 = 0,
    signal_scrubber_level: u2 = 0,
    pub fn owns(self: Equipment, utility: UtilityEquipment) bool {
        const bit = @as(u2, 1) << @intCast(@intFromEnum(utility));
        return (self.owned_utilities & bit) != 0;
    }
    pub fn setOwned(self: *Equipment, utility: UtilityEquipment) void {
        const bit = @as(u2, 1) << @intCast(@intFromEnum(utility));
        self.owned_utilities |= bit;
    }
    pub fn level(self: Equipment, utility: UtilityEquipment) u2 {
        return switch (utility) { .silent_boots => self.silent_boots_level, .signal_scrubber => self.signal_scrubber_level };
    }
    pub fn setLevel(self: *Equipment, utility: UtilityEquipment, value: u2) void {
        switch (utility) { .silent_boots => self.silent_boots_level = value, .signal_scrubber => self.signal_scrubber_level = value }
    }
    pub fn movementDetectionCost(self: Equipment) u8 {
        if (self.equipped_utility == null or self.equipped_utility.? != .silent_boots) return 5;
        return switch (self.silent_boots_level) { 0 => 4, 1 => 3, else => 2 };
    }
    pub fn incorrectAuthenticationDetectionCost(self: Equipment) u8 {
        if (self.equipped_utility == null or self.equipped_utility.? != .signal_scrubber) return 15;
        return switch (self.signal_scrubber_level) { 0 => 12, 1 => 9, else => 6 };
    }
};
pub const Player = struct {
    handle: []const u8 = "ghost",
    balance: u32 = 250,
    reputation: u32 = 0,
    xp: u32 = 0,
    equipment: Equipment = .{},
};
