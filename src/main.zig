const std = @import("std");
const Mission = @import("mission.zig").Mission;
const Player = @import("player.zig").Player;
const save = @import("save.zig");

fn printBanner(writer: anytype) !void {
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

fn printHelp(writer: anytype) !void {
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

fn playerLevel(player: Player) u32 {
    var level: u32 = 1;
    var next_level_xp: u32 = 100;
    while (level < 99 and player.xp >= next_level_xp) : (level += 1) {
        next_level_xp += 150;
    }
    return level;
}

fn xpForNextLevel(level: u32) u32 {
    return 100 + (level - 1) * 150;
}

fn printStatus(writer: anytype, player: Player, active: ?usize, missions: []const Mission) !void {
    const level = playerLevel(player);
    try writer.print(
        \\OPERATOR
        \\  Handle:      {s}
        \\  Balance:     ${d}
        \\  Reputation:  {d}
        \\  Level:       {d}
        \\  XP:          {d}/{d}
        \\  Decryptor:   {s}
        \\
    , .{ player.handle, player.balance, player.reputation, level, player.xp, xpForNextLevel(level), if (player.has_decryptor) "installed" else "not installed" });

    if (active) |index| {
        try writer.print("  Active job:  {s} ({s})\n", .{ missions[index].name, missions[index].id });
    } else {
        try writer.writeAll("  Active job:  none\n");
    }
}

fn printMissions(writer: anytype, player: Player, missions: []const Mission) !void {
    const level = playerLevel(player);
    try writer.writeAll("AVAILABLE CONTRACTS\n");
    for (missions) |mission| {
        const state = if (mission.completed) "COMPLETED" else if (level < mission.required_level) "LOCKED" else "AVAILABLE";
        try writer.print("  [{s}] {s} | target: {s} | reward: ${d} + {d} XP | {s}", .{
            mission.id,
            mission.name,
            mission.target,
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

fn printHistory(writer: anytype, missions: []const Mission) !void {
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

fn completeMission(writer: anytype, player: *Player, mission: Mission) !void {
    const old_level = playerLevel(player.*);
    player.balance += mission.reward;
    player.reputation += 1;
    player.xp += mission.xp_reward;
    const new_level = playerLevel(player.*);
    try writer.print("\n[CONTRACT COMPLETE] {s}\nReward received: ${d}\nXP gained: {d}\nReputation increased.\n", .{ mission.name, mission.reward, mission.xp_reward });
    if (new_level > old_level) {
        try writer.print("[LEVEL UP] You are now level {d}!\n", .{new_level});
    }
}

fn runCommand(
    writer: anytype,
    line: []const u8,
    player: *Player,
    missions: []Mission,
    active: *?usize,
    scanned: *bool,
    connected: *bool,
    access_granted: *bool,
    decrypted: *bool,
) !bool {
    var tokens = std.mem.tokenizeScalar(u8, line, ' ');
    const command = tokens.next() orelse return true;
    const arg = tokens.next() orelse "";

    if (std.mem.eql(u8, command, "help")) {
        try printHelp(writer);
    } else if (std.mem.eql(u8, command, "status")) {
        try printStatus(writer, player.*, active.*, missions);
    } else if (std.mem.eql(u8, command, "missions")) {
        try printMissions(writer, player.*, missions);
    } else if (std.mem.eql(u8, command, "briefing")) {
        if (active.*) |index| {
            const mission = missions[index];
            try writer.print("CONTRACT BRIEFING: {s}\nTarget: {s}\nPassword clue: {s}\nEncrypted file: {s}\nDecryption clue: {s}\n", .{
                mission.name, mission.target, mission.password_hint, mission.encrypted_file, mission.decryption_hint,
            });
        } else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "accept")) {
        if (active.* != null) {
            try writer.writeAll("A contract is already active. Complete it first.\n");
        } else {
            var found = false;
            for (missions, 0..) |mission, index| {
                if (std.mem.eql(u8, mission.id, arg) and !mission.completed and playerLevel(player.*) >= mission.required_level) {
                    active.* = index;
                    scanned.* = false;
                    connected.* = false;
                    access_granted.* = false;
                    decrypted.* = false;
                    found = true;
                    try writer.print("Contract accepted: {s}\nTarget: {s}\n", .{ mission.name, mission.target });
                    break;
                }
            }
            if (!found) {
                var locked = false;
                for (missions) |mission| {
                    if (std.mem.eql(u8, mission.id, arg) and !mission.completed) {
                        locked = true;
                        try writer.print("Contract locked. Reach level {d} first.\n", .{mission.required_level});
                        break;
                    }
                }
                if (!locked) try writer.writeAll("Unknown or already completed contract. Use 'missions'.\n");
            }
        }
    } else if (std.mem.eql(u8, command, "scan")) {
        if (active.*) |index| {
            if (!std.mem.eql(u8, arg, missions[index].target)) {
                try writer.writeAll("No active contract matches that target.\n");
            } else {
                scanned.* = true;
                try writer.print("[SCAN COMPLETE] Fictional host {s} is reachable. One simulated service requires authentication.\n", .{arg});
                try writer.writeAll("A password challenge was identified.\n");
            }
        } else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "connect")) {
        if (active.*) |index| {
            if (!scanned.* or !std.mem.eql(u8, arg, missions[index].target)) {
                try writer.writeAll("Scan the active target first: scan <target>\n");
            } else {
                connected.* = true;
                try writer.print("Simulated session established with {s}.\n", .{arg});
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "disconnect")) {
        connected.* = false;
        try writer.writeAll("Session closed.\n");
    } else if (std.mem.eql(u8, command, "brute")) {
        if (active.*) |index| {
            if (!connected.*) {
                try writer.writeAll("No session. Connect to the target first.\n");
            } else if (std.mem.eql(u8, arg, missions[index].password)) {
                access_granted.* = true;
                try writer.writeAll("[ACCESS GRANTED] Authentication challenge solved.\n");
            } else {
                try writer.writeAll("[ACCESS DENIED] Incorrect password. Check the mission briefing.\n");
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "decrypt")) {
        if (active.*) |index| {
            if (!access_granted.*) {
                try writer.writeAll("Authentication is required before decryption.\n");
            } else if (!player.has_decryptor) {
                try writer.writeAll("Missing tool: decryptor. Visit the shop.\n");
            } else if (std.mem.eql(u8, arg, missions[index].decryption_key)) {
                decrypted.* = true;
                try writer.writeAll("[DECRYPTED] File contents verified. You can now extract the file.\n");
            } else {
                try writer.writeAll("[DECRYPTION FAILED] Incorrect key.\n");
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "extract")) {
        if (active.*) |index| {
            if (!decrypted.* or !std.mem.eql(u8, arg, missions[index].encrypted_file)) {
                try writer.writeAll("The requested file is unavailable or still encrypted.\n");
            } else {
                const finished = missions[index];
                missions[index].completed = true;
                active.* = null;
                scanned.* = false;
                connected.* = false;
                access_granted.* = false;
                decrypted.* = false;
                try writer.print("[EXTRACTED] {s}\n", .{finished.encrypted_file});
                try completeMission(writer, player, finished);
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "inventory")) {
        try writer.writeAll("INVENTORY\n  Basic terminal kit\n");
        if (player.has_decryptor) try writer.writeAll("  File decryptor\n");
    } else if (std.mem.eql(u8, command, "shop")) {
        try writer.writeAll("BLACK MARKET (fictional)\n  decryptor - $150 - required to decrypt mission files\n");
    } else if (std.mem.eql(u8, command, "buy")) {
        if (std.mem.eql(u8, arg, "decryptor")) {
            if (player.has_decryptor) {
                try writer.writeAll("You already own a decryptor.\n");
            } else if (player.balance < 150) {
                try writer.writeAll("Insufficient funds.\n");
            } else {
                player.balance -= 150;
                player.has_decryptor = true;
                try writer.writeAll("Purchase complete: decryptor installed.\n");
            }
        } else try writer.writeAll("Unknown item. Use 'shop'.\n");
    } else if (std.mem.eql(u8, command, "history")) {
        try printHistory(writer, missions);
    } else if (std.mem.eql(u8, command, "save")) {
        save.saveGame(player.*, missions, active.*) catch {
            try writer.writeAll("Save failed. Check filesystem permissions.\n");
            return true;
        };
        try writer.writeAll("Progress saved to saves/player.sav.\n");
    } else if (std.mem.eql(u8, command, "clear")) {
        try writer.writeAll("\x1b[2J\x1b[H");
    } else if (std.mem.eql(u8, command, "exit")) {
        try writer.writeAll("Closing terminal. Stay safe, operator.\n");
        return false;
    } else {
        try writer.writeAll("Unknown command. Type 'help' for available commands.\n");
    }
    return true;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const allocator = general_purpose_allocator.allocator();

    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();

    var player = Player{};
    var missions = [_]Mission{
        .{
            .id = "job-01",
            .name = "Cold Storage",
            .target = "vault-01.local",
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

    const active_from_save = save.loadGame(allocator, &player, &missions);

    try printBanner(stdout);
    try stdout.print("Welcome back, {s}.\nBalance: ${d} | Reputation: {d} | Level: {d} | XP: {d}\n", .{
        player.handle,
        player.balance,
        player.reputation,
        playerLevel(player),
        player.xp,
    });
    try stdout.writeAll("Type 'help' to see commands.\n");

    var input_buffer: [512]u8 = undefined;
    var active: ?usize = active_from_save;
    var scanned = false;
    var connected = false;
    var access_granted = false;
    var decrypted = false;

    while (true) {
        try stdout.print("\n{s}@darknet:~$ ", .{player.handle});
        const maybe_line = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
        if (maybe_line == null) break;
        const line = std.mem.trim(u8, maybe_line.?, " \r\t");
        if (line.len == 0) continue;

        const keep_running = try runCommand(
            stdout,
            line,
            &player,
            &missions,
            &active,
            &scanned,
            &connected,
            &access_granted,
            &decrypted,
        );
        if (!keep_running) break;
    }
}
