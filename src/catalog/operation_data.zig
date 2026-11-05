const operation_model = @import("../domain/operation.zig");
const Operation = operation_model.Operation;
const OperationStage = operation_model.OperationStage;
const OperationFact = operation_model.OperationFact;

/// The first authored three-contract operation.
pub const blackout_protocol = Operation{
    .id = "blackout-protocol",
    .name = "Blackout Protocol",
    .description = "Trace a concealed maintenance signature through an archive and relay chain.",
    .stages = &.{
        .{
            .mission_id = "job-01",
            .outgoing = .{ .fact = .maintenance_telemetry, .objective_id = "maintenance-telemetry" },
        },
        .{
            .mission_id = "job-02",
            .incoming = .{ .fact = .maintenance_telemetry, .objective_id = "routing-header" },
            .outgoing = .{ .fact = .routing_header, .objective_id = "routing-header" },
        },
        .{
            .mission_id = "job-03",
            .incoming = .{ .fact = .routing_header, .objective_id = "relay-trace" },
        },
    },
};

/// Returns the static operation catalog.
pub fn all() []const Operation {
    return &.{blackout_protocol};
}

/// Finds an operation by its stable command ID.
pub fn find(id: []const u8) ?Operation {
    for (all()) |operation| {
        if (@import("std").mem.eql(u8, operation.id, id)) return operation;
    }
    return null;
}
