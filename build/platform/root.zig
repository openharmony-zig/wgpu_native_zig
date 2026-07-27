const std = @import("std");
const android = @import("android.zig");
const apple = @import("apple.zig");
const linux = @import("linux.zig");
const ohos = @import("ohos.zig");
const types = @import("types.zig");
const windows = @import("windows.zig");

pub const Config = types.Config;
pub const Kind = types.Kind;

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget) Config {
    const result = target.result;
    if (result.abi == .ohos or result.abi == .ohoseabi) {
        return ohos.build(b, target);
    }
    if (result.abi == .android or result.abi == .androideabi) {
        return android.build(b, target);
    }
    return switch (result.os.tag) {
        .ios, .macos => apple.build(b, target),
        .linux => linux.build(b, target),
        .windows => windows.build(b, target),
        else => @import("common.zig").unsupportedTarget(result),
    };
}

pub fn configureSource(
    b: *std.Build,
    cargo: *std.Build.Step.Run,
    config: Config,
) void {
    switch (config.kind) {
        .android => android.configureSource(b, cargo, config),
        .apple => apple.configureSource(b, cargo, config),
        .linux => linux.configureSource(b, cargo, config),
        .ohos => ohos.configureSource(b, cargo, config),
        .windows => windows.configureSource(b, cargo, config),
    }
}

pub fn configureModule(
    b: *std.Build,
    config: Config,
    mod: *std.Build.Module,
    link_mode: std.builtin.LinkMode,
) void {
    switch (config.kind) {
        .android => android.configureModule(b, config, mod, link_mode),
        .apple => apple.configureModule(b, config, mod, link_mode),
        .linux => linux.configureModule(b, config, mod, link_mode),
        .ohos => ohos.configureModule(b, config, mod, link_mode),
        .windows => windows.configureModule(b, config, mod, link_mode),
    }
}

pub fn configureTranslateC(
    config: Config,
    translate_c: *std.Build.Step.TranslateC,
) void {
    switch (config.kind) {
        .android => android.configureTranslateC(config, translate_c),
        .apple => apple.configureTranslateC(config, translate_c),
        .linux => linux.configureTranslateC(config, translate_c),
        .ohos => ohos.configureTranslateC(config, translate_c),
        .windows => windows.configureTranslateC(config, translate_c),
    }
}

pub fn configureCompile(
    config: Config,
    compile: *std.Build.Step.Compile,
) void {
    switch (config.kind) {
        .android => android.configureCompile(config, compile),
        .apple => apple.configureCompile(config, compile),
        .linux => linux.configureCompile(config, compile),
        .ohos => ohos.configureCompile(config, compile),
        .windows => windows.configureCompile(config, compile),
    }
}

pub fn configureTest(
    config: Config,
    mod: *std.Build.Module,
    link_mode: std.builtin.LinkMode,
) void {
    switch (config.kind) {
        .android => android.configureTest(config, mod, link_mode),
        .apple => apple.configureTest(config, mod, link_mode),
        .linux => linux.configureTest(config, mod, link_mode),
        .ohos => ohos.configureTest(config, mod, link_mode),
        .windows => windows.configureTest(config, mod, link_mode),
    }
}
