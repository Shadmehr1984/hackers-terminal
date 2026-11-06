const std = @import("std");
const Rival = @import("../domain/rival.zig").Rival;
const RivalId = @import("../domain/rival.zig").RivalId;
const Mission = @import("../domain/mission.zig").Mission;

/// Five authored offline competitors and their deterministic optional-intel contests.
const rivals = [_]Rival{
    .{
        .id = .ghost_operator,
        .name = "Ghost Operator",
        .faction = .ghost_protocol,
        .specialty = "Stealth access and low-noise routing",
        .approach = "Maps alternate relay paths and looks for traces before the main operation begins.",
        .mission_id = "job-03",
        .objective_id = "relay-trace",
        .briefing_hint = "A relay trace is exposed by the initial scan. Check your objectives immediately after scanning.",
    },
    .{
        .id = .null_byte,
        .name = "Null Byte",
        .faction = .null_syndicate,
        .specialty = "Disruption, decoys, and corrupted records",
        .approach = "Leaves misleading-looking fragments around contested data paths.",
        .mission_id = "job-04",
        .objective_id = "mirror-fragment",
        .briefing_hint = "A mirrored relay branch may contain optional intelligence. Explore it before decrypting the target file.",
    },
    .{
        .id = .glasswire,
        .name = "Glasswire",
        .faction = .black_veil,
        .specialty = "Document analysis and provenance tracking",
        .approach = "Searches archives for routing records and incomplete evidence.",
        .mission_id = "job-02",
        .objective_id = "routing-header",
        .briefing_hint = "A routing record may be contested. Inspect relevant fictional evidence before decrypting the target file.",
    },
    .{
        .id = .patchwork,
        .name = "Patchwork",
        .faction = .iron_meridian,
        .specialty = "Infrastructure access and operational disruption",
        .approach = "Targets maintenance paths and exposed utility infrastructure.",
        .mission_id = "job-01",
        .objective_id = "maintenance-telemetry",
        .briefing_hint = "A maintenance-side signal may be contested. Explore optional network branches before decrypting the target file.",
    },
    .{
        .id = .redshift,
        .name = "Redshift",
        .faction = .helix_consortium,
        .specialty = "Predictive analysis and research intelligence",
        .approach = "Correlates mirrored traffic and secondary destination markers.",
        .mission_id = "job-05",
        .objective_id = "mirror-fragment",
        .briefing_hint = "A traffic-mirror branch may contain optional intelligence. Explore it before decrypting the target file.",
    },
};

/// Returns the five rivals in stable catalog order.
pub fn all() []const Rival {
    return &rivals;
}

/// Looks up a rival by stable identity.
pub fn find(id: RivalId) ?Rival {
    for (rivals) |entry| {
        if (entry.id == id) return entry;
    }
    return null;
}

/// Returns the rival authored to contest a contract, if one exists.
pub fn forMission(mission_id: []const u8) ?Rival {
    for (rivals) |entry| {
        if (std.mem.eql(u8, entry.mission_id, mission_id)) return entry;
    }
    return null;
}

/// Validates unique identities and complete references to the current catalogs.
pub fn validate(missions: []const Mission) bool {
    if (rivals.len != 5) return false;
    for (rivals, 0..) |entry, index| {
        if (entry.name.len == 0 or entry.specialty.len == 0 or entry.approach.len == 0 or entry.briefing_hint.len == 0) return false;
        if (entry.mission_id.len == 0 or entry.objective_id.len == 0) return false;
        for (rivals[0..index]) |previous| {
            if (previous.id == entry.id or std.mem.eql(u8, previous.mission_id, entry.mission_id)) return false;
        }
        var mission_found = false;
        for (missions) |mission| {
            if (!std.mem.eql(u8, mission.id, entry.mission_id)) continue;
            mission_found = true;
            var objective_found = false;
            for (mission.objectives) |objective| {
                if (std.mem.eql(u8, objective.id, entry.objective_id) and objective.optional and objective.hidden and objective.bonus_reward == 0) {
                    objective_found = true;
                    break;
                }
            }
            if (!objective_found) return false;
        }
        if (!mission_found) return false;
    }
    return true;
}
