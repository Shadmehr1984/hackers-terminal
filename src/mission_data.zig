const Mission = @import("mission.zig").Mission;
const MissionObjective = @import("mission.zig").MissionObjective;
const MissionObjectiveKind = @import("mission.zig").MissionObjectiveKind;

const cold_storage_objectives: []const MissionObjective = &.{
    .{ .kind = .scan_target, .description = "Survey vault-01.local and identify its exposed service." },
    .{ .kind = .authenticate, .description = "Authenticate to the vault service." },
    .{ .kind = .decrypt_file, .description = "Decrypt the ledger.enc evidence file." },
    .{ .kind = .extract_file, .description = "Recover ledger.enc from the vault." },
};

const paper_trail_objectives: []const MissionObjective = &.{
    .{ .kind = .scan_target, .description = "Survey archive-02.local and locate the mail service." },
    .{ .kind = .authenticate, .description = "Gain access to the archive mail service." },
    .{ .kind = .decrypt_file, .description = "Decrypt the mailbox.enc message archive." },
    .{ .kind = .extract_file, .description = "Recover mailbox.enc from the archive." },
};

const quiet_exit_objectives: []const MissionObjective = &.{
    .{ .kind = .scan_target, .description = "Survey relay-03.local and identify its relay service." },
    .{ .kind = .authenticate, .description = "Authenticate to the relay service." },
    .{ .kind = .decrypt_file, .description = "Decrypt the manifest.enc transfer manifest." },
    .{ .kind = .extract_file, .description = "Recover manifest.enc from the relay." },
};

/// Returns the built-in contracts with their original order and configuration.
pub fn defaultMissions() [3]Mission {
    return .{
        .{
            .id = "job-01",
            .name = "Cold Storage",
            .target = "vault-01.local",
            .difficulty = .easy,
            .objectives = cold_storage_objectives,
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
            .objectives = paper_trail_objectives,
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
            .objectives = quiet_exit_objectives,
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
