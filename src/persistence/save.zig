const std = @import("std");
const Mission = @import("../domain/mission.zig").Mission;
const Player = @import("../domain/player.zig").Player;

/// Writes the current player and mission completion state to the default save location.
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

const SaveFormat = enum { v3, v2, v1, legacy };

fn parseFlag(value: []const u8) ?bool {
    const parsed = std.fmt.parseInt(u8, value, 10) catch return null;
    return switch (parsed) {
        0 => false,
        1 => true,
        else => null,
    };
}

fn parseActiveCandidate(value: []const u8) ?usize {
    const parsed = std.fmt.parseInt(i64, value, 10) catch return null;
    if (parsed < -1 or parsed == -1) return null;
    return std.fmt.parseInt(usize, value, 10) catch null;
}

fn validateSave(data: []const u8, mission_count: usize) ?SaveFormat {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    const first_line = lines.next() orelse return null;
    const format: SaveFormat = if (std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V3"))
        .v3
    else if (std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V2"))
        .v2
    else if (std.mem.eql(u8, first_line, "HACKERS_TERMINAL_SAVE_V1"))
        .v1
    else blk: {
        _ = std.fmt.parseInt(u32, first_line, 10) catch return null;
        break :blk .legacy;
    };

    var field_index: usize = 0;
    while (lines.next()) |value| : (field_index += 1) {
        switch (format) {
            .v3 => switch (field_index) {
                0...2 => _ = std.fmt.parseInt(u32, value, 10) catch return null,
                3 => _ = parseFlag(value) orelse return null,
                4...7 => _ = std.fmt.parseInt(u8, value, 10) catch return null,
                8 => {
                    const active = std.fmt.parseInt(i64, value, 10) catch return null;
                    if (active < -1) return null;
                    if (active >= 0) _ = std.fmt.parseInt(usize, value, 10) catch return null;
                },
                else => _ = parseFlag(value) orelse return null,
            },
            .v2 => switch (field_index) {
                0...2 => _ = std.fmt.parseInt(u32, value, 10) catch return null,
                3 => _ = parseFlag(value) orelse return null,
                4 => {
                    const active = std.fmt.parseInt(i64, value, 10) catch return null;
                    if (active < -1) return null;
                    if (active >= 0) _ = std.fmt.parseInt(usize, value, 10) catch return null;
                },
                else => _ = parseFlag(value) orelse return null,
            },
            .v1 => switch (field_index) {
                0...1 => _ = std.fmt.parseInt(u32, value, 10) catch return null,
                2 => _ = parseFlag(value) orelse return null,
                3 => {
                    const active = std.fmt.parseInt(i64, value, 10) catch return null;
                    if (active < -1) return null;
                    if (active >= 0) _ = std.fmt.parseInt(usize, value, 10) catch return null;
                },
                else => _ = parseFlag(value) orelse return null,
            },
            .legacy => switch (field_index) {
                0 => _ = std.fmt.parseInt(u32, value, 10) catch return null,
                1 => _ = parseFlag(value) orelse return null,
                else => _ = parseFlag(value) orelse return null,
            },
        }
    }

    const fixed_fields: usize = switch (format) {
        .v3 => 9,
        .v2 => 5,
        .v1 => 4,
        .legacy => 2,
    };
    if (field_index < fixed_fields) return null;
    const completion_flags = field_index - fixed_fields;
    if (completion_flags != mission_count and
        !(mission_count > 0 and completion_flags + 1 == mission_count))
    {
        return null;
    }
    return format;
}

fn fixedFieldCount(format: SaveFormat) usize {
    return switch (format) {
        .v3 => 9,
        .v2 => 5,
        .v1 => 4,
        .legacy => 2,
    };
}

/// Loads V3, V2, V1, or legacy save data without partially mutating live state.
pub fn loadGameFromBytes(data: []const u8, player: *Player, missions: []Mission) ?usize {
    const format = validateSave(data, missions.len) orelse return null;
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    const first_line = lines.next() orelse return null;

    var loaded_player = player.*;
    loaded_player.equipment.owned_utilities = 0;
    loaded_player.equipment.equipped_utility = null;
    loaded_player.equipment.silent_boots_level = 0;
    loaded_player.equipment.signal_scrubber_level = 0;
    var active_candidate: ?usize = null;

    switch (format) {
        .v3 => {
            loaded_player.balance = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.reputation = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.xp = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.equipment.has_decryptor = parseFlag(lines.next() orelse return null) orelse return null;
            loaded_player.equipment.owned_utilities = @truncate(std.fmt.parseInt(u8, lines.next() orelse return null, 10) catch return null);
            loaded_player.equipment.equipped_utility = switch (std.fmt.parseInt(u8, lines.next() orelse return null, 10) catch return null) {
                1 => .silent_boots,
                2 => .signal_scrubber,
                else => null,
            };
            loaded_player.equipment.silent_boots_level = @intCast(@min(std.fmt.parseInt(u8, lines.next() orelse return null, 10) catch return null, 2));
            loaded_player.equipment.signal_scrubber_level = @intCast(@min(std.fmt.parseInt(u8, lines.next() orelse return null, 10) catch return null, 2));
            if (loaded_player.equipment.equipped_utility) |utility| {
                if (!loaded_player.equipment.owns(utility)) loaded_player.equipment.equipped_utility = null;
            }
            if (!loaded_player.equipment.owns(.silent_boots)) loaded_player.equipment.silent_boots_level = 0;
            if (!loaded_player.equipment.owns(.signal_scrubber)) loaded_player.equipment.signal_scrubber_level = 0;
            active_candidate = parseActiveCandidate(lines.next() orelse return null);
        },
        .v2 => {
            loaded_player.balance = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.reputation = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.xp = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.equipment.has_decryptor = parseFlag(lines.next() orelse return null) orelse return null;
            active_candidate = parseActiveCandidate(lines.next() orelse return null);
        },
        .v1 => {
            loaded_player.balance = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.reputation = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.equipment.has_decryptor = parseFlag(lines.next() orelse return null) orelse return null;
            active_candidate = parseActiveCandidate(lines.next() orelse return null);
            loaded_player.xp = 0;
        },
        .legacy => {
            loaded_player.balance = std.fmt.parseInt(u32, first_line, 10) catch return null;
            loaded_player.reputation = std.fmt.parseInt(u32, lines.next() orelse return null, 10) catch return null;
            loaded_player.equipment.has_decryptor = parseFlag(lines.next() orelse return null) orelse return null;
        },
    }

    // V1 has no XP field; reconstruct it from the completed catalog missions.
    if (format == .v1) {
        var migration_lines = std.mem.tokenizeScalar(u8, data, '\n');
        _ = migration_lines.next();
        for (0..fixedFieldCount(format)) |_| _ = migration_lines.next();
        for (missions) |mission| {
            const completed = if (migration_lines.next()) |value| parseFlag(value).? else false;
            if (completed) {
                loaded_player.xp = std.math.add(u32, loaded_player.xp, mission.xp_reward) catch return null;
            }
        }
    }

    // All remaining operations are infallible after validateSave succeeds.
    player.* = loaded_player;
    var completion_lines = std.mem.tokenizeScalar(u8, data, '\n');
    _ = completion_lines.next();
    for (0..fixedFieldCount(format)) |_| _ = completion_lines.next();
    for (missions) |*mission| {
        mission.completed = if (completion_lines.next()) |value| parseFlag(value).? else false;
    }

    if (active_candidate) |index| {
        if (index < missions.len and !missions[index].completed) return index;
    }
    return null;
}

/// Loads the default save file into the supplied player and mission state.
pub fn loadGame(allocator: std.mem.Allocator, player: *Player, missions: []Mission) ?usize {
    const file = std.fs.cwd().openFile("saves/player.sav", .{}) catch return null;
    defer file.close();
    const data = file.readToEndAlloc(allocator, 4096) catch return null;
    defer allocator.free(data);
    return loadGameFromBytes(data, player, missions);
}
