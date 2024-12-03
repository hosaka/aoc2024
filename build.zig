const std = @import("std");

const required_zig_version = std.SemanticVersion.parse("0.13.0") catch unreachable;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    if (comptime @import("builtin").zig_version.order(required_zig_version) == .lt) {
        std.debug.print("Your version of Zig is too old. Install at least 0.13.0\n", .{});
        std.os.exit(1);
    }

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const install_all = b.step("install_all", "Install all days");
    const run_all = b.step("run_all", "Run all days");

    comptime var day: usize = 1;
    inline while (day <= 25) : (day += 1) {
        const day_name = b.fmt("day{:0>2}", .{day});
        const day_src = b.fmt("{s}/main.zig", .{day_name});
        const exe = b.addExecutable(.{ .name = day_name, .root_source_file = b.path(day_src), .target = target, .optimize = optimize });

        const install_cmd = b.addInstallArtifact(exe, .{});

        const build_test = b.addTest(.{ .root_source_file = b.path(day_src), .target = target, .optimize = optimize });

        const run_test = b.addRunArtifact(build_test);

        {
            const step_key = b.fmt("install_{s}", .{day_name});
            const step_desc = b.fmt("Install {s} exe", .{day_name});
            const install_step = b.step(step_key, step_desc);
            install_step.dependOn(&install_cmd.step);
            install_all.dependOn(&install_cmd.step);
        }
        {
            const step_key = b.fmt("test_{s}", .{day_name});
            const step_desc = b.fmt("Run tests in {s}", .{day_name});
            const test_step = b.step(step_key, step_desc);
            test_step.dependOn(&run_test.step);
        }

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_desc = b.fmt("Run {s}", .{day_name});
        const run_step = b.step(day_name, run_desc);
        run_step.dependOn(&run_cmd.step);
        run_all.dependOn(&run_cmd.step);
    }

    const test_all = b.step("test", "Run all tests");
    const all_tests = b.addTest(.{ .root_source_file = b.path("tests.zig"), .target = target, .optimize = optimize });
    const run_all_tests = b.addRunArtifact(all_tests);
    test_all.dependOn(&run_all_tests.step);
}
