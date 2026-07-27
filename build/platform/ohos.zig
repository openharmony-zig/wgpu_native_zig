const std = @import("std");
const common = @import("common.zig");
const types = @import("types.zig");
const addDirectoryFiles = @import("../file_tree.zig").addDirectoryFiles;

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

pub fn patchSource(
    b: *std.Build,
    staged_source: *std.Build.Step.WriteFile,
    source_root: std.Build.LazyPath,
    config: types.Config,
) bool {
    if (config.target.result.cpu.arch != .arm) return true;

    const wgpu_source = b.lazyDependency("wgpu_source_29_0_1", .{}) orelse
        return false;
    addDirectoryFiles(
        b,
        staged_source,
        wgpu_source.path("wgpu-hal"),
        "vendor/wgpu-hal",
    );
    _ = staged_source.addCopyFile(
        b.path("build/patches/wgpu-hal-29.0.1/Cargo.toml"),
        "vendor/wgpu-hal/Cargo.toml",
    );

    const adapter = readFile(
        b,
        wgpu_source.path("wgpu-hal/src/vulkan/adapter.rs"),
        1024 * 1024,
    );
    const old_timespec =
        \\            let mut timespec = libc::timespec {
        \\                tv_sec: 0,
        \\                tv_nsec: 0,
        \\            };
    ;
    const new_timespec =
        \\            // Backported from wgpu-hal 30.0.0 for 32-bit OHOS, where
        \\            // libc::timespec contains a private padding field.
        \\            let mut timespec = libc::timespec::default();
    ;
    _ = staged_source.add(
        "vendor/wgpu-hal/src/vulkan/adapter.rs",
        replaceExactlyOnce(b, adapter, old_timespec, new_timespec),
    );

    const cargo_lock = readFile(b, source_root.path(b, "Cargo.lock"), 1024 * 1024);
    const registry_entry =
        \\source = "registry+https://github.com/rust-lang/crates.io-index"
        \\checksum = "89a47aef47636562f3937285af4c44b4b5b404b46577471411cc5313a921da7e"
    ;
    _ = staged_source.add(
        "Cargo.lock",
        replaceExactlyOnce(b, cargo_lock, registry_entry, ""),
    );
    _ = staged_source.add(".cargo/config.toml",
        \\# wgpu-hal 29.0.1 constructs libc::timespec with a struct literal.
        \\# Its private padding field makes that fail for 32-bit OHOS. Keep the
        \\# same crate version and apply the initialization used by wgpu-hal 30.
        \\[patch.crates-io]
        \\wgpu-hal = { path = "vendor/wgpu-hal" }
        \\
    );
    return true;
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

fn readFile(
    b: *std.Build,
    path: std.Build.LazyPath,
    max_bytes: usize,
) []const u8 {
    const resolved = path.getPath3(b, null);
    return resolved.root_dir.handle.readFileAlloc(
        b.graph.io,
        resolved.sub_path,
        b.allocator,
        .limited(max_bytes),
    ) catch |err| std.debug.panic(
        "unable to read {s}: {s}",
        .{ path.getPath(b), @errorName(err) },
    );
}

fn replaceExactlyOnce(
    b: *std.Build,
    input: []const u8,
    needle: []const u8,
    replacement: []const u8,
) []const u8 {
    const first = std.mem.indexOf(u8, input, needle) orelse
        std.debug.panic("wgpu source patch no longer applies", .{});
    if (std.mem.indexOfPos(u8, input, first + needle.len, needle) != null) {
        std.debug.panic("wgpu source patch matched more than once", .{});
    }
    return std.mem.replaceOwned(
        u8,
        b.allocator,
        input,
        needle,
        replacement,
    ) catch @panic("out of memory");
}
