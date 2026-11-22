const std = @import("std");

const project_name = "Zig8";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const submodules = .{
        .hardware = b.addModule("hardware", .{
            .root_source_file = b.path("src/hardware/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .fenster = b.addModule("fenster", .{
            .root_source_file = b.path("src/fenster/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    };

    submodules.hardware.addImport("fenster", submodules.fenster);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    inline for (@typeInfo(@TypeOf(submodules)).@"struct".field_names) |field_name| {
        exe_mod.addImport(field_name, @field(submodules, field_name));
    }

    // Compile fenster.c directly as C (fast, avoids translate-c hang)
    exe_mod.addCSourceFile(.{
        .file = b.path("src/fenster/fenster.c"),
        .flags = &.{},
    });
    exe_mod.addIncludePath(b.path("src"));

    // Link OS-specific windowing libraries
    switch (target.result.os.tag) {
        .windows => {
            exe_mod.linkSystemLibrary("gdi32", .{});
            exe_mod.linkSystemLibrary("winmm", .{});
        },
        .macos => {
            exe_mod.linkFramework("Cocoa", .{});
            exe_mod.linkFramework("AudioToolbox", .{});
        },
        .linux => {
            exe_mod.linkSystemLibrary("X11", .{});
            exe_mod.linkSystemLibrary("asound", .{});
        },
        else => {},
    }

    const exe = b.addExecutable(.{
        .name = project_name,
        .root_module = exe_mod,
    });

    if (target.result.os.tag == .windows) {
        exe.subsystem = .windows;
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}
