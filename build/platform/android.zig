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
    const toolchain_root = toolchainRoot(b, config);
    const api_level = apiLevel(b, config);
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
    b: *std.Build,
    config: types.Config,
    mod: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {
    // Zig does not bundle an Android libc. Link the NDK runtime and platform
    // stubs directly instead of requesting Zig's libc/libc++ builds.
    mod.link_libc = false;
    mod.link_libcpp = false;

    const target_library_dir: std.Build.LazyPath = .{
        .cwd_relative = b.pathJoin(&.{
            toolchainRoot(b, config),
            "sysroot",
            "usr",
            "lib",
            systemIncludeTarget(config),
        }),
    };
    const platform_library_dir = target_library_dir.path(
        b,
        apiLevel(b, config),
    );
    mod.addLibraryPath(target_library_dir);
    mod.addLibraryPath(platform_library_dir);

    mod.addObjectFile(target_library_dir.path(b, "libc++_static.a"));
    mod.addObjectFile(target_library_dir.path(b, "libc++abi.a"));
    inline for ([_][]const u8{
        "libc.so",
        "libm.so",
        "libdl.so",
        "libandroid.so",
        "liblog.so",
    }) |library| {
        mod.addObjectFile(platform_library_dir.path(b, library));
    }
}

pub fn configureTranslateC(
    config: types.Config,
    translate_c: *std.Build.Step.TranslateC,
) void {
    const b = translate_c.step.owner;
    const sysroot = b.pathJoin(&.{ toolchainRoot(b, config), "sysroot" });
    translate_c.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
        sysroot,
        "usr",
        "include",
    }) });
    translate_c.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
        sysroot,
        "usr",
        "include",
        systemIncludeTarget(config),
    }) });
}

pub fn configureCompile(_: types.Config, _: *std.Build.Step.Compile) void {}

pub fn configureTest(
    _: types.Config,
    _: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {}

fn toolchainRoot(b: *std.Build, config: types.Config) []const u8 {
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
    return b.pathJoin(&.{
        ndk_root,
        "toolchains",
        "llvm",
        "prebuilt",
        host_dir,
    });
}

fn apiLevel(b: *std.Build, config: types.Config) []const u8 {
    return b.graph.environ_map.get("ANDROID_API_LEVEL") orelse b.fmt(
        "{d}",
        .{config.target.result.os.version_range.linux.android},
    );
}

fn systemIncludeTarget(config: types.Config) []const u8 {
    return switch (config.target.result.cpu.arch) {
        .aarch64 => "aarch64-linux-android",
        .arm => "arm-linux-androideabi",
        .x86 => "i686-linux-android",
        .x86_64 => "x86_64-linux-android",
        else => unreachable,
    };
}
