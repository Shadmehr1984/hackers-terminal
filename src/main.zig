const std = @import("std");
const Player = @import("domain/player.zig").Player;
const MissionState = @import("domain/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const save = @import("persistence/save.zig");
const game = @import("application/game.zig");
const progression = @import("domain/progression.zig");
const terminal = @import("presentation/terminal.zig");
const mission_data = @import("catalog/mission_data.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (general_purpose_allocator.deinit() == .leak) {
            std.debug.print("[MEMORY LEAK] GeneralPurposeAllocator detected leaked allocations.\n", .{});
        }
    }
    const allocator = general_purpose_allocator.allocator();

    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();

    var player = Player{};
    var missions = mission_data.defaultMissions();
    const load_result = save.loadGameWithStatus(allocator, &player, &missions);
    const active_from_save = load_result.active;

    try terminal.printBanner(stdout);
    try stdout.print("Welcome back, {s}.\nBalance: ${d} | Reputation: {d} | Level: {d} | XP: {d}\n", .{
        player.handle, player.balance, player.reputation, progression.playerLevel(player), player.xp,
    });
    try stdout.writeAll("Type 'help' to see commands.\n");
    switch (load_result.status) {
        .loaded, .missing => {},
        .invalid => try stdout.writeAll("[SAVE WARNING] The existing save is malformed or unsupported. Default progress is active; preserve the save file before saving again.\n"),
        .io_error => try stdout.writeAll("[SAVE WARNING] The existing save could not be read. Default progress is active; check file permissions and preserve the save file before saving again.\n"),
    }

    var input_buffer: [512]u8 = undefined;
    var active: ?usize = active_from_save;
    var session = MissionSession{};
    var preparation = MissionPreparation{};
    if (active) |index| {
        session.startWithLoadout(game.currentLoadout(player));
        if (!session.initializeObjectives(missions[index].objectives)) {
            active = null;
            session.reset();
        } else if (missions[index].topology) |topology| {
            session.current_node = topology.entry_node;
            const discovered = session.discoverNode(topology.entry_node, missions[index].objectives);
            if (discovered > 0) try stdout.print("[HIDDEN OBJECTIVE DISCOVERED] {d} optional objective(s) revealed. Use 'objectives' to inspect them.\n", .{discovered});
        }
    }

    while (true) {
        try stdout.print("\n{s}@darknet:~$ ", .{player.handle});
        const maybe_line = stdin.readUntilDelimiterOrEof(&input_buffer, '\n') catch |err| switch (err) {
            error.StreamTooLong => {
                while (true) {
                    const remaining = stdin.readUntilDelimiterOrEof(&input_buffer, '\n') catch |drain_err| switch (drain_err) {
                        error.StreamTooLong => continue,
                        else => return drain_err,
                    };
                    if (remaining == null) break;
                    break;
                }
                try stdout.writeAll("Input too long. Command discarded.\n");
                continue;
            },
            else => return err,
        };
        if (maybe_line == null) break;
        const line = std.mem.trim(u8, maybe_line.?, " \r\t");
        if (line.len == 0) continue;

        const keep_running = try game.runCommand(stdout, line, &player, &missions, &active, &session, &preparation);
        if (!keep_running) break;
    }
}
