const std = @import("std");
const progression = @import("progression.zig");

/// Identifies one of the fictional in-game Contacts.
pub const ContactId = enum {
    broker,
    fixer,

    /// Parses a Contact command token; returns null for unknown values.
    pub fn parse(value: []const u8) ?ContactId {
        if (std.mem.eql(u8, value, "broker")) return .broker;
        if (std.mem.eql(u8, value, "fixer")) return .fixer;
        return null;
    }

    /// Returns the player-facing Contact name.
    pub fn label(self: ContactId) []const u8 {
        return switch (self) {
            .broker => "Information Broker",
            .fixer => "Fixer",
        };
    }

    /// Returns the Contact's short role description.
    pub fn role(self: ContactId) []const u8 {
        return switch (self) {
            .broker => "Information, contract intelligence, and paid puzzle clues",
            .fixer => "Exclusive contracts and temporary operational services",
        };
    }

    /// Returns the minimum Reputation required to unlock this Contact.
    pub fn requiredReputation(self: ContactId) u32 {
        return switch (self) {
            .broker => 1,
            .fixer => 3,
        };
    }
};

/// Defines the in-game price of one Broker intelligence purchase.
pub const intel_price: u32 = 50;
/// Defines the maximum Detection reduction offered by the Fixer service.
pub const detection_reduction: u8 = 10;

/// Reports whether the supplied Reputation unlocks the Contact.
pub fn isUnlocked(contact: ContactId, reputation: u32) bool {
    return reputation >= contact.requiredReputation();
}

/// Returns the Fixer service price for the Reputation tier, or null when locked.
pub fn fixerServicePrice(reputation: u32) ?u32 {
    return switch (progression.reputationTier(reputation)) {
        .trusted => 100,
        .elite => 75,
        .unknown, .recognized => null,
    };
}
