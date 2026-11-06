// Compatibility facade; implementation lives in persistence/save.zig.
const implementation = @import("persistence/save.zig");
pub const Mission = implementation.Mission;
pub const Player = implementation.Player;
pub const SaveContext = implementation.SaveContext;
pub const saveGame = implementation.saveGame;
pub const saveGameToDirectory = implementation.saveGameToDirectory;
pub const loadGameFromBytes = implementation.loadGameFromBytes;
pub const LoadStatus = implementation.LoadStatus;
pub const LoadResult = implementation.LoadResult;
pub const loadGameWithStatus = implementation.loadGameWithStatus;
pub const loadGame = implementation.loadGame;
