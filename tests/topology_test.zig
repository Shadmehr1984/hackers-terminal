const std = @import("std");
const topology = @import("../src/topology.zig");

const Node = topology.Node;
const Link = topology.Link;
const Topology = topology.Topology;

test "topology lookup and links are bidirectional" {
    const nodes = [_]Node{ .{ .id = "entry", .label = "Entry" }, .{ .id = "vault", .label = "Vault" } };
    const links = [_]Link{.{ .from = "entry", .to = "vault" }};
    const graph = Topology{
        .nodes = &nodes,
        .links = &links,
        .entry_node = "entry",
        .scan_node = "entry",
        .auth_node = "entry",
        .decrypt_node = "vault",
        .analyze_node = "vault",
        .extract_node = "vault",
    };
    try std.testing.expect(graph.containsNode("vault"));
    try std.testing.expect(!graph.containsNode("missing"));
    try std.testing.expect(graph.areAdjacent("entry", "vault"));
    try std.testing.expect(graph.areAdjacent("vault", "entry"));
    try std.testing.expect(!graph.areAdjacent("entry", "missing"));
    try std.testing.expect(graph.isValid());
}
