const Mission = @import("mission.zig").Mission;
const MissionDifficulty = @import("mission.zig").MissionDifficulty;

/// Returns the built-in contracts with their original order and configuration.
pub fn defaultMissions() [3]Mission {
    return .{
        .{
            .id = "job-01",
            .name = "Cold Storage",
            .target = "vault-01.local",
            .difficulty = .easy,
            .password = "orion42",
            .password_hint = "A hunter constellation, followed by the number 42.",
            .encrypted_file = "ledger.enc",
            .decryption_hint = "The middle of the night.",
            .decryption_key = "midnight",
            .reward = 300,
            .xp_reward = 100,
            .required_level = 1,
        },
        .{
            .id = "job-02",
            .name = "Paper Trail",
            .target = "archive-02.local",
            .difficulty = .medium,
            .password = "copper17",
            .password_hint = "A reddish metal, followed by the number 17.",
            .encrypted_file = "mailbox.enc",
            .decryption_hint = "A small songbird often associated with a clear blue color.",
            .decryption_key = "bluebird",
            .reward = 500,
            .xp_reward = 150,
            .required_level = 2,
        },
        .{
            .id = "job-03",
            .name = "Quiet Exit",
            .target = "relay-03.local",
            .difficulty = .hard,
            .password = "northstar",
            .password_hint = "A fixed point used for navigation in the northern sky.",
            .encrypted_file = "manifest.enc",
            .decryption_hint = "The time after normal business hours.",
            .decryption_key = "afterhours",
            .reward = 800,
            .xp_reward = 200,
            .required_level = 3,
        },
    };
}

test "built-in missions have increasing difficulty" {
    const missions = defaultMissions();

    try @import("std").testing.expectEqual(MissionDifficulty.easy, missions[0].difficulty);
    try @import("std").testing.expectEqual(MissionDifficulty.medium, missions[1].difficulty);
    try @import("std").testing.expectEqual(MissionDifficulty.hard, missions[2].difficulty);
}
