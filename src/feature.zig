const raw = @import("raw.zig");

pub const FeatureName = enum(u32) {
    core_features_and_limits = 0x00000001,
    depth_clip_control = 0x00000002,
    depth32_float_stencil8 = 0x00000003,
    texture_compression_bc = 0x00000004,
    texture_compression_bc_sliced_3d = 0x00000005,
    texture_compression_etc2 = 0x00000006,
    texture_compression_astc = 0x00000007,
    texture_compression_astc_sliced_3d = 0x00000008,
    timestamp_query = 0x00000009,
    indirect_first_instance = 0x0000000A,
    shader_f16 = 0x0000000B,
    rg11b10_ufloat_renderable = 0x0000000C,
    bgra8_unorm_storage = 0x0000000D,
    float32_filterable = 0x0000000E,
    float32_blendable = 0x0000000F,
    clip_distances = 0x00000010,
    dual_source_blending = 0x00000011,
    subgroups = 0x00000012,
    texture_formats_tier_1 = 0x00000013,
    texture_formats_tier_2 = 0x00000014,
    primitive_index = 0x00000015,
    texture_component_swizzle = 0x00000016,

    // wgpu-native extras
    immediates = 0x00030001,
    texture_adapter_specific_format_features = 0x00030002,
    multi_draw_indirect_count = 0x00030004,
    vertex_writable_storage = 0x00030005,
    texture_binding_array = 0x00030006,
    sampled_texture_and_storage_buffer_array_non_uniform_indexing = 0x00030007,
    pipeline_statistics_query = 0x00030008,
    storage_resource_binding_array = 0x00030009,
    partially_bound_binding_array = 0x0003000A,
    texture_format_16bit_norm = 0x0003000B,
    texture_compression_astc_hdr = 0x0003000C,
    mappable_primary_buffers = 0x0003000E,
    buffer_binding_array = 0x0003000F,
    uniform_buffer_and_storage_texture_array_non_uniform_indexing = 0x00030010,
    polygon_mode_line = 0x00030013,
    polygon_mode_point = 0x00030014,
    conservative_rasterization = 0x00030015,
    spirv_shader_passthrough = 0x00030017,
    vertex_attribute_64bit = 0x00030019,
    texture_format_nv12 = 0x0003001A,
    ray_query = 0x0003001C,
    shader_f64 = 0x0003001D,
    shader_i16 = 0x0003001E,
    shader_early_depth_test = 0x00030020,
    subgroup = 0x00030021,
    subgroup_vertex = 0x00030022,
    subgroup_barrier = 0x00030023,
    timestamp_query_inside_encoders = 0x00030024,
    timestamp_query_inside_passes = 0x00030025,
    shader_int64 = 0x00030026,
};

pub const SupportedFeatures = extern struct {
    feature_count: usize = 0,
    features: ?[*]const FeatureName = null,

    pub inline fn deinit(self: *SupportedFeatures) void {
        raw.call(void, "wgpuSupportedFeaturesFreeMembers", .{self.*});
        self.feature_count = 0;
        self.features = null;
    }
};
