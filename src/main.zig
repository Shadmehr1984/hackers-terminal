const std = @import("std");
const Player = @import("domain/player.zig").Player;
const MissionState = @import("domain/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const save = @import("persistence/save.zig");
const game = @import("application/game.zig");
const terminal_input = @import("application/terminal_input.zig");
const terminal_io = @import("application/terminal_io.zig");
const progression = @import("domain/progression.zig");
const terminal = @import("presentation/terminal.zig");
const mission_data = @import("catalog/mission_data.zig");

/// Process entry point for Zig 0.17.1.
pub fn main(init: std.process.Init) !void {
    var stdout = terminal_io.ProcessWriter{
        .io = init.io,
        .file = std.Io.File.stdout(),
        .allocator = init.gpa,
    };
    var input_buffer: [terminal_input.buffer_capacity]u8 = undefined;
    var stdin = std.Io.File.stdin().readerStreaming(init.io, &input_buffer);
    try runApplication(init.gpa, &stdout, &stdin.interface, save.SaveContext{
        .io = init.io,
        .dir = std.Io.Dir.cwd(),
    });
}

fn runApplication(allocator: std.mem.Allocator, stdout: anytype, stdin: anytype, save_context: save.SaveContext) !void {
    var player = Player{};
    var missions = mission_data.defaultMissions();
    const load_result = save.loadGameWithStatus(save_context, allocator, &player, &missions);
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
        const maybe_line = terminal_io.readLine(stdin, stdout) catch |err| switch (err) {
            error.CommandDiscarded => continue,
            else => return err,
        };
        if (maybe_line == null) break;
        const raw_line = maybe_line.?;
        const line = std.mem.trim(u8, raw_line, " \r\t");
        if (line.len == 0) continue;

        const keep_running = try game.runCommandWithSaveContext(stdout, line, &player, &missions, &active, &session, &preparation, save_context);
        if (!keep_running) break;
    }
}
