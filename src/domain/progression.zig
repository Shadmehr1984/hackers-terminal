const std = @import("std");
const Mission = @import("../domain/mission.zig").Mission;
const MissionSession = @import("../domain/mission_state.zig").MissionSession;
const Player = @import("../domain/player.zig").Player;

/// Represents the player's derived Reputation tier.
pub const ReputationTier = enum {
    unknown,
    recognized,
    trusted,
    elite,

    /// Returns the player-facing name of this Reputation tier.
    pub fn label(self: ReputationTier) []const u8 {
        return switch (self) {
            .unknown => "Unknown",
            .recognized => "Recognized",
            .trusted => "Trusted",
            .elite => "Elite",
        };
    }
};

/// Maps a numeric Reputation score to its tier.
pub fn reputationTier(reputation: u32) ReputationTier {
    return switch (reputation) {
        0 => .unknown,
        1...2 => .recognized,
        3...4 => .trusted,
        else => .elite,
    };
}

/// Calculates the player's level from cumulative XP, capped at level 99.
pub fn playerLevel(player: Player) u32 {
    var level: u32 = 1;
    var next_level_xp: u32 = 100;
    while (level < 99 and player.xp >= next_level_xp) : (level += 1) next_level_xp += 150;
    return level;
}

/// Returns the cumulative XP threshold associated with the requested level.
pub fn xpForNextLevel(level: u32) u32 {
    return 100 + (level - 1) * 150;
}

/// Applies a completed contract's cash, XP, and Reputation rewards and writes the result.
pub fn completeMission(writer: anytype, player: *Player, mission: Mission, session: *MissionSession) !void {
    if (session.completion_reward_paid) return;
    const run = session.*;
    const old_level = playerLevel(player.*);
    const bonus_reward = run.optionalReward(mission.objectives);
    const modifier_bonus = if (run.modifier) |modifier| modifier.completionBonus() else @import("mission_modifier.zig").CompletionBonus{ .cash = 0, .xp = 0 };
    const reputation_bonus: u32 = if (run.allOptionalObjectivesComplete(mission.objectives)) 1 else 0;
    const reputation_gain: u32 = 1 + reputation_bonus;

    // Preflight every accumulated value before writing output or mutating live state.
    const cash_reward = std.math.add(u32, mission.reward, bonus_reward) catch return error.RewardOverflow;
    const total_cash_reward = std.math.add(u32, cash_reward, modifier_bonus.cash) catch return error.RewardOverflow;
    const new_balance = std.math.add(u32, player.balance, total_cash_reward) catch return error.RewardOverflow;
    const new_reputation = std.math.add(u32, player.reputation, reputation_gain) catch return error.RewardOverflow;
    const xp_reward = std.math.add(u32, mission.xp_reward, modifier_bonus.xp) catch return error.RewardOverflow;
    const new_xp = std.math.add(u32, player.xp, xp_reward) catch return error.RewardOverflow;
    var updated_player = player.*;
    updated_player.balance = new_balance;
    updated_player.reputation = new_reputation;
    updated_player.xp = new_xp;
    const new_level = playerLevel(updated_player);
    try writer.print("\n[CONTRACT COMPLETE] {s}\nReward received: ${d}", .{ mission.name, mission.reward });
    if (bonus_reward > 0) try writer.print("\nOptional objective bonus: +${d}", .{bonus_reward});
    if (modifier_bonus.cash > 0 or modifier_bonus.xp > 0) try writer.print("\nMission modifier bonus: +${d}, +{d} XP", .{ modifier_bonus.cash, modifier_bonus.xp });
    try writer.print("\nXP gained: {d}\nReputation increased by {d} ({s}).\n", .{
        mission.xp_reward,
        reputation_gain,
        reputationTier(new_reputation).label(),
    });
    if (new_level > old_level) try writer.print("[LEVEL UP] You are now level {d}!\n", .{new_level});

    // Commit only after all calculations and output operations have succeeded.
    player.* = updated_player;
    session.completion_reward_paid = true;
}
