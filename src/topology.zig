// Compatibility facade; implementation lives in domain/topology.zig.
const implementation = @import("domain/topology.zig");
pub const Node = implementation.Node;
pub const Link = implementation.Link;
pub const Topology = implementation.Topology;
