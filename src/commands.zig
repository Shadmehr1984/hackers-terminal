// Compatibility facade; implementation lives in application/commands.zig.
const implementation = @import("application/commands.zig");
pub const ParsedCommand = implementation.ParsedCommand;
pub const parse = implementation.parse;
