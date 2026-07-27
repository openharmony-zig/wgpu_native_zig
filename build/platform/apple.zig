const builtin = @import("builtin");
const std = @import("std");
const common = @import("common.zig");
const types = @import("types.zig");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget) types.Config {
    const result = target.result;
    const sdk_root = findSdkRoot(b, result);
    return switch (result.os.tag) {
        .ios => switch (result.cpu.arch) {
            .aarch64 => if (result.abi == .simulator)
                .{
                    .kind = .apple,
                    .target = target,
                    .rust_target = "aarch64-apple-ios-sim",
                    .prebuilt_base = "wgpu_ios_aarch64_simulator",
                    .dynamic_name = "libwgpu_native.dylib",
                    .apple_sdk_root = sdk_root,
                }
            else
                .{
                    .kind = .apple,
                    .target = target,
                    .rust_target = "aarch64-apple-ios",
                    .prebuilt_base = "wgpu_ios_aarch64",
                    .dynamic_name = "libwgpu_native.dylib",
                    .apple_sdk_root = sdk_root,
                },
            .x86_64 => if (result.abi == .simulator)
                .{
                    .kind = .apple,
                    .target = target,
                    .rust_target = "x86_64-apple-ios",
                    .prebuilt_base = "wgpu_ios_x86_64_simulator",
                    .dynamic_name = "libwgpu_native.dylib",
                    .apple_sdk_root = sdk_root,
                }
            else
                common.unsupportedTarget(result),
            else => common.unsupportedTarget(result),
        },
        .macos => switch (result.cpu.arch) {
            .aarch64 => .{
                .kind = .apple,
                .target = target,
                .rust_target = "aarch64-apple-darwin",
                .prebuilt_base = "wgpu_macos_aarch64",
                .dynamic_name = "libwgpu_native.dylib",
                .apple_sdk_root = sdk_root,
            },
            .x86_64 => .{
                .kind = .apple,
                .target = target,
                .rust_target = "x86_64-apple-darwin",
                .prebuilt_base = "wgpu_macos_x86_64",
                .dynamic_name = "libwgpu_native.dylib",
                .apple_sdk_root = sdk_root,
            },
            else => common.unsupportedTarget(result),
        },
        else => common.unsupportedTarget(result),
    };
}

pub fn configureSource(
    _: *std.Build,
    _: *std.Build.Step.Run,
    _: types.Config,
) void {}

pub fn configureModule(
    b: *std.Build,
    config: types.Config,
    mod: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {
    // Explicit Apple targets do not inherit native SDK search paths.
    if (config.apple_sdk_root) |sdk_root| {
        mod.addLibraryPath(.{ .cwd_relative = b.pathJoin(&.{
            sdk_root,
            "usr",
            "lib",
        }) });
        mod.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{
            sdk_root,
            "System",
            "Library",
            "Frameworks",
        }) });
    }
    mod.linkFramework("Foundation", .{});
    mod.linkFramework("QuartzCore", .{});
    mod.linkFramework("Metal", .{});
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

fn findSdkRoot(b: *std.Build, target: std.Target) ?[]const u8 {
    if (b.graph.environ_map.get("SDKROOT")) |sdk_root| {
        if (std.fs.path.isAbsolute(sdk_root)) return sdk_root;
    }
    if (!comptime builtin.os.tag.isDarwin()) return null;
    return std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &target);
}
