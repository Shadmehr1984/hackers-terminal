const std = @import("std");
const Mission = @import("mission.zig").Mission;

/// Maximum number of contract stages in one authored operation.
pub const max_operation_stages: usize = 8;

/// Bounded, typed facts that may cross successful operation-stage boundaries.
pub const OperationFact = enum(u3) {
    maintenance_telemetry,
    routing_header,
};

/// A fact that reveals one authored hidden optional objective at the next stage.
pub const IncomingFact = struct {
    fact: OperationFact,
    objective_id: []const u8,
};

/// A completed optional objective that grants a fact after its stage succeeds.
pub const OutgoingFact = struct {
    fact: OperationFact,
    objective_id: []const u8,
};

/// One existing contract referenced by an operation's ordered stage list.
pub const OperationStage = struct {
    mission_id: []const u8,
    incoming: ?IncomingFact = null,
    outgoing: ?OutgoingFact = null,
};

/// Static, linear operation definition. Stage references must be unique.
pub const Operation = struct {
    id: []const u8,
    name: []const u8,
    description: []const u8,
    stages: []const OperationStage,

    /// Validates the operation against the supplied mission catalog.
    pub fn validate(self: Operation, missions: []const Mission) bool {
        if (self.id.len == 0 or self.name.len == 0 or self.stages.len == 0 or
            self.stages.len > max_operation_stages) return false;

        for (self.stages, 0..) |stage, index| {
            if (stage.mission_id.len == 0) return false;
            for (self.stages[0..index]) |previous| {
                if (std.mem.eql(u8, previous.mission_id, stage.mission_id)) return false;
            }

            if (stage.incoming) |incoming| {
                if (index == 0) return false;
                const previous_outgoing = self.stages[index - 1].outgoing orelse return false;
                if (previous_outgoing.fact != incoming.fact) return false;
            }
            const mission = findMission(missions, stage.mission_id) orelse return false;
            if (stage.incoming) |incoming| {
                if (!hasHiddenOptionalObjective(mission, incoming.objective_id)) return false;
            }
            if (stage.outgoing) |outgoing| {
                if (!hasHiddenOptionalObjective(mission, outgoing.objective_id)) return false;
            }
        }
        return true;
    }
};

/// Looks up a mission by its stable catalog ID.
pub fn findMission(missions: []const Mission, id: []const u8) ?Mission {
    for (missions) |mission| {
        if (std.mem.eql(u8, mission.id, id)) return mission;
    }
    return null;
}

fn hasHiddenOptionalObjective(mission: Mission, id: []const u8) bool {
    for (mission.objectives) |objective| {
        if (std.mem.eql(u8, objective.id, id)) return objective.optional and objective.hidden;
    }
    return false;
}
