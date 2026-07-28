const std = @import("std");
const Platform = @import("platform/root.zig");
const WgpuNativeArtifact = @import("WgpuNativeArtifact.zig");

pub const Options = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    link_mode: std.builtin.LinkMode,
    use_prebuilt: bool,
};

pub const Result = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    link_mode: std.builtin.LinkMode,
    platform: Platform.Config,
    artifact: WgpuNativeArtifact.Result,
    install_lib_dir: []const u8,
    wgpu_mod: *std.Build.Module,
    wgpu_c_mod: *std.Build.Module,

    pub fn isOhos(self: Result) bool {
        return self.platform.kind == .ohos;
    }

    pub fn isAndroid(self: Result) bool {
        return self.platform.kind == .android;
    }

    pub fn linkModule(
        self: Result,
        b: *std.Build,
        mod: *std.Build.Module,
    ) void {
        mod.link_libcpp = true;
        Platform.configureModule(
            b,
            self.platform,
            mod,
            self.link_mode,
        );
        if (self.artifact.link_library) |library| {
            mod.addObjectFile(library);
        } else if (self.link_mode == .dynamic) {
            mod.addLibraryPath(self.artifact.library_dir);
            mod.linkSystemLibrary("wgpu_native", .{});
        }
    }

    pub fn linkTestModule(
        self: Result,
        b: *std.Build,
        mod: *std.Build.Module,
    ) void {
        self.linkModule(b, mod);
        Platform.configureTest(
            self.platform,
            mod,
            self.link_mode,
        );
    }

    pub fn configureCompile(
        self: Result,
        compile: *std.Build.Step.Compile,
    ) void {
        Platform.configureCompile(self.platform, compile);
    }

    pub fn configureRun(
        self: Result,
        b: *std.Build,
        run: *std.Build.Step.Run,
    ) void {
        if (self.link_mode != .dynamic) return;
        run.addPathDir(self.install_lib_dir);
        run.step.dependOn(b.getInstallStep());
    }
};

pub fn standardOptions(b: *std.Build) Options {
    return .{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .link_mode = b.option(
            std.builtin.LinkMode,
            "link_mode",
            "Select static or dynamic wgpu-native linking",
        ) orelse .static,
        .use_prebuilt = b.option(
            bool,
            "use_prebuilt",
            "Use published wgpu-native binaries instead of building from source",
        ) orelse envFlag(b, "WGPU_NATIVE_USE_PREBUILT"),
    };
}

pub fn build(b: *std.Build, options: Options) ?Result {
    const platform = Platform.build(b, options.target);
    const artifact = WgpuNativeArtifact.build(
        b,
        platform,
        options.optimize,
        options.link_mode,
        options.use_prebuilt,
    ) orelse return null;

    const wgpu_mod = b.addModule("wgpu", .{
        .root_source_file = b.path("src/root.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });
    const translate_step = b.addTranslateC(.{
        .root_source_file = artifact.header,
        .target = options.target,
        .optimize = options.optimize,
    });
    Platform.configureTranslateC(platform, translate_step);
    const wgpu_c_mod = translate_step.addModule("wgpu-c");
    wgpu_c_mod.resolved_target = options.target;
    wgpu_mod.addImport("wgpu-header", wgpu_c_mod);

    var result: Result = .{
        .target = options.target,
        .optimize = options.optimize,
        .link_mode = options.link_mode,
        .platform = platform,
        .artifact = artifact,
        .install_lib_dir = b.getInstallPath(.lib, ""),
        .wgpu_mod = wgpu_mod,
        .wgpu_c_mod = wgpu_c_mod,
    };
    result.linkModule(b, wgpu_mod);
    result.linkModule(b, wgpu_c_mod);
    install(b, artifact);
    return result;
}

fn install(b: *std.Build, artifact: WgpuNativeArtifact.Result) void {
    const install_static_library = b.addInstallLibFile(
        artifact.static_library,
        artifact.static_name,
    );
    b.getInstallStep().dependOn(&install_static_library.step);
    const install_dynamic_library = b.addInstallLibFile(
        artifact.dynamic_library,
        artifact.dynamic_name,
    );
    b.getInstallStep().dependOn(&install_dynamic_library.step);
    if (artifact.dynamic_import_library) |import_library| {
        const install_import_library = b.addInstallLibFile(
            import_library,
            artifact.dynamic_import_name.?,
        );
        b.getInstallStep().dependOn(&install_import_library.step);
    }
    const install_wgpu_header = b.addInstallHeaderFile(
        artifact.header,
        "webgpu/wgpu.h",
    );
    b.getInstallStep().dependOn(&install_wgpu_header.step);
    const install_webgpu_header = b.addInstallHeaderFile(
        artifact.webgpu_header,
        "webgpu/webgpu.h",
    );
    b.getInstallStep().dependOn(&install_webgpu_header.step);
    if (artifact.runtime_library) |runtime_library| {
        const write_files = b.addNamedWriteFiles("lib");
        _ = write_files.addCopyFile(runtime_library, artifact.dynamic_name);
    }
}

fn envFlag(b: *std.Build, name: []const u8) bool {
    const value = b.graph.environ_map.get(name) orelse return false;
    if (std.mem.eql(u8, value, "1") or
        std.ascii.eqlIgnoreCase(value, "true") or
        std.ascii.eqlIgnoreCase(value, "yes") or
        std.ascii.eqlIgnoreCase(value, "on"))
    {
        return true;
    }
    if (std.mem.eql(u8, value, "0") or
        std.ascii.eqlIgnoreCase(value, "false") or
        std.ascii.eqlIgnoreCase(value, "no") or
        std.ascii.eqlIgnoreCase(value, "off"))
    {
        return false;
    }
    std.debug.panic(
        "{s} must be one of 1/0, true/false, yes/no, or on/off; got '{s}'",
        .{ name, value },
    );
}
