// Compatibility facade; implementation lives in catalog/mission_data.zig.
const implementation = @import("catalog/mission_data.zig");
pub const defaultMissions = implementation.defaultMissions;
