// Compatibility facade; implementation lives in domain/progression.zig.
const implementation = @import("domain/progression.zig");
pub const ReputationTier = implementation.ReputationTier;
pub const reputationTier = implementation.reputationTier;
pub const playerLevel = implementation.playerLevel;
pub const xpForNextLevel = implementation.xpForNextLevel;
pub const completeMission = implementation.completeMission;
