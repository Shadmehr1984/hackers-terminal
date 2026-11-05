const std = @import("std");
const Mission = @import("mission.zig").Mission;
const Player = @import("player.zig").Player;

pub fn saveGame(player: Player, missions: []const Mission, active: ?usize) !void {
    try std.fs.cwd().makePath("saves");
    const file = try std.fs.cwd().createFile("saves/player.sav", .{ .truncate = true });
    defer file.close();

    var writer = file.writer();
    try writer.print("HACKERS_TERMINAL_SAVE_V2\n{d}\n{d}\n{d}\n{d}\n", .{
        player.balance,
        player.reputation,
        player.xp,
        @as(u8, if (player.has_decryptor) 1 else 0),
    });
    if (active) |index| {
        try writer.print("{d}\n", .{index});
    } else {
        try writer.writeAll("-1\n");
    }
    for (missions) |mission| {
        try writer.print("{d}\n", .{@as(u8, if (mission.completed) 1 else 0)});
    }
}

pub fn loadGame(allocator: std.mem.Allocator, player: *Player, missions: []Mission) ?usize {
    const file = std.fs.cwd().openFile("saves/player.sav", .{}) catch return null;
    defer file.close();

    const data = file.readToEndAlloc(allocator, 4096) catch return null;
    defer allocator.free(data);

    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    const first_line = lines.next() orelse return null;
    var active: ?usize = null;
    var migrate_v1_xp = false;

    if (std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V2")) {
        if (lines.next()) |value| player.balance = std.fmt.parseInt(u32, value, 10) catch player.balance;
        if (lines.next()) |value| player.reputation = std.fmt.parseInt(u32, value, 10) catch player.reputation;
        if (lines.next()) |value| player.xp = std.fmt.parseInt(u32, value, 10) catch player.xp;
        if (lines.next()) |value| player.has_decryptor = std.mem.eql(u8, value, "1");
        if (lines.next()) |value| {
            const parsed = std.fmt.parseInt(i64, value, 10) catch -1;
            if (parsed >= 0) {
                const index: usize = @intCast(parsed);
                if (index < missions.len and !missions[index].completed) active = index;
            }
        }
    } else if (std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V1")) {
        // Reconstruct XP from completed contracts because V1 did not store it.
        migrate_v1_xp = true;
        if (lines.next()) |value| player.balance = std.fmt.parseInt(u32, value, 10) catch player.balance;
        if (lines.next()) |value| player.reputation = std.fmt.parseInt(u32, value, 10) catch player.reputation;
        if (lines.next()) |value| player.has_decryptor = std.mem.eql(u8, value, "1");
        if (lines.next()) |value| {
            const parsed = std.fmt.parseInt(i64, value, 10) catch -1;
            if (parsed >= 0) {
                const index: usize = @intCast(parsed);
                if (index < missions.len and !missions[index].completed) active = index;
            }
        }
    } else {
        // Read saves created by the first public version.
        player.balance = std.fmt.parseInt(u32, first_line, 10) catch player.balance;
        if (lines.next()) |value| player.reputation = std.fmt.parseInt(u32, value, 10) catch player.reputation;
        if (lines.next()) |value| player.has_decryptor = std.mem.eql(u8, value, "1");
    }

    for (missions) |*mission| {
        if (lines.next()) |value| {
            mission.completed = std.mem.eql(u8, value, "1");
        }
    }
    if (migrate_v1_xp) {
        for (missions) |mission| {
            if (mission.completed) player.xp += mission.xp_reward;
        }
    }
    return active;
}

