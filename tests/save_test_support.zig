const builtin = @import("builtin");
const std = @import("std");
const save = @import("../src/save.zig");

pub const Dir = if (builtin.zig_version.minor >= 16) std.Io.Dir else std.fs.Dir;

pub fn context(dir: Dir) save.SaveContext {
    if (builtin.zig_version.minor >= 16) {
        return .{ .io = std.testing.io, .dir = dir };
    }
    return .{ .dir = dir };
}

pub fn readSaveFile(dir: Dir, allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    if (builtin.zig_version.minor >= 16) {
        return dir.readFileAlloc(std.testing.io, path, allocator, .limited(4097));
    }
    return dir.readFileAlloc(allocator, path, 4096);
}

pub fn makePath(dir: Dir, path: []const u8) !void {
    if (builtin.zig_version.minor >= 16) {
        try dir.createDirPath(std.testing.io, path);
    } else {
        try dir.makePath(path);
    }
}

pub fn expectMissingFile(dir: Dir, path: []const u8) !void {
    if (builtin.zig_version.minor >= 16) {
        try std.testing.expectError(error.FileNotFound, dir.openFile(std.testing.io, path, .{}));
    } else {
        try std.testing.expectError(error.FileNotFound, dir.openFile(path, .{}));
    }
}
