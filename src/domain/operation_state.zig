const std = @import("std");
const operation_model = @import("operation.zig");
const Operation = operation_model.Operation;
const OperationFact = operation_model.OperationFact;

/// Runtime-only, allocation-free state for one active linear operation.
pub const OperationState = struct {
    active: bool = false,
    operation_id: []const u8 = "",
    stage_index: u8 = 0,
    facts: u8 = 0,
    current_stage_reward_eligible: bool = false,
    last_completed_operation_id: []const u8 = "",

    /// Starts an operation after its catalog and progression requirements are validated.
    pub fn start(self: *OperationState, operation: Operation, reward_eligible: bool) bool {
        if (self.active or operation.stages.len == 0 or operation.stages.len > operation_model.max_operation_stages) return false;
        self.active = true;
        self.operation_id = operation.id;
        self.stage_index = 0;
        self.facts = 0;
        self.current_stage_reward_eligible = reward_eligible;
        self.last_completed_operation_id = "";
        return true;
    }

    /// Returns whether a typed fact has been earned in this process.
    pub fn hasFact(self: OperationState, fact: OperationFact) bool {
        return (self.facts & (@as(u8, 1) << @intFromEnum(fact))) != 0;
    }

    /// Grants a typed fact. Repeated grants are harmless.
    pub fn grantFact(self: *OperationState, fact: OperationFact) void {
        self.facts |= @as(u8, 1) << @intFromEnum(fact);
    }

    /// Advances exactly one successful stage, or records final completion.
    pub fn advance(self: *OperationState, operation: Operation, next_reward_eligible: bool) bool {
        if (!self.active or !std.mem.eql(u8, self.operation_id, operation.id) or
            self.stage_index >= operation.stages.len) return false;
        if (@as(usize, self.stage_index) + 1 >= operation.stages.len) {
            self.active = false;
            self.last_completed_operation_id = self.operation_id;
            self.operation_id = "";
            self.stage_index = 0;
            self.current_stage_reward_eligible = false;
            return true;
        }
        self.stage_index += 1;
        self.current_stage_reward_eligible = next_reward_eligible;
        return false;
    }

    /// Clears transient operation progress while retaining no completion marker.
    pub fn reset(self: *OperationState) void {
        self.* = .{};
    }

    /// Returns the current stage, or null when the state is inactive/invalid.
    pub fn currentStage(self: OperationState, operation: Operation) ?operation_model.OperationStage {
        if (!self.active or !std.mem.eql(u8, self.operation_id, operation.id) or
            self.stage_index >= operation.stages.len) return null;
        return operation.stages[self.stage_index];
    }
};
