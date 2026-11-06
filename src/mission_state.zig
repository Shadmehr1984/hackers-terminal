// Compatibility facade; implementation lives in domain/mission_state.zig.
const implementation = @import("domain/mission_state.zig");
pub const MissionLoadout = implementation.MissionLoadout;
pub const MissionPreparation = implementation.MissionPreparation;
pub const MissionProgress = implementation.MissionProgress;
pub const DetectionBand = implementation.DetectionBand;
pub const MissionSession = implementation.MissionSession;
