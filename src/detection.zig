// Compatibility facade; implementation lives in application/detection.zig.
const implementation = @import("application/detection.zig");
pub const failure_penalty = implementation.failure_penalty;
pub const apply = implementation.apply;
