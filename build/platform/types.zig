const std = @import("std");

pub const Kind = enum {
    android,
    apple,
    linux,
    ohos,
    windows,
};

pub const Config = struct {
    kind: Kind,
    target: std.Build.ResolvedTarget,
    rust_target: []const u8,
    prebuilt_base: ?[]const u8,
    static_name: []const u8 = "libwgpu_native.a",
    dynamic_name: []const u8 = "libwgpu_native.so",
    dynamic_import_name: ?[]const u8 = null,
    clang_target: ?[]const u8 = null,
    ohos_library_target: ?[]const u8 = null,
};
