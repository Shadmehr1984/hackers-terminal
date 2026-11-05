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

    fn indexOfNode(self: *const Topology, id: []const u8) ?usize {
        for (self.nodes, 0..) |node, index| {
            if (std.mem.eql(u8, node.id, id)) return index;
        }
        return null;
    }

    pub fn isValid(self: *const Topology, allocator: std.mem.Allocator) bool {
        if (!self.containsNode(self.entry_node) or
            !self.containsNode(self.scan_node) or
            !self.containsNode(self.auth_node) or
            !self.containsNode(self.decrypt_node) or
            !self.containsNode(self.analyze_node) or
            !self.containsNode(self.extract_node)) return false;
        for (self.nodes, 0..) |node, index| {
            if (node.id.len == 0) return false;
            for (self.nodes[index + 1 ..]) |other| {
                if (std.mem.eql(u8, node.id, other.id)) return false;
            }
        }
        for (self.links) |link| {
            if (!self.containsNode(link.from) or !self.containsNode(link.to) or
                std.mem.eql(u8, link.from, link.to)) return false;
        }

        // Traverse from the entry node and require every operation location to be reachable.
        const reached = allocator.alloc(bool, self.nodes.len) catch return false;
        defer allocator.free(reached);
        const queue = allocator.alloc(usize, self.nodes.len) catch return false;
        defer allocator.free(queue);
        @memset(reached, false);

        const entry_index = self.indexOfNode(self.entry_node) orelse return false;
        reached[entry_index] = true;
        queue[0] = entry_index;
        var head: usize = 0;
        var tail: usize = 1;
        while (head < tail) : (head += 1) {
            const current_id = self.nodes[queue[head]].id;
            for (self.links) |link| {
                const neighbor_id = if (std.mem.eql(u8, link.from, current_id))
                    link.to
                else if (std.mem.eql(u8, link.to, current_id))
                    link.from
                else
                    continue;
                const neighbor_index = self.indexOfNode(neighbor_id) orelse return false;
                if (!reached[neighbor_index]) {
                    reached[neighbor_index] = true;
                    queue[tail] = neighbor_index;
                    tail += 1;
                }
            }
        }

        const required_nodes = [_][]const u8{
            self.scan_node,
            self.auth_node,
            self.decrypt_node,
            self.analyze_node,
            self.extract_node,
        };
        for (required_nodes) |id| {
            const index = self.indexOfNode(id) orelse return false;
            if (!reached[index]) return false;
        }
        return true;
    }

    pub fn purposeAt(self: *const Topology, id: []const u8) []const u8 {
        const scan = std.mem.eql(u8, id, self.scan_node);
        const auth = std.mem.eql(u8, id, self.auth_node);
        const decrypt = std.mem.eql(u8, id, self.decrypt_node);
        const analyze = std.mem.eql(u8, id, self.analyze_node);
        const extract = std.mem.eql(u8, id, self.extract_node);

        if (scan and auth) return "SCAN,AUTH";
        if (decrypt and analyze and extract) return "DECRYPT,ANALYZE,EXTRACT";
        if (decrypt and analyze) return "DECRYPT,ANALYZE";
        if (decrypt and extract) return "DECRYPT,EXTRACT";
        if (scan) return "SCAN";
        if (auth) return "AUTH";
        if (decrypt) return "DECRYPT";
        if (analyze) return "ANALYZE";
        if (extract) return "EXTRACT";
        return "";
    }
};

const std = @import("std");
