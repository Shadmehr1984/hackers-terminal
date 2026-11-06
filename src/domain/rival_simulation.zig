const std = @import("std");
const Rival = @import("rival.zig").Rival;
const RivalStatus = @import("rival.zig").RivalStatus;
const Mission = @import("mission.zig").Mission;
const faction = @import("faction.zig");
const Tracker = @import("mission_objectives.zig").Tracker;

/// Derives rival status from progression and the active run's objective state.
pub fn status(
    rival: Rival,
    missions: []const Mission,
    level: u32,
    reputation: u32,
    active_mission_id: ?[]const u8,
    tracker: ?*const Tracker,
) RivalStatus {
    for (missions) |mission| {
        if (!std.mem.eql(u8, mission.id, rival.mission_id)) continue;
        if (mission.completed) return .outpaced;
        if (active_mission_id) |active_id| {
            if (std.mem.eql(u8, active_id, rival.mission_id)) {
                if (tracker) |current| {
                    if (current.stateOf(rival.objective_id)) |state| {
                        return switch (state) {
                            .unavailable => .rival_ahead,
                            .discovered, .completed => .outpaced,
                            .undiscovered => .contesting,
                        };
                    }
                }
            }
        }
        if (level < mission.required_level or reputation < mission.required_reputation or
            faction.playerStanding(mission.client_faction, reputation, missions) == .hostile)
        {
            return .dormant;
        }
        return .contesting;
    }
    return .dormant;
}

/// Lets the authored rival claim an undiscovered side opportunity at successful decryption.
pub fn resolveAfterDecryption(rival: Rival, tracker: *Tracker) bool {
    return tracker.markUnavailable(rival.objective_id);
}
