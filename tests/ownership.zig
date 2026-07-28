const std = @import("std");
const testing = std.testing;

const wgpu = @import("wgpu");

test "empty SurfaceCapabilities can be deinitialized repeatedly" {
    var capabilities = wgpu.SurfaceCapabilities{};

    try testing.expectEqual(0, capabilities.formatsSlice().len);
    try testing.expectEqual(0, capabilities.presentModesSlice().len);
    try testing.expectEqual(0, capabilities.alphaModesSlice().len);
    capabilities.deinit();
    capabilities.deinit();

    try testing.expectEqual(wgpu.TextureUsages.none, capabilities.usages);
    try testing.expectEqual(0, capabilities.format_count);
    try testing.expectEqual(null, capabilities.formats);
    try testing.expectEqual(0, capabilities.present_mode_count);
    try testing.expectEqual(null, capabilities.present_modes);
    try testing.expectEqual(0, capabilities.alpha_mode_count);
    try testing.expectEqual(null, capabilities.alpha_modes);
}

test "owned output arrays expose bounded slices" {
    const features = [_]wgpu.FeatureName{
        .core_features_and_limits,
        .depth_clip_control,
    };
    const supported_features = wgpu.SupportedFeatures{
        .feature_count = features.len,
        .features = &features,
    };
    try testing.expectEqualSlices(
        wgpu.FeatureName,
        &features,
        supported_features.slice(),
    );

    const formats = [_]wgpu.TextureFormat{ .rgba8_unorm, .bgra8_unorm };
    const present_modes = [_]wgpu.PresentMode{ .fifo, .mailbox };
    const alpha_modes = [_]wgpu.CompositeAlphaMode{.@"opaque"};
    const capabilities = wgpu.SurfaceCapabilities{
        .format_count = formats.len,
        .formats = &formats,
        .present_mode_count = present_modes.len,
        .present_modes = &present_modes,
        .alpha_mode_count = alpha_modes.len,
        .alpha_modes = &alpha_modes,
    };
    try testing.expectEqualSlices(
        wgpu.TextureFormat,
        &formats,
        capabilities.formatsSlice(),
    );
    try testing.expectEqualSlices(
        wgpu.PresentMode,
        &present_modes,
        capabilities.presentModesSlice(),
    );
    try testing.expectEqualSlices(
        wgpu.CompositeAlphaMode,
        &alpha_modes,
        capabilities.alphaModesSlice(),
    );
}

test "SurfaceTexture transfers texture ownership explicitly" {
    const texture: *wgpu.Texture = @ptrFromInt(1);
    var surface_texture = wgpu.SurfaceTexture{
        .texture = texture,
        .status = .success_optimal,
    };

    try testing.expectEqual(texture, surface_texture.takeTexture());
    try testing.expectEqual(null, surface_texture.texture);

    // The transferred texture is no longer released by SurfaceTexture.
    surface_texture.deinit();
}

test "empty SurfaceTexture can be deinitialized repeatedly" {
    var surface_texture = wgpu.SurfaceTexture{};

    surface_texture.deinit();
    surface_texture.deinit();

    try testing.expectEqual(null, surface_texture.texture);
}
