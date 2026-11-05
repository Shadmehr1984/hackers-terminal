const std = @import("std");
const Player = @import("player.zig").Player;
const MissionState = @import("mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const save = @import("save.zig");
const game = @import("game.zig");
const terminal = @import("terminal.zig");
const mission_data = @import("mission_data.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const allocator = general_purpose_allocator.allocator();

    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();

    var player = Player{};
    var missions = mission_data.defaultMissions();
    const active_from_save = save.loadGame(allocator, &player, &missions);

    try terminal.printBanner(stdout);
    try stdout.print("Welcome back, {s}.\nBalance: ${d} | Reputation: {d} | Level: {d} | XP: {d}\n", .{
        player.handle, player.balance, player.reputation, game.playerLevel(player), player.xp,
    });
    try stdout.writeAll("Type 'help' to see commands.\n");

    var input_buffer: [512]u8 = undefined;
    var active: ?usize = active_from_save;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    if (active) |index| {
        session.startWithLoadout(game.currentLoadout(player));
        if (missions[index].topology) |topology| session.current_node = topology.entry_node;
    }

    while (true) {
        try stdout.print("\n{s}@darknet:~$ ", .{player.handle});
        const maybe_line = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
        if (maybe_line == null) break;
        const line = std.mem.trim(u8, maybe_line.?, " \r\t");
        if (line.len == 0) continue;

        const keep_running = try game.runCommand(stdout, line, &player, &missions, &active, &session, &preparation);
        if (!keep_running) break;
    }
}
