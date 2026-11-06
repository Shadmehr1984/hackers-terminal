const std = @import("std");
const FactionId = @import("faction_id.zig").FactionId;

/// Stable identity for one fictional rival hacker.
pub const RivalId = enum {
    ghost_operator,
    null_byte,
    glasswire,
    patchwork,
    redshift,

    /// Parses the stable command-facing rival identifier.
    pub fn parse(value: []const u8) ?RivalId {
        if (std.mem.eql(u8, value, "ghost-operator")) return .ghost_operator;
        if (std.mem.eql(u8, value, "null-byte")) return .null_byte;
        if (std.mem.eql(u8, value, "glasswire")) return .glasswire;
        if (std.mem.eql(u8, value, "patchwork")) return .patchwork;
        if (std.mem.eql(u8, value, "redshift")) return .redshift;
        return null;
    }

    /// Returns the stable command identifier.
    pub fn slug(self: RivalId) []const u8 {
        return switch (self) {
            .ghost_operator => "ghost-operator",
            .null_byte => "null-byte",
            .glasswire => "glasswire",
            .patchwork => "patchwork",
            .redshift => "redshift",
        };
    }
};

/// Current deterministic status of a rival's authored contract contest.
pub const RivalStatus = enum {
    dormant,
    contesting,
    rival_ahead,
    outpaced,

    /// Returns the terminal-facing status label.
    pub fn label(self: RivalStatus) []const u8 {
        return switch (self) {
            .dormant => "DORMANT",
            .contesting => "CONTESTING",
            .rival_ahead => "RIVAL AHEAD",
            .outpaced => "OUTPACED",
        };
    }
};

/// Static identity and one authored optional-intelligence contest.
pub const Rival = struct {
    id: RivalId,
    name: []const u8,
    faction: FactionId,
    specialty: []const u8,
    approach: []const u8,
    mission_id: []const u8,
    objective_id: []const u8,
    briefing_hint: []const u8,
};
