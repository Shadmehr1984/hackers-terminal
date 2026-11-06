const Mission = @import("../domain/mission.zig").Mission;
const MissionState = @import("../domain/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const Player = @import("../domain/player.zig").Player;
const UtilityEquipment = @import("../domain/player.zig").UtilityEquipment;
const ModifierId = @import("../domain/mission_modifier.zig").ModifierId;
const std = @import("std");
const progression = @import("../domain/progression.zig");
const contacts = @import("../domain/contacts.zig");
const contract_board = @import("../domain/contract_board.zig");
const operation_data = @import("../catalog/operation_data.zig");
const operation_model = @import("../domain/operation.zig");
const faction = @import("../domain/faction.zig");
const FactionId = @import("../domain/faction_id.zig").FactionId;
const faction_data = @import("../catalog/faction_data.zig");

/// Writes the game banner.
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

/// Writes the available command help.
pub fn printHelp(writer: anytype) !void {
    try writer.writeAll(
        \\COMMANDS
        \\  help                 Show this help
        \\  status               Show operator status
        \\  missions             List available contracts
        \\  operations           List multi-stage operations
        \\  operation <id>       Inspect an operation and its stages
        \\  operation-start <id> Start an operation
        \\  operation-status     Show current operation stage and earned facts
        \\  board                Open the Contract Board
        \\  factions             List all known organizations
        \\  faction <id>         Inspect a faction dossier and relationships
        \\  contacts             Show unlocked and locked contacts
        \\  contact <id>         Inspect a contact and its offers
        \\  offers               List actionable contact offers
        \\  deal <id>            Purchase or accept a contact offer
        \\  briefing             Show clues and objectives for the active contract
        \\  objectives           Show active contract objective progress
        \\  map                  Show the active fictional network map
        \\  move <node-id>       Move to an adjacent map node (equipment may reduce Detection)
        \\  Detection is shown by 'status'; risky actions increase exposure.
        \\  prepare <id>         Review a contract and prepare its loadout
        \\  loadout <utility|none> Select this run's utility
        \\  modifier [id|none] Select or inspect this run's mission modifier
        \\  accept <id>          Launch the prepared contract
        \\  cancel               Cancel mission preparation
        \\  scan <target>        Scan the active fictional target
        \\  connect <target>     Connect after scanning
        \\  disconnect           End the simulated connection
        \\  brute <password>     Solve the password challenge
        \\  decrypt <key>        Decrypt the mission file
        \\  inspect <filename>   Inspect fictional evidence for hidden objectives
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
        \\  missions -> prepare -> loadout -> accept -> briefing -> scan -> connect
        \\  -> brute -> decrypt -> analyze (optional) -> extract
        \\
    );
}

/// Writes the player, mission, progression, and Detection status.
pub fn printStatus(writer: anytype, player: Player, active: ?usize, missions: []const Mission, level: u32, next_level_xp: u32, session: MissionSession) !void {
    try writer.print(
        \\OPERATOR
        \\  Handle:      {s}
        \\  Balance:     ${d}
        \\  Reputation:  {d} ({s})
        \\  Level:       {d}
        \\  XP:          {d}/{d}
        \\  Decryptor:   {s}
        \\  Utility:     {s}
        \\
    , .{
        player.handle,
        player.balance,
        player.reputation,
        progression.reputationTier(player.reputation).label(),
        level,
        player.xp,
        next_level_xp,
        if (player.equipment.has_decryptor) "installed" else "not installed",
        if (active != null) (if (session.loadout.utility) |utility| utility.label() else "none") else if (player.equipment.equipped_utility) |utility| utility.label() else "none",
    });

    if (active) |index| {
        try writer.print("  Active job:  {s} ({s})\n  Detection:   {d}/100 ({s})\n", .{
            missions[index].name,
            missions[index].id,
            session.detection_level,
            session.detectionBand().label(),
        });
        if (session.current_node) |node| try writer.print("  Location:    {s}\n", .{node});
        try writer.print("  Traversals:  {d}\n", .{session.traversal_count});
        if (session.modifier) |modifier| try writer.print("  Modifier:    {s}\n", .{modifier.label()});
    } else {
        try writer.writeAll("  Active job:  none\n  Detection:   inactive\n");
    }
}

/// Writes the contract catalog and its availability requirements.
pub fn printMissions(writer: anytype, missions: []const Mission, level: u32, reputation: u32) !void {
    try writer.writeAll("AVAILABLE CONTRACTS\n");
    for (missions) |mission| {
        const level_locked = level < mission.required_level;
        const reputation_locked = reputation < mission.required_reputation;
        const state = if (mission.completed) "COMPLETED" else if (level_locked or reputation_locked) "LOCKED" else if (mission.requires_contact_offer) "CONTACT OFFER" else "AVAILABLE";
        try writer.print("  [{s}] {s} | target: {s} | difficulty: {s} | reward: ${d} + {d} XP | {s}", .{
            mission.id,
            mission.name,
            mission.target,
            mission.difficulty.label(),
            mission.reward,
            mission.xp_reward,
            state,
        });
        if (!mission.completed and level_locked) {
            try writer.print(" (requires level {d})", .{mission.required_level});
        }
        if (!mission.completed and reputation_locked) {
            try writer.print(" (requires Reputation {d})", .{mission.required_reputation});
        }
        try writer.writeAll("\n");
    }
    try writer.writeAll("\nUse: prepare <id>\n");
}

/// Writes every catalog contract with derived availability and reward range.
pub fn printContractBoard(writer: anytype, missions: []const Mission, level: u32, reputation: u32, another_contract_busy: bool) !void {
    try writer.writeAll("CONTRACT BOARD\n");
    for (missions) |mission| {
        const entry = contract_board.evaluate(mission, .{
            .level = level,
            .reputation = reputation,
            .another_contract_busy = another_contract_busy,
            .missions = missions,
        });
        try writer.print("  [{s}] {s} — {s} | {s} | ${d}-${d} + {d} XP | {s}\n", .{
            mission.id,
            mission.name,
            mission.category.label(),
            mission.difficulty.label(),
            entry.minimum_reward,
            entry.maximum_reward,
            mission.xp_reward,
            entry.availability.label(),
        });
        const client = faction_data.find(mission.client_faction).?;
        const standing = entry.player_standing;
        try writer.print("    Client: {s} | Your standing: {s} | Security: {d}/5\n", .{ client.name, standing.label(), client.security_rating });
        if (mission.target_owner_faction) |owner_id| {
            const owner = faction_data.find(owner_id).?;
            try writer.print("    Target owner: {s}\n", .{owner.name});
        }
        if (entry.availability == .locked) {
            if (entry.level_locked) try writer.print("    Requires level {d} (current: {d}).\n", .{ mission.required_level, level });
            if (entry.reputation_locked) try writer.print("    Requires Reputation {d} (current: {d}).\n", .{ mission.required_reputation, reputation });
        } else if (entry.availability == .exclusive) {
            try writer.writeAll("    Obtain this contract through its Contact offer.\n");
        } else if (entry.availability == .faction_blocked) {
            try writer.print("    {s} is hostile to you; complete contracts for this faction to restore access.\n", .{client.name});
        } else if (entry.availability == .unavailable) {
            try writer.writeAll("    Finish or fail the active contract, or cancel the current preparation, before selecting another.\n");
        }
    }
    try writer.writeAll("\nUse prepare <id> for standard contracts; use the relevant Contact offer for exclusive contracts.\n");
}

/// Writes the seven fictional organizations and the player's derived standing with each.
pub fn printFactions(writer: anytype, reputation: u32, missions: []const Mission) !void {
    try writer.writeAll("FACTION NETWORK\n");
    for (faction_data.all()) |entry| {
        const standing = faction.playerStanding(entry.id, reputation, missions);
        try writer.print("  [{s}] {s} — {s} | Security {d}/5\n", .{
            standing.label(), entry.name, entry.archetype, entry.security_rating,
        });
    }
    try writer.writeAll("\nUse faction <id> to inspect a dossier. Standing is derived from Reputation and completed contracts.\n");
}

/// Writes one faction dossier and its authored relationships with the other organizations.
pub fn printFaction(writer: anytype, id: FactionId, reputation: u32, missions: []const Mission) !void {
    const entry = faction_data.find(id) orelse return;
    const standing = faction.playerStanding(id, reputation, missions);
    try writer.print("{s} [{s}]\n{s}\n\nStanding: {s}\nArchetype: {s}\nSpecialty: {s}\nSecurity ({d}/5): {s}\nEconomic profile: {s}\n\nRELATIONSHIPS\n", .{
        entry.name, id.slug(), entry.description, standing.label(), entry.archetype,
        entry.specialty, entry.security_rating, entry.security_style, entry.economic_style,
    });
    for (faction_data.all()) |other| {
        if (other.id == id) continue;
        const relation = faction_data.relationship(id, other.id);
        try writer.print("  {s}: {s}\n", .{ other.name, relation.label() });
    }
}

/// Writes the Contacts unlocked by the player's Reputation.
pub fn printContacts(writer: anytype, player: Player) !void {
    try writer.print("CONTACT NETWORK\nReputation: {d} ({s})\n\n", .{
        player.reputation, progression.reputationTier(player.reputation).label(),
    });
    const all = [_]contacts.ContactId{ .broker, .fixer };
    for (all) |contact| {
        if (contacts.isUnlocked(contact, player.reputation)) {
            try writer.print("  [UNLOCKED] {s} — {s}\n", .{ contact.label(), contact.role() });
        } else {
            try writer.print("  [LOCKED] {s} — requires Reputation {d}\n", .{
                contact.label(), contact.requiredReputation(),
            });
        }
    }
    try writer.writeAll("\nUse contact <id> for details and offers for available deals.\n");
}

/// Writes the details and available services for one Contact.
pub fn printContact(
    writer: anytype,
    contact: contacts.ContactId,
    player: Player,
    missions: []const Mission,
    active: ?usize,
    session: MissionSession,
    preparation: MissionPreparation,
) !void {
    try writer.print("{s}\nRole: {s}\n", .{ contact.label(), contact.role() });
    if (!contacts.isUnlocked(contact, player.reputation)) {
        try writer.print("Status: LOCKED — requires Reputation {d}; current Reputation: {d}.\n", .{
            contact.requiredReputation(), player.reputation,
        });
        return;
    }
    try writer.writeAll("Status: AVAILABLE\n");
    switch (contact) {
        .broker => {
            try writer.writeAll("Contract intelligence costs $50 and reveals clues, never puzzle answers.\nAvailable intelligence:\n");
            var found = false;
            for (missions) |mission| {
                if (mission.completed or progression.playerLevel(player) < mission.required_level or player.reputation < mission.required_reputation) continue;
                found = true;
                try writer.print("  deal intel-{s} — {s}\n", .{ mission.id, mission.name });
            }
            if (!found) try writer.writeAll("  No eligible contract intelligence right now.\n");
        },
        .fixer => {
            if (contacts.fixerServicePrice(player.reputation)) |price| {
                if (active != null and session.detection_level > 0 and !session.fixer_service_used) {
                    try writer.print("  deal scrub-detection — reduce Detection by up to 10 for ${d}\n", .{price});
                } else {
                    try writer.writeAll("  Detection service requires an active contract with Detection above zero and no prior service use.\n");
                }
            }
            for (missions) |mission| {
                if (active == null and preparation.mission_index == null and
                    std.mem.eql(u8, mission.id, "job-04") and !mission.completed and
                    progression.playerLevel(player) >= mission.required_level and player.reputation >= mission.required_reputation)
                {
                    try writer.writeAll("  deal ghost-signal — prepare the exclusive contract\n");
                }
            }
        },
    }
    try writer.writeAll("Use 'offers' to see currently actionable deals.\n");
}

/// Writes the contracts currently available through Contact offers.
pub fn printOffers(
    writer: anytype,
    player: Player,
    missions: []const Mission,
    active: ?usize,
    session: MissionSession,
    preparation: MissionPreparation,
) !void {
    try writer.writeAll("AVAILABLE CONTACT OFFERS\n");
    var found = false;
    if (contacts.isUnlocked(.broker, player.reputation)) {
        for (missions) |mission| {
            if (mission.completed or progression.playerLevel(player) < mission.required_level or player.reputation < mission.required_reputation) continue;
            found = true;
            try writer.print("  intel-{s} — {s} clues ($50)\n", .{ mission.id, mission.name });
        }
    }
    if (contacts.isUnlocked(.fixer, player.reputation)) {
        if (active != null and session.detection_level > 0 and !session.fixer_service_used) {
            found = true;
            try writer.print("  scrub-detection — reduce Detection by up to 10 (${d})\n", .{contacts.fixerServicePrice(player.reputation).?});
        }
        for (missions) |mission| {
            if (active == null and preparation.mission_index == null and
                std.mem.eql(u8, mission.id, "job-04") and !mission.completed and
                progression.playerLevel(player) >= mission.required_level and player.reputation >= mission.required_reputation)
            {
                found = true;
                try writer.writeAll("  ghost-signal — exclusive contract (no fee)\n");
            }
        }
    }
    if (!found) try writer.writeAll("  No offers are currently available. Improve Reputation or progress a contract.\n");
    try writer.writeAll("Use deal <id> to purchase or accept an offer.\n");
}

/// Writes objective completion state for the active contract.
pub fn printObjectives(writer: anytype, mission: Mission, session: MissionSession) !void {
    try writer.print("OBJECTIVES: {s}\n", .{mission.name});
    for (mission.objectives) |objective| {
        const progress = session.objective_tracker.progressOf(objective.id) orelse continue;
        if (!progress.revealed) continue;
        const state = switch (progress.state) {
            .undiscovered => continue,
            .discovered => "[ ]",
            .completed => "[x]",
            .unavailable => "[!]",
        };
        const category = if (objective.optional) "[OPTIONAL] " else "";
        try writer.print("  {s} {s}{s}", .{ state, category, objective.description });
        if (objective.optional and objective.bonus_reward > 0) try writer.print(" (+${d})", .{objective.bonus_reward});
        try writer.writeAll("\n");
    }
    try writer.writeAll("\n");
}

/// Writes a pre-launch briefing without revealing undiscovered puzzle clues or answers.
pub fn printPreparation(writer: anytype, mission: Mission, player: Player, selected_utility: ?UtilityEquipment, selected_modifier: ?ModifierId) !void {
    try writer.print("MISSION PREPARATION: {s} ({s})\nTarget: {s}\nDifficulty: {s}\nReward: ${d} + {d} XP\n", .{
        mission.name, mission.id, mission.target, mission.difficulty.label(), mission.reward, mission.xp_reward,
    });
    try writer.print("Decryptor: {s}\n", .{if (player.equipment.has_decryptor) "owned" else "not owned — purchase before decryption"});
    try writer.writeAll("\nKNOWN OBJECTIVES\n");
    for (mission.objectives) |objective| {
        if (objective.hidden) continue;
        try writer.print("  {s}{s}\n", .{ if (objective.optional) "[OPTIONAL] " else "", objective.description });
    }
    if (mission.topology) |topology| {
        try writer.writeAll("\nKNOWN TOPOLOGY\nNodes: ");
        for (topology.nodes, 0..) |node, index| {
            if (index > 0) try writer.writeAll(", ");
            try writer.writeAll(node.id);
        }
        try writer.writeAll("\nLinks:\n");
        for (topology.links) |link| try writer.print("  {s} <-> {s}\n", .{ link.from, link.to });
    } else try writer.writeAll("\nTopology: none authored for this contract.\n");
    try writer.writeAll("\nPUZZLE INTELLIGENCE\n  Password clue: undiscovered\n  Decryption clue: undiscovered\n  Puzzle answers: hidden\n");
    if (selected_utility) |utility| {
        try writer.print("\nSelected loadout: {s} (level {d})\n", .{ utility.label(), player.equipment.level(utility) });
    } else try writer.writeAll("\nSelected loadout: none\n");
    try writer.writeAll("Risk indicators: scan +10, successful authentication +5, decryption +10, wrong key +10, optional analysis +5, extraction +5.\n");
    try writer.writeAll("Movement cost: ");
    if (selected_utility) |utility| {
        if (utility == .silent_boots) {
            const cost: u8 = switch (player.equipment.level(utility)) {
                0 => 4,
                1 => 3,
                else => 2,
            };
            try writer.print("{d} Detection per traversal (Silent Boots).\n", .{cost});
        } else try writer.writeAll("5 Detection per traversal.\n");
    } else try writer.writeAll("5 Detection per traversal.\n");
    try writer.writeAll("Incorrect password cost: ");
    if (selected_utility) |utility| {
        if (utility == .signal_scrubber) {
            const cost: u8 = switch (player.equipment.level(utility)) {
                0 => 12,
                1 => 9,
                else => 6,
            };
            try writer.print("{d} Detection (Signal Scrubber).\n", .{cost});
        } else try writer.writeAll("15 Detection.\n");
    } else try writer.writeAll("15 Detection.\n");
    try writer.writeAll("\n");
    try printModifierOptions(writer, mission, selected_modifier);
    try writer.writeAll("\nUse 'loadout <utility|none>' to change this run's utility; use 'modifier <id|none>' to choose one modifier. Then 'accept <id>' to launch or 'cancel' to leave preparation.\n");
}

/// Writes the modifiers allowed by a prepared contract and the current selection.
pub fn printModifierOptions(writer: anytype, mission: Mission, selected: ?ModifierId) !void {
    try writer.writeAll("MISSION MODIFIERS (choose at most one)\n");
    if (mission.allowed_modifiers.len == 0) {
        try writer.writeAll("  No modifiers are available for this contract.\n");
        return;
    }
    for (mission.allowed_modifiers) |modifier| {
        const bonus = modifier.completionBonus();
        try writer.print("  {s}{s} — {s}\n    Effect: {s}\n    Successful completion bonus: +${d}, +{d} XP\n", .{
            if (selected != null and selected.? == modifier) "[SELECTED] " else "",
            modifier.commandId(),
            modifier.label(),
            modifier.description(),
            bonus.cash,
            bonus.xp,
        });
    }
    try writer.print("  Current selection: {s}\n", .{if (selected) |modifier| modifier.commandId() else "none"});
}
/// Writes the authored operation catalog and derived availability.
pub fn printOperations(writer: anytype, player: Player, missions: []const Mission, preparation: MissionPreparation) !void {
    try writer.writeAll("OPERATIONS\n");
    for (operation_data.all()) |operation| {
        var available = true;
        for (operation.stages) |stage| {
            const mission = operation_model.findMission(missions, stage.mission_id) orelse {
                available = false;
                break;
            };
            if (progression.playerLevel(player) < mission.required_level or player.reputation < mission.required_reputation) {
                available = false;
            }
        }
        const status = if (preparation.operation_state.active and
            std.mem.eql(u8, preparation.operation_state.operation_id, operation.id))
            "IN PROGRESS"
        else if (available)
            "AVAILABLE"
        else
            "LOCKED";
        try writer.print("  [{s}] {s} — {d} stages | {s}\n", .{
            operation.id, operation.name, operation.stages.len, status,
        });
    }
    if (preparation.operation_state.last_completed_operation_id.len > 0) {
        try writer.print("Last completed this session: {s}\n", .{preparation.operation_state.last_completed_operation_id});
    }
    try writer.writeAll("Use operation <id> for details, then operation-start <id>.\n");
}

/// Writes an operation's ordered contracts and their progression requirements.
pub fn printOperationDetails(writer: anytype, operation: operation_model.Operation, player: Player, missions: []const Mission) !void {
    try writer.print("{s} ({s})\n{s}\nSTAGES\n", .{ operation.name, operation.id, operation.description });
    for (operation.stages, 0..) |stage, index| {
        const mission = operation_model.findMission(missions, stage.mission_id) orelse continue;
        const level = progression.playerLevel(player);
        const status = if (level < mission.required_level or player.reputation < mission.required_reputation) "LOCKED" else "AVAILABLE";
        try writer.print("  {d}. {s} — {s} | requires level {d}, Reputation {d} | {s}\n", .{
            index + 1, mission.id, mission.name, mission.required_level, mission.required_reputation, status,
        });
    }
}

/// Writes the current operation stage and its already-earned typed facts.
pub fn printOperationStatus(writer: anytype, preparation: MissionPreparation, missions: []const Mission) !void {
    if (!preparation.operation_state.active) {
        if (preparation.operation_state.last_completed_operation_id.len > 0) {
            try writer.print("Last completed this session: {s}\n", .{preparation.operation_state.last_completed_operation_id});
        } else {
            try writer.writeAll("No active operation.\n");
        }
        return;
    }
    const operation = operation_data.find(preparation.operation_state.operation_id) orelse return;
    const stage = operation.stages[preparation.operation_state.stage_index];
    const mission = operation_model.findMission(missions, stage.mission_id) orelse return;
    try writer.print("OPERATION: {s}\nStage: {d}/{d} — {s} ({s})\nEarned facts:", .{
        operation.name,
        @as(usize, preparation.operation_state.stage_index) + 1,
        operation.stages.len,
        stage.mission_id,
        mission.name,
    });
    var any = false;
    if (preparation.operation_state.hasFact(.maintenance_telemetry)) {
        try writer.writeAll(" maintenance_telemetry");
        any = true;
    }
    if (preparation.operation_state.hasFact(.routing_header)) {
        try writer.writeAll(" routing_header");
        any = true;
    }
    if (!any) try writer.writeAll(" none");
    try writer.writeAll("\n");
}

/// Writes the completion history for the supplied contracts.
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

/// Writes the fictional topology map and current player location.
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
