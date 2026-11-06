const std = @import("std");
const Mission = @import("mission.zig").Mission;
const faction = @import("faction.zig");

/// Derived availability state; none of these values are persisted.
pub const Availability = enum {
    available,
    locked,
    completed,
    exclusive,
    unavailable,
    faction_blocked,

    /// Returns the stable terminal label.
    pub fn label(self: Availability) []const u8 {
        return switch (self) {
            .available => "AVAILABLE",
            .locked => "LOCKED",
            .completed => "COMPLETED",
            .exclusive => "EXCLUSIVE",
            .unavailable => "UNAVAILABLE",
            .faction_blocked => "FACTION LOCKED",
        };
    }
};

/// The conditions supplied by the current player/game state.
pub const Context = struct {
    level: u32,
    reputation: u32,
    another_contract_busy: bool = false,
    missions: []const Mission = &.{},
};

/// A read-only result for one catalog entry.
pub const Entry = struct {
    availability: Availability,
    level_locked: bool,
    reputation_locked: bool,
    minimum_reward: u32,
    maximum_reward: u32,
    faction_locked: bool,
    player_standing: faction.Standing,
};

/// Calculates the visible cash reward ceiling without leaking undiscovered hidden rewards.
pub fn maximumReward(mission: Mission) error{RewardOverflow}!u32 {
    var result = mission.reward;
    for (mission.objectives) |objective| {
        if (objective.optional and !objective.hidden) {
            result = std.math.add(u32, result, objective.bonus_reward) catch return error.RewardOverflow;
        }
    }
    return result;
}

/// Derives availability without mutating the catalog or player state.
pub fn evaluate(mission: Mission, context: Context) error{RewardOverflow}!Entry {
    const level_locked = context.level < mission.required_level;
    const reputation_locked = context.reputation < mission.required_reputation;
    const player_standing = faction.playerStanding(mission.client_faction, context.reputation, context.missions);
    const faction_locked = player_standing == .hostile;
    const availability: Availability = if (mission.completed)
        .completed
    else if (context.another_contract_busy)
        .unavailable
    else if (level_locked or reputation_locked)
        .locked
    else if (faction_locked)
        .faction_blocked
    else if (mission.requires_contact_offer)
        .exclusive
    else
        .available;

    return .{
        .availability = availability,
        .level_locked = level_locked,
        .reputation_locked = reputation_locked,
        .minimum_reward = mission.reward,
        .maximum_reward = try maximumReward(mission),
        .faction_locked = faction_locked,
        .player_standing = player_standing,
    };
}
