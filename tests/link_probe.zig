const wgpu = @import("wgpu");

export fn wgpuNativeZigLinkProbe() callconv(.c) u32 {
    const instance = wgpu.Instance.create(null) orelse return 0;
    instance.release();
    return 1;
}
