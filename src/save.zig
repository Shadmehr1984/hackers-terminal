const std = @import("std");
const Mission = @import("mission.zig").Mission;
const Player = @import("player.zig").Player;

pub fn saveGame(player: Player, missions: []const Mission, active: ?usize) !void {
    try std.fs.cwd().makePath("saves");
    const file = try std.fs.cwd().createFile("saves/player.sav", .{ .truncate = true });
    defer file.close();
    var writer = file.writer();
    const equipped: u8 = if (player.equipment.equipped_utility) |utility| @intFromEnum(utility) + 1 else 0;
    try writer.print("HACKERS_TERMINAL_SAVE_V3\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n", .{
        player.balance, player.reputation, player.xp,
        @as(u8, if (player.equipment.has_decryptor) 1 else 0),
        player.equipment.owned_utilities, equipped,
        player.equipment.silent_boots_level, player.equipment.signal_scrubber_level,
    });
    if (active) |index| try writer.print("{d}\n", .{index}) else try writer.writeAll("-1\n");
    for (missions) |mission| try writer.print("{d}\n", .{@as(u8, if (mission.completed) 1 else 0)});
}

fn readActive(lines: anytype, missions: []Mission) ?usize {
    const value = lines.next() orelse return null;
    const parsed = std.fmt.parseInt(i64, value, 10) catch -1;
    if (parsed < 0) return null;
    const index: usize = @intCast(parsed);
    if (index < missions.len and !missions[index].completed) return index;
    return null;
}

fn readLevel(value: []const u8) u2 {
    const parsed = std.fmt.parseInt(u8, value, 10) catch 0;
    return @intCast(@min(parsed, 2));
}

pub fn loadGameFromBytes(data: []const u8, player: *Player, missions: []Mission) ?usize {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    const first_line = lines.next() orelse return null;
    var active: ?usize = null;
    var migrate_v1_xp = false;

    if (std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V3")) {
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
        active = readActive(&lines, missions);
    } else if (std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V2")) {
        if (lines.next()) |v| player.balance = std.fmt.parseInt(u32, v, 10) catch player.balance;
        if (lines.next()) |v| player.reputation = std.fmt.parseInt(u32, v, 10) catch player.reputation;
        if (lines.next()) |v| player.xp = std.fmt.parseInt(u32, v, 10) catch player.xp;
        if (lines.next()) |v| player.equipment.has_decryptor = std.mem.eql(u8, v, "1");
        active = readActive(&lines, missions);
    } else if (std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V1")) {
        migrate_v1_xp = true;
        if (lines.next()) |v| player.balance = std.fmt.parseInt(u32, v, 10) catch player.balance;
        if (lines.next()) |v| player.reputation = std.fmt.parseInt(u32, v, 10) catch player.reputation;
        if (lines.next()) |v| player.equipment.has_decryptor = std.mem.eql(u8, v, "1");
        active = readActive(&lines, missions);
    } else {
        player.balance = std.fmt.parseInt(u32, first_line, 10) catch player.balance;
        if (lines.next()) |v| player.reputation = std.fmt.parseInt(u32, v, 10) catch player.reputation;
        if (lines.next()) |v| player.equipment.has_decryptor = std.mem.eql(u8, v, "1");
    }
    for (missions) |*mission| {
        if (lines.next()) |value| mission.completed = std.mem.eql(u8, value, "1");
    }
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
