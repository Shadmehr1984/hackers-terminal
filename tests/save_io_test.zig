const std = @import("std");
const save = @import("../src/persistence/save.zig");

fn readSave(context: save.SaveContext, allocator: std.mem.Allocator) ![]u8 {
    return context.dir.readFileAlloc(context.io, "saves/player.sav", allocator, .limited(4097));
}

test "Zig 0.17 save adapter writes and reloads the unchanged V3 payload" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const context = save.SaveContext{ .io = std.testing.io, .dir = tmp.dir };

    const player = save.Player{ .balance = 123 };
    var missions: [0]save.Mission = .{};
    try save.saveGameToDirectory(context, player, &missions, null);

    const bytes = try readSave(context, std.testing.allocator);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualStrings(
        "HACKERS_TERMINAL_SAVE_V3\n123\n0\n0\n0\n0\n0\n0\n0\n-1\n",
        bytes,
    );

    var restored = save.Player{};
    const result = save.loadGameWithStatus(context, std.testing.allocator, &restored, &missions);
    try std.testing.expectEqual(save.LoadStatus.loaded, result.status);
    try std.testing.expect(result.active == null);
    try std.testing.expectEqual(@as(u32, 123), restored.balance);
}

test "Zig 0.17 save replacement remains safe when staging fails" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const context = save.SaveContext{ .io = std.testing.io, .dir = tmp.dir };

    var player = save.Player{ .balance = 321 };
    var missions: [0]save.Mission = .{};
    try save.saveGameToDirectory(context, player, &missions, null);

    try tmp.dir.createDirPath(std.testing.io, "saves/player.sav.tmp");
    player.balance = 999;
    if (save.saveGameToDirectory(context, player, &missions, null)) |_| {
        return error.ExpectedSaveWriteFailure;
    } else |_| {}

    var restored = save.Player{};
    const result = save.loadGameWithStatus(context, std.testing.allocator, &restored, &missions);
    try std.testing.expectEqual(save.LoadStatus.loaded, result.status);
    try std.testing.expectEqual(@as(u32, 321), restored.balance);
}

test "Zig 0.17 save reader preserves the 4096-byte boundary" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const context = save.SaveContext{ .io = std.testing.io, .dir = tmp.dir };
    try tmp.dir.createDirPath(std.testing.io, "saves");

    var exact: [4096]u8 = undefined;
    @memset(&exact, 'x');
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "saves/player.sav", .data = &exact });

    var player = save.Player{};
    var missions: [0]save.Mission = .{};
    const exact_result = save.loadGameWithStatus(context, std.testing.allocator, &player, &missions);
    try std.testing.expectEqual(save.LoadStatus.invalid, exact_result.status);

    var oversized: [4097]u8 = undefined;
    @memset(&oversized, 'x');
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "saves/player.sav", .data = &oversized });

    const oversized_result = save.loadGameWithStatus(context, std.testing.allocator, &player, &missions);
    try std.testing.expectEqual(save.LoadStatus.io_error, oversized_result.status);
}

test "Zig 0.17 missing save remains a missing status" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const context = save.SaveContext{ .io = std.testing.io, .dir = tmp.dir };
    var player = save.Player{};
    var missions: [0]save.Mission = .{};

    const result = save.loadGameWithStatus(context, std.testing.allocator, &player, &missions);
    try std.testing.expectEqual(save.LoadStatus.missing, result.status);
}
