const std = @import("std");
const save = @import("../src/save.zig");

pub const Dir = std.Io.Dir;

pub fn context(dir: Dir) save.SaveContext {
    return .{ .io = std.testing.io, .dir = dir };
}

pub fn readSaveFile(dir: Dir, allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return dir.readFileAlloc(std.testing.io, path, allocator, .limited(4097));
}

pub fn makePath(dir: Dir, path: []const u8) !void {
    try dir.createDirPath(std.testing.io, path);
}

pub fn expectMissingFile(dir: Dir, path: []const u8) !void {
    try std.testing.expectError(error.FileNotFound, dir.openFile(std.testing.io, path, .{}));
}
