const raw = @import("raw.zig");
const ChainedStruct = @import("chained_struct.zig").ChainedStruct;

const _misc = @import("misc.zig");
const WGPUFlags = _misc.WGPUFlags;
const WGPUBool = _misc.WGPUBool;
const StringView = _misc.StringView;
const U32_MAX = _misc.U32_MAX;

pub const WGPU_ARRAY_LAYER_COUNT_UNDEFINED = U32_MAX;
pub const WGPU_MIP_LEVEL_COUNT_UNDEFINED = U32_MAX;

pub const TextureFormat = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument.
    r8_unorm = 0x00000001,
    r8_snorm = 0x00000002,
    r8_uint = 0x00000003,
    r8_sint = 0x00000004,
    r16_unorm = 0x00000005,
    r16_snorm = 0x00000006,
    r16_uint = 0x00000007,
    r16_sint = 0x00000008,
    r16_float = 0x00000009,
    rg8_unorm = 0x0000000A,
    rg8_snorm = 0x0000000B,
    rg8_uint = 0x0000000C,
    rg8_sint = 0x0000000D,
    r32_float = 0x0000000E,
    r32_uint = 0x0000000F,
    r32_sint = 0x00000010,
    rg16_unorm = 0x00000011,
    rg16_snorm = 0x00000012,
    rg16_uint = 0x00000013,
    rg16_sint = 0x00000014,
    rg16_float = 0x00000015,
    rgba8_unorm = 0x00000016,
    rgba8_unorm_srgb = 0x00000017,
    rgba8_snorm = 0x00000018,
    rgba8_uint = 0x00000019,
    rgba8_sint = 0x0000001A,
    bgra8_unorm = 0x0000001B,
    bgra8_unorm_srgb = 0x0000001C,
    rgb10a2_uint = 0x0000001D,
    rgb10a2_unorm = 0x0000001E,
    rg11b10_ufloat = 0x0000001F,
    rgb9e5_ufloat = 0x00000020,
    rg32_float = 0x00000021,
    rg32_uint = 0x00000022,
    rg32_sint = 0x00000023,
    rgba16_unorm = 0x00000024,
    rgba16_snorm = 0x00000025,
    rgba16_uint = 0x00000026,
    rgba16_sint = 0x00000027,
    rgba16_float = 0x00000028,
    rgba32_float = 0x00000029,
    rgba32_uint = 0x0000002A,
    rgba32_sint = 0x0000002B,
    stencil8 = 0x0000002C,
    depth16_unorm = 0x0000002D,
    depth24_plus = 0x0000002E,
    depth24_plus_stencil8 = 0x0000002F,
    depth32_float = 0x00000030,
    depth32_float_stencil8 = 0x00000031,
    bc1_rgba_unorm = 0x00000032,
    bc1_rgba_unorm_srgb = 0x00000033,
    bc2_rgba_unorm = 0x00000034,
    bc2_rgba_unorm_srgb = 0x00000035,
    bc3_rgba_unorm = 0x00000036,
    bc3_rgba_unorm_srgb = 0x00000037,
    bc4_r_unorm = 0x00000038,
    bc4_r_snorm = 0x00000039,
    bc5_rg_unorm = 0x0000003A,
    bc5_rg_snorm = 0x0000003B,
    bc6_hrgb_ufloat = 0x0000003C,
    bc6_hrgb_float = 0x0000003D,
    bc7_rgba_unorm = 0x0000003E,
    bc7_rgba_unorm_srgb = 0x0000003F,
    etc2_rgb8_unorm = 0x00000040,
    etc2_rgb8_unorm_srgb = 0x00000041,
    etc2_rgb8a1_unorm = 0x00000042,
    etc2_rgb8a1_unorm_srgb = 0x00000043,
    etc2_rgba8_unorm = 0x00000044,
    etc2_rgba8_unorm_srgb = 0x00000045,
    eacr11_unorm = 0x00000046,
    eacr11_snorm = 0x00000047,
    eacrg11_unorm = 0x00000048,
    eacrg11_snorm = 0x00000049,
    astc4x4_unorm = 0x0000004A,
    astc4x4_unorm_srgb = 0x0000004B,
    astc5x4_unorm = 0x0000004C,
    astc5x4_unorm_srgb = 0x0000004D,
    astc5x5_unorm = 0x0000004E,
    astc5x5_unorm_srgb = 0x0000004F,
    astc6x5_unorm = 0x00000050,
    astc6x5_unorm_srgb = 0x00000051,
    astc6x6_unorm = 0x00000052,
    astc6x6_unorm_srgb = 0x00000053,
    astc8x5_unorm = 0x00000054,
    astc8x5_unorm_srgb = 0x00000055,
    astc8x6_unorm = 0x00000056,
    astc8x6_unorm_srgb = 0x00000057,
    astc8x8_unorm = 0x00000058,
    astc8x8_unorm_srgb = 0x00000059,
    astc10x5_unorm = 0x0000005A,
    astc10x5_unorm_srgb = 0x0000005B,
    astc10x6_unorm = 0x0000005C,
    astc10x6_unorm_srgb = 0x0000005D,
    astc10x8_unorm = 0x0000005E,
    astc10x8_unorm_srgb = 0x0000005F,
    astc10x10_unorm = 0x00000060,
    astc10x10_unorm_srgb = 0x00000061,
    astc12x10_unorm = 0x00000062,
    astc12x10_unorm_srgb = 0x00000063,
    astc12x12_unorm = 0x00000064,
    astc12x12_unorm_srgb = 0x00000065,

    // wgpu-native texture formats
    native_r16_unorm = 0x00030001,
    native_r16_snorm = 0x00030002,
    native_rg16_unorm = 0x00030003,
    native_rg16_snorm = 0x00030004,
    native_rgba16_unorm = 0x00030005,
    native_rgba16_snorm = 0x00030006,
    nv12 = 0x00030007,
    p010 = 0x00030008,
};

pub const TextureUsage = WGPUFlags;
pub const TextureUsages = struct {
    pub const none = @as(TextureUsage, 0x0000000000000000);
    pub const copy_src = @as(TextureUsage, 0x0000000000000001);
    pub const copy_dst = @as(TextureUsage, 0x0000000000000002);
    pub const texture_binding = @as(TextureUsage, 0x0000000000000004);
    pub const storage_binding = @as(TextureUsage, 0x0000000000000008);
    pub const render_attachment = @as(TextureUsage, 0x0000000000000010);
    pub const transient_attachment = @as(TextureUsage, 0x0000000000000020);
};

pub const TextureAspect = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument.
    all = 0x00000001,
    stencil_only = 0x00000002,
    depth_only = 0x00000003,
};

pub const TextureViewDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    format: TextureFormat = TextureFormat.undefined,
    dimension: ViewDimension = ViewDimension.undefined,
    base_mip_level: u32 = 0,
    mip_level_count: u32 = WGPU_MIP_LEVEL_COUNT_UNDEFINED,
    base_array_layer: u32 = 0,
    array_layer_count: u32 = WGPU_ARRAY_LAYER_COUNT_UNDEFINED,
    aspect: TextureAspect = TextureAspect.all,
    usage: TextureUsage = TextureUsages.none,
};

pub const ComponentSwizzle = enum(u32) {
    undefined = 0x00000000,
    zero = 0x00000001,
    one = 0x00000002,
    r = 0x00000003,
    g = 0x00000004,
    b = 0x00000005,
    a = 0x00000006,
};

pub const TextureComponentSwizzle = extern struct {
    r: ComponentSwizzle = .undefined,
    g: ComponentSwizzle = .undefined,
    b: ComponentSwizzle = .undefined,
    a: ComponentSwizzle = .undefined,
};

pub const TextureComponentSwizzleDescriptor = extern struct {
    chain: ChainedStruct = .{
        .s_type = .texture_component_swizzle_descriptor,
    },
    swizzle: TextureComponentSwizzle = .{},
};

pub const TextureView = opaque {
    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *TextureView, label: []const u8) void {
    //     wgpuTextureViewSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *TextureView) void {
        raw.call(void, "wgpuTextureViewAddRef", .{self});
    }
    pub inline fn release(self: *TextureView) void {
        raw.call(void, "wgpuTextureViewRelease", .{self});
    }
};

pub const TextureSampleType = enum(u32) {
    // Indicates that this TextureBindingLayout member of its parent BindGroupLayoutEntry is not used.
    binding_not_used = 0x00000000,

    // Indicates no value is passed for this argument.
    undefined = 0x00000001,

    float = 0x00000002,
    unfilterable_float = 0x00000003,
    depth = 0x00000004,
    s_int = 0x00000005,
    u_int = 0x00000006,
};

pub const ViewDimension = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument.
    @"1d" = 0x00000001,
    @"2d" = 0x00000002,
    @"2d_array" = 0x00000003,
    cube = 0x00000004,
    cube_array = 0x00000005,
    @"3d" = 0x00000006,
};

pub const TextureBindingViewDimension = extern struct {
    chain: ChainedStruct = .{
        .s_type = .texture_binding_view_dimension,
    },
    texture_binding_view_dimension: ViewDimension = .undefined,
};

pub const TextureBindingLayout = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    sample_type: TextureSampleType = .undefined,
    view_dimension: ViewDimension = ViewDimension.@"2d",
    multisampled: WGPUBool = @intFromBool(false),
};

pub const StorageTextureAccess = enum(u32) {
    // Indicates that this StorageTextureBindingLayout member of its parent BindGroupLayoutEntry is not used.
    binding_not_used = 0x00000000,

    // Indicates no value is passed for this argument.
    undefined = 0x00000001,

    write_only = 0x00000002,
    read_only = 0x00000003,
    read_write = 0x00000004,
};

pub const StorageTextureBindingLayout = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    access: StorageTextureAccess = StorageTextureAccess.undefined,
    format: TextureFormat = TextureFormat.undefined,
    view_dimension: ViewDimension = ViewDimension.@"2d",
};

pub const TextureDimension = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument.
    @"1d" = 0x00000001,
    @"2d" = 0x00000002,
    @"3d" = 0x00000003,
};

pub const Extent3D = extern struct {
    width: u32 = 1,
    height: u32 = 1,
    depth_or_array_layers: u32 = 1,
};

pub const TextureDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    usage: TextureUsage,
    dimension: TextureDimension = TextureDimension.@"2d",
    size: Extent3D,
    format: TextureFormat,
    mip_level_count: u32 = 1,
    sample_count: u32 = 1,
    view_format_count: usize = 0,
    view_formats: [*]const TextureFormat = &[_]TextureFormat{},

    /// Returns a descriptor that borrows `view_formats`.
    pub inline fn withViewFormats(
        self: TextureDescriptor,
        view_formats: []const TextureFormat,
    ) TextureDescriptor {
        var descriptor = self;
        descriptor.view_format_count = view_formats.len;
        descriptor.view_formats = view_formats.ptr;
        return descriptor;
    }
};

/// Borrowed backend-native `id<MTLTexture>` returned by wgpu-native.
pub const NativeMetalTexture = opaque {};

pub const Texture = opaque {
    pub inline fn createView(self: *Texture, descriptor: ?*const TextureViewDescriptor) ?*TextureView {
        return raw.call(?*TextureView, "wgpuTextureCreateView", .{ self, descriptor });
    }
    pub inline fn destroy(self: *Texture) void {
        raw.call(void, "wgpuTextureDestroy", .{self});
    }
    pub inline fn getDepthOrArrayLayers(self: *Texture) u32 {
        return raw.call(u32, "wgpuTextureGetDepthOrArrayLayers", .{self});
    }
    pub inline fn getDimension(self: *Texture) TextureDimension {
        return raw.call(TextureDimension, "wgpuTextureGetDimension", .{self});
    }
    pub inline fn getFormat(self: *Texture) TextureFormat {
        return raw.call(TextureFormat, "wgpuTextureGetFormat", .{self});
    }
    pub inline fn getHeight(self: *Texture) u32 {
        return raw.call(u32, "wgpuTextureGetHeight", .{self});
    }
    pub inline fn getMipLevelCount(self: *Texture) u32 {
        return raw.call(u32, "wgpuTextureGetMipLevelCount", .{self});
    }
    pub inline fn getSampleCount(self: *Texture) u32 {
        return raw.call(u32, "wgpuTextureGetSampleCount", .{self});
    }
    pub inline fn getUsage(self: *Texture) TextureUsage {
        return raw.call(TextureUsage, "wgpuTextureGetUsage", .{self});
    }
    pub inline fn getWidth(self: *Texture) u32 {
        return raw.call(u32, "wgpuTextureGetWidth", .{self});
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *Texture, label: []const u8) void {
    //     wgpuTextureSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *Texture) void {
        raw.call(void, "wgpuTextureAddRef", .{self});
    }
    pub inline fn release(self: *Texture) void {
        raw.call(void, "wgpuTextureRelease", .{self});
    }

    /// Returns a borrowed Metal texture when this texture uses the Metal backend.
    /// The pointer remains valid only while `self` is alive and must not be released.
    pub inline fn getNativeMetalTexture(self: *Texture) ?*NativeMetalTexture {
        return raw.call(?*NativeMetalTexture, "wgpuTextureGetNativeMetalTexture", .{self});
    }
};
