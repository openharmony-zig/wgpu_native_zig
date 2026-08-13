const std = @import("std");
const testing = std.testing;

const wgpu = @import("wgpu");

fn expectChain(expected: *const wgpu.ChainedStruct, actual: ?*const wgpu.ChainedStruct) !void {
    try testing.expect(actual != null);
    try testing.expectEqual(@intFromPtr(expected), @intFromPtr(actual.?));
}

fn expectPointer(expected: anytype, actual: anytype) !void {
    try testing.expectEqual(@intFromPtr(expected), @intFromPtr(actual));
}

test "shader descriptor helpers borrow caller-owned sources" {
    const spirv_code = [_]u32{0};
    const spirv_source = wgpu.ShaderSourceSPIRV.init(&spirv_code);
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

    const ohos_source = wgpu.SurfaceSourceOhosNativeWindow{ .window = native_pointer };
    const ohos_descriptor = wgpu.surfaceDescriptorFromOhosNativeWindow(&ohos_source, "OHOS");
    try expectChain(&ohos_source.chain, ohos_descriptor.next_in_chain);
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

    const sampler_extras = wgpu.SamplerDescriptorExtras{ .sampler_border_color = .opaque_black };
    const sampler_descriptor = (wgpu.SamplerDescriptor{}).withExtras(&sampler_extras);
    try expectChain(&sampler_extras.chain, sampler_descriptor.next_in_chain);

    const layout_entry_extras = wgpu.BindGroupLayoutEntryExtras{ .count = 2 };
    const layout_entry = (wgpu.BindGroupLayoutEntry{
        .binding = 0,
        .visibility = wgpu.ShaderStages.compute,
    }).withExtras(&layout_entry_extras);
    try expectChain(&layout_entry_extras.chain, layout_entry.next_in_chain);

    const bind_group_entry_extras = wgpu.BindGroupEntryExtras{};
    const bind_group_entry = (wgpu.BindGroupEntry{ .binding = 0 }).withExtras(&bind_group_entry_extras);
    try expectChain(&bind_group_entry_extras.chain, bind_group_entry.next_in_chain);

    const render_pass_extras = wgpu.RenderPassMaxDrawCount{ .max_draw_count = 1 };
    const render_pass_descriptor =
        wgpu.RenderPassDescriptor.init(&.{}).withExtras(&render_pass_extras);
    try expectChain(&render_pass_extras.chain, render_pass_descriptor.next_in_chain);

    const statistics = [_]wgpu.PipelineStatisticName{.compute_shader_invocations};
    const query_extras = wgpu.QuerySetDescriptorExtras.init(&statistics);
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

test "descriptor slice helpers synchronize borrowed pointer-count pairs" {
    const instance_features = [_]wgpu.InstanceFeatureName{
        .shader_source_spirv,
        .multiple_devices_per_adapter,
    };
    const instance_descriptor =
        (wgpu.InstanceDescriptor{}).withRequiredFeatures(&instance_features);
    try testing.expectEqual(instance_features.len, instance_descriptor.required_feature_count);
    try expectPointer(instance_features[0..].ptr, instance_descriptor.required_features);

    const device_features = [_]wgpu.FeatureName{
        .depth_clip_control,
        .timestamp_query,
    };
    const device_descriptor =
        (wgpu.DeviceDescriptor{}).withRequiredFeatures(&device_features);
    try testing.expectEqual(device_features.len, device_descriptor.required_feature_count);
    try expectPointer(device_features[0..].ptr, device_descriptor.required_features);

    const layout_entries = [_]wgpu.BindGroupLayoutEntry{.{
        .binding = 0,
        .visibility = wgpu.ShaderStages.compute,
    }};
    const bind_group_layout_descriptor =
        wgpu.BindGroupLayoutDescriptor.init(&layout_entries);
    try testing.expectEqual(layout_entries.len, bind_group_layout_descriptor.entry_count);
    try expectPointer(layout_entries[0..].ptr, bind_group_layout_descriptor.entries);

    const bind_group_layout: *wgpu.BindGroupLayout = @ptrFromInt(0x1000);
    const bind_group_entries = [_]wgpu.BindGroupEntry{.{ .binding = 0 }};
    const bind_group_descriptor =
        wgpu.BindGroupDescriptor.init(bind_group_layout, &bind_group_entries);
    try testing.expectEqual(bind_group_entries.len, bind_group_descriptor.entry_count);
    try expectPointer(bind_group_entries[0..].ptr, bind_group_descriptor.entries);

    const buffer: *wgpu.Buffer = @ptrFromInt(0x2000);
    const sampler: *wgpu.Sampler = @ptrFromInt(0x3000);
    const texture_view: *wgpu.TextureView = @ptrFromInt(0x4000);
    const buffers = [_]*wgpu.Buffer{buffer};
    const samplers = [_]*wgpu.Sampler{sampler};
    const texture_views = [_]*wgpu.TextureView{texture_view};
    const bind_group_entry_extras = (wgpu.BindGroupEntryExtras{})
        .withBuffers(&buffers)
        .withSamplers(&samplers)
        .withTextureViews(&texture_views);
    try testing.expectEqual(buffers.len, bind_group_entry_extras.buffer_count);
    try expectPointer(buffers[0..].ptr, bind_group_entry_extras.buffers.?);
    try testing.expectEqual(samplers.len, bind_group_entry_extras.sampler_count);
    try expectPointer(samplers[0..].ptr, bind_group_entry_extras.samplers.?);
    try testing.expectEqual(texture_views.len, bind_group_entry_extras.texture_view_count);
    try expectPointer(texture_views[0..].ptr, bind_group_entry_extras.texture_views.?);

    const empty_bind_group_entry_extras = (wgpu.BindGroupEntryExtras{})
        .withBuffers(&.{})
        .withSamplers(&.{})
        .withTextureViews(&.{});
    try testing.expectEqual(null, empty_bind_group_entry_extras.buffers);
    try testing.expectEqual(null, empty_bind_group_entry_extras.samplers);
    try testing.expectEqual(null, empty_bind_group_entry_extras.texture_views);

    const bind_group_layouts = [_]*wgpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout_descriptor =
        wgpu.PipelineLayoutDescriptor.init(&bind_group_layouts);
    try testing.expectEqual(
        bind_group_layouts.len,
        pipeline_layout_descriptor.bind_group_layout_count,
    );
    try expectPointer(
        bind_group_layouts[0..].ptr,
        pipeline_layout_descriptor.bind_group_layouts,
    );

    const shader_module: *wgpu.ShaderModule = @ptrFromInt(0x5000);
    const constants = [_]wgpu.ConstantEntry{.{
        .key = wgpu.StringView.fromSlice("constant"),
        .value = 1,
    }};
    const compute_state = (wgpu.ComputeState{
        .module = shader_module,
    }).withConstants(&constants);
    try testing.expectEqual(constants.len, compute_state.constant_count);
    try expectPointer(constants[0..].ptr, compute_state.constants);

    const attributes = [_]wgpu.VertexAttribute{.{
        .format = .float32x4,
        .offset = 0,
        .shader_location = 0,
    }};
    const vertex_buffer = wgpu.VertexBufferLayout.init(16, &attributes);
    try testing.expectEqual(attributes.len, vertex_buffer.attribute_count);
    try expectPointer(attributes[0..].ptr, vertex_buffer.attributes);

    const vertex_buffers = [_]wgpu.VertexBufferLayout{vertex_buffer};
    const vertex_state = (wgpu.VertexState{
        .module = shader_module,
    }).withConstants(&constants).withBuffers(&vertex_buffers);
    try testing.expectEqual(constants.len, vertex_state.constant_count);
    try expectPointer(constants[0..].ptr, vertex_state.constants);
    try testing.expectEqual(vertex_buffers.len, vertex_state.buffer_count);
    try expectPointer(vertex_buffers[0..].ptr, vertex_state.buffers);

    const targets = [_]wgpu.ColorTargetState{.{ .format = .rgba8_unorm }};
    const fragment_state = wgpu.FragmentState.init(shader_module, &.{})
        .withTargets(&targets)
        .withConstants(&constants);
    try testing.expectEqual(constants.len, fragment_state.constant_count);
    try expectPointer(constants[0..].ptr, fragment_state.constants);
    try testing.expectEqual(targets.len, fragment_state.target_count);
    try expectPointer(targets[0..].ptr, fragment_state.targets);

    const color_formats = [_]wgpu.TextureFormat{ .rgba8_unorm, .bgra8_unorm };
    const render_bundle_descriptor =
        wgpu.RenderBundleEncoderDescriptor.init(&color_formats);
    try testing.expectEqual(color_formats.len, render_bundle_descriptor.color_format_count);
    try expectPointer(color_formats[0..].ptr, render_bundle_descriptor.color_formats);

    const color_attachments = [_]wgpu.ColorAttachment{.{ .view = texture_view }};
    const render_pass_descriptor = wgpu.RenderPassDescriptor.init(&color_attachments);
    try testing.expectEqual(
        color_attachments.len,
        render_pass_descriptor.color_attachment_count,
    );
    try expectPointer(
        color_attachments[0..].ptr,
        render_pass_descriptor.color_attachments,
    );

    const texture_descriptor = (wgpu.TextureDescriptor{
        .usage = wgpu.TextureUsages.render_attachment,
        .size = .{},
        .format = .rgba8_unorm,
    }).withViewFormats(&color_formats);
    try testing.expectEqual(color_formats.len, texture_descriptor.view_format_count);
    try expectPointer(color_formats[0..].ptr, texture_descriptor.view_formats);

    const device: *wgpu.Device = @ptrFromInt(0x6000);
    const surface_configuration = (wgpu.SurfaceConfiguration{
        .device = device,
        .format = .rgba8_unorm,
        .width = 1,
        .height = 1,
    }).withViewFormats(&color_formats);
    try testing.expectEqual(color_formats.len, surface_configuration.view_format_count);
    try expectPointer(color_formats[0..].ptr, surface_configuration.view_formats);

    const spirv_words = [_]u32{ 0x07230203, 0 };
    const native_spirv = wgpu.ShaderModuleDescriptorSpirV.init(&spirv_words);
    try testing.expectEqual(@as(u32, spirv_words.len), native_spirv.source_size);
    try expectPointer(spirv_words[0..].ptr, native_spirv.source);

    const chained_spirv = wgpu.ShaderSourceSPIRV.init(&spirv_words);
    try testing.expectEqual(@as(u32, spirv_words.len), chained_spirv.code_size);
    try expectPointer(spirv_words[0..].ptr, chained_spirv.code);

    const defines = [_]wgpu.ShaderDefine{.{
        .name = wgpu.StringView.fromSlice("VALUE"),
        .value = wgpu.StringView.fromSlice("1"),
    }};
    const glsl_source = (wgpu.ShaderSourceGLSL{
        .stage = wgpu.ShaderStages.compute,
        .code = wgpu.StringView.fromSlice("void main() {}"),
    }).withDefines(&defines);
    try testing.expectEqual(@as(u32, defines.len), glsl_source.define_count);
    try expectPointer(defines[0..].ptr, glsl_source.defines.?);
    const glsl_source_without_defines = glsl_source.withDefines(&.{});
    try testing.expectEqual(@as(u32, 0), glsl_source_without_defines.define_count);
    try testing.expectEqual(null, glsl_source_without_defines.defines);

    const statistics = [_]wgpu.PipelineStatisticName{
        .vertex_shader_invocations,
        .fragment_shader_invocations,
    };
    const query_extras = wgpu.QuerySetDescriptorExtras.init(&statistics);
    try testing.expectEqual(statistics.len, query_extras.pipeline_statistic_count);
    try expectPointer(statistics[0..].ptr, query_extras.pipeline_statistics);
}
