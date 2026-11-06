// Compatibility facade; implementation lives in domain/mission.zig.
const implementation = @import("domain/mission.zig");
pub const Topology = implementation.Topology;
pub const MissionDifficulty = implementation.MissionDifficulty;
pub const MissionCategory = implementation.MissionCategory;
pub const MissionObjectiveKind = implementation.MissionObjectiveKind;
pub const MissionObjective = implementation.MissionObjective;
pub const Mission = implementation.Mission;
