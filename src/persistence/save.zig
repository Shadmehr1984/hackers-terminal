const builtin = @import("builtin");
const std = @import("std");
pub const Mission = @import("../domain/mission.zig").Mission;
pub const Player = @import("../domain/player.zig").Player;

/// Filesystem capability passed from the process boundary into persistence.
pub const SaveContext = if (builtin.zig_version.minor >= 16)
    struct {
        io: std.Io,
        dir: std.Io.Dir,
    }
else
    struct {
        dir: std.fs.Dir,
    };

fn makeDirectoryPath(context: SaveContext, path: []const u8) !void {
    if (builtin.zig_version.minor >= 16) {
        try context.dir.createDirPath(context.io, path);
    } else {
        try context.dir.makePath(path);
    }
}

fn deleteFile(context: SaveContext, path: []const u8) !void {
    if (builtin.zig_version.minor >= 16) {
        try context.dir.deleteFile(context.io, path);
    } else {
        try context.dir.deleteFile(path);
    }
}

fn renameFile(context: SaveContext, old_path: []const u8, new_path: []const u8) !void {
    if (builtin.zig_version.minor >= 16) {
        try context.dir.rename(old_path, context.dir, new_path, context.io);
    } else {
        try context.dir.rename(old_path, new_path);
    }
}

fn readSaveFile(context: SaveContext, allocator: std.mem.Allocator) ![]u8 {
    if (builtin.zig_version.minor >= 16) {
        return context.dir.readFileAlloc(context.io, "saves/player.sav", allocator, .limited(4097));
    } else {
        const file = try context.dir.openFile("saves/player.sav", .{});
        defer file.close();
        return file.readToEndAlloc(allocator, 4096);
    }
}

/// Writes the current player and mission completion state to the supplied save context.
pub fn saveGame(context: SaveContext, player: Player, missions: []const Mission, active: ?usize) !void {
    try saveGameToDirectory(context, player, missions, active);
}

/// Writes through a temporary file and renames it into place.
/// The context also allows filesystem behavior to be tested in isolation.
pub fn saveGameToDirectory(context: SaveContext, player: Player, missions: []const Mission, active: ?usize) !void {
    const save_path = "saves/player.sav";
    const temporary_path = "saves/player.sav.tmp";

    try makeDirectoryPath(context, "saves");
    errdefer deleteFile(context, temporary_path) catch {};

    if (builtin.zig_version.minor >= 16) {
        {
            const file = try context.dir.createFile(context.io, temporary_path, .{ .truncate = true });
            defer file.close(context.io);
            var buffer: [1024]u8 = undefined;
            var writer = file.writer(context.io, &buffer);
            try writeSavePayload(&writer.interface, player, missions, active);
            try writer.interface.flush();
        }
    } else {
        {
            const file = try context.dir.createFile(temporary_path, .{ .truncate = true });
            defer file.close();
            var writer = file.writer();
            try writeSavePayload(&writer, player, missions, active);
        }
    }

    // Rename only after the complete new save has been flushed and closed.
    // A failed write therefore leaves the previous player.sav untouched.
    try renameFile(context, temporary_path, save_path);
}

/// Emits the stable V3 payload through either the legacy or std.Io writer adapter.
fn writeSavePayload(writer: anytype, player: Player, missions: []const Mission, active: ?usize) !void {
    const equipped: u8 = if (player.equipment.equipped_utility) |utility| @intFromEnum(utility) + 1 else 0;
    try writer.print("HACKERS_TERMINAL_SAVE_V3\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n{d}\n", .{
        player.balance,                                        player.reputation,                      player.xp,
        @as(u8, if (player.equipment.has_decryptor) 1 else 0), player.equipment.owned_utilities,       equipped,
        player.equipment.silent_boots_level,                   player.equipment.signal_scrubber_level,
    });
    if (active) |index| try writer.print("{d}\n", .{index}) else try writer.writeAll("-1\n");
    for (missions) |mission| try writer.print("{d}\n", .{@as(u8, if (mission.completed) 1 else 0)});
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
    if (parsed < 0) return null;
    return std.fmt.parseInt(usize, value, 10) catch null;
}

fn isValidActiveCandidate(value: []const u8, mission_count: usize) bool {
    const parsed = std.fmt.parseInt(i64, value, 10) catch return false;
    if (parsed < -1) return false;
    if (parsed == -1) return true;
    const index = std.fmt.parseInt(usize, value, 10) catch return false;
    return index < mission_count;
}

fn validateSave(data: []const u8, mission_count: usize) ?SaveFormat {
    const payload = if (std.mem.endsWith(u8, data, "\n")) data[0 .. data.len - 1] else data;
    var lines = std.mem.splitScalar(u8, payload, '\n');
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
                4 => {
                    const owned = std.fmt.parseInt(u8, value, 10) catch return null;
                    if (owned > 3) return null;
                },
                5 => {
                    const equipped = std.fmt.parseInt(u8, value, 10) catch return null;
                    if (equipped > 2) return null;
                },
                6...7 => {
                    const level = std.fmt.parseInt(u8, value, 10) catch return null;
                    if (level > 2) return null;
                },
                8 => {
                    if (!isValidActiveCandidate(value, mission_count)) return null;
                },
                else => _ = parseFlag(value) orelse return null,
            },
            .v2 => switch (field_index) {
                0...2 => _ = std.fmt.parseInt(u32, value, 10) catch return null,
                3 => _ = parseFlag(value) orelse return null,
                4 => {
                    if (!isValidActiveCandidate(value, mission_count)) return null;
                },
                else => _ = parseFlag(value) orelse return null,
            },
            .v1 => switch (field_index) {
                0...1 => _ = std.fmt.parseInt(u32, value, 10) catch return null,
                2 => _ = parseFlag(value) orelse return null,
                3 => {
                    if (!isValidActiveCandidate(value, mission_count)) return null;
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
    if (completion_flags > mission_count) return null;
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
    const payload = if (std.mem.endsWith(u8, data, "\n")) data[0 .. data.len - 1] else data;
    var lines = std.mem.splitScalar(u8, payload, '\n');
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
            loaded_player.equipment.owned_utilities = @intCast(std.fmt.parseInt(u8, lines.next() orelse return null, 10) catch return null);
            loaded_player.equipment.equipped_utility = switch (std.fmt.parseInt(u8, lines.next() orelse return null, 10) catch return null) {
                1 => .silent_boots,
                2 => .signal_scrubber,
                else => null,
            };
            loaded_player.equipment.silent_boots_level = @intCast(std.fmt.parseInt(u8, lines.next() orelse return null, 10) catch return null);
            loaded_player.equipment.signal_scrubber_level = @intCast(std.fmt.parseInt(u8, lines.next() orelse return null, 10) catch return null);
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
        const migration_payload = if (std.mem.endsWith(u8, data, "\n")) data[0 .. data.len - 1] else data;
        var migration_lines = std.mem.splitScalar(u8, migration_payload, '\n');
        _ = migration_lines.next();
        for (0..fixedFieldCount(format)) |_| _ = migration_lines.next();
        for (missions) |mission| {
            const completed = if (migration_lines.next()) |value| (parseFlag(value) orelse false) else false;
            if (completed) {
                loaded_player.xp = std.math.add(u32, loaded_player.xp, mission.xp_reward) catch return null;
            }
        }
    }

    // All remaining operations are infallible after validateSave succeeds.
    player.* = loaded_player;
    const completion_payload = if (std.mem.endsWith(u8, data, "\n")) data[0 .. data.len - 1] else data;
    var completion_lines = std.mem.splitScalar(u8, completion_payload, '\n');
    _ = completion_lines.next();
    for (0..fixedFieldCount(format)) |_| _ = completion_lines.next();
    for (missions) |*mission| {
        mission.completed = if (completion_lines.next()) |value| (parseFlag(value) orelse false) else false;
    }

    if (active_candidate) |index| {
        if (index < missions.len and !missions[index].completed) return index;
    }
    return null;
}

/// Describes the outcome of attempting to load the default save file.
pub const LoadStatus = enum {
    loaded,
    missing,
    invalid,
    io_error,
};

/// Returns the active mission and an explicit status so callers can distinguish
/// a first run from an unreadable or malformed existing save.
pub const LoadResult = struct {
    active: ?usize,
    status: LoadStatus,
};

/// Loads the save file and reports why no state was restored when applicable.
pub fn loadGameWithStatus(context: SaveContext, allocator: std.mem.Allocator, player: *Player, missions: []Mission) LoadResult {
    const data = readSaveFile(context, allocator) catch |err| {
        return .{
            .active = null,
            .status = if (err == error.FileNotFound) .missing else .io_error,
        };
    };
    if (data.len > 4096) {
        allocator.free(data);
        return .{ .active = null, .status = .io_error };
    }
    defer allocator.free(data);
    if (validateSave(data, missions.len) == null) {
        return .{ .active = null, .status = .invalid };
    }
    return .{
        .active = loadGameFromBytes(data, player, missions),
        .status = .loaded,
    };
}

/// Loads the save file into the supplied player and mission state.
pub fn loadGame(context: SaveContext, allocator: std.mem.Allocator, player: *Player, missions: []Mission) ?usize {
    return loadGameWithStatus(context, allocator, player, missions).active;
}
