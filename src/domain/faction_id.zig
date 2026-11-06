const std = @import("std");

/// Stable identity for one fictional organization in the game world.
pub const FactionId = enum {
    nexus_dynamics,
    ghost_protocol,
    black_veil,
    aegis_initiative,
    iron_meridian,
    null_syndicate,
    helix_consortium,

    /// Parses the stable command-facing faction identifier.
    pub fn parse(value: []const u8) ?FactionId {
        inline for (@typeInfo(FactionId).Enum.fields) |field| {
            const id: FactionId = @enumFromInt(field.value);
            if (std.mem.eql(u8, value, id.slug())) return id;
        }
        return null;
    }

    /// Returns the stable lowercase identifier used by terminal commands.
    pub fn slug(self: FactionId) []const u8 {
        return switch (self) {
            .nexus_dynamics => "nexus-dynamics",
            .ghost_protocol => "ghost-protocol",
            .black_veil => "black-veil",
            .aegis_initiative => "aegis-initiative",
            .iron_meridian => "iron-meridian",
            .null_syndicate => "null-syndicate",
            .helix_consortium => "helix-consortium",
        };
    }
};
