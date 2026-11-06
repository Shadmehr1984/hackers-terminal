const builtin = @import("builtin");
const std = @import("std");
const ModifierId = @import("../src/domain/mission_modifier.zig").ModifierId;

test "exactly three stable modifier command IDs are defined" {
    const field_count = if (comptime builtin.zig_version.minor >= 16) @typeInfo(ModifierId).@"enum".field_names.len else @typeInfo(ModifierId).Enum.fields.len;
    try std.testing.expectEqual(@as(usize, 3), field_count);
    try std.testing.expectEqualStrings("heightened-monitoring", ModifierId.heightened_monitoring.commandId());
    try std.testing.expectEqualStrings("security-sweep", ModifierId.security_sweep.commandId());
    try std.testing.expectEqualStrings("hardened-encryption", ModifierId.hardened_encryption.commandId());
    try std.testing.expect(ModifierId.fromCommandId("unknown") == null);
}

test "modifier command IDs resolve without accepting aliases" {
    try std.testing.expectEqual(ModifierId.heightened_monitoring, ModifierId.fromCommandId("heightened-monitoring").?);
    try std.testing.expectEqual(ModifierId.security_sweep, ModifierId.fromCommandId("security-sweep").?);
    try std.testing.expectEqual(ModifierId.hardened_encryption, ModifierId.fromCommandId("hardened-encryption").?);
    try std.testing.expect(ModifierId.fromCommandId("Security-Sweep") == null);
}

test "heightened monitoring exposes the approved traversal surcharge" {
    const effect = ModifierId.heightened_monitoring.detectionEffect();
    try std.testing.expectEqual(.successful_traversal_surcharge, effect.kind);
    try std.testing.expectEqual(@as(u8, 2), effect.amount);
    try std.testing.expectEqual(@as(u8, 0), effect.cadence);
}

test "security sweep exposes the approved cadence and detection amount" {
    const effect = ModifierId.security_sweep.detectionEffect();
    try std.testing.expectEqual(.successful_traversal_cadence, effect.kind);
    try std.testing.expectEqual(@as(u8, 8), effect.amount);
    try std.testing.expectEqual(@as(u8, 3), effect.cadence);
}

test "hardened encryption exposes the approved incorrect decryption cost" {
    const effect = ModifierId.hardened_encryption.detectionEffect();
    try std.testing.expectEqual(.incorrect_decryption_cost, effect.kind);
    try std.testing.expectEqual(@as(u8, 15), effect.amount);
}

test "all modifiers share the approved completion bonus and disclose effects" {
    if (comptime builtin.zig_version.minor >= 16) {
        const enum_info = @typeInfo(ModifierId).@"enum";
        inline for (enum_info.field_values) |field_value| {
            const id: ModifierId = @fromBackingInt(@intCast(field_value));
            const bonus = id.completionBonus();
            try std.testing.expectEqual(@as(u32, 50), bonus.cash);
            try std.testing.expectEqual(@as(u32, 25), bonus.xp);
            try std.testing.expect(id.label().len > 0);
            try std.testing.expect(id.description().len > 0);
        }
    } else {
        inline for (@typeInfo(ModifierId).Enum.fields) |field| {
            const id: ModifierId = @enumFromInt(field.value);
            const bonus = id.completionBonus();
            try std.testing.expectEqual(@as(u32, 50), bonus.cash);
            try std.testing.expectEqual(@as(u32, 25), bonus.xp);
            try std.testing.expect(id.label().len > 0);
            try std.testing.expect(id.description().len > 0);
        }
    }
}
