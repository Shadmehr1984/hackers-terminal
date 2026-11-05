const Mission = @import("mission.zig").Mission;
const MissionSession = @import("mission_state.zig").MissionSession;
const Player = @import("player.zig").Player;

pub const ReputationTier = enum {
    unknown,
    recognized,
    trusted,
    elite,

    pub fn label(self: ReputationTier) []const u8 {
        return switch (self) {
            .unknown => "Unknown",
            .recognized => "Recognized",
            .trusted => "Trusted",
            .elite => "Elite",
        };
    }
}

pub fn reputationTier(reputation: u32) ReputationTier {
    return switch (reputation) {
        0 => .unknown,
        1...2 => .recognized,
        3...4 => .trusted,
        else => .elite,
    };
}

pub fn playerLevel(player: Player) u32 {
    var level: u32 = 1;
    var next_level_xp: u32 = 100;
    while (level < 99 and player.xp >= next_level_xp) : (level += 1) next_level_xp += 150;
    return level;
}

pub fn xpForNextLevel(level: u32) u32 {
    return 100 + (level - 1) * 150;
}

pub fn completeMission(writer: anytype, player: *Player, mission: Mission, session: MissionSession) !void {
    const old_level = playerLevel(player.*);
    const bonus_reward = session.optionalReward(mission.objectives);
    const reputation_bonus: u32 = if (session.allOptionalObjectivesComplete(mission.objectives)) 1 else 0;
    const reputation_gain: u32 = 1 + reputation_bonus;
    player.balance += mission.reward + bonus_reward;
    player.reputation += reputation_gain;
    player.xp += mission.xp_reward;
    const new_level = playerLevel(player.*);
    try writer.print("\n[CONTRACT COMPLETE] {s}\nReward received: ${d}", .{ mission.name, mission.reward });
    if (bonus_reward > 0) try writer.print("\nOptional objective bonus: +${d}", .{bonus_reward});
    try writer.print("\nXP gained: {d}\nReputation increased by {d} ({s}).\n", .{
        mission.xp_reward,
        reputation_gain,
        reputationTier(player.reputation).label(),
    });
    if (new_level > old_level) try writer.print("[LEVEL UP] You are now level {d}!\n", .{new_level});
}
