const std = @import("std");
const testing = std.testing;

const wgpu = @import("wgpu");

test "empty SurfaceCapabilities can be deinitialized repeatedly" {
    var capabilities = wgpu.SurfaceCapabilities{};

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
