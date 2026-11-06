const builtin = @import("builtin");
const std = @import("std");
const Player = @import("domain/player.zig").Player;
const MissionState = @import("domain/mission_state.zig");
const MissionSession = MissionState.MissionSession;
const MissionPreparation = MissionState.MissionPreparation;
const save = @import("persistence/save.zig");
const game = @import("application/game.zig");
const terminal_input = @import("application/terminal_input.zig");
const terminal_io = if (builtin.zig_version.minor >= 16) @import("application/terminal_io.zig") else struct {};
const progression = @import("domain/progression.zig");
const terminal = @import("presentation/terminal.zig");
const mission_data = @import("catalog/mission_data.zig");

/// Select the process entry point supported by the active Zig standard library.
pub const main = if (builtin.zig_version.minor >= 16) mainWithIo else mainLegacy;

fn mainLegacy() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (general_purpose_allocator.deinit() == .leak) {
            std.debug.print("[MEMORY LEAK] GeneralPurposeAllocator detected leaked allocations.\n", .{});
        }
    }
    const allocator = general_purpose_allocator.allocator();

    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();
    try runApplication(allocator, &stdout, &stdin, save.SaveContext{ .dir = std.fs.cwd() });
}

/// Zig 0.16+ supplies process resources, including the allocator and I/O context.
fn mainWithIo(init: std.process.Init) !void {
    var stdout = terminal_io.ProcessWriter{
        .io = init.io,
        .file = std.Io.File.stdout(),
        .allocator = init.gpa,
    };
    var input_buffer: [terminal_input.buffer_capacity]u8 = undefined;
    var stdin = std.Io.File.stdin().readerStreaming(init.io, &input_buffer);
    try runApplication(init.gpa, &stdout, &stdin.interface, save.SaveContext{ .io = init.io, .dir = std.Io.Dir.cwd() });
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

    var legacy_input_buffer: [terminal_input.buffer_capacity]u8 = undefined;
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
        const maybe_line = if (builtin.zig_version.minor >= 16)
            terminal_io.readLine(stdin, stdout) catch |err| switch (err) {
                error.CommandDiscarded => continue,
                else => return err,
            }
        else
            stdin.readUntilDelimiterOrEof(&legacy_input_buffer, '\n') catch |err| switch (err) {
                error.StreamTooLong => {
                    while (true) {
                        const remaining = stdin.readUntilDelimiterOrEof(&legacy_input_buffer, '\n') catch |drain_err| switch (drain_err) {
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
        const raw_line = maybe_line.?;
        const line = std.mem.trim(u8, raw_line, " \r\t");
        if (line.len == 0) continue;

        const keep_running = try game.runCommandWithSaveContext(stdout, line, &player, &missions, &active, &session, &preparation, save_context);
        if (!keep_running) break;
    }
}
