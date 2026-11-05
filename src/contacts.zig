const progression = @import("progression.zig");

pub const ContactId = enum {
    broker,
    fixer,

    pub fn parse(value: []const u8) ?ContactId {
        const std = @import("std");
        if (std.mem.eql(u8, value, "broker")) return .broker;
        if (std.mem.eql(u8, value, "fixer")) return .fixer;
        return null;
    }

    pub fn label(self: ContactId) []const u8 {
        return switch (self) {
            .broker => "Information Broker",
            .fixer => "Fixer",
        };
    }

    pub fn role(self: ContactId) []const u8 {
        return switch (self) {
            .broker => "Information, contract intelligence, and paid puzzle clues",
            .fixer => "Exclusive contracts and temporary operational services",
        };
    }

    pub fn requiredReputation(self: ContactId) u32 {
        return switch (self) {
            .broker => 1,
            .fixer => 3,
        };
    }
};

pub const intel_price: u32 = 50;
pub const detection_reduction: u8 = 10;

pub fn isUnlocked(contact: ContactId, reputation: u32) bool {
    return reputation >= contact.requiredReputation();
}

pub fn fixerServicePrice(reputation: u32) ?u32 {
    return switch (progression.reputationTier(reputation)) {
        .trusted => 100,
        .elite => 75,
        .unknown, .recognized => null,
    };
}
