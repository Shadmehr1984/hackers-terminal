const std = @import("std");
const objectives = @import("../src/domain/mission_objectives.zig");

test "tracker has fixed capacity" {
    try std.testing.expectEqual(@as(usize, 32), objectives.max_objectives);
}
