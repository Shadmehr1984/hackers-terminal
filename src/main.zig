const std = @import("std");

const Mission = struct {
    id: []const u8,
    name: []const u8,
    target: []const u8,
    password: []const u8,
    encrypted_file: []const u8,
    decryption_key: []const u8,
    reward: u32,
    completed: bool = false,
};

const Player = struct {
    handle: []const u8 = "ghost",
    balance: u32 = 250,
    reputation: u32 = 0,
    has_decryptor: bool = false,
};

fn printBanner(writer: anytype) !void {
    try writer.writeAll(
        \\============================================================
        \\                    HACKER'S TERMINAL
        \\               REALISTIC DARK SIMULATOR
        \\============================================================
        \\
        \\  This is a fictional, self-contained hacking simulation.
        \\  No real networks or external systems are contacted.
        \\
    );
}

fn printHelp(writer: anytype) !void {
    try writer.writeAll(
        \\COMMANDS
        \\  help                 Show this help
        \\  status               Show operator status
        \\  missions             List available contracts
        \\  accept <id>          Accept a contract
        \\  scan <target>        Scan the active fictional target
        \\  connect <target>     Connect after scanning
        \\  disconnect           End the simulated connection
        \\  brute <password>     Solve the password challenge
        \\  decrypt <key>        Decrypt the mission file
        \\  extract <filename>   Retrieve the mission file
        \\  inventory            Show owned tools
        \\  shop                 Show available tools
        \\  buy <item>           Purchase a tool
        \\  save                 Save progress
        \\  clear                Clear the terminal
        \\  exit                 Leave the game
        \\
        \\MISSION FLOW
        \\  missions -> accept -> scan -> connect -> brute
        \\  -> decrypt -> extract
        \\
    );
}

fn printStatus(writer: anytype, player: Player, active: ?usize, missions: []const Mission) !void {
    try writer.print(
        \\OPERATOR
        \\  Handle:      {s}
        \\  Balance:     ${d}
        \\  Reputation:  {d}
        \\  Decryptor:   {s}
        \\
    , .{ player.handle, player.balance, player.reputation, if (player.has_decryptor) "installed" else "not installed" });

    if (active) |index| {
        try writer.print("  Active job:  {s} ({s})\n", .{ missions[index].name, missions[index].id });
    } else {
        try writer.writeAll("  Active job:  none\n");
    }
}

fn printMissions(writer: anytype, missions: []const Mission) !void {
    try writer.writeAll("AVAILABLE CONTRACTS\n");
    for (missions) |mission| {
        try writer.print("  [{s}] {s} | target: {s} | reward: ${d} | {s}\n", .{
            mission.id,
            mission.name,
            mission.target,
            mission.reward,
            if (mission.completed) "COMPLETED" else "OPEN",
        });
    }
    try writer.writeAll("\nUse: accept <id>\n");
}

fn saveGame(player: Player, missions: []const Mission) !void {
    try std.fs.cwd().makePath("saves");
    const file = try std.fs.cwd().createFile("saves/player.sav", .{ .truncate = true });
    defer file.close();

    const writer = file.writer();
    try writer.print("{d}\n{d}\n{d}\n", .{
        player.balance,
        player.reputation,
        @as(u8, if (player.has_decryptor) 1 else 0),
    });
    for (missions) |mission| {
        try writer.print("{d}\n", .{@as(u8, if (mission.completed) 1 else 0)});
    }
}

fn loadGame(allocator: std.mem.Allocator, player: *Player, missions: []Mission) void {
    const file = std.fs.cwd().openFile("saves/player.sav", .{}) catch return;
    defer file.close();

    const data = file.readToEndAlloc(allocator, 4096) catch return;
    defer allocator.free(data);

    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    if (lines.next()) |value| player.balance = std.fmt.parseInt(u32, value, 10) catch player.balance;
    if (lines.next()) |value| player.reputation = std.fmt.parseInt(u32, value, 10) catch player.reputation;
    if (lines.next()) |value| player.has_decryptor = std.mem.eql(u8, value, "1");

    for (missions) |*mission| {
        if (lines.next()) |value| {
            mission.completed = std.mem.eql(u8, value, "1");
        }
    }
}

fn completeMission(writer: anytype, player: *Player, mission: Mission) !void {
    player.balance += mission.reward;
    player.reputation += 1;
    try writer.print(
        \\\n[CONTRACT COMPLETE] {s}
        \\Reward received: ${d}
        \\Reputation increased.
        \\
    , .{ mission.name, mission.reward });
}

fn runCommand(
    allocator: std.mem.Allocator,
    writer: anytype,
    line: []const u8,
    player: *Player,
    missions: []Mission,
    active: *?usize,
    scanned: *bool,
    connected: *bool,
    access_granted: *bool,
    decrypted: *bool,
) !bool {
    var tokens = std.mem.tokenizeScalar(u8, line, ' ');
    const command = tokens.next() orelse return true;
    const arg = tokens.next() orelse "";

    if (std.mem.eql(u8, command, "help")) {
        try printHelp(writer);
    } else if (std.mem.eql(u8, command, "status")) {
        try printStatus(writer, player.*, active.*, missions);
    } else if (std.mem.eql(u8, command, "missions")) {
        try printMissions(writer, missions);
    } else if (std.mem.eql(u8, command, "accept")) {
        if (active.* != null) {
            try writer.writeAll("A contract is already active. Complete it first.\n");
        } else {
            var found = false;
            for (missions, 0..) |mission, index| {
                if (std.mem.eql(u8, mission.id, arg) and !mission.completed) {
                    active.* = index;
                    scanned.* = false;
                    connected.* = false;
                    access_granted.* = false;
                    decrypted.* = false;
                    found = true;
                    try writer.print("Contract accepted: {s}\nTarget: {s}\n", .{ mission.name, mission.target });
                    break;
                }
            }
            if (!found) try writer.writeAll("Unknown or already completed contract. Use 'missions'.\n");
        }
    } else if (std.mem.eql(u8, command, "scan")) {
        if (active.*) |index| {
            if (!std.mem.eql(u8, arg, missions[index].target)) {
                try writer.writeAll("No active contract matches that target.\n");
            } else {
                scanned.* = true;
                try writer.print("[SCAN COMPLETE] Fictional host {s} is reachable. One simulated service requires authentication.\n", .{arg});
                try writer.writeAll("A password challenge was identified.\n");
            }
        } else try writer.writeAll("No active contract. Accept a mission first.\n");
    } else if (std.mem.eql(u8, command, "connect")) {
        if (active.*) |index| {
            if (!scanned.* or !std.mem.eql(u8, arg, missions[index].target)) {
                try writer.writeAll("Scan the active target first: scan <target>\n");
            } else {
                connected.* = true;
                try writer.print("Simulated session established with {s}.\n", .{arg});
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "disconnect")) {
        connected.* = false;
        try writer.writeAll("Session closed.\n");
    } else if (std.mem.eql(u8, command, "brute")) {
        if (active.*) |index| {
            if (!connected.*) {
                try writer.writeAll("No session. Connect to the target first.\n");
            } else if (std.mem.eql(u8, arg, missions[index].password)) {
                access_granted.* = true;
                try writer.writeAll("[ACCESS GRANTED] Authentication challenge solved.\n");
            } else {
                try writer.writeAll("[ACCESS DENIED] Incorrect password. Check the mission briefing.\n");
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "decrypt")) {
        if (active.*) |index| {
            if (!access_granted.*) {
                try writer.writeAll("Authentication is required before decryption.\n");
            } else if (!player.has_decryptor) {
                try writer.writeAll("Missing tool: decryptor. Visit the shop.\n");
            } else if (std.mem.eql(u8, arg, missions[index].decryption_key)) {
                decrypted.* = true;
                try writer.writeAll("[DECRYPTED] File contents verified. You can now extract the file.\n");
            } else {
                try writer.writeAll("[DECRYPTION FAILED] Incorrect key.\n");
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "extract")) {
        if (active.*) |index| {
            if (!decrypted.* or !std.mem.eql(u8, arg, missions[index].encrypted_file)) {
                try writer.writeAll("The requested file is unavailable or still encrypted.\n");
            } else {
                const finished = missions[index];
                missions[index].completed = true;
                active.* = null;
                scanned.* = false;
                connected.* = false;
                access_granted.* = false;
                decrypted.* = false;
                try writer.print("[EXTRACTED] {s}\n", .{finished.encrypted_file});
                try completeMission(writer, player, finished);
            }
        } else try writer.writeAll("No active contract.\n");
    } else if (std.mem.eql(u8, command, "inventory")) {
        try writer.writeAll("INVENTORY\n  Basic terminal kit\n");
        if (player.has_decryptor) try writer.writeAll("  File decryptor\n");
    } else if (std.mem.eql(u8, command, "shop")) {
        try writer.writeAll("BLACK MARKET (fictional)\n  decryptor - $150 - required to decrypt mission files\n");
    } else if (std.mem.eql(u8, command, "buy")) {
        if (std.mem.eql(u8, arg, "decryptor")) {
            if (player.has_decryptor) {
                try writer.writeAll("You already own a decryptor.\n");
            } else if (player.balance < 150) {
                try writer.writeAll("Insufficient funds.\n");
            } else {
                player.balance -= 150;
                player.has_decryptor = true;
                try writer.writeAll("Purchase complete: decryptor installed.\n");
            }
        } else try writer.writeAll("Unknown item. Use 'shop'.\n");
    } else if (std.mem.eql(u8, command, "save")) {
        saveGame(player.*, missions) catch {
            try writer.writeAll("Save failed. Check filesystem permissions.\n");
            return true;
        };
        try writer.writeAll("Progress saved to saves/player.sav.\n");
    } else if (std.mem.eql(u8, command, "clear")) {
        try writer.writeAll("\x1b[2J\x1b[H");
    } else if (std.mem.eql(u8, command, "exit")) {
        try writer.writeAll("Closing terminal. Stay safe, operator.\n");
        return false;
    } else {
        _ = allocator;
        try writer.writeAll("Unknown command. Type 'help' for available commands.\n");
    }
    return true;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const allocator = general_purpose_allocator.allocator();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var player = Player{};
    var missions = [_]Mission{
        .{
            .id = "job-01",
            .name = "Cold Storage",
            .target = "vault-01.local",
            .password = "orion42",
            .encrypted_file = "ledger.enc",
            .decryption_key = "midnight",
            .reward = 300,
        },
        .{
            .id = "job-02",
            .name = "Paper Trail",
            .target = "archive-02.local",
            .password = "copper17",
            .encrypted_file = "mailbox.enc",
            .decryption_key = "bluebird",
            .reward = 500,
        },
        .{
            .id = "job-03",
            .name = "Quiet Exit",
            .target = "relay-03.local",
            .password = "northstar",
            .encrypted_file = "manifest.enc",
            .decryption_key = "afterhours",
            .reward = 800,
        },
    };

    loadGame(allocator, &player, &missions);

    try printBanner(stdout);
    try stdout.print("Welcome back, {s}.\nBalance: ${d} | Reputation: {d}\n", .{
        player.handle,
        player.balance,
        player.reputation,
    });
    try stdout.writeAll("Type 'help' to see commands.\n");

    var input_buffer: [512]u8 = undefined;
    var active: ?usize = null;
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

        const keep_running = try runCommand(
            allocator,
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
