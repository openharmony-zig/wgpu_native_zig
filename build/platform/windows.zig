const std = @import("std");
const common = @import("common.zig");
const types = @import("types.zig");

pub fn build(_: *std.Build, target: std.Build.ResolvedTarget) types.Config {
    const result = target.result;
    return switch (result.cpu.arch) {
        .aarch64 => if (result.abi == .msvc)
            .{
                .kind = .windows,
                .target = target,
                .rust_target = "aarch64-pc-windows-msvc",
                .prebuilt_base = "wgpu_windows_aarch64_msvc",
                .static_name = "wgpu_native.lib",
                .dynamic_name = "wgpu_native.dll",
                .dynamic_import_name = "wgpu_native.dll.lib",
            }
        else
            common.unsupportedTarget(result),
        .x86 => switch (result.abi) {
            .msvc => .{
                .kind = .windows,
                .target = target,
                .rust_target = "i686-pc-windows-msvc",
                .prebuilt_base = "wgpu_windows_x86_msvc",
                .static_name = "wgpu_native.lib",
                .dynamic_name = "wgpu_native.dll",
                .dynamic_import_name = "wgpu_native.dll.lib",
            },
            .gnu => .{
                .kind = .windows,
                .target = target,
                .rust_target = "i686-pc-windows-gnu",
                .prebuilt_base = null,
                .dynamic_name = "wgpu_native.dll",
                .dynamic_import_name = "libwgpu_native.dll.a",
            },
            else => common.unsupportedTarget(result),
        },
        .x86_64 => switch (result.abi) {
            .msvc => .{
                .kind = .windows,
                .target = target,
                .rust_target = "x86_64-pc-windows-msvc",
                .prebuilt_base = "wgpu_windows_x86_64_msvc",
                .static_name = "wgpu_native.lib",
                .dynamic_name = "wgpu_native.dll",
                .dynamic_import_name = "wgpu_native.dll.lib",
            },
            .gnu => .{
                .kind = .windows,
                .target = target,
                .rust_target = "x86_64-pc-windows-gnu",
                .prebuilt_base = "wgpu_windows_x86_64_gnu",
                .dynamic_name = "wgpu_native.dll",
                .dynamic_import_name = "libwgpu_native.dll.a",
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
    config: types.Config,
    mod: *std.Build.Module,
    link_mode: std.builtin.LinkMode,
) void {
    const is_gnu = config.target.result.abi == .gnu;
    if (!is_gnu) {
        mod.link_libcpp = false;
        mod.link_libc = true;
    }
    if (link_mode == .static) linkSystemLibraries(mod, is_gnu);
}

pub fn configureTranslateC(
    config: types.Config,
    translate_c: *std.Build.Step.TranslateC,
) void {
    if (config.target.result.abi == .msvc) {
        // Zig 0.16 translate-c does not accept MSVC's `ui64` literal suffix.
        // stdint.h guards SIZE_MAX, so define it using the portable builtin.
        translate_c.defineCMacro("SIZE_MAX", "__SIZE_MAX__");
    }
}

pub fn configureCompile(
    config: types.Config,
    compile: *std.Build.Step.Compile,
) void {
    if (config.target.result.abi == .msvc) {
        compile.bundle_compiler_rt = false;
        compile.bundle_ubsan_rt = false;
    }
}

pub fn configureTest(
    config: types.Config,
    mod: *std.Build.Module,
    link_mode: std.builtin.LinkMode,
) void {
    if (link_mode == .static and config.target.result.abi == .gnu) {
        mod.linkSystemLibrary("unwind", .{});
    }
}

fn linkSystemLibraries(mod: *std.Build.Module, is_gnu: bool) void {
    if (is_gnu) {
        mod.linkSystemLibrary("d3dcompiler_47", .{});
        mod.linkSystemLibrary("api-ms-win-core-winrt-error-l1-1-0", .{});
    } else {
        mod.linkSystemLibrary("d3dcompiler", .{});
        mod.linkSystemLibrary("user32", .{});
        mod.linkSystemLibrary("RuntimeObject", .{});
    }
    mod.linkSystemLibrary("opengl32", .{});
    mod.linkSystemLibrary("gdi32", .{});
    mod.linkSystemLibrary("OleAut32", .{});
    mod.linkSystemLibrary("Ole32", .{});
    mod.linkSystemLibrary("ws2_32", .{});
    mod.linkSystemLibrary("userenv", .{});
    mod.linkSystemLibrary("propsys", .{});
}
