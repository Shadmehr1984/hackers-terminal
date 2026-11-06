const FactionId = @import("faction_id.zig").FactionId;
const Mission = @import("mission.zig").Mission;

/// The player's derived standing with one faction.
pub const Standing = enum {
    hostile,
    wary,
    neutral,
    trusted,
    allied,

    /// Returns the stable terminal label for this standing.
    pub fn label(self: Standing) []const u8 {
        return switch (self) {
            .hostile => "HOSTILE",
            .wary => "WARY",
            .neutral => "NEUTRAL",
            .trusted => "TRUSTED",
            .allied => "ALLIED",
        };
    }
};

/// The authored relationship between two different factions.
pub const RelationshipKind = enum {
    allied,
    cooperative,
    neutral,
    rival,
    hostile,

    /// Returns the player-facing relationship label.
    pub fn label(self: RelationshipKind) []const u8 {
        return switch (self) {
            .allied => "Allied",
            .cooperative => "Cooperative",
            .neutral => "Neutral",
            .rival => "Rivals",
            .hostile => "Hostile",
        };
    }
};

/// One symmetric, static relationship between two faction identities.
pub const Relationship = struct {
    first: FactionId,
    second: FactionId,
    kind: RelationshipKind,
};

/// Derives a player's standing from global Reputation and completed contract outcomes.
///
/// Completing a contract adds two points for its client and subtracts two points
/// for its target owner and any distinct opposing faction. No faction score is stored.
pub fn playerStanding(faction_id: FactionId, reputation: u32, missions: []const Mission) Standing {
    var score: i64 = reputation;
    for (missions) |mission| {
        if (!mission.completed) continue;

        if (mission.client_faction == faction_id) score += 2;

        const target_owner_is_faction = if (mission.target_owner_faction) |owner| owner == faction_id else false;
        const opposing_is_faction = if (mission.opposing_faction) |opposing| opposing == faction_id else false;
        if (target_owner_is_faction or opposing_is_faction) score -= 2;
    }

    return if (score <= -2)
        .hostile
    else if (score == -1)
        .wary
    else if (score <= 2)
        .neutral
    else if (score <= 5)
        .trusted
    else
        .allied;
}
