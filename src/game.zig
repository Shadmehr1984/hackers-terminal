const std = @import("std");
const Mission = @import("mission.zig").Mission;
const MissionState = @import("mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const MissionLoadout = MissionState.MissionLoadout;
const UtilityEquipment = @import("player.zig").UtilityEquipment;
const Player = @import("player.zig").Player;
const save = @import("save.zig");
const terminal = @import("terminal.zig");
const shop = @import("shop.zig");
const commands = @import("commands.zig");

pub const detection_failure_penalty: u32 = 50;

fn parseUtility(name: []const u8) ?UtilityEquipment {
    if (std.mem.eql(u8, name, "silent-boots")) return .silent_boots;
    if (std.mem.eql(u8, name, "signal-scrubber")) return .signal_scrubber;
    return null;
}

pub fn currentLoadout(player: Player) MissionLoadout {
    const utility = player.equipment.equipped_utility orelse return .{};
    if (!player.equipment.owns(utility)) return .{};
    return .{ .utility = utility, .level = player.equipment.level(utility) };
}

fn atMissionNode(mission: Mission, session: MissionSession, expected: []const u8) bool {
    if (mission.topology == null) return true;
    return std.mem.eql(u8, session.current_node orelse "", expected);
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

fn completeMission(writer: anytype, player: *Player, mission: Mission, session: MissionSession) !void {
    const old_level = playerLevel(player.*);
    const bonus_reward = session.optionalReward(mission.objectives);
    player.balance += mission.reward + bonus_reward;
    player.reputation += 1;
    player.xp += mission.xp_reward;
    const new_level = playerLevel(player.*);
    try writer.print("\n[CONTRACT COMPLETE] {s}\nReward received: ${d}", .{ mission.name, mission.reward });
    if (bonus_reward > 0) try writer.print("\nOptional objective bonus: +${d}", .{bonus_reward});
    try writer.print("\nXP gained: {d}\nReputation increased.\n", .{mission.xp_reward});
    if (new_level > old_level) try writer.print("[LEVEL UP] You are now level {d}!\n", .{new_level});
}

fn applyDetection(
    writer: anytype,
    player: *Player,
    active: *?usize,
    session: *MissionSession,
    amount: u8,
) !bool {
    const previous_band = session.detectionBand();
    session.addDetection(amount);
    const current_band = session.detectionBand();
    if (current_band != previous_band and current_band != .compromised) {
        try writer.print("[DETECTION WARNING] Exposure is now {d}/100 ({s}).\n", .{
            session.detection_level, current_band.label(),
        });
    }
    if (session.detection_level >= 100) {
        const penalty = @min(player.balance, detection_failure_penalty);
        player.balance -= penalty;
        try writer.print(
            "[CONTRACT FAILED] Detection reached 100/100. The operation was compromised. ${d} penalty applied; remaining balance: {d}. You may accept this contract again.\n",
            .{ penalty, player.balance },
        );
        active.* = null;
        session.reset();
        return true;
    }
    return false;
}

pub fn runCommandWithPreparation(
    writer: anytype,
    line: []const u8,
    player: *Player,
    missions: []Mission,
    active: *?usize,
    session: *MissionSession,
    preparation: *MissionPreparation,
) !bool {
    const parsed = commands.parse(line) orelse return true;
    const command = parsed.name;
    const arg = parsed.argument;

    if (std.mem.eql(u8, command, "help")) {
        try terminal.printHelp(writer);
    } else if (std.mem.eql(u8, command, "status")) {
        const level = playerLevel(player.*);
        try terminal.printStatus(writer, player.*, active.*, missions, level, xpForNextLevel(level), session.*);
    } else if (std.mem.eql(u8, command, "missions")) {
        try terminal.printMissions(writer, missions, playerLevel(player.*));
    } else if (std.mem.eql(u8, command, "prepare")) {
        if (active.* != null) {
            try writer.writeAll("A contract is already active. Finish or fail it before preparing another.\n");
        } else if (preparation.mission_index != null) {
            try writer.writeAll("A contract is already prepared. Use cancel before choosing another.\n");
        } else {
            var found = false;
            for (missions, 0..) |mission, index| {
                if (!std.mem.eql(u8, mission.id, arg)) continue;
                found = true;
                if (mission.completed) {
                    try writer.writeAll("This contract is already completed.\n");
                } else if (playerLevel(player.*) < mission.required_level) {
                    try writer.print("Contract locked. Reach level {d} first.\n", .{mission.required_level});
                } else {
                    preparation.mission_index = index;
                    preparation.selected_utility = if (player.equipment.equipped_utility) |utility|
                        (if (player.equipment.owns(utility)) utility else null)
                    else
                        null;
                    try terminal.printPreparation(writer, mission, player.*, preparation.selected_utility);
                }
                break;
            }
            if (!found) try writer.writeAll("Unknown contract. Use missions.\n");
        }
    } else if (std.mem.eql(u8, command, "loadout")) {
        if (preparation.mission_index == null) {
            try writer.writeAll("No contract is being prepared. Use prepare <id> first.\n");
        } else if (std.mem.eql(u8, arg, "none")) {
            preparation.selected_utility = null;
            try writer.writeAll("Preparation loadout set to no utility.\n");
        } else if (parseUtility(arg)) |utility| {
            if (!player.equipment.owns(utility)) {
                try writer.writeAll("You do not own that utility.\n");
            } else {
                preparation.selected_utility = utility;
                try writer.print("Preparation loadout set to {s} (level {d}).\n", .{ utility.label(), player.equipment.level(utility) });
            }
        } else try writer.writeAll("Unknown loadout. Use loadout silent-boots, loadout signal-scrubber, or loadout none.\n");
    } else if (std.mem.eql(u8, command, "cancel")) {
        if (preparation.mission_index != null) {
            preparation.clear();
            try writer.writeAll("Mission preparation cancelled. No cost was charged.\n");
        } else if (active.* != null) {
            try writer.writeAll("An active contract cannot be abandoned or restarted.\n");
        } else try writer.writeAll("There is no mission preparation to cancel.\n");
    } else if (std.mem.eql(u8, command, "map")) {
        if (active.*) |index| try terminal.printMap(writer, missions[index], session.*) else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "move")) {
        if (active.*) |index| {
            if (missions[index].topology) |topology| {
                if (session.current_node) |current| {
                    if (!topology.containsNode(arg)) {
                        try writer.writeAll("Unknown node. Use 'map' to inspect this contract's network.\n");
                    } else if (!topology.areAdjacent(current, arg)) {
                        try writer.writeAll("That node is not directly connected to your current location.\n");
                    } else {
                        const node = topology.findNode(arg).?;
                        session.current_node = node.id;
                        session.traversal_count += 1;
                        try writer.print("[MOVED] {s} — {s}\n", .{ node.id, node.label });
                        _ = try applyDetection(writer, player, active, session, session.loadout.movementDetectionCost());
                    }
                } else try writer.writeAll("Current location is unavailable. Restart the contract.\n");
            } else try writer.writeAll("This contract has no network map.\n");
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "briefing")) {
        if (active.*) |index| {
            const mission = missions[index];
            try writer.print("CONTRACT BRIEFING: {s}\nTarget: {s}\nDifficulty: {s}\nPassword clue: {s}\nEncrypted file: {s}\nDecryption clue: {s}\n", .{
                mission.name, mission.target, mission.difficulty.label(), mission.password_hint, mission.encrypted_file, mission.decryption_hint,
            });
            if (mission.topology != null) try writer.writeAll("Network: use 'map' to inspect nodes and objective locations.\n");
            try terminal.printObjectives(writer, mission, session.*);
        } else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "objectives")) {
        if (active.*) |index| try terminal.printObjectives(writer, missions[index], session.*) else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "accept")) {
        if (active.* != null) {
            try writer.writeAll("A contract is already active. Complete it first.\n");
        } else if (preparation.mission_index == null) {
            try writer.writeAll("Prepare a contract before launching it: prepare <id>.\n");
        } else {
            const index = preparation.mission_index.?;
            const mission = missions[index];
            if (!std.mem.eql(u8, mission.id, arg)) {
                try writer.print("Prepared contract is {s}. Use accept {s} to launch it, or cancel to choose another.\n", .{ mission.id, mission.id });
            } else if (mission.completed or playerLevel(player.*) < mission.required_level) {
                preparation.clear();
                try writer.writeAll("The prepared contract is no longer available. Preparation cleared.\n");
            } else if (preparation.selected_utility) |utility| {
                if (!player.equipment.owns(utility)) {
                    try writer.writeAll("Selected utility is no longer owned. Choose another loadout.\n");
                } else {
                    session.startWithLoadout(.{ .utility = utility, .level = player.equipment.level(utility) });
                    active.* = index;
                    preparation.clear();
                    if (mission.topology) |topology| session.current_node = topology.entry_node;
                    try writer.print("Contract launched: {s}\nTarget: {s}\n", .{ mission.name, mission.target });
                    if (session.current_node) |node| try writer.print("Starting node: {s}\n", .{node});
                }
            } else {
                session.startWithLoadout(.{});
                active.* = index;
                preparation.clear();
                if (mission.topology) |topology| session.current_node = topology.entry_node;
                try writer.print("Contract launched: {s}\nTarget: {s}\n", .{ mission.name, mission.target });
                if (session.current_node) |node| try writer.print("Starting node: {s}\n", .{node});
            }
        }
    } else if (std.mem.eql(u8, command, "scan")) {
        if (active.*) |index| {
            const mission = missions[index];
            if (!std.mem.eql(u8, arg, mission.target)) {
                try writer.writeAll("No active contract matches that target.\n");
            } else if (mission.topology) |topology| {
                if (!atMissionNode(mission, session.*, topology.scan_node)) {
                    try writer.print("Move to node '{s}' before scanning this target.\n", .{topology.scan_node});
                } else {
                    const already_scanned = session.isObjectiveComplete(.scan_target);
                    session.markScanned();
                    session.completeObjective(.scan_target);
                    try writer.print("[SCAN COMPLETE] Fictional host {s} is reachable. One simulated service requires authentication.\n", .{arg});
                    try writer.writeAll("A password challenge was identified.\n");
                    if (!already_scanned) _ = try applyDetection(writer, player, active, session, 10);
                }
            } else {
                const already_scanned = session.isObjectiveComplete(.scan_target);
                session.markScanned();
                session.completeObjective(.scan_target);
                try writer.print("[SCAN COMPLETE] Fictional host {s} is reachable. One simulated service requires authentication.\n", .{arg});
                try writer.writeAll("A password challenge was identified.\n");
                if (!already_scanned) _ = try applyDetection(writer, player, active, session, 10);
            }
        } else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "connect")) {
        if (active.*) |index| {
            const mission = missions[index];
            if (!session.hasScanned() or !std.mem.eql(u8, arg, mission.target)) {
                try writer.writeAll("Scan the active target first: scan <target>\n");
            } else if (mission.topology) |topology| {
                if (!atMissionNode(mission, session.*, topology.auth_node)) {
                    try writer.print("Move to node '{s}' before connecting.\n", .{topology.auth_node});
                } else {
                    session.connected = true;
                    try writer.print("Simulated session established with {s}.\n", .{arg});
                }
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
            const mission = missions[index];
            if (mission.topology != null and !atMissionNode(mission, session.*, mission.topology.?.auth_node)) {
                try writer.print("Move to node '{s}' before authentication.\n", .{mission.topology.?.auth_node});
            } else if (!session.connected) {
                try writer.writeAll("No session. Connect to the target first.\n");
            } else if (std.mem.eql(u8, arg, mission.password)) {
                const already_authenticated = session.isAuthenticated();
                session.markAuthenticated();
                session.completeObjective(.authenticate);
                try writer.writeAll("[ACCESS GRANTED] Authentication challenge solved.\n");
                if (!already_authenticated) _ = try applyDetection(writer, player, active, session, 5);
            } else {
                try writer.writeAll("[ACCESS DENIED] Incorrect password. Check the mission briefing.\n");
                _ = try applyDetection(writer, player, active, session, session.loadout.incorrectAuthenticationDetectionCost());
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "decrypt")) {
        if (active.*) |index| {
            const mission = missions[index];
            if (!session.isAuthenticated()) {
                try writer.writeAll("Authentication is required before decryption.\n");
            } else if (mission.topology != null and !atMissionNode(mission, session.*, mission.topology.?.decrypt_node)) {
                try writer.print("Move to node '{s}' before decryption.\n", .{mission.topology.?.decrypt_node});
            } else if (!player.equipment.has_decryptor) {
                try writer.writeAll("Missing tool: decryptor. Visit the shop.\n");
            } else if (std.mem.eql(u8, arg, mission.decryption_key)) {
                const already_decrypted = session.isDecrypted();
                session.markDecrypted();
                session.completeObjective(.decrypt_file);
                try writer.writeAll("[DECRYPTED] File contents verified. You can now analyze metadata or extract the file.\n");
                if (!already_decrypted) _ = try applyDetection(writer, player, active, session, 10);
            } else {
                try writer.writeAll("[DECRYPTION FAILED] Incorrect key.\n");
                _ = try applyDetection(writer, player, active, session, 10);
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "analyze")) {
        if (active.*) |index| {
            const mission = missions[index];
            if (!session.isDecrypted() or !std.mem.eql(u8, arg, mission.encrypted_file)) {
                try writer.writeAll("Decrypt the active mission file first: decrypt <key>\n");
            } else if (mission.topology != null and !atMissionNode(mission, session.*, mission.topology.?.analyze_node)) {
                try writer.print("Move to node '{s}' before metadata analysis.\n", .{mission.topology.?.analyze_node});
            } else {
                var available = false;
                for (mission.objectives) |objective| {
                    if (objective.kind == .analyze_metadata and objective.optional) {
                        available = true;
                        break;
                    }
                }
                if (!available) {
                    try writer.writeAll("No optional metadata analysis is available for this contract.\n");
                } else if (session.isObjectiveComplete(.analyze_metadata)) {
                    try writer.writeAll("Metadata has already been analyzed.\n");
                } else {
                    session.completeObjective(.analyze_metadata);
                    try writer.writeAll("[ANALYSIS COMPLETE] Hidden metadata reference recovered. Optional objective completed.\n");
                    _ = try applyDetection(writer, player, active, session, 5);
                }
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "extract")) {
        if (active.*) |index| {
            const mission = missions[index];
            if (!session.isDecrypted() or !std.mem.eql(u8, arg, mission.encrypted_file)) {
                try writer.writeAll("The requested file is unavailable or still encrypted.\n");
            } else if (mission.topology != null and !atMissionNode(mission, session.*, mission.topology.?.extract_node)) {
                try writer.print("Move to node '{s}' before extracting this file.\n", .{mission.topology.?.extract_node});
            } else {
                const already_extracted = session.isObjectiveComplete(.extract_file);
                session.completeObjective(.extract_file);
                if (!already_extracted and try applyDetection(writer, player, active, session, 5)) return true;
                if (!session.allObjectivesComplete(mission.objectives)) {
                    try writer.writeAll("Contract objectives are incomplete. Review 'objectives'.\n");
                } else {
                    missions[index].completed = true;
                    try writer.print("[EXTRACTED] {s}\n", .{mission.encrypted_file});
                    try completeMission(writer, player, mission, session.*);
                    active.* = null;
                    session.reset();
                }
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "inventory")) {
        try shop.printInventory(writer, player.*);
    } else if (std.mem.eql(u8, command, "shop")) {
        try shop.printShop(writer);
    } else if (std.mem.eql(u8, command, "buy")) {
        try shop.buyItem(writer, player, arg);
    } else if (std.mem.eql(u8, command, "equip")) {
        try shop.equipItem(writer, player, arg);
    } else if (std.mem.eql(u8, command, "upgrade")) {
        try shop.upgradeItem(writer, player, arg);
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


pub fn runCommand(
    writer: anytype,
    line: []const u8,
    player: *Player,
    missions: []Mission,
    active: *?usize,
    session: *MissionSession,
) !bool {
    var preparation = MissionPreparation{};
    return runCommandWithPreparation(writer, line, player, missions, active, session, &preparation);
}
