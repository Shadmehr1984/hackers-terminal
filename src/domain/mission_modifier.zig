/// Stable identifiers for the owner-approved mission modifiers.
pub const ModifierId = enum {
    heightened_monitoring,
    security_sweep,
    hardened_encryption,

    /// Returns the stable command argument used to select this modifier.
    pub fn commandId(self: ModifierId) []const u8 {
        return switch (self) {
            .heightened_monitoring => "heightened-monitoring",
            .security_sweep => "security-sweep",
            .hardened_encryption => "hardened-encryption",
        };
    }

    /// Returns the player-facing modifier name.
    pub fn label(self: ModifierId) []const u8 {
        return switch (self) {
            .heightened_monitoring => "Heightened Monitoring",
            .security_sweep => "Security Sweep",
            .hardened_encryption => "Hardened Encryption",
        };
    }

    /// Returns the exact effect disclosed during Mission Preparation.
    pub fn description(self: ModifierId) []const u8 {
        return switch (self) {
            .heightened_monitoring => "+2 Detection on every successful topology traversal, after Silent Boots adjustment.",
            .security_sweep => "+8 Detection after every third successful topology traversal; revisits count, rejected moves do not.",
            .hardened_encryption => "Incorrect decryption-key attempts cost +15 Detection instead of +10.",
        };
    }

    /// Returns the typed Detection behavior associated with this modifier.
    pub fn detectionEffect(self: ModifierId) DetectionEffect {
        return switch (self) {
            .heightened_monitoring => .{ .kind = .successful_traversal_surcharge, .amount = 2 },
            .security_sweep => .{ .kind = .successful_traversal_cadence, .amount = 8, .cadence = 3 },
            .hardened_encryption => .{ .kind = .incorrect_decryption_cost, .amount = 15 },
        };
    }

    /// Returns the additional reward paid once after successful completion.
    pub fn completionBonus(_: ModifierId) CompletionBonus {
        return .{ .cash = 50, .xp = 25 };
    }

    /// Resolves a stable command argument to a modifier ID.
    pub fn fromCommandId(value: []const u8) ?ModifierId {
        inline for (@typeInfo(ModifierId).Enum.fields) |field| {
            const id: ModifierId = @enumFromInt(field.value);
            if (std.mem.eql(u8, value, id.commandId())) return id;
        }
        return null;
    }
};

const std = @import("std");

/// The single Detection event shape contributed by a modifier.
pub const DetectionEffect = struct {
    kind: Kind,
    amount: u8,
    cadence: u8 = 0,

    pub const Kind = enum {
        successful_traversal_surcharge,
        successful_traversal_cadence,
        incorrect_decryption_cost,
    };
};

/// Additional cash and experience awarded for a successful modified run.
pub const CompletionBonus = struct {
    cash: u32,
    xp: u32,
};
