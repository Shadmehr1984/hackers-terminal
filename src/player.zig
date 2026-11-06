// Compatibility facade; implementation lives in domain/player.zig.
const implementation = @import("domain/player.zig");
pub const UtilityEquipment = implementation.UtilityEquipment;
pub const Equipment = implementation.Equipment;
pub const Player = implementation.Player;
