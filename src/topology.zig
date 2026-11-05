/// Static, fictional mission graph data. This module has no game or I/O dependencies.
pub const Node = struct {
    id: []const u8,
    label: []const u8,
};

pub const Link = struct {
    from: []const u8,
    to: []const u8,
};

pub const Topology = struct {
    nodes: []const Node,
    links: []const Link,
    entry_node: []const u8,
    scan_node: []const u8,
    auth_node: []const u8,
    decrypt_node: []const u8,
    analyze_node: []const u8,
    extract_node: []const u8,

    pub fn findNode(self: *const Topology, id: []const u8) ?Node {
        for (self.nodes) |node| {
            if (std.mem.eql(u8, node.id, id)) return node;
        }
        return null;
    }

    pub fn areAdjacent(self: *const Topology, first: []const u8, second: []const u8) bool {
        for (self.links) |link| {
            if ((std.mem.eql(u8, link.from, first) and std.mem.eql(u8, link.to, second)) or
                (std.mem.eql(u8, link.from, second) and std.mem.eql(u8, link.to, first)))
            {
                return true;
            }
        }
        return false;
    }

    pub fn containsNode(self: *const Topology, id: []const u8) bool {
        return self.findNode(id) != null;
    }

    pub fn isValid(self: *const Topology) bool {
        if (!self.containsNode(self.entry_node) or
            !self.containsNode(self.scan_node) or
            !self.containsNode(self.auth_node) or
            !self.containsNode(self.decrypt_node) or
            !self.containsNode(self.analyze_node) or
            !self.containsNode(self.extract_node)) return false;
        for (self.links) |link| {
            if (!self.containsNode(link.from) or !self.containsNode(link.to) or
                std.mem.eql(u8, link.from, link.to)) return false;
        }
        return true;
    }

    pub fn purposeAt(self: *const Topology, id: []const u8) []const u8 {
        var purpose: []const u8 = "";
        if (std.mem.eql(u8, id, self.scan_node)) purpose = appendPurpose(purpose, "SCAN");
        if (std.mem.eql(u8, id, self.auth_node)) purpose = appendPurpose(purpose, "AUTH");
        if (std.mem.eql(u8, id, self.decrypt_node)) purpose = appendPurpose(purpose, "DECRYPT");
        if (std.mem.eql(u8, id, self.analyze_node)) purpose = appendPurpose(purpose, "ANALYZE");
        if (std.mem.eql(u8, id, self.extract_node)) purpose = appendPurpose(purpose, "EXTRACT");
        return purpose;
    }
};

const std = @import("std");

fn appendPurpose(current: []const u8, next: []const u8) []const u8 {
    if (current.len == 0) return next;
    // All combinations are static labels; avoid allocation in this foundational module.
    if (std.mem.eql(u8, current, "SCAN")) return if (std.mem.eql(u8, next, "AUTH")) "SCAN,AUTH" else "SCAN,DECRYPT";
    if (std.mem.eql(u8, current, "AUTH")) return "AUTH,DECRYPT";
    if (std.mem.eql(u8, current, "DECRYPT")) return if (std.mem.eql(u8, next, "EXTRACT")) "DECRYPT,EXTRACT" else "DECRYPT,ANALYZE";
    if (std.mem.eql(u8, current, "ANALYZE")) return "ANALYZE,EXTRACT";
    if (std.mem.eql(u8, current, "SCAN,AUTH")) return "SCAN,AUTH,DECRYPT";
    if (std.mem.eql(u8, current, "DECRYPT,ANALYZE")) return "DECRYPT,ANALYZE,EXTRACT";
    return next;
}

