const std = @import("std");

/// Maximum number of independently tracked objectives in one mission run.
pub const max_objectives: usize = 32;

/// Runtime lifecycle of one authored objective.
pub const ObjectiveState = enum {
    undiscovered,
    discovered,
    completed,
    unavailable,
};

/// Action events that can reveal hidden objectives.
pub const DiscoveryAction = enum {
    scan_target,
    authenticate,
    decrypt_file,
    extract_file,
    analyze_metadata,
};

/// A deterministic, fictional in-game condition that reveals an objective.
pub const DiscoveryTrigger = union(enum) {
    node: []const u8,
    file: []const u8,
    action: DiscoveryAction,
};

/// Runtime copy of the objective identity and reward metadata.
pub const ObjectiveProgress = struct {
    id: []const u8 = "",
    kind: u8 = 0,
    optional: bool = false,
    bonus_reward: u32 = 0,
    revealed: bool = false,
    state: ObjectiveState = .undiscovered,
};

/// Fixed-capacity, allocation-free objective state for a single mission run.
pub const Tracker = struct {
    entries: [max_objectives]ObjectiveProgress = [_]ObjectiveProgress{.{}} ** max_objectives,
    count: u8 = 0,

    /// Initializes progress from a catalog slice. Invalid catalogs are rejected atomically.
    pub fn initialize(self: *Tracker, objectives: anytype) bool {
        if (objectives.len > max_objectives) return false;

        var next = Tracker{};
        for (objectives, 0..) |objective, index| {
            if (objective.id.len == 0) return false;
            for (objectives[0..index]) |previous| {
                if (std.mem.eql(u8, previous.id, objective.id)) return false;
            }
            if (objective.hidden) {
                if (!objective.optional) return false;
                const trigger = objective.discovery_trigger orelse return false;
                switch (trigger) {
                    .node => |node_id| {
                        if (node_id.len == 0) return false;
                    },
                    .file => |file_id| {
                        if (file_id.len == 0) return false;
                    },
                    .action => {},
                }
            }

            next.entries[index] = .{
                .id = objective.id,
                .kind = @intCast(@intFromEnum(objective.kind)),
                .optional = objective.optional,
                .bonus_reward = objective.bonus_reward,
                .revealed = !objective.hidden,
                .state = if (objective.hidden) .undiscovered else .discovered,
            };
        }
        next.count = @intCast(objectives.len);
        self.* = next;
        return true;
    }

    /// Reveals objectives matching a reached fictional topology node.
    pub fn discoverNode(self: *Tracker, node_id: []const u8, objectives: anytype) usize {
        return self.discover(.{ .node = node_id }, objectives);
    }

    /// Reveals objectives matching an inspected fictional evidence file.
    pub fn discoverFile(self: *Tracker, file_id: []const u8, objectives: anytype) usize {
        return self.discover(.{ .file = file_id }, objectives);
    }

    /// Reveals objectives matching a successfully completed in-game action.
    pub fn discoverAction(self: *Tracker, action: DiscoveryAction, objectives: anytype) usize {
        return self.discover(.{ .action = action }, objectives);
    }

    fn discover(self: *Tracker, event: DiscoveryTrigger, objectives: anytype) usize {
        if (objectives.len != self.count) return 0;
        for (objectives, 0..) |objective, index| {
            if (!std.mem.eql(u8, self.entries[index].id, objective.id)) return 0;
        }
        var discovered: usize = 0;
        for (0..self.count) |index| {
            if (self.entries[index].state != .undiscovered) continue;
            const trigger = objectives[index].discovery_trigger orelse continue;
            if (triggersMatch(trigger, event)) {
                self.entries[index].state = .discovered;
                self.entries[index].revealed = true;
                discovered += 1;
            }
        }
        return discovered;
    }

    fn triggersMatch(expected: DiscoveryTrigger, actual: DiscoveryTrigger) bool {
        return switch (expected) {
            .node => |id| switch (actual) {
                .node => |actual_id| std.mem.eql(u8, id, actual_id),
                else => false,
            },
            .file => |id| switch (actual) {
                .file => |actual_id| std.mem.eql(u8, id, actual_id),
                else => false,
            },
            .action => |action| switch (actual) {
                .action => |actual_action| action == actual_action,
                else => false,
            },
        };
    }

    /// Reveals one authored hidden optional objective by stable ID.
    /// The catalog identity is checked before mutation and repeated reveals are harmless.
    pub fn revealById(self: *Tracker, id: []const u8, objectives: anytype) bool {
        if (objectives.len != self.count) return false;
        for (objectives, 0..) |objective, index| {
            if (!std.mem.eql(u8, self.entries[index].id, objective.id)) return false;
        }
        for (objectives, 0..) |objective, index| {
            if (!std.mem.eql(u8, objective.id, id)) continue;
            if (!objective.hidden or !objective.optional or self.entries[index].state != .undiscovered) return false;
            self.entries[index].state = .discovered;
            self.entries[index].revealed = true;
            return true;
        }
        return false;
    }

    /// Completes every discovered objective configured for the supplied event kind.
    /// Returns the number of objectives newly completed by this event.
    pub fn complete(self: *Tracker, kind: u8) usize {
        var completed: usize = 0;
        for (self.entries[0..self.count]) |*entry| {
            if (entry.kind == kind and entry.state == .discovered) {
                entry.state = .completed;
                completed += 1;
            }
        }
        return completed;
    }

    /// Marks incomplete optional objectives for an event kind unavailable after that event has passed.
    pub fn markOptionalUnavailableForKind(self: *Tracker, kind: u8) void {
        for (self.entries[0..self.count]) |*entry| {
            if (entry.optional and entry.kind == kind and entry.state != .completed) {
                entry.state = .unavailable;
            }
        }
    }

    /// Marks an objective unavailable for the remainder of this run.
    pub fn markUnavailable(self: *Tracker, id: []const u8) bool {
        for (self.entries[0..self.count]) |*entry| {
            if (std.mem.eql(u8, entry.id, id) and entry.state == .undiscovered) {
                entry.state = .unavailable;
                return true;
            }
        }
        return false;
    }

    /// Returns the full runtime progress for a stable mission-local objective ID.
    pub fn progressOf(self: Tracker, id: []const u8) ?ObjectiveProgress {
        for (self.entries[0..self.count]) |entry| {
            if (std.mem.eql(u8, entry.id, id)) return entry;
        }
        return null;
    }

    /// Returns the state for a stable mission-local objective ID.
    pub fn stateOf(self: Tracker, id: []const u8) ?ObjectiveState {
        for (self.entries[0..self.count]) |entry| {
            if (std.mem.eql(u8, entry.id, id)) return entry.state;
        }
        return null;
    }

    /// Reports whether all required objectives have been completed.
    pub fn allRequiredComplete(self: Tracker) bool {
        for (self.entries[0..self.count]) |entry| {
            if (!entry.optional and entry.state != .completed) return false;
        }
        return true;
    }

    /// Reports whether at least one optional objective exists and all are complete.
    pub fn allOptionalComplete(self: Tracker) bool {
        var found = false;
        for (self.entries[0..self.count]) |entry| {
            if (!entry.optional) continue;
            found = true;
            if (entry.state != .completed) return false;
        }
        return found;
    }

    /// Sums optional cash rewards for objectives completed in this run.
    pub fn optionalReward(self: Tracker) error{RewardOverflow}!u32 {
        var total: u32 = 0;
        for (self.entries[0..self.count]) |entry| {
            if (entry.optional and entry.state == .completed) {
                total = std.math.add(u32, total, entry.bonus_reward) catch return error.RewardOverflow;
            }
        }
        return total;
    }

    /// Clears all objective progress and catalog references.
    pub fn reset(self: *Tracker) void {
        self.* = .{};
    }
};

test "tracker validates capacity identity and hidden objective invariants atomically" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan, analyze },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const valid = [_]Objective{
        .{ .id = "required", .kind = .scan },
        .{ .id = "secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .node = "vault" } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&valid));
    try std.testing.expectEqual(@as(u8, 2), tracker.count);
    try std.testing.expectEqual(ObjectiveState.discovered, tracker.stateOf("required").?);
    try std.testing.expectEqual(ObjectiveState.undiscovered, tracker.stateOf("secret").?);

    const duplicate = [_]Objective{
        .{ .id = "same", .kind = .scan },
        .{ .id = "same", .kind = .analyze },
    };
    try std.testing.expect(!tracker.initialize(&duplicate));
    try std.testing.expectEqual(@as(u8, 2), tracker.count);
    try std.testing.expectEqual(ObjectiveState.undiscovered, tracker.stateOf("secret").?);

    const invalid_hidden = [_]Objective{
        .{ .id = "secret", .kind = .analyze, .hidden = true },
    };
    try std.testing.expect(!tracker.initialize(&invalid_hidden));
    try std.testing.expectEqual(@as(u8, 2), tracker.count);
}

test "node file and action triggers are typed idempotent and independent" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan, analyze },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const objectives = [_]Objective{
        .{ .id = "node-secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .node = "vault" } },
        .{ .id = "file-secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .file = "trace.log" } },
        .{ .id = "action-secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .action = .scan_target } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&objectives));
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverNode("entry", &objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverNode("vault", &objectives));
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverNode("vault", &objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverFile("trace.log", &objectives));
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverFile("other.log", &objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverAction(.scan_target, &objectives));
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverAction(.scan_target, &objectives));
}

test "same event kind completes independently discovered objectives and rewards once" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan, analyze },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const objectives = [_]Objective{
        .{ .id = "visible-analysis", .kind = .analyze, .optional = true, .bonus_reward = 25 },
        .{ .id = "hidden-analysis", .kind = .analyze, .optional = true, .bonus_reward = 50, .hidden = true, .discovery_trigger = .{ .action = .scan_target } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&objectives));
    try std.testing.expectEqual(@as(usize, 1), tracker.discoverAction(.scan_target, &objectives));
    try std.testing.expectEqual(@as(usize, 2), tracker.complete(@intFromEnum(@as(@TypeOf(objectives[0].kind), .analyze))));
    try std.testing.expectEqual(ObjectiveState.completed, tracker.stateOf("visible-analysis").?);
    try std.testing.expectEqual(ObjectiveState.completed, tracker.stateOf("hidden-analysis").?);
    try std.testing.expectEqual(@as(u32, 75), tracker.optionalReward());
    try std.testing.expect(tracker.allOptionalComplete());
    try std.testing.expectEqual(@as(usize, 0), tracker.complete(@intFromEnum(@as(@TypeOf(objectives[0].kind), .analyze))));
}

test "undiscovered optional objectives prevent reputation bonus and can become unavailable" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan, analyze },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const objectives = [_]Objective{
        .{ .id = "required", .kind = .scan },
        .{ .id = "secret", .kind = .analyze, .optional = true, .hidden = true, .discovery_trigger = .{ .file = "secret.log" } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&objectives));
    try std.testing.expect(!tracker.allOptionalComplete());
    try std.testing.expect(!tracker.allRequiredComplete());
    try std.testing.expect(tracker.markUnavailable("secret"));
    try std.testing.expectEqual(ObjectiveState.unavailable, tracker.stateOf("secret").?);
    try std.testing.expect(!tracker.markUnavailable("secret"));
    try std.testing.expect(!tracker.allOptionalComplete());
    try std.testing.expectEqual(@as(u32, 0), tracker.optionalReward());
}

test "tracker rejects catalogs above the 32 objective capacity" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    var too_many: [33]Objective = undefined;
    for (&too_many, 0..) |*objective, index| {
        objective.* = .{ .id = if (index == 0) "objective-0" else "objective", .kind = .scan };
    }
    var tracker = Tracker{};
    try std.testing.expect(!tracker.initialize(&too_many));
    try std.testing.expectEqual(@as(u8, 0), tracker.count);
}

test "tracker accepts exactly 32 independently identified objectives" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    var ids: [32][16]u8 = undefined;
    var catalog: [32]Objective = undefined;
    for (&catalog, 0..) |*objective, index| {
        const id = try std.fmt.bufPrint(&ids[index], "objective-{d}", .{index});
        objective.* = .{ .id = id, .kind = .scan };
    }
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&catalog));
    try std.testing.expectEqual(@as(u8, 32), tracker.count);
}

test "one-shot event completion makes undiscovered matching optional objectives unavailable" {
    const Objective = struct {
        id: []const u8,
        kind: enum { scan },
        optional: bool = false,
        bonus_reward: u32 = 0,
        hidden: bool = false,
        discovery_trigger: ?DiscoveryTrigger = null,
    };
    const catalog = [_]Objective{
        .{ .id = "visible-scan", .kind = .scan },
        .{ .id = "late-scan", .kind = .scan, .optional = true, .hidden = true, .discovery_trigger = .{ .file = "late.log" } },
    };
    var tracker = Tracker{};
    try std.testing.expect(tracker.initialize(&catalog));
    try std.testing.expectEqual(@as(usize, 1), tracker.complete(0));
    tracker.markOptionalUnavailableForKind(0);
    try std.testing.expectEqual(ObjectiveState.completed, tracker.stateOf("visible-scan").?);
    try std.testing.expectEqual(ObjectiveState.unavailable, tracker.stateOf("late-scan").?);
    try std.testing.expectEqual(@as(usize, 0), tracker.discoverFile("late.log", &catalog));
}
