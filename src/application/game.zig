const std = @import("std");
const Mission = @import("../domain/mission.zig").Mission;
const MissionState = @import("../domain/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const MissionLoadout = MissionState.MissionLoadout;
const ModifierId = @import("../domain/mission_modifier.zig").ModifierId;
const UtilityEquipment = @import("../domain/player.zig").UtilityEquipment;
const Player = @import("../domain/player.zig").Player;
const save = @import("../persistence/save.zig");
const terminal = @import("../presentation/terminal.zig");
const shop = @import("shop.zig");
const commands = @import("commands.zig");
const progression = @import("../domain/progression.zig");
const detection = @import("detection.zig");
const contacts = @import("../domain/contacts.zig");
const DiscoveryAction = @import("../domain/mission_objectives.zig").DiscoveryAction;

/// Re-exports the configured in-game penalty for a Detection compromise.
pub const detection_failure_penalty: u32 = detection.failure_penalty;

fn isMissionUnlocked(mission: Mission, player: Player) bool {
    return progression.playerLevel(player) >= mission.required_level and player.reputation >= mission.required_reputation;
}

fn printMissionLock(writer: anytype, mission: Mission, player: Player) !void {
    const level = progression.playerLevel(player);
    if (level < mission.required_level) try writer.print("Contract locked. Reach level {d} first.\n", .{mission.required_level});
    if (player.reputation < mission.required_reputation) try writer.print("Contract locked. Reach Reputation {d} first.\n", .{mission.required_reputation});
}

fn parseUtility(name: []const u8) ?UtilityEquipment {
    if (std.mem.eql(u8, name, "silent-boots")) return .silent_boots;
    if (std.mem.eql(u8, name, "signal-scrubber")) return .signal_scrubber;
    return null;
}

/// Builds the run-specific loadout from the player's currently equipped utility.
pub fn currentLoadout(player: Player) MissionLoadout {
    const utility = player.equipment.equipped_utility orelse return .{};
    if (!player.equipment.owns(utility)) return .{};
    return .{ .utility = utility, .level = player.equipment.level(utility) };
}

fn reportObjectiveDiscoveries(writer: anytype, count: usize) !void {
    if (count > 0) try writer.print("[HIDDEN OBJECTIVE DISCOVERED] {d} optional objective(s) revealed. Use 'objectives' to inspect them.\n", .{count});
}

fn atMissionNode(mission: Mission, session: MissionSession, expected: []const u8) bool {
    if (mission.topology == null) return true;
    return std.mem.eql(u8, session.current_node orelse "", expected);
}

fn handleDeal(
    writer: anytype,
    arg: []const u8,
    player: *Player,
    missions: []Mission,
    active: *?usize,
    session: *MissionSession,
    preparation: *MissionPreparation,
) !void {
    if (std.mem.startsWith(u8, arg, "intel-")) {
        if (!contacts.isUnlocked(.broker, player.reputation)) {
            try writer.writeAll("Information Broker is locked. Reach Reputation 1 first.\n");
            return;
        }
        const mission_id = arg[6..];
        for (missions) |mission| {
            if (!std.mem.eql(u8, mission.id, mission_id)) continue;
            if (mission.completed) {
                try writer.writeAll("That contract is already completed; no new intelligence is available.\n");
            } else if (!isMissionUnlocked(mission, player.*)) {
                try printMissionLock(writer, mission, player.*);
            } else if (player.balance < contacts.intel_price) {
                try writer.print("Insufficient funds. Intelligence costs ${d}.\n", .{contacts.intel_price});
            } else {
                player.balance -= contacts.intel_price;
                try writer.print("[INTELLIGENCE PURCHASED] {s}\nPassword clue: {s}\nDecryption clue: {s}\nRemaining balance: ${d}\n", .{
                    mission.name, mission.password_hint, mission.decryption_hint, player.balance,
                });
            }
            return;
        }
        try writer.writeAll("Unknown intelligence offer. Use offers to see available IDs.\n");
    } else if (std.mem.eql(u8, arg, "scrub-detection")) {
        if (!contacts.isUnlocked(.fixer, player.reputation)) {
            try writer.writeAll("Fixer is locked. Reach Reputation 3 first.\n");
            return;
        }
        const cost = contacts.fixerServicePrice(player.reputation).?;
        if (active.* == null) {
            try writer.writeAll("Detection service requires an active contract.\n");
        } else if (session.fixer_service_used) {
            try writer.writeAll("The Fixer service has already been used in this contract.\n");
        } else if (session.detection_level == 0) {
            try writer.writeAll("Detection is already at zero; no service is needed.\n");
        } else if (player.balance < cost) {
            try writer.print("Insufficient funds. The service costs ${d}.\n", .{cost});
        } else {
            const reduction = @min(contacts.detection_reduction, session.detection_level);
            player.balance -= cost;
            session.detection_level -= reduction;
            session.fixer_service_used = true;
            try writer.print("[FIXER SERVICE] Detection reduced by {d}. Cost: ${d}. Remaining balance: ${d}.\n", .{
                reduction, cost, player.balance,
            });
        }
    } else if (std.mem.eql(u8, arg, "ghost-signal")) {
        if (!contacts.isUnlocked(.fixer, player.reputation)) {
            try writer.writeAll("Fixer is locked. Reach Reputation 3 first.\n");
            return;
        }
        if (active.* != null) {
            try writer.writeAll("Finish or fail the active contract before accepting another offer.\n");
            return;
        }
        if (preparation.mission_index != null) {
            try writer.writeAll("Cancel the current preparation before choosing this offer.\n");
            return;
        }
        for (missions, 0..) |mission, index| {
            if (!std.mem.eql(u8, mission.id, "job-04")) continue;
            if (mission.completed) {
                try writer.writeAll("Ghost Signal has already been completed.\n");
            } else if (!isMissionUnlocked(mission, player.*)) {
                try printMissionLock(writer, mission, player.*);
            } else {
                preparation.mission_index = index;
                preparation.selected_modifier = null;
                preparation.selected_utility = if (player.equipment.equipped_utility) |utility|
                    (if (player.equipment.owns(utility)) utility else null)
                else
                    null;
                try writer.writeAll("[FIXER CONTRACT OFFER ACCEPTED]\n");
                try terminal.printPreparation(writer, mission, player.*, preparation.selected_utility, preparation.selected_modifier);
            }
            return;
        }
        try writer.writeAll("Ghost Signal contract is not present in this catalog.\n");
    } else {
        try writer.writeAll("Unknown offer. Use offers to see available IDs.\n");
    }
}

/// Applies the base movement cost before any modifier-specific traversal exposure.
fn applyTraversalDetection(
    writer: anytype,
    player: *Player,
    active: *?usize,
    session: *MissionSession,
) !bool {
    if (try detection.apply(writer, player, active, session, session.loadout.movementDetectionCost())) return true;
    if (session.modifier) |modifier| {
        switch (modifier) {
            .heightened_monitoring => return detection.apply(writer, player, active, session, 2),
            .security_sweep => {
                if (session.traversal_count > 0 and session.traversal_count % 3 == 0) {
                    return detection.apply(writer, player, active, session, 8);
                }
            },
            .hardened_encryption => {},
        }
    }
    return false;
}

/// Parses and dispatches one game command, applying validation and state transitions.
pub fn runCommand(
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
        const level = progression.playerLevel(player.*);
        try terminal.printStatus(writer, player.*, active.*, missions, level, progression.xpForNextLevel(level), session.*);
    } else if (std.mem.eql(u8, command, "board")) {
        const level = progression.playerLevel(player.*);
        try terminal.printContractBoard(writer, missions, level, player.reputation, active.* != null or preparation.mission_index != null);
    } else if (std.mem.eql(u8, command, "missions")) {
        try terminal.printMissions(writer, missions, progression.playerLevel(player.*), player.reputation);
    } else if (std.mem.eql(u8, command, "contacts")) {
        try terminal.printContacts(writer, player.*);
    } else if (std.mem.eql(u8, command, "contact")) {
        if (contacts.ContactId.parse(arg)) |contact_id| {
            try terminal.printContact(writer, contact_id, player.*, missions, active.*, session.*, preparation.*);
        } else try writer.writeAll("Unknown contact. Use contact broker or contact fixer.\n");
    } else if (std.mem.eql(u8, command, "offers")) {
        try terminal.printOffers(writer, player.*, missions, active.*, session.*, preparation.*);
    } else if (std.mem.eql(u8, command, "deal")) {
        try handleDeal(writer, arg, player, missions, active, session, preparation);
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
                } else if (!isMissionUnlocked(mission, player.*)) {
                    try printMissionLock(writer, mission, player.*);
                } else if (mission.requires_contact_offer) {
                    try writer.writeAll("This contract is an exclusive contact offer. Use contact fixer, then deal ghost-signal.\n");
                } else {
                    preparation.mission_index = index;
                    preparation.selected_utility = if (player.equipment.equipped_utility) |utility|
                        (if (player.equipment.owns(utility)) utility else null)
                    else
                        null;
                    try terminal.printPreparation(writer, mission, player.*, preparation.selected_utility, preparation.selected_modifier);
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
    } else if (std.mem.eql(u8, command, "modifier")) {
        if (preparation.mission_index) |index| {
            const mission = missions[index];
            if (arg.len == 0) {
                try terminal.printModifierOptions(writer, mission, preparation.selected_modifier);
            } else if (std.mem.eql(u8, arg, "none")) {
                preparation.selected_modifier = null;
                try writer.writeAll("Preparation modifier cleared.\n");
            } else if (ModifierId.fromCommandId(arg)) |modifier| {
                if (preparation.selectModifier(mission, modifier)) {
                    try writer.print("Modifier selected: {s}. Its effects and completion bonus are shown below.\n", .{modifier.label()});
                    try terminal.printModifierOptions(writer, mission, preparation.selected_modifier);
                } else {
                    try writer.print("Modifier '{s}' is not available for this contract. No selection was changed.\n", .{arg});
                }
            } else {
                try writer.writeAll("Unknown modifier. Use modifier to list choices, modifier <id> to select, or modifier none to clear.\n");
            }
        } else {
            try writer.writeAll("No contract is being prepared. Use prepare <id> first.\n");
        }
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
                        try reportObjectiveDiscoveries(writer, session.discoverNode(node.id, missions[index].objectives));
                        _ = try applyTraversalDetection(writer, player, active, session);
                    }
                } else try writer.writeAll("Current location is unavailable. Restart the contract.\n");
            } else try writer.writeAll("This contract has no network map.\n");
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "inspect")) {
        if (active.*) |index| {
            const revealed = session.discoverFile(arg, missions[index].objectives);
            if (revealed == 0) {
                try writer.writeAll("No undiscovered evidence matching that fictional file is available here.\n");
            } else {
                try writer.print("[EVIDENCE INSPECTED] {s}\n", .{arg});
                try reportObjectiveDiscoveries(writer, revealed);
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "briefing")) {
        if (active.*) |index| {
            const mission = missions[index];
            try writer.print("CONTRACT BRIEFING: {s}\nTarget: {s}\nDifficulty: {s}\nPassword clue: {s}\nEncrypted file: {s}\nDecryption clue: {s}\n", .{
                mission.name, mission.target, mission.difficulty.label(), mission.password_hint, mission.encrypted_file, mission.decryption_hint,
            });
            if (mission.topology != null) try writer.writeAll("Network: use 'map' to inspect nodes and objective locations.\n");
            if (session.modifier) |modifier| try writer.print("Mission modifier: {s}\nEffect: {s}\n", .{ modifier.label(), modifier.description() });
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
            } else if (mission.completed or !isMissionUnlocked(mission, player.*)) {
                preparation.clear();
                try writer.writeAll("The prepared contract is no longer available. Preparation cleared.\n");
            } else if (preparation.selected_utility) |utility| {
                if (!player.equipment.owns(utility)) {
                    try writer.writeAll("Selected utility is no longer owned. Choose another loadout.\n");
                } else {
                    session.startWithModifier(.{ .utility = utility, .level = player.equipment.level(utility) }, preparation.selected_modifier);
                    if (!session.initializeObjectives(mission.objectives)) {
                        session.reset();
                        try writer.writeAll("Contract catalog contains invalid objective definitions; launch rejected.\n");
                        return true;
                    }
                    active.* = index;
                    preparation.clear();
                    if (mission.topology) |topology| session.current_node = topology.entry_node;
                    try writer.print("Contract launched: {s}\nTarget: {s}\n", .{ mission.name, mission.target });
                    if (session.current_node) |node| try writer.print("Starting node: {s}\n", .{node});
                }
            } else {
                session.startWithModifier(.{}, preparation.selected_modifier);
                if (!session.initializeObjectives(mission.objectives)) {
                    session.reset();
                    try writer.writeAll("Contract catalog contains invalid objective definitions; launch rejected.\n");
                    return true;
                }
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
                    try reportObjectiveDiscoveries(writer, session.discoverAction(.scan_target, mission.objectives));
                    session.completeObjective(.scan_target);
                    try writer.print("[SCAN COMPLETE] Fictional host {s} is reachable. One simulated service requires authentication.\n", .{arg});
                    try writer.writeAll("A password challenge was identified.\n");
                    if (!already_scanned) _ = try detection.apply(writer, player, active, session, 10);
                }
            } else {
                const already_scanned = session.isObjectiveComplete(.scan_target);
                session.markScanned();
                try reportObjectiveDiscoveries(writer, session.discoverAction(.scan_target, mission.objectives));
                session.completeObjective(.scan_target);
                try writer.print("[SCAN COMPLETE] Fictional host {s} is reachable. One simulated service requires authentication.\n", .{arg});
                try writer.writeAll("A password challenge was identified.\n");
                if (!already_scanned) _ = try detection.apply(writer, player, active, session, 10);
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
            if (session.isAuthenticated()) {
                try writer.writeAll("Authentication already completed.\n");
            } else if (mission.topology != null and !atMissionNode(mission, session.*, mission.topology.?.auth_node)) {
                try writer.print("Move to node '{s}' before authentication.\n", .{mission.topology.?.auth_node});
            } else if (!session.connected) {
                try writer.writeAll("No session. Connect to the target first.\n");
            } else if (std.mem.eql(u8, arg, mission.password)) {
                const already_authenticated = session.isAuthenticated();
                session.markAuthenticated();
                try reportObjectiveDiscoveries(writer, session.discoverAction(.authenticate, mission.objectives));
                session.completeObjective(.authenticate);
                try writer.writeAll("[ACCESS GRANTED] Authentication challenge solved.\n");
                if (!already_authenticated) _ = try detection.apply(writer, player, active, session, 5);
            } else {
                try writer.writeAll("[ACCESS DENIED] Incorrect password. Check the mission briefing.\n");
                _ = try detection.apply(writer, player, active, session, session.loadout.incorrectAuthenticationDetectionCost());
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "decrypt")) {
        if (active.*) |index| {
            const mission = missions[index];
            if (session.isDecrypted()) {
                try writer.writeAll("File already decrypted.\n");
            } else if (!session.isAuthenticated()) {
                try writer.writeAll("Authentication is required before decryption.\n");
            } else if (mission.topology != null and !atMissionNode(mission, session.*, mission.topology.?.decrypt_node)) {
                try writer.print("Move to node '{s}' before decryption.\n", .{mission.topology.?.decrypt_node});
            } else if (!player.equipment.has_decryptor) {
                try writer.writeAll("Missing tool: decryptor. Visit the shop.\n");
            } else if (std.mem.eql(u8, arg, mission.decryption_key)) {
                const already_decrypted = session.isDecrypted();
                session.markDecrypted();
                try reportObjectiveDiscoveries(writer, session.discoverAction(.decrypt_file, mission.objectives));
                session.completeObjective(.decrypt_file);
                try writer.writeAll("[DECRYPTED] File contents verified. You can now analyze metadata or extract the file.\n");
                if (!already_decrypted) _ = try detection.apply(writer, player, active, session, 10);
            } else {
                try writer.writeAll("[DECRYPTION FAILED] Incorrect key.\n");
                const failure_cost: u8 = if (session.modifier) |modifier| (if (modifier == .hardened_encryption) 15 else 10) else 10;
                _ = try detection.apply(writer, player, active, session, failure_cost);
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
                    _ = try detection.apply(writer, player, active, session, 5);
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
                try reportObjectiveDiscoveries(writer, session.discoverAction(.extract_file, mission.objectives));
                session.completeObjective(.extract_file);
                if (!already_extracted and try detection.apply(writer, player, active, session, 5)) return true;
                session.markUndiscoveredObjectivesUnavailable();
                if (!session.allObjectivesComplete(mission.objectives)) {
                    try writer.writeAll("Contract objectives are incomplete. Review 'objectives'.\n");
                } else {
                    missions[index].completed = true;
                    try writer.print("[EXTRACTED] {s}\n", .{mission.encrypted_file});
                    try progression.completeMission(writer, player, mission, session);
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
