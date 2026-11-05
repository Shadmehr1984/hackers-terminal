const Mission = @import("../domain/mission.zig").Mission;
const ModifierId = @import("../domain/mission_modifier.zig").ModifierId;

const all_mission_modifiers = [_]ModifierId{ .heightened_monitoring, .security_sweep, .hardened_encryption };
const MissionObjective = @import("../domain/mission.zig").MissionObjective;
const Topology = @import("../domain/topology.zig").Topology;
const Node = @import("../domain/topology.zig").Node;
const Link = @import("../domain/topology.zig").Link;

const cold_storage_nodes = [_]Node{
    .{ .id = "entry", .label = "Facility perimeter" },
    .{ .id = "service", .label = "Service kiosk" },
    .{ .id = "corridor", .label = "Exposed service corridor" },
    .{ .id = "maintenance", .label = "Maintenance access" },
    .{ .id = "plant", .label = "Utility room" },
    .{ .id = "vault", .label = "Evidence vault" },
};
const cold_storage_links = [_]Link{
    .{ .from = "entry", .to = "service" },
    .{ .from = "service", .to = "corridor" },
    .{ .from = "corridor", .to = "vault" },
    .{ .from = "service", .to = "maintenance" },
    .{ .from = "maintenance", .to = "plant" },
    .{ .from = "plant", .to = "vault" },
};
const cold_storage_topology = Topology{
    .nodes = &cold_storage_nodes,
    .links = &cold_storage_links,
    .entry_node = "entry",
    .scan_node = "service",
    .auth_node = "service",
    .decrypt_node = "vault",
    .analyze_node = "vault",
    .extract_node = "vault",
};

const paper_trail_nodes = [_]Node{
    .{ .id = "entry", .label = "Archive gateway" },
    .{ .id = "index", .label = "Indexing hub" },
    .{ .id = "mail-gw", .label = "Mail-processing gateway" },
    .{ .id = "mail-store", .label = "Mailbox store" },
    .{ .id = "records-gw", .label = "Records-access gateway" },
    .{ .id = "records", .label = "Records metadata vault" },
};
const paper_trail_links = [_]Link{
    .{ .from = "entry", .to = "index" },
    .{ .from = "index", .to = "mail-gw" },
    .{ .from = "mail-gw", .to = "mail-store" },
    .{ .from = "index", .to = "records-gw" },
    .{ .from = "records-gw", .to = "records" },
};
const paper_trail_topology = Topology{
    .nodes = &paper_trail_nodes,
    .links = &paper_trail_links,
    .entry_node = "entry",
    .scan_node = "index",
    .auth_node = "mail-gw",
    .decrypt_node = "mail-store",
    .analyze_node = "records",
    .extract_node = "mail-store",
};

const quiet_exit_nodes = [_]Node{
    .{ .id = "entry", .label = "Outer relay entry" },
    .{ .id = "relay-a", .label = "Relay station A" },
    .{ .id = "relay-core", .label = "Central relay" },
    .{ .id = "decoy", .label = "Decoy relay branch" },
    .{ .id = "transfer", .label = "Transfer cache" },
    .{ .id = "exit", .label = "Controlled exit node" },
};
const quiet_exit_links = [_]Link{
    .{ .from = "entry", .to = "relay-a" },
    .{ .from = "relay-a", .to = "relay-core" },
    .{ .from = "relay-core", .to = "decoy" },
    .{ .from = "relay-core", .to = "transfer" },
    .{ .from = "transfer", .to = "exit" },
};
const quiet_exit_topology = Topology{
    .nodes = &quiet_exit_nodes,
    .links = &quiet_exit_links,
    .entry_node = "entry",
    .scan_node = "relay-a",
    .auth_node = "relay-core",
    .decrypt_node = "transfer",
    .analyze_node = "transfer",
    .extract_node = "exit",
};

const ghost_signal_nodes = [_]Node{
    .{ .id = "entry", .label = "Abandoned relay entrance" },
    .{ .id = "uplink", .label = "Uplink switchboard" },
    .{ .id = "handshake", .label = "Handshake relay" },
    .{ .id = "cache", .label = "Signal cache" },
    .{ .id = "mirror", .label = "Mirrored traffic branch" },
    .{ .id = "beacon", .label = "Ghost beacon" },
};
const ghost_signal_links = [_]Link{
    .{ .from = "entry", .to = "uplink" },
    .{ .from = "uplink", .to = "handshake" },
    .{ .from = "handshake", .to = "cache" },
    .{ .from = "cache", .to = "beacon" },
    .{ .from = "uplink", .to = "mirror" },
    .{ .from = "mirror", .to = "cache" },
};
const ghost_signal_topology = Topology{
    .nodes = &ghost_signal_nodes,
    .links = &ghost_signal_links,
    .entry_node = "entry",
    .scan_node = "uplink",
    .auth_node = "handshake",
    .decrypt_node = "cache",
    .analyze_node = "cache",
    .extract_node = "beacon",
};

const cold_storage_objectives: []const MissionObjective = &.{
    .{ .kind = .scan_target, .description = "Survey vault-01.local and identify its exposed service." },
    .{ .kind = .authenticate, .description = "Authenticate to the vault service." },
    .{ .kind = .decrypt_file, .description = "Decrypt the ledger.enc evidence file." },
    .{ .kind = .extract_file, .description = "Recover ledger.enc from the vault." },
    .{ .kind = .analyze_metadata, .description = "Analyze the recovered ledger metadata for a hidden reference.", .optional = true, .bonus_reward = 75 },
};

const paper_trail_objectives: []const MissionObjective = &.{
    .{ .kind = .scan_target, .description = "Survey archive-02.local and locate the mail service." },
    .{ .kind = .authenticate, .description = "Gain access to the archive mail service." },
    .{ .kind = .decrypt_file, .description = "Decrypt the mailbox.enc message archive." },
    .{ .kind = .extract_file, .description = "Recover mailbox.enc from the archive." },
    .{ .kind = .analyze_metadata, .description = "Analyze mailbox metadata and identify its concealed sender tag.", .optional = true, .bonus_reward = 100 },
};

const quiet_exit_objectives: []const MissionObjective = &.{
    .{ .kind = .scan_target, .description = "Survey relay-03.local and identify its relay service." },
    .{ .kind = .authenticate, .description = "Authenticate to the relay service." },
    .{ .kind = .decrypt_file, .description = "Decrypt the manifest.enc transfer manifest." },
    .{ .kind = .extract_file, .description = "Recover manifest.enc from the relay." },
    .{ .kind = .analyze_metadata, .description = "Analyze manifest metadata to uncover an alternate relay marker.", .optional = true, .bonus_reward = 125 },
};

const ghost_signal_objectives: []const MissionObjective = &.{
    .{ .kind = .scan_target, .description = "Survey signal-04.local and identify the dormant uplink." },
    .{ .kind = .authenticate, .description = "Authenticate through the handshake relay." },
    .{ .kind = .decrypt_file, .description = "Decrypt the ghost-signal.enc transmission." },
    .{ .kind = .extract_file, .description = "Recover ghost-signal.enc from the beacon." },
    .{ .kind = .analyze_metadata, .description = "Analyze the transmission metadata to identify its origin marker.", .optional = true, .bonus_reward = 175 },
};

/// Returns the built-in contracts with their original order and configuration.
/// job-04 is appended so persisted indices 0..2 retain their original meaning.
pub fn defaultMissions() [4]Mission {
    return .{
        .{
            .id = "job-01",
            .name = "Cold Storage",
            .target = "vault-01.local",
            .difficulty = .easy,
            .category = .data_recovery,
            .allowed_modifiers = &all_mission_modifiers,
            .objectives = cold_storage_objectives,
            .topology = &cold_storage_topology,
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
            .category = .intelligence,
            .allowed_modifiers = &all_mission_modifiers,
            .objectives = paper_trail_objectives,
            .topology = &paper_trail_topology,
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
            .category = .extraction,
            .allowed_modifiers = &all_mission_modifiers,
            .objectives = quiet_exit_objectives,
            .topology = &quiet_exit_topology,
            .password = "northstar",
            .password_hint = "A fixed point used for navigation in the northern sky.",
            .encrypted_file = "manifest.enc",
            .decryption_hint = "The time after normal business hours.",
            .decryption_key = "afterhours",
            .reward = 800,
            .xp_reward = 200,
            .required_level = 3,
        },
        .{
            .id = "job-04",
            .name = "Ghost Signal",
            .target = "signal-04.local",
            .difficulty = .hard,
            .category = .infiltration,
            .allowed_modifiers = &all_mission_modifiers,
            .objectives = ghost_signal_objectives,
            .topology = &ghost_signal_topology,
            .password = "glasshouse",
            .password_hint = "A transparent shelter used to grow delicate plants.",
            .encrypted_file = "ghost-signal.enc",
            .decryption_hint = "A sudden, brief fall of rain.",
            .decryption_key = "cloudburst",
            .reward = 1100,
            .xp_reward = 250,
            .required_level = 3,
            .required_reputation = 3,
            .requires_contact_offer = true,
        },
    };
}
