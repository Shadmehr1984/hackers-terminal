const std = @import("std");
const Mission = @import("mission.zig").Mission;
const MissionSession = @import("mission_state.zig").MissionSession;
const Player = @import("player.zig").Player;
const save = @import("save.zig");
const terminal = @import("terminal.zig");
const shop = @import("shop.zig");
const commands = @import("commands.zig");

/// Returns the player's level using the original progression thresholds.
pub fn playerLevel(player: Player) u32 {
    var level: u32 = 1;
    var next_level_xp: u32 = 100;
    while (level < 99 and player.xp >= next_level_xp) : (level += 1) {
        next_level_xp += 150;
    }
    return level;
}

/// Returns the cumulative XP threshold for the supplied level.
pub fn xpForNextLevel(level: u32) u32 {
    return 100 + (level - 1) * 150;
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

pub fn runCommand(
    writer: anytype,
    line: []const u8,
    player: *Player,
    missions: []Mission,
    active: *?usize,
    session: *MissionSession,
) !bool {
    const parsed = commands.parse(line) orelse return true;
    const command = parsed.name;
    const arg = parsed.argument;

    if (std.mem.eql(u8, command, "help")) {
        try terminal.printHelp(writer);
    } else if (std.mem.eql(u8, command, "status")) {
        try terminal.printStatus(writer, player.*, active.*, missions, playerLevel(player.*), xpForNextLevel(playerLevel(player.*)));
    } else if (std.mem.eql(u8, command, "missions")) {
        try terminal.printMissions(writer, missions, playerLevel(player.*));
    } else if (std.mem.eql(u8, command, "briefing")) {
        if (active.*) |index| {
            const mission = missions[index];
            try writer.print("CONTRACT BRIEFING: {s}\nTarget: {s}\nDifficulty: {s}\nPassword clue: {s}\nEncrypted file: {s}\nDecryption clue: {s}\n", .{
                mission.name, mission.target, mission.difficulty.label(), mission.password_hint, mission.encrypted_file, mission.decryption_hint,
            });
            try terminal.printObjectives(writer, mission, session.*);
        } else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "objectives")) {
        if (active.*) |index| {
            try terminal.printObjectives(writer, missions[index], session.*);
        } else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "accept")) {
        if (active.* != null) {
            try writer.writeAll("A contract is already active. Complete it first.\n");
        } else {
            var found = false;
            for (missions, 0..) |mission, index| {
                if (std.mem.eql(u8, mission.id, arg) and !mission.completed and playerLevel(player.*) >= mission.required_level) {
                    active.* = index;
                    session.start();
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
                session.markScanned();
                session.completeObjective(.scan_target);
                try writer.print("[SCAN COMPLETE] Fictional host {s} is reachable. One simulated service requires authentication.\n", .{arg});
                try writer.writeAll("A password challenge was identified.\n");
            }
        } else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "connect")) {
        if (active.*) |index| {
            if (!session.hasScanned() or !std.mem.eql(u8, arg, missions[index].target)) {
                try writer.writeAll("Scan the active target first: scan <target>\n");
            } else {
                session.connected = true;
                try writer.print("Simulated session established with {s}.\n", .{arg});
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "disconnect")) {
        session.connected = false;
        try writer.writeAll("Session closed.\n");
    } else if (std.mem.eql(u8, command, "brute")) {
        if (active.*) |index| {
            if (!session.connected) {
                try writer.writeAll("No session. Connect to the target first.\n");
            } else if (std.mem.eql(u8, arg, missions[index].password)) {
                session.markAuthenticated();
                session.completeObjective(.authenticate);
                try writer.writeAll("[ACCESS GRANTED] Authentication challenge solved.\n");
            } else {
                try writer.writeAll("[ACCESS DENIED] Incorrect password. Check the mission briefing.\n");
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "decrypt")) {
        if (active.*) |index| {
            if (!session.isAuthenticated()) {
                try writer.writeAll("Authentication is required before decryption.\n");
            } else if (!player.has_decryptor) {
                try writer.writeAll("Missing tool: decryptor. Visit the shop.\n");
            } else if (std.mem.eql(u8, arg, missions[index].decryption_key)) {
                session.markDecrypted();
                session.completeObjective(.decrypt_file);
                try writer.writeAll("[DECRYPTED] File contents verified. You can now extract the file.\n");
            } else {
                try writer.writeAll("[DECRYPTION FAILED] Incorrect key.\n");
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "extract")) {
        if (active.*) |index| {
            if (!session.isDecrypted() or !std.mem.eql(u8, arg, missions[index].encrypted_file)) {
                try writer.writeAll("The requested file is unavailable or still encrypted.\n");
            } else {
                session.completeObjective(.extract_file);
                if (!session.allObjectivesComplete(missions[index].objectives)) {
                    try writer.writeAll("Contract objectives are incomplete. Review 'objectives'.\n");
                } else {
                    const finished = missions[index];
                    missions[index].completed = true;
                    active.* = null;
                    session.reset();
                    try writer.print("[EXTRACTED] {s}\n", .{finished.encrypted_file});
                    try completeMission(writer, player, finished);
                }
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "inventory")) {
        try shop.printInventory(writer, player.*);
    } else if (std.mem.eql(u8, command, "shop")) {
        try shop.printShop(writer);
    } else if (std.mem.eql(u8, command, "buy")) {
        try shop.buyItem(writer, player, arg);
    } else if (std.mem.eql(u8, command, "history")) {
        try terminal.printHistory(writer, missions);
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
