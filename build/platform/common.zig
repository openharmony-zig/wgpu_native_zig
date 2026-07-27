const std = @import("std");

pub fn configureCargoLinker(
    b: *std.Build,
    cargo: *std.Build.Step.Run,
    rust_target: []const u8,
    linker: []const u8,
    cxx: []const u8,
) void {
    const cargo_target = envTargetName(b, rust_target, true);
    const cc_target = envTargetName(b, rust_target, false);
    cargo.setEnvironmentVariable(
        b.fmt("CARGO_TARGET_{s}_LINKER", .{cargo_target}),
        linker,
    );
    cargo.setEnvironmentVariable(b.fmt("CC_{s}", .{cc_target}), linker);
    cargo.setEnvironmentVariable(b.fmt("CXX_{s}", .{cc_target}), cxx);
}

pub fn configureBindgen(
    b: *std.Build,
    cargo: *std.Build.Step.Run,
    clang_target: []const u8,
    sysroot: []const u8,
) void {
    const existing = b.graph.environ_map.get("BINDGEN_EXTRA_CLANG_ARGS");
    const args = if (existing) |value|
        b.fmt("{s} --target={s} --sysroot={s}", .{ value, clang_target, sysroot })
    else
        b.fmt("--target={s} --sysroot={s}", .{ clang_target, sysroot });
    cargo.setEnvironmentVariable("BINDGEN_EXTRA_CLANG_ARGS", args);
}

pub fn unsupportedTarget(target: std.Target) noreturn {
    std.debug.panic(
        "wgpu-native source builds do not support {s}-{s}-{s}",
        .{
            @tagName(target.cpu.arch),
            @tagName(target.os.tag),
            @tagName(target.abi),
        },
    );
}

fn envTargetName(
    b: *std.Build,
    target: []const u8,
    uppercase: bool,
) []const u8 {
    const result = b.allocator.dupe(u8, target) catch @panic("OOM");
    for (result) |*character| {
        if (character.* == '-') {
            character.* = '_';
        } else if (uppercase) {
            character.* = std.ascii.toUpper(character.*);
        }
    }
    return result;
}
