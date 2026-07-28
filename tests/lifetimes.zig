const std = @import("std");
const testing = std.testing;

const wgpu = @import("wgpu");

fn expectChain(expected: *const wgpu.ChainedStruct, actual: ?*const wgpu.ChainedStruct) !void {
    try testing.expect(actual != null);
    try testing.expectEqual(@intFromPtr(expected), @intFromPtr(actual.?));
}

test "shader descriptor helpers borrow caller-owned sources" {
    const spirv_code = [_]u32{0};
    const spirv_source = wgpu.ShaderSourceSPIRV{
        .code_size = spirv_code.len,
        .code = &spirv_code,
    };
    const spirv_descriptor = wgpu.shaderModuleSPIRVDescriptor(&spirv_source, "SPIR-V");
    try expectChain(&spirv_source.chain, spirv_descriptor.next_in_chain);

    const wgsl_source = wgpu.ShaderSourceWGSL{
        .code = wgpu.StringView.fromSlice("@compute @workgroup_size(1) fn main() {}"),
    };
    const wgsl_descriptor = wgpu.shaderModuleWGSLDescriptor(&wgsl_source, "WGSL");
    try expectChain(&wgsl_source.chain, wgsl_descriptor.next_in_chain);

    const glsl_source = wgpu.ShaderSourceGLSL{
        .stage = wgpu.ShaderStages.vertex,
        .code = wgpu.StringView.fromSlice("void main() {}"),
    };
    const glsl_descriptor = wgpu.shaderModuleGLSLDescriptor(&glsl_source, "GLSL");
    try expectChain(&glsl_source.chain, glsl_descriptor.next_in_chain);
}

test "surface descriptor helpers borrow caller-owned sources" {
    const native_pointer: *anyopaque = @ptrFromInt(1);

    const android_source = wgpu.SurfaceSourceAndroidNativeWindow{ .window = native_pointer };
    const android_descriptor = wgpu.surfaceDescriptorFromAndroidNativeWindow(&android_source, "Android");
    try expectChain(&android_source.chain, android_descriptor.next_in_chain);

    const metal_source = wgpu.SurfaceSourceMetalLayer{ .layer = native_pointer };
    const metal_descriptor = wgpu.surfaceDescriptorFromMetalLayer(&metal_source, "Metal");
    try expectChain(&metal_source.chain, metal_descriptor.next_in_chain);

    const wayland_source = wgpu.SurfaceSourceWaylandSurface{
        .display = native_pointer,
        .surface = native_pointer,
    };
    const wayland_descriptor = wgpu.surfaceDescriptorFromWaylandSurface(&wayland_source, "Wayland");
    try expectChain(&wayland_source.chain, wayland_descriptor.next_in_chain);

    const windows_source = wgpu.SurfaceSourceWindowsHWND{
        .hinstance = native_pointer,
        .hwnd = native_pointer,
    };
    const windows_descriptor = wgpu.surfaceDescriptorFromWindowsHWND(&windows_source, "Windows");
    try expectChain(&windows_source.chain, windows_descriptor.next_in_chain);

    const xcb_source = wgpu.SurfaceSourceXCBWindow{
        .connection = native_pointer,
        .window = 1,
    };
    const xcb_descriptor = wgpu.surfaceDescriptorFromXcbWindow(&xcb_source, "XCB");
    try expectChain(&xcb_source.chain, xcb_descriptor.next_in_chain);

    const xlib_source = wgpu.SurfaceSourceXlibWindow{
        .display = native_pointer,
        .window = 1,
    };
    const xlib_descriptor = wgpu.surfaceDescriptorFromXlibWindow(&xlib_source, "Xlib");
    try expectChain(&xlib_source.chain, xlib_descriptor.next_in_chain);
}

test "withExtras helpers borrow caller-owned extensions" {
    const instance_extras = wgpu.InstanceExtras{
        .backends = wgpu.InstanceBackends.all,
        .flags = wgpu.InstanceFlags.default,
        .dx12_shader_compiler = .undefined,
        .gles3_minor_version = .automatic,
        .gl_fence_behavior = .gl_fence_behaviour_normal,
        .dxc_max_shader_model = .dxc_max_shader_model_v6_0,
    };
    const instance_descriptor = (wgpu.InstanceDescriptor{}).withExtras(&instance_extras);
    try expectChain(&instance_extras.chain, instance_descriptor.next_in_chain);

    const device_extras = wgpu.DeviceExtras{ .trace_path = wgpu.StringView{} };
    const device_descriptor = (wgpu.DeviceDescriptor{ .required_limits = null }).withExtras(&device_extras);
    try expectChain(&device_extras.chain, device_descriptor.next_in_chain);

    const pipeline_extras = wgpu.PipelineLayoutExtras{ .immediate_data_size = 16 };
    const pipeline_descriptor = (wgpu.PipelineLayoutDescriptor{
        .bind_group_layout_count = 0,
        .bind_group_layouts = &.{},
    }).withExtras(&pipeline_extras);
    try expectChain(&pipeline_extras.chain, pipeline_descriptor.next_in_chain);

    const layout_entry_extras = wgpu.BindGroupLayoutEntryExtras{ .count = 2 };
    const layout_entry = (wgpu.BindGroupLayoutEntry{
        .binding = 0,
        .visibility = wgpu.ShaderStages.compute,
    }).withExtras(&layout_entry_extras);
    try expectChain(&layout_entry_extras.chain, layout_entry.next_in_chain);

    const bind_group_entry_extras = wgpu.BindGroupEntryExtras{
        .buffers = null,
        .samplers = null,
        .texture_views = null,
    };
    const bind_group_entry = (wgpu.BindGroupEntry{ .binding = 0 }).withExtras(&bind_group_entry_extras);
    try expectChain(&bind_group_entry_extras.chain, bind_group_entry.next_in_chain);

    const render_pass_extras = wgpu.RenderPassMaxDrawCount{ .max_draw_count = 1 };
    const render_pass_descriptor = (wgpu.RenderPassDescriptor{
        .color_attachment_count = 0,
        .color_attachments = &.{},
    }).withExtras(&render_pass_extras);
    try expectChain(&render_pass_extras.chain, render_pass_descriptor.next_in_chain);

    const statistics = [_]wgpu.PipelineStatisticName{.compute_shader_invocations};
    const query_extras = wgpu.QuerySetDescriptorExtras{
        .pipeline_statistics = &statistics,
        .pipeline_statistic_count = statistics.len,
    };
    const query_descriptor = (wgpu.QuerySetDescriptor{
        .type = .pipeline_statistics,
        .count = 1,
    }).withExtras(&query_extras);
    try expectChain(&query_extras.chain, query_descriptor.next_in_chain);

    const surface_extras = wgpu.SurfaceConfigurationExtras{
        .desired_maximum_frame_latency = 2,
    };
    const surface_configuration = (wgpu.SurfaceConfiguration{
        .device = @ptrFromInt(1),
        .format = .rgba8_unorm,
        .width = 1,
        .height = 1,
    }).withExtras(&surface_extras);
    try expectChain(&surface_extras.chain, surface_configuration.next_in_chain);
}
