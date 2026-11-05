const Mission = @import("mission.zig").Mission;
const Player = @import("player.zig").Player;

pub fn printBanner(writer: anytype) !void {
    try writer.writeAll(
        \\============================================================
        \\                    HACKER'S TERMINAL
        \\               REALISTIC DARK SIMULATOR
        \\============================================================
        \\
        \\  This is a fictional, self-contained hacking simulation.
        \\  No real networks or external systems are contacted.
        \\
    );
}

pub fn printHelp(writer: anytype) !void {
    try writer.writeAll(
        \\COMMANDS
        \\  help                 Show this help
        \\  status               Show operator status
        \\  missions             List available contracts
        \\  briefing             Show clues for the active contract
        \\  accept <id>          Accept a contract
        \\  scan <target>        Scan the active fictional target
        \\  connect <target>     Connect after scanning
        \\  disconnect           End the simulated connection
        \\  brute <password>     Solve the password challenge
        \\  decrypt <key>        Decrypt the mission file
        \\  extract <filename>   Retrieve the mission file
        \\  inventory            Show owned tools
        \\  shop                 Show available tools
        \\  buy <item>           Purchase a tool
        \\  history              Show completed contracts
        \\  save                 Save progress
        \\  clear                Clear the terminal
        \\  exit                 Leave the game
        \\
        \\MISSION FLOW
        \\  missions -> accept -> briefing -> scan -> connect
        \\  -> brute -> decrypt -> extract
        \\
    );
}

pub fn printStatus(writer: anytype, player: Player, active: ?usize, missions: []const Mission, level: u32, next_level_xp: u32) !void {
    try writer.print(
        \\OPERATOR
        \\  Handle:      {s}
        \\  Balance:     ${d}
        \\  Reputation:  {d}
        \\  Level:       {d}
        \\  XP:          {d}/{d}
        \\  Decryptor:   {s}
        \\
    , .{ player.handle, player.balance, player.reputation, level, player.xp, next_level_xp, if (player.has_decryptor) "installed" else "not installed" });

    if (active) |index| {
        try writer.print("  Active job:  {s} ({s})\n", .{ missions[index].name, missions[index].id });
    } else {
        try writer.writeAll("  Active job:  none\n");
    }
}

pub fn printMissions(writer: anytype, missions: []const Mission, level: u32) !void {
    try writer.writeAll("AVAILABLE CONTRACTS\n");
    for (missions) |mission| {
        const state = if (mission.completed) "COMPLETED" else if (level < mission.required_level) "LOCKED" else "AVAILABLE";
        try writer.print("  [{s}] {s} | target: {s} | difficulty: {s} | reward: ${d} + {d} XP | {s}", .{
            mission.id,
            mission.name,
            mission.target,
            mission.difficulty.label(),
            mission.reward,
            mission.xp_reward,
            state,
        });
        if (!mission.completed and level < mission.required_level) {
            try writer.print(" (requires level {d})", .{mission.required_level});
        }
        try writer.writeAll("\n");
    }
    try writer.writeAll("\nUse: accept <id>\n");
}

pub fn printHistory(writer: anytype, missions: []const Mission) !void {
    try writer.writeAll("CONTRACT HISTORY\n");
    var found = false;
    for (missions) |mission| {
        if (mission.completed) {
            found = true;
            try writer.print("  [COMPLETED] {s} ({s}) | reward: ${d}\n", .{
                mission.name, mission.id, mission.reward,
            });
        }
    }
    if (!found) try writer.writeAll("  No completed contracts yet.\n");
}
