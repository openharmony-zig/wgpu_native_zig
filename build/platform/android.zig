const std = @import("std");
const common = @import("common.zig");
const types = @import("types.zig");

pub fn build(_: *std.Build, target: std.Build.ResolvedTarget) types.Config {
    const result = target.result;
    return switch (result.cpu.arch) {
        .aarch64 => .{
            .kind = .android,
            .target = target,
            .rust_target = "aarch64-linux-android",
            .prebuilt_base = "wgpu_android_aarch64",
            .clang_target = "aarch64-linux-android",
        },
        .arm => .{
            .kind = .android,
            .target = target,
            .rust_target = "armv7-linux-androideabi",
            .prebuilt_base = "wgpu_android_armv7",
            .clang_target = "armv7a-linux-androideabi",
        },
        .x86 => .{
            .kind = .android,
            .target = target,
            .rust_target = "i686-linux-android",
            .prebuilt_base = "wgpu_android_x86",
            .clang_target = "i686-linux-android",
        },
        .x86_64 => .{
            .kind = .android,
            .target = target,
            .rust_target = "x86_64-linux-android",
            .prebuilt_base = "wgpu_android_x86_64",
            .clang_target = "x86_64-linux-android",
        },
        else => common.unsupportedTarget(result),
    };
}

pub fn configureSource(
    b: *std.Build,
    cargo: *std.Build.Step.Run,
    config: types.Config,
) void {
    const ndk_root = b.graph.environ_map.get("ANDROID_NDK_HOME") orelse
        b.graph.environ_map.get("ANDROID_NDK_ROOT") orelse
        std.debug.panic(
            "Building {s} requires ANDROID_NDK_HOME or ANDROID_NDK_ROOT",
            .{config.rust_target},
        );
    const host_dir = switch (b.graph.host.result.os.tag) {
        .linux => "linux-x86_64",
        .macos => "darwin-x86_64",
        .windows => "windows-x86_64",
        else => std.debug.panic("Unsupported Android NDK host", .{}),
    };
    const toolchain_root = b.pathJoin(&.{
        ndk_root,
        "toolchains",
        "llvm",
        "prebuilt",
        host_dir,
    });
    const api_level = b.graph.environ_map.get("ANDROID_API_LEVEL") orelse "21";
    const clang_target = config.clang_target.?;
    const linker = b.pathJoin(&.{
        toolchain_root,
        "bin",
        b.fmt("{s}{s}-clang", .{ clang_target, api_level }),
    });
    common.configureCargoLinker(
        b,
        cargo,
        config.rust_target,
        linker,
        b.fmt("{s}++", .{linker}),
    );
    common.configureBindgen(
        b,
        cargo,
        clang_target,
        b.pathJoin(&.{ toolchain_root, "sysroot" }),
    );
}

pub fn configureModule(
    _: *std.Build,
    _: types.Config,
    _: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {}

pub fn configureTranslateC(
    _: types.Config,
    _: *std.Build.Step.TranslateC,
) void {}

pub fn configureCompile(_: types.Config, _: *std.Build.Step.Compile) void {}

pub fn configureTest(
    _: types.Config,
    _: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {}
