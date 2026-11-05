const std = @import("std");
const Player = @import("player.zig").Player;

pub fn printInventory(writer: anytype, player: Player) !void {
    try writer.writeAll("INVENTORY\n  Basic terminal kit\n");
    if (player.has_decryptor) try writer.writeAll("  File decryptor\n");
}

pub fn printShop(writer: anytype) !void {
    try writer.writeAll("BLACK MARKET (fictional)\n  decryptor - $150 - required to decrypt mission files\n");
}

pub fn buyItem(writer: anytype, player: *Player, item: []const u8) !void {
    if (std.mem.eql(u8, item, "decryptor")) {
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
}
