const std = @import("std");
const Platform = @import("platform/root.zig");

pub const Result = struct {
    header: std.Build.LazyPath,
    webgpu_header: std.Build.LazyPath,
    library_dir: std.Build.LazyPath,
    link_library: ?std.Build.LazyPath,
    runtime_library: ?std.Build.LazyPath,
    static_library: std.Build.LazyPath,
    static_name: []const u8,
    dynamic_library: std.Build.LazyPath,
    dynamic_name: []const u8,
    dynamic_import_library: ?std.Build.LazyPath,
    dynamic_import_name: ?[]const u8,
};

pub fn build(
    b: *std.Build,
    platform: Platform.Config,
    optimize: std.builtin.OptimizeMode,
    link_mode: std.builtin.LinkMode,
    use_prebuilt: bool,
) ?Result {
    const local_prebuilt_dir = b.graph.environ_map.get("WGPU_NATIVE_PREBUILT_DIR");
    if (use_prebuilt or local_prebuilt_dir != null) {
        return buildPrebuilt(
            b,
            platform,
            optimize,
            link_mode,
            local_prebuilt_dir,
        );
    }
    return buildSource(b, platform, optimize, link_mode);
}

fn buildPrebuilt(
    b: *std.Build,
    platform: Platform.Config,
    optimize: std.builtin.OptimizeMode,
    link_mode: std.builtin.LinkMode,
    local_prebuilt_dir: ?[]const u8,
) ?Result {
    const root: std.Build.LazyPath = if (local_prebuilt_dir) |path|
        .{ .cwd_relative = b.dupePath(path) }
    else blk: {
        const base = platform.prebuilt_base orelse std.debug.panic(
            "No published wgpu-native archive exists for {s}; unset WGPU_NATIVE_USE_PREBUILT or provide WGPU_NATIVE_PREBUILT_DIR",
            .{platform.rust_target},
        );
        const mode = if (optimize == .Debug) "debug" else "release";
        const dependency_name = b.fmt("{s}_{s}", .{ base, mode });
        const dependency = b.lazyDependency(dependency_name, .{}) orelse return null;
        break :blk dependency.path("");
    };

    return artifactFromPaths(
        b,
        platform,
        link_mode,
        root.path(b, "lib"),
        root.path(b, "include/webgpu/wgpu.h"),
        root.path(b, "include/webgpu/webgpu.h"),
    );
}

fn buildSource(
    b: *std.Build,
    platform: Platform.Config,
    optimize: std.builtin.OptimizeMode,
    link_mode: std.builtin.LinkMode,
) ?Result {
    const source_dependency = b.lazyDependency("wgpu_native_source", .{});
    const headers_dependency = b.lazyDependency("webgpu_headers_source", .{});
    if (source_dependency == null or headers_dependency == null) return null;

    const staged_source = b.addWriteFiles();
    _ = staged_source.addCopyDirectory(source_dependency.?.path(""), "", .{});
    _ = staged_source.addCopyDirectory(
        headers_dependency.?.path(""),
        "ffi/webgpu-headers",
        .{},
    );
    _ = staged_source.addCopyFile(
        headers_dependency.?.path("webgpu.h"),
        "ffi/webgpu.h",
    );
    const source_root = staged_source.getDirectory();

    const cargo = b.addSystemCommand(&.{
        "cargo",
        "build",
        "--locked",
        "--manifest-path",
    });
    cargo.setName(b.fmt("build wgpu-native for {s}", .{platform.rust_target}));
    cargo.addFileArg(source_root.path(b, "Cargo.toml"));
    cargo.addArgs(&.{ "--target", platform.rust_target, "--target-dir" });
    const cargo_target_dir = cargo.addOutputDirectoryArg("wgpu-native-target");
    if (optimize != .Debug) cargo.addArg("--release");
    Platform.configureSource(b, cargo, platform);

    const profile = if (optimize == .Debug) "debug" else "release";
    const artifact_root = cargo_target_dir.path(
        b,
        b.fmt("{s}/{s}", .{ platform.rust_target, profile }),
    );

    return artifactFromPaths(
        b,
        platform,
        link_mode,
        artifact_root,
        source_root.path(b, "ffi/wgpu.h"),
        source_root.path(b, "ffi/webgpu.h"),
    );
}

fn artifactFromPaths(
    b: *std.Build,
    platform: Platform.Config,
    link_mode: std.builtin.LinkMode,
    library_dir: std.Build.LazyPath,
    header: std.Build.LazyPath,
    webgpu_header: std.Build.LazyPath,
) Result {
    const static_name = platform.static_name;
    const dynamic_name = platform.dynamic_name;
    const dynamic_import_name = platform.dynamic_import_name;
    const static_library = library_dir.path(b, static_name);
    const dynamic_library = library_dir.path(b, dynamic_name);
    const dynamic_import_library = if (dynamic_import_name) |name|
        library_dir.path(b, name)
    else
        null;

    return .{
        .header = header,
        .webgpu_header = webgpu_header,
        .library_dir = library_dir,
        .link_library = if (link_mode == .static)
            static_library
        else if (dynamic_import_library != null)
            dynamic_import_library
        else
            null,
        .runtime_library = if (link_mode == .dynamic) dynamic_library else null,
        .static_library = static_library,
        .static_name = static_name,
        .dynamic_library = dynamic_library,
        .dynamic_name = dynamic_name,
        .dynamic_import_library = dynamic_import_library,
        .dynamic_import_name = dynamic_import_name,
    };
}
