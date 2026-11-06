// Compatibility facade; implementation lives in application/shop.zig.
const implementation = @import("application/shop.zig");
pub const decryptor_price = implementation.decryptor_price;
pub const utility_price = implementation.utility_price;
pub const upgrade_prices = implementation.upgrade_prices;
pub const printInventory = implementation.printInventory;
pub const printShop = implementation.printShop;
pub const buyItem = implementation.buyItem;
pub const equipItem = implementation.equipItem;
pub const upgradeItem = implementation.upgradeItem;
