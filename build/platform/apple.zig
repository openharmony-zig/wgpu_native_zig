const std = @import("std");
const common = @import("common.zig");
const types = @import("types.zig");

pub fn build(_: *std.Build, target: std.Build.ResolvedTarget) types.Config {
    const result = target.result;
    return switch (result.os.tag) {
        .ios => switch (result.cpu.arch) {
            .aarch64 => if (result.abi == .simulator)
                .{
                    .kind = .apple,
                    .target = target,
                    .rust_target = "aarch64-apple-ios-sim",
                    .prebuilt_base = "wgpu_ios_aarch64_simulator",
                    .dynamic_name = "libwgpu_native.dylib",
                }
            else
                .{
                    .kind = .apple,
                    .target = target,
                    .rust_target = "aarch64-apple-ios",
                    .prebuilt_base = "wgpu_ios_aarch64",
                    .dynamic_name = "libwgpu_native.dylib",
                },
            .x86_64 => if (result.abi == .simulator)
                .{
                    .kind = .apple,
                    .target = target,
                    .rust_target = "x86_64-apple-ios",
                    .prebuilt_base = "wgpu_ios_x86_64_simulator",
                    .dynamic_name = "libwgpu_native.dylib",
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
            },
            .x86_64 => .{
                .kind = .apple,
                .target = target,
                .rust_target = "x86_64-apple-darwin",
                .prebuilt_base = "wgpu_macos_x86_64",
                .dynamic_name = "libwgpu_native.dylib",
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
    _: *std.Build,
    _: types.Config,
    mod: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {
    mod.linkFramework("Foundation", .{});
    mod.linkFramework("QuartzCore", .{});
    mod.linkFramework("Metal", .{});
}

pub fn configureCompile(_: types.Config, _: *std.Build.Step.Compile) void {}

pub fn configureTest(
    _: types.Config,
    _: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {}
