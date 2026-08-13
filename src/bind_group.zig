const raw = @import("raw.zig");
const _chained_struct = @import("chained_struct.zig");
const ChainedStruct = _chained_struct.ChainedStruct;
const SType = _chained_struct.SType;

const _buffer = @import("buffer.zig");
const Buffer = _buffer.Buffer;
const BufferBindingLayout = _buffer.BufferBindingLayout;
const BufferBindingType = _buffer.BufferBindingType;

const _sampler = @import("sampler.zig");
const Sampler = _sampler.Sampler;
const SamplerBindingLayout = _sampler.SamplerBindingLayout;
const SamplerBindingType = _sampler.SamplerBindingType;

const _texture = @import("texture.zig");
const TextureView = _texture.TextureView;
const TextureBindingLayout = _texture.TextureBindingLayout;
const StorageTextureBindingLayout = _texture.StorageTextureBindingLayout;
const StorageTextureAccess = _texture.StorageTextureAccess;
const TextureSampleType = _texture.TextureSampleType;

const ShaderStage = @import("shader.zig").ShaderStage;

const _misc = @import("misc.zig");
const WGPU_WHOLE_SIZE = _misc.WGPU_WHOLE_SIZE;
const StringView = _misc.StringView;

// wgpu-native v29 declares ExternalTexture lifecycle functions, but their
// implementations panic. Keep the handle type for binding descriptors while
// exposing those functions only through `wgpu.raw`.
pub const ExternalTexture = opaque {};

pub const ExternalTextureBindingLayout = extern struct {
    chain: ChainedStruct = .{
        .s_type = .external_texture_binding_layout,
    },
};

pub const ExternalTextureBindingEntry = extern struct {
    chain: ChainedStruct = .{
        .s_type = .external_texture_binding_entry,
    },
    external_texture: ?*ExternalTexture = null,
};

pub const BindGroupLayoutEntryExtras = extern struct {
    chain: ChainedStruct = ChainedStruct{
        .s_type = SType.bind_group_layout_entry_extras,
    },

    // Why does this exist? Is this different from entry_count on BindGroupLayoutDescriptor?
    count: u32,
};

pub const BindGroupLayoutEntry = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    binding: u32,
    visibility: ShaderStage,
    binding_array_size: u32 = 0,
    buffer: BufferBindingLayout = BufferBindingLayout{
        .type = BufferBindingType.binding_not_used,
    },
    sampler: SamplerBindingLayout = SamplerBindingLayout{
        .type = SamplerBindingType.binding_not_used,
    },
    texture: TextureBindingLayout = TextureBindingLayout{
        .sample_type = TextureSampleType.binding_not_used,
    },
    storage_texture: StorageTextureBindingLayout = StorageTextureBindingLayout{
        .access = StorageTextureAccess.binding_not_used,
    },

    pub inline fn withExtras(self: BindGroupLayoutEntry, extras: *const BindGroupLayoutEntryExtras) BindGroupLayoutEntry {
        var entry = self;
        entry.next_in_chain = @ptrCast(extras);
        return entry;
    }
};

pub const BindGroupLayoutDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    entry_count: usize,
    entries: [*]const BindGroupLayoutEntry,

    /// Initializes a descriptor that borrows `entries`.
    pub inline fn init(entries: []const BindGroupLayoutEntry) BindGroupLayoutDescriptor {
        return .{
            .entry_count = entries.len,
            .entries = entries.ptr,
        };
    }
};

pub const BindGroupLayout = opaque {
    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/4a26b5b0757fe281c07dac4f3a6e2078c811f635/src/unimplemented.rs
    // pub inline fn setLabel(self: *BindGroupLayout, label: []const u8) void {
    //     wgpuBindGroupLayoutSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *BindGroupLayout) void {
        raw.call(void, "wgpuBindGroupLayoutAddRef", .{self});
    }
    pub inline fn release(self: *BindGroupLayout) void {
        raw.call(void, "wgpuBindGroupLayoutRelease", .{self});
    }
};

pub const BindGroupEntryExtras = extern struct {
    chain: ChainedStruct = ChainedStruct{
        .s_type = SType.bind_group_entry_extras,
    },
    buffers: ?[*]const *Buffer = null,
    buffer_count: usize = 0,
    samplers: ?[*]const *Sampler = null,
    sampler_count: usize = 0,
    texture_views: ?[*]const *TextureView = null,
    texture_view_count: usize = 0,

    /// Returns extras that borrow `buffers`.
    pub inline fn withBuffers(
        self: BindGroupEntryExtras,
        buffers: []const *Buffer,
    ) BindGroupEntryExtras {
        var extras = self;
        extras.buffer_count = buffers.len;
        extras.buffers = if (buffers.len == 0) null else buffers.ptr;
        return extras;
    }

    /// Returns extras that borrow `samplers`.
    pub inline fn withSamplers(
        self: BindGroupEntryExtras,
        samplers: []const *Sampler,
    ) BindGroupEntryExtras {
        var extras = self;
        extras.sampler_count = samplers.len;
        extras.samplers = if (samplers.len == 0) null else samplers.ptr;
        return extras;
    }

    /// Returns extras that borrow `texture_views`.
    pub inline fn withTextureViews(
        self: BindGroupEntryExtras,
        texture_views: []const *TextureView,
    ) BindGroupEntryExtras {
        var extras = self;
        extras.texture_view_count = texture_views.len;
        extras.texture_views = if (texture_views.len == 0)
            null
        else
            texture_views.ptr;
        return extras;
    }
};

pub const BindGroupEntry = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    binding: u32,
    buffer: ?*Buffer = null,
    offset: u64 = 0,
    size: u64 = WGPU_WHOLE_SIZE,
    sampler: ?*Sampler = null,
    texture_view: ?*TextureView = null,

    pub inline fn withExtras(self: BindGroupEntry, extras: *const BindGroupEntryExtras) BindGroupEntry {
        var entry = self;
        entry.next_in_chain = @ptrCast(extras);
        return entry;
    }
};

pub const BindGroupDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    layout: *BindGroupLayout,
    entry_count: usize,
    entries: [*]const BindGroupEntry,

    /// Initializes a descriptor that borrows `entries`.
    pub inline fn init(
        layout: *BindGroupLayout,
        entries: []const BindGroupEntry,
    ) BindGroupDescriptor {
        return .{
            .layout = layout,
            .entry_count = entries.len,
            .entries = entries.ptr,
        };
    }
};

pub const BindGroup = opaque {
    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/4a26b5b0757fe281c07dac4f3a6e2078c811f635/src/unimplemented.rs
    // pub inline fn setLabel(self: *BindGroup, label: []const u8) void {
    //     wgpuBindGroupSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *BindGroup) void {
        raw.call(void, "wgpuBindGroupAddRef", .{self});
    }
    pub inline fn release(self: *BindGroup) void {
        raw.call(void, "wgpuBindGroupRelease", .{self});
    }
};
