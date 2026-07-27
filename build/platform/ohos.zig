const std = @import("std");
const common = @import("common.zig");
const types = @import("types.zig");

pub fn build(_: *std.Build, target: std.Build.ResolvedTarget) types.Config {
    const result = target.result;
    return switch (result.cpu.arch) {
        .aarch64 => .{
            .kind = .ohos,
            .target = target,
            .rust_target = "aarch64-unknown-linux-ohos",
            .prebuilt_base = null,
            .clang_target = "aarch64-unknown-linux-ohos",
            .ohos_library_target = "aarch64-linux-ohos",
        },
        .arm => .{
            .kind = .ohos,
            .target = target,
            .rust_target = "armv7-unknown-linux-ohos",
            .prebuilt_base = null,
            .clang_target = "armv7-unknown-linux-ohos",
            .ohos_library_target = "arm-linux-ohos",
        },
        .x86_64 => .{
            .kind = .ohos,
            .target = target,
            .rust_target = "x86_64-unknown-linux-ohos",
            .prebuilt_base = null,
            .clang_target = "x86_64-unknown-linux-ohos",
            .ohos_library_target = "x86_64-linux-ohos",
        },
        else => common.unsupportedTarget(result),
    };
}

pub fn configureSource(
    b: *std.Build,
    cargo: *std.Build.Step.Run,
    config: types.Config,
) void {
    const native_root = nativeRoot(b, config);
    const clang_target = config.clang_target.?;
    const linker = b.pathJoin(&.{
        native_root,
        "llvm",
        "bin",
        b.fmt("{s}-clang", .{clang_target}),
    });
    const cxx = b.pathJoin(&.{
        native_root,
        "llvm",
        "bin",
        b.fmt("{s}-clang++", .{clang_target}),
    });
    common.configureCargoLinker(b, cargo, config.rust_target, linker, cxx);
    common.configureBindgen(
        b,
        cargo,
        clang_target,
        b.pathJoin(&.{ native_root, "sysroot" }),
    );
}

pub fn configureModule(
    b: *std.Build,
    config: types.Config,
    mod: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {
    const library_dir: std.Build.LazyPath = .{ .cwd_relative = b.pathJoin(&.{
        nativeRoot(b, config),
        "sysroot",
        "usr",
        "lib",
        config.ohos_library_target.?,
    }) };
    mod.addLibraryPath(library_dir);
    mod.linkSystemLibrary("c", .{});
    mod.addObjectFile(library_dir.path(b, "libc.so"));
}

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

fn nativeRoot(b: *std.Build, config: types.Config) []const u8 {
    const sdk_root = b.graph.environ_map.get("OHOS_NDK_HOME") orelse
        b.graph.environ_map.get("OHOS_SDK_HOME") orelse
        std.debug.panic(
            "Building {s} requires OHOS_NDK_HOME or OHOS_SDK_HOME",
            .{config.rust_target},
        );
    return if (std.mem.eql(u8, std.fs.path.basename(sdk_root), "native"))
        sdk_root
    else
        b.pathJoin(&.{ sdk_root, "native" });
}
