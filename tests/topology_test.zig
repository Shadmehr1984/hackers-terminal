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


test "topology validation rejects duplicate nodes and self-links" {
    const duplicate_nodes = [_]Node{
        .{ .id = "entry", .label = "Entry" },
        .{ .id = "entry", .label = "Duplicate entry" },
    };
    const self_link = [_]Link{.{ .from = "entry", .to = "entry" }};
    const duplicate_graph = Topology{
        .nodes = &duplicate_nodes,
        .links = &.{},
        .entry_node = "entry",
        .scan_node = "entry",
        .auth_node = "entry",
        .decrypt_node = "entry",
        .analyze_node = "entry",
        .extract_node = "entry",
    };
    const self_link_graph = Topology{
        .nodes = duplicate_nodes[0..1],
        .links = &self_link,
        .entry_node = "entry",
        .scan_node = "entry",
        .auth_node = "entry",
        .decrypt_node = "entry",
        .analyze_node = "entry",
        .extract_node = "entry",
    };
    try std.testing.expect(!duplicate_graph.isValid());
    try std.testing.expect(!self_link_graph.isValid());
}
