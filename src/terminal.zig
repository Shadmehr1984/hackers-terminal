const Mission = @import("mission.zig").Mission;
const MissionSession = @import("mission_state.zig").MissionSession;
const Player = @import("player.zig").Player;
const std = @import("std");

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
        \\  briefing             Show clues and objectives for the active contract
        \\  objectives           Show active contract objective progress
        \\  map                  Show the active fictional network map
        \\  move <node-id>       Move to an adjacent map node (+5 detection)
        \\  Detection is shown by 'status'; risky actions increase exposure.
        \\  accept <id>          Accept a contract
        \\  scan <target>        Scan the active fictional target
        \\  connect <target>     Connect after scanning
        \\  disconnect           End the simulated connection
        \\  brute <password>     Solve the password challenge
        \\  decrypt <key>        Decrypt the mission file
        \\  analyze <filename>   Analyze optional metadata after decryption
        \\  extract <filename>   Retrieve the mission file
        \\  inventory            Show owned tools
        \\  shop                 Show available tools
        \\  buy <item>           Purchase a tool
        \\  equip <utility>      Equip an owned utility
        \\  upgrade <utility>    Upgrade an owned utility
        \\  history              Show completed contracts
        \\  save                 Save progress
        \\  clear                Clear the terminal
        \\  exit                 Leave the game
        \\
        \\MISSION FLOW
        \\  missions -> accept -> briefing -> scan -> connect
        \\  -> brute -> decrypt -> analyze (optional) -> extract
        \\
    );
}

pub fn printStatus(writer: anytype, player: Player, active: ?usize, missions: []const Mission, level: u32, next_level_xp: u32, session: MissionSession) !void {
    try writer.print(
        \\OPERATOR
        \\  Handle:      {s}
        \\  Balance:     ${d}
        \\  Reputation:  {d}
        \\  Level:       {d}
        \\  XP:          {d}/{d}
        \\  Decryptor:   {s}
        \\
    , .{ player.handle, player.balance, player.reputation, level, player.xp, next_level_xp, if (player.equipment.has_decryptor) "installed" else "not installed" });

    if (active) |index| {
        try writer.print("  Active job:  {s} ({s})\n  Detection:   {d}/100 ({s})\n", .{ missions[index].name, missions[index].id, session.detection_level, session.detectionBand().label() });
        if (session.current_node) |node| try writer.print("  Location:    {s}\n", .{node});
        try writer.print("  Traversals:  {d}\n", .{session.traversal_count});
    } else {
        try writer.writeAll("  Active job:  none\n  Detection:   inactive\n");
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

pub fn printObjectives(writer: anytype, mission: Mission, session: MissionSession) !void {
    try writer.print("OBJECTIVES: {s}\n", .{mission.name});
    for (mission.objectives) |objective| {
        const state = if (session.isObjectiveComplete(objective.kind)) "[x]" else "[ ]";
        const category = if (objective.optional) "[OPTIONAL] " else "";
        try writer.print("  {s} {s}{s}", .{ state, category, objective.description });
        if (objective.optional) try writer.print(" (+${d})", .{objective.bonus_reward});
        try writer.writeAll("\n");
    }
    try writer.writeAll("\n");
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

pub fn printMap(writer: anytype, mission: Mission, session: MissionSession) !void {
    if (mission.topology) |topology| {
        try writer.print("NETWORK MAP: {s}\nCurrent node: {s}\nSuccessful traversals: {d}\n\nNODES\n", .{
            mission.name, session.current_node orelse "unknown", session.traversal_count,
        });
        for (topology.nodes) |node| {
            const current = if (session.current_node) |id| std.mem.eql(u8, id, node.id) else false;
            const purpose = topology.purposeAt(node.id);
            if (purpose.len > 0) {
                try writer.print("  {s}{s} — {s} [{s}]\n", .{
                    if (current) "-> " else "   ", node.id, node.label, purpose,
                });
            } else {
                try writer.print("  {s}{s} — {s}\n", .{
                    if (current) "-> " else "   ", node.id, node.label,
                });
            }
        }
        try writer.writeAll("\nLINKS\n");
        for (topology.links) |link| try writer.print("  {s} <-> {s}\n", .{ link.from, link.to });
        try writer.writeAll("\nMove only to an adjacent node. Every successful move adds 5 detection before equipment modifiers.\n");
    } else try writer.writeAll("This contract has no network topology.\n");
}
