pub const SType = enum(u32) {
    shader_source_spirv = 0x00000001,
    shader_source_wgsl = 0x00000002,
    render_pass_max_draw_count = 0x00000003,
    surface_source_metal_layer = 0x00000004,
    surface_source_windows_hwnd = 0x00000005,
    surface_source_xlib_window = 0x00000006,
    surface_source_wayland_surface = 0x00000007,
    surface_source_android_native_window = 0x00000008,
    surface_source_xcb_window = 0x00000009,
    surface_color_management = 0x0000000A,
    request_adapter_webxr_options = 0x0000000B,
    texture_component_swizzle_descriptor = 0x0000000C,
    external_texture_binding_layout = 0x0000000D,
    external_texture_binding_entry = 0x0000000E,
    compatibility_mode_limits = 0x0000000F,
    texture_binding_view_dimension = 0x00000010,

    // wgpu-native extras (wgpu.h)
    device_extras = 0x00030001,
    native_limits = 0x00030002,
    pipeline_layout_extras = 0x00030003,
    shader_source_glsl = 0x00030004,
    instance_extras = 0x00030006,
    bind_group_entry_extras = 0x00030007,
    bind_group_layout_entry_extras = 0x00030008,
    query_set_descriptor_extras = 0x00030009,
    surface_configuration_extras = 0x0003000A,
    surface_source_swap_chain_panel = 0x0003000B,
    primitive_state_extras = 0x0003000C,
};

pub const ChainedStruct = extern struct {
    next: ?*ChainedStruct = null,
    s_type: SType,
};

pub const ChainedStructOut = extern struct {
    next: ?*ChainedStructOut = null,
    s_type: SType,
};
