const std = @import("std");
const Mission = @import("../domain/mission.zig").Mission;
const Player = @import("../domain/player.zig").Player;

pub fn saveGame(player: Player, missions: []const Mission, active: ?usize) !void {
    try saveGameToDirectory(std.fs.cwd(), player, missions, active);
}

/// Writes through a temporary file and renames it into place.
/// The directory parameter also allows filesystem behavior to be tested in isolation.
pub fn saveGameToDirectory(dir: std.fs.Dir, player: Player, missions: []const Mission, active: ?usize) !void {
    const save_path = "saves/player.sav";
    const temporary_path = "saves/player.sav.tmp";

    try dir.makePath("saves");
    errdefer dir.deleteFile(temporary_path) catch {};

    {
        const file = try dir.createFile(temporary_path, .{ .truncate = true });
        defer file.close();
        var writer = file.writer();
        const equipped: u8 = if (player.equipment.equipped_utility) |utility| @intFromEnum(utility) + 1 else 0;
        try writer.print("HACKERS_TERMINAL_SAVE_V3\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n", .{
            player.balance,                                        player.reputation,                      player.xp,
            @as(u8, if (player.equipment.has_decryptor) 1 else 0), player.equipment.owned_utilities,       equipped,
            player.equipment.silent_boots_level,                   player.equipment.signal_scrubber_level,
        });
        if (active) |index| try writer.print("{d}\n", .{index}) else try writer.writeAll("-1\n");
        for (missions) |mission| try writer.print("{d}\n", .{@as(u8, if (mission.completed) 1 else 0)});
    }

    // Rename only after the complete new save has been written and closed.
    // A failed write therefore leaves the previous player.sav untouched.
    try dir.rename(temporary_path, save_path);
}

fn readActiveCandidate(lines: anytype) ?usize {
    const value = lines.next() orelse return null;
    return std.fmt.parseInt(usize, value, 10) catch null;
}

fn validateActiveCandidate(candidate: ?usize, missions: []const Mission) ?usize {
    if (candidate) |index| {
        if (index < missions.len and !missions[index].completed) return index;
    }
    return null;
}

fn readLevel(value: []const u8) u2 {
    const parsed = std.fmt.parseInt(u8, value, 10) catch 0;
    return @intCast(@min(parsed, 2));
}

pub fn loadGameFromBytes(data: []const u8, player: *Player, missions: []Mission) ?usize {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    const first_line = lines.next() orelse return null;
    const is_v3 = std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V3");
    const is_v2 = std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V2");
    const is_v1 = std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V1");
    // Only an actual numeric first line qualifies as the unversioned legacy format.
    // Reject unknown markers before mutating any caller-owned state.
    const legacy_balance: ?u32 = if (is_v3 or is_v2 or is_v1)
        null
    else
        std.fmt.parseInt(u32, first_line, 10) catch return null;

    player.equipment.owned_utilities = 0;
    player.equipment.equipped_utility = null;
    player.equipment.silent_boots_level = 0;
    player.equipment.signal_scrubber_level = 0;
    for (missions) |*mission| mission.completed = false;
    var active_candidate: ?usize = null;
    var migrate_v1_xp = false;

    if (is_v3) {
        if (lines.next()) |v| player.balance = std.fmt.parseInt(u32, v, 10) catch player.balance;
        if (lines.next()) |v| player.reputation = std.fmt.parseInt(u32, v, 10) catch player.reputation;
        if (lines.next()) |v| player.xp = std.fmt.parseInt(u32, v, 10) catch player.xp;
        if (lines.next()) |v| player.equipment.has_decryptor = std.mem.eql(u8, v, "1");
        if (lines.next()) |v| player.equipment.owned_utilities = @truncate(std.fmt.parseInt(u8, v, 10) catch 0);
        if (lines.next()) |v| {
            player.equipment.equipped_utility = switch (std.fmt.parseInt(u8, v, 10) catch 0) {
                1 => .silent_boots,
                2 => .signal_scrubber,
                else => null,
            };
        }
        if (lines.next()) |v| player.equipment.silent_boots_level = readLevel(v);
        if (lines.next()) |v| player.equipment.signal_scrubber_level = readLevel(v);
        if (player.equipment.equipped_utility) |utility| {
            if (!player.equipment.owns(utility)) player.equipment.equipped_utility = null;
        }
        if (!player.equipment.owns(.silent_boots)) player.equipment.silent_boots_level = 0;
        if (!player.equipment.owns(.signal_scrubber)) player.equipment.signal_scrubber_level = 0;
        active_candidate = readActiveCandidate(&lines);
    } else if (is_v2) {
        if (lines.next()) |v| player.balance = std.fmt.parseInt(u32, v, 10) catch player.balance;
        if (lines.next()) |v| player.reputation = std.fmt.parseInt(u32, v, 10) catch player.reputation;
        if (lines.next()) |v| player.xp = std.fmt.parseInt(u32, v, 10) catch player.xp;
        if (lines.next()) |v| player.equipment.has_decryptor = std.mem.eql(u8, v, "1");
        active_candidate = readActiveCandidate(&lines);
    } else if (is_v1) {
        migrate_v1_xp = true;
        if (lines.next()) |v| player.balance = std.fmt.parseInt(u32, v, 10) catch player.balance;
        if (lines.next()) |v| player.reputation = std.fmt.parseInt(u32, v, 10) catch player.reputation;
        if (lines.next()) |v| player.equipment.has_decryptor = std.mem.eql(u8, v, "1");
        active_candidate = readActiveCandidate(&lines);
    } else {
        player.balance = legacy_balance.?;
        if (lines.next()) |v| player.reputation = std.fmt.parseInt(u32, v, 10) catch player.reputation;
        if (lines.next()) |v| player.equipment.has_decryptor = std.mem.eql(u8, v, "1");
    }
    for (missions) |*mission| {
        if (lines.next()) |value| mission.completed = std.mem.eql(u8, value, "1");
    }
    const active = validateActiveCandidate(active_candidate, missions);
    if (migrate_v1_xp) {
        for (missions) |mission| {
            if (mission.completed) player.xp += mission.xp_reward;
        }
    }
    return active;
}

pub fn loadGame(allocator: std.mem.Allocator, player: *Player, missions: []Mission) ?usize {
    const file = std.fs.cwd().openFile("saves/player.sav", .{}) catch return null;
    defer file.close();
    const data = file.readToEndAlloc(allocator, 4096) catch return null;
    defer allocator.free(data);
    return loadGameFromBytes(data, player, missions);
}
