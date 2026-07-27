const std = @import("std");
const common = @import("common.zig");
const types = @import("types.zig");

pub fn build(_: *std.Build, target: std.Build.ResolvedTarget) types.Config {
    const result = target.result;
    return switch (result.cpu.arch) {
        .aarch64 => switch (result.abi) {
            .gnu => .{
                .kind = .linux,
                .target = target,
                .rust_target = "aarch64-unknown-linux-gnu",
                .prebuilt_base = "wgpu_linux_aarch64",
            },
            .musl => .{
                .kind = .linux,
                .target = target,
                .rust_target = "aarch64-unknown-linux-musl",
                .prebuilt_base = null,
            },
            else => common.unsupportedTarget(result),
        },
        .x86_64 => switch (result.abi) {
            .gnu => .{
                .kind = .linux,
                .target = target,
                .rust_target = "x86_64-unknown-linux-gnu",
                .prebuilt_base = "wgpu_linux_x86_64",
            },
            .musl => .{
                .kind = .linux,
                .target = target,
                .rust_target = "x86_64-unknown-linux-musl",
                .prebuilt_base = null,
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
    _: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {}

pub fn configureCompile(_: types.Config, _: *std.Build.Step.Compile) void {}

pub fn configureTest(
    _: types.Config,
    _: *std.Build.Module,
    _: std.builtin.LinkMode,
) void {}
