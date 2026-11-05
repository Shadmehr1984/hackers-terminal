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
    try std.testing.expect(graph.isValid(std.testing.allocator));
}

test "topology validation rejects unreachable required operation nodes" {
    const nodes = [_]Node{
        .{ .id = "entry", .label = "Entry" },
        .{ .id = "scan", .label = "Scan" },
        .{ .id = "auth", .label = "Auth" },
        .{ .id = "decrypt", .label = "Decrypt" },
        .{ .id = "analyze", .label = "Analyze" },
        .{ .id = "extract", .label = "Extract" },
        .{ .id = "decorative", .label = "Disconnected decorative node" },
    };
    const disconnected_links = [_]Link{
        .{ .from = "entry", .to = "scan" },
        .{ .from = "auth", .to = "decrypt" },
        .{ .from = "decrypt", .to = "analyze" },
        .{ .from = "analyze", .to = "extract" },
    };
    const connected_links = [_]Link{
        .{ .from = "entry", .to = "scan" },
        .{ .from = "scan", .to = "auth" },
        .{ .from = "auth", .to = "decrypt" },
        .{ .from = "decrypt", .to = "analyze" },
        .{ .from = "analyze", .to = "extract" },
    };
    const disconnected = Topology{
        .nodes = &nodes,
        .links = &disconnected_links,
        .entry_node = "entry",
        .scan_node = "scan",
        .auth_node = "auth",
        .decrypt_node = "decrypt",
        .analyze_node = "analyze",
        .extract_node = "extract",
    };
    const connected = Topology{
        .nodes = &nodes,
        .links = &connected_links,
        .entry_node = "entry",
        .scan_node = "scan",
        .auth_node = "auth",
        .decrypt_node = "decrypt",
        .analyze_node = "analyze",
        .extract_node = "extract",
    };
    try std.testing.expect(!disconnected.isValid(std.testing.allocator));
    try std.testing.expect(connected.isValid(std.testing.allocator));
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
    try std.testing.expect(!duplicate_graph.isValid(std.testing.allocator));
    try std.testing.expect(!self_link_graph.isValid(std.testing.allocator));
}

test "topology validation returns false when either traversal allocation fails" {
    const nodes = [_]Node{
        .{ .id = "entry", .label = "Entry" },
        .{ .id = "scan", .label = "Scan" },
        .{ .id = "auth", .label = "Auth" },
        .{ .id = "decrypt", .label = "Decrypt" },
        .{ .id = "analyze", .label = "Analyze" },
        .{ .id = "extract", .label = "Extract" },
    };
    const links = [_]Link{
        .{ .from = "entry", .to = "scan" },
        .{ .from = "scan", .to = "auth" },
        .{ .from = "auth", .to = "decrypt" },
        .{ .from = "decrypt", .to = "analyze" },
        .{ .from = "analyze", .to = "extract" },
    };
    const graph = Topology{
        .nodes = &nodes,
        .links = &links,
        .entry_node = "entry",
        .scan_node = "scan",
        .auth_node = "auth",
        .decrypt_node = "decrypt",
        .analyze_node = "analyze",
        .extract_node = "extract",
    };

    inline for (.{ 0, 1 }) |fail_index| {
        var failing_allocator = std.testing.FailingAllocator.init(.{
            .allocator = std.testing.allocator,
            .fail_index = fail_index,
        });
        try std.testing.expect(!graph.isValid(failing_allocator.allocator(@returnAddress())));
    }
}
