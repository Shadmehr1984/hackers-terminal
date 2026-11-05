const std = @import("std");
const Player = @import("player.zig").Player;
const UtilityEquipment = @import("player.zig").UtilityEquipment;
pub const decryptor_price: u32 = 150;
pub const utility_price: u32 = 100;
pub const upgrade_prices = [_]u32{ 150, 250 };
fn parseUtility(name: []const u8) ?UtilityEquipment {
    if (std.mem.eql(u8, name, "silent-boots")) return .silent_boots;
    if (std.mem.eql(u8, name, "signal-scrubber")) return .signal_scrubber;
    return null;
}
pub fn printInventory(writer: anytype, player: Player) !void {
    try writer.writeAll("INVENTORY\n  Basic terminal kit\n");
    if (player.equipment.has_decryptor) try writer.writeAll("  File decryptor\n") else try writer.writeAll("  File decryptor: not owned\n");
    inline for (.{ UtilityEquipment.silent_boots, UtilityEquipment.signal_scrubber }) |utility| {
        if (player.equipment.owns(utility)) try writer.print("  {s} (level {d}){s}\n", .{
            utility.label(), player.equipment.level(utility),
            if (player.equipment.equipped_utility == utility) " [EQUIPPED]" else "",
        });
    }
    if (player.equipment.equipped_utility == null) try writer.writeAll("  Active utility: none\n");
}
pub fn printShop(writer: anytype) !void {
    try writer.writeAll("BLACK MARKET (fictional)\n  decryptor - $150 - required to decrypt mission files\n  silent-boots - $100 - reduce Detection from topology movement\n  signal-scrubber - $100 - reduce Detection from incorrect authentication\n  upgrade <utility> - level 1: $150, level 2: $250\n  equip <utility> - activate one owned utility (one slot)\n");
}
pub fn buyItem(writer: anytype, player: *Player, item: []const u8) !void {
    if (std.mem.eql(u8, item, "decryptor")) {
        if (player.equipment.has_decryptor) try writer.writeAll("You already own a decryptor.\n")
        else if (player.balance < decryptor_price) try writer.writeAll("Insufficient funds.\n")
        else { player.balance -= decryptor_price; player.equipment.has_decryptor = true; try writer.writeAll("Purchase complete: decryptor installed.\n"); }
        return;
    }
    const utility = parseUtility(item) orelse { try writer.writeAll("Unknown item. Use 'shop'.\n"); return; };
    if (player.equipment.owns(utility)) try writer.writeAll("You already own this utility.\n")
    else if (player.balance < utility_price) try writer.writeAll("Insufficient funds.\n")
    else {
        player.balance -= utility_price;
        player.equipment.setOwned(utility);
        try writer.print("Purchase complete: {s} acquired at level 0. Use 'equip {s}' to activate it.\n", .{ utility.label(), utility.commandName() });
    }
}
pub fn equipItem(writer: anytype, player: *Player, item: []const u8) !void {
    const utility = parseUtility(item) orelse { try writer.writeAll("Unknown utility. Use 'inventory' to inspect owned equipment.\n"); return; };
    if (!player.equipment.owns(utility)) try writer.writeAll("You do not own this utility.\n")
    else if (player.equipment.equipped_utility == utility) try writer.writeAll("This utility is already equipped.\n")
    else { player.equipment.equipped_utility = utility; try writer.print("{s} equipped. It is now your active utility.\n", .{utility.label()}); }
}
pub fn upgradeItem(writer: anytype, player: *Player, item: []const u8) !void {
    const utility = parseUtility(item) orelse { try writer.writeAll("Unknown utility. Use 'shop' to inspect upgrade options.\n"); return; };
    if (!player.equipment.owns(utility)) { try writer.writeAll("Purchase this utility before upgrading it.\n"); return; }
    const current_level = player.equipment.level(utility);
    if (current_level >= 2) { try writer.writeAll("This utility is already at maximum level.\n"); return; }
    const price = upgrade_prices[current_level];
    if (player.balance < price) { try writer.writeAll("Insufficient funds.\n"); return; }
    player.balance -= price;
    player.equipment.setLevel(utility, current_level + 1);
    try writer.print("{s} upgraded to level {d} for ${d}.\n", .{ utility.label(), current_level + 1, price });
}
