const FactionId = @import("../domain/faction_id.zig").FactionId;
const faction = @import("../domain/faction.zig");

/// Static authored identity and gameplay profile for one fictional organization.
pub const Faction = struct {
    id: FactionId,
    name: []const u8,
    archetype: []const u8,
    description: []const u8,
    security_style: []const u8,
    economic_style: []const u8,
    specialty: []const u8,
    security_rating: u8,
};

const factions = [_]Faction{
    .{
        .id = .nexus_dynamics,
        .name = "Nexus Dynamics",
        .archetype = "Technology megacorporation",
        .description = "A dominant infrastructure company that treats data access as a commercial asset.",
        .security_style = "Layered access controls, hardened gateways, and extensive audit trails",
        .economic_style = "Premium contracts with high-value corporate assets",
        .specialty = "Corporate infrastructure and protected data",
        .security_rating = 5,
    },
    .{
        .id = .ghost_protocol,
        .name = "Ghost Protocol",
        .archetype = "Independent hacker collective",
        .description = "A decentralized group that values quiet access, anonymity, and operational discipline.",
        .security_style = "Stealth-oriented relays, decoys, and low-noise authentication",
        .economic_style = "Selective contracts with bonuses for clean execution",
        .specialty = "Covert infiltration and discreet extraction",
        .security_rating = 3,
    },
    .{
        .id = .black_veil,
        .name = "Black Veil",
        .archetype = "Underground information syndicate",
        .description = "A broker network that trades in provenance, leverage, and carefully compartmentalized intelligence.",
        .security_style = "Compartmentalized archives, misleading records, and layered secrecy",
        .economic_style = "Information-for-information deals and variable contract value",
        .specialty = "Intelligence gathering and evidence recovery",
        .security_rating = 4,
    },
    .{
        .id = .aegis_initiative,
        .name = "Aegis Initiative",
        .archetype = "Civic watchdog organization",
        .description = "An independent oversight group documenting institutional abuse and concealed public risks.",
        .security_style = "Evidence integrity checks and traceable audit systems",
        .economic_style = "Modest budgets with clear public-interest objectives",
        .specialty = "Corruption evidence and accountability records",
        .security_rating = 2,
    },
    .{
        .id = .iron_meridian,
        .name = "Iron Meridian",
        .archetype = "Private security contractor",
        .description = "A security provider selling monitoring, incident response, and defensive infrastructure.",
        .security_style = "Aggressive monitoring, decoy systems, and rapid counter-intrusion",
        .economic_style = "High-fee protection contracts and strict service terms",
        .specialty = "Defense systems and simulated tracking networks",
        .security_rating = 5,
    },
    .{
        .id = .null_syndicate,
        .name = "Null Syndicate",
        .archetype = "Saboteur collective",
        .description = "A loose coalition seeking to expose fragile power structures through disruptive operations.",
        .security_style = "Unstable infrastructure, false trails, and irregular access paths",
        .economic_style = "Risk-heavy work with unconventional compensation",
        .specialty = "Disruption and infrastructure weaknesses",
        .security_rating = 4,
    },
    .{
        .id = .helix_consortium,
        .name = "Helix Consortium",
        .archetype = "Research consortium",
        .description = "A research alliance exploring advanced cryptography, synthetic intelligence, and experimental systems.",
        .security_style = "Experimental authentication, encrypted research stores, and unusual protocols",
        .economic_style = "Research grants, specialist fees, and technology-based rewards",
        .specialty = "Cryptography and experimental technology",
        .security_rating = 4,
    },
};

const relationships = [_]faction.Relationship{
    .{ .first = .nexus_dynamics, .second = .iron_meridian, .kind = .allied },
    .{ .first = .ghost_protocol, .second = .null_syndicate, .kind = .cooperative },
    .{ .first = .aegis_initiative, .second = .nexus_dynamics, .kind = .hostile },
    .{ .first = .aegis_initiative, .second = .null_syndicate, .kind = .hostile },
    .{ .first = .black_veil, .second = .helix_consortium, .kind = .rival },
    .{ .first = .helix_consortium, .second = .ghost_protocol, .kind = .cooperative },
};

/// Returns the seven authored faction definitions in stable catalog order.
pub fn all() []const Faction {
    return &factions;
}

/// Looks up a faction by its stable identity.
pub fn find(id: FactionId) ?Faction {
    for (factions) |entry| {
        if (entry.id == id) return entry;
    }
    return null;
}

/// Returns the authored symmetric relationship; unspecified pairs are neutral.
pub fn relationship(first: FactionId, second: FactionId) faction.RelationshipKind {
    if (first == second) return .allied;
    for (relationships) |entry| {
        if ((entry.first == first and entry.second == second) or
            (entry.first == second and entry.second == first))
        {
            return entry.kind;
        }
    }
    return .neutral;
}

/// Validates stable identities, profile bounds, and unique non-self relationship pairs.
pub fn validate() bool {
    if (factions.len != 7) return false;
    for (factions, 0..) |entry, index| {
        if (entry.name.len == 0 or entry.archetype.len == 0 or entry.description.len == 0) return false;
        if (entry.security_style.len == 0 or entry.economic_style.len == 0 or entry.specialty.len == 0) return false;
        if (entry.security_rating < 1 or entry.security_rating > 5) return false;
        for (factions[0..index]) |previous| {
            if (previous.id == entry.id) return false;
        }
    }
    for (relationships, 0..) |entry, index| {
        if (entry.first == entry.second) return false;
        for (relationships[0..index]) |previous| {
            const same_pair = (previous.first == entry.first and previous.second == entry.second) or
                (previous.first == entry.second and previous.second == entry.first);
            if (same_pair) return false;
        }
    }
    return true;
}
