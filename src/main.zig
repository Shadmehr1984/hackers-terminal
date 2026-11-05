const std = @import("std");
const Mission = @import("mission.zig").Mission;
const Player = @import("player.zig").Player;
const save = @import("save.zig");
const game = @import("game.zig");
const terminal = @import("terminal.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const allocator = general_purpose_allocator.allocator();

    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();

    var player = Player{};
    var missions = [_]Mission{
        .{
            .id = "job-01",
            .name = "Cold Storage",
            .target = "vault-01.local",
            .password = "orion42",
            .password_hint = "A hunter constellation, followed by the number 42.",
            .encrypted_file = "ledger.enc",
            .decryption_hint = "The middle of the night.",
            .decryption_key = "midnight",
            .reward = 300,
            .xp_reward = 100,
            .required_level = 1,
        },
        .{
            .id = "job-02",
            .name = "Paper Trail",
            .target = "archive-02.local",
            .password = "copper17",
            .password_hint = "A reddish metal, followed by the number 17.",
            .encrypted_file = "mailbox.enc",
            .decryption_hint = "A small songbird often associated with a clear blue color.",
            .decryption_key = "bluebird",
            .reward = 500,
            .xp_reward = 150,
            .required_level = 2,
        },
        .{
            .id = "job-03",
            .name = "Quiet Exit",
            .target = "relay-03.local",
            .password = "northstar",
            .password_hint = "A fixed point used for navigation in the northern sky.",
            .encrypted_file = "manifest.enc",
            .decryption_hint = "The time after normal business hours.",
            .decryption_key = "afterhours",
            .reward = 800,
            .xp_reward = 200,
            .required_level = 3,
        },
    };

    const active_from_save = save.loadGame(allocator, &player, &missions);

    try terminal.printBanner(stdout);
    try stdout.print("Welcome back, {s}.\nBalance: ${d} | Reputation: {d} | Level: {d} | XP: {d}\n", .{
        player.handle,
        player.balance,
        player.reputation,
        game.playerLevel(player),
        player.xp,
    });
    try stdout.writeAll("Type 'help' to see commands.\n");

    var input_buffer: [512]u8 = undefined;
    var active: ?usize = active_from_save;
    var scanned = false;
    var connected = false;
    var access_granted = false;
    var decrypted = false;

    while (true) {
        try stdout.print("\n{s}@darknet:~$ ", .{player.handle});
        const maybe_line = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
        if (maybe_line == null) break;
        const line = std.mem.trim(u8, maybe_line.?, " \r\t");
        if (line.len == 0) continue;

        const keep_running = try game.runCommand(
            stdout,
            line,
            &player,
            &missions,
            &active,
            &scanned,
            &connected,
            &access_granted,
            &decrypted,
        );
        if (!keep_running) break;
    }
}
