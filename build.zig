const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Keep the current 0.13.0 CI baseline usable while the rest of the
    // repository is migrated. Zig 0.15+ requires an explicit root module.
    const exe = if (builtin.zig_version.minor >= 17)
        b.addExecutable(.{
            .name = "hackers-terminal",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
            }),
        })
    else
        b.addExecutable(.{
            .name = "hackers-terminal",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (builtin.zig_version.minor >= 17) {
        run_cmd.addPassthruArgs();
    } else if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run Hacker's Terminal");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = if (builtin.zig_version.minor >= 17)
        b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("test_root.zig"),
                .target = target,
                .optimize = optimize,
            }),
        })
    else
        b.addTest(.{
            .root_source_file = b.path("test_root.zig"),
            .target = target,
            .optimize = optimize,
        });

    const run_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run the Hacker's Terminal test suite");
    test_step.dependOn(&run_tests.step);
}
