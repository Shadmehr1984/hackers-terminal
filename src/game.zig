// Compatibility facade; implementation lives in application/game.zig.
const implementation = @import("application/game.zig");
pub const detection_failure_penalty = implementation.detection_failure_penalty;
pub const currentLoadout = implementation.currentLoadout;
pub const runCommand = implementation.runCommand;
pub const runCommandWithSaveContext = implementation.runCommandWithSaveContext;
