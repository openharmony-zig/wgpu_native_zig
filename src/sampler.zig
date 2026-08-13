const raw = @import("raw.zig");
const _chained_struct = @import("chained_struct.zig");
const ChainedStruct = _chained_struct.ChainedStruct;
const SType = _chained_struct.SType;

const _misc = @import("misc.zig");
const CompareFunction = _misc.CompareFunction;
const StringView = _misc.StringView;

pub const SamplerBindingType = enum(u32) {
    // Indicates that this SamplerBindingLayout member of its parent BindGroupLayoutEntry is not used.
    binding_not_used = 0x00000000,

    // Indicates no value is passed for this argument.
    undefined = 0x00000001,

    filtering = 0x00000002,
    non_filtering = 0x00000003,
    comparison = 0x00000004,
};

pub const SamplerBindingLayout = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    type: SamplerBindingType = SamplerBindingType.undefined,
};

pub const AddressMode = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument
    clamp_to_edge = 0x00000001,
    repeat = 0x00000002,
    mirror_repeat = 0x00000003,
};

pub const NativeAddressMode = enum(u32) {
    clamp_to_border = 0x00000004,
};

pub const SamplerBorderColor = enum(u32) {
    undefined = 0x00000000,
    transparent_black = 0x00000001,
    opaque_black = 0x00000002,
    opaque_white = 0x00000003,
    zero = 0x00000004,
};

pub const SamplerDescriptorExtras = extern struct {
    chain: ChainedStruct = ChainedStruct{
        .s_type = SType.sampler_descriptor_extras,
    },
    sampler_border_color: SamplerBorderColor = .undefined,
};

pub const FilterMode = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument.
    nearest = 0x00000001,
    linear = 0x00000002,
};

pub const MipmapFilterMode = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument.
    nearest = 0x00000001,
    linear = 0x00000002,
};

pub const SamplerDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    address_mode_u: AddressMode = AddressMode.clamp_to_edge,
    address_mode_v: AddressMode = AddressMode.clamp_to_edge,
    address_mode_w: AddressMode = AddressMode.clamp_to_edge,
    mag_filter: FilterMode = FilterMode.nearest,
    min_filter: FilterMode = FilterMode.nearest,
    mipmap_filter: MipmapFilterMode = MipmapFilterMode.nearest,
    lod_min_clamp: f32 = 0.0,
    lod_max_clamp: f32 = 32.0,
    compare: CompareFunction = CompareFunction.undefined,
    max_anisotropy: u16 = 1,

    pub inline fn withExtras(
        self: SamplerDescriptor,
        extras: *const SamplerDescriptorExtras,
    ) SamplerDescriptor {
        var descriptor = self;
        descriptor.next_in_chain = @ptrCast(extras);
        return descriptor;
    }
};

pub const Sampler = opaque {
    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/4a26b5b0757fe281c07dac4f3a6e2078c811f635/src/unimplemented.rs
    // pub inline fn setLabel(self: *Sampler, label: []const u8) void {
    //     wgpuSamplerSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *Sampler) void {
        raw.call(void, "wgpuSamplerAddRef", .{self});
    }
    pub inline fn release(self: *Sampler) void {
        raw.call(void, "wgpuSamplerRelease", .{self});
    }
};
