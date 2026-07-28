const raw = @import("raw.zig");
const _misc = @import("misc.zig");
const WGPUBool = _misc.WGPUBool;
const IndexFormat = _misc.IndexFormat;
const StringView = _misc.StringView;

const ChainedStruct = @import("chained_struct.zig").ChainedStruct;
const TextureFormat = @import("texture.zig").TextureFormat;
const Buffer = @import("buffer.zig").Buffer;
const BindGroup = @import("bind_group.zig").BindGroup;
const RenderPipeline = @import("pipeline.zig").RenderPipeline;
pub const RenderBundleEncoderDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    color_format_count: usize,
    color_formats: [*]const TextureFormat,
    depth_stencil_format: TextureFormat = TextureFormat.undefined,
    sample_count: u32 = 1,
    depth_read_only: WGPUBool = @intFromBool(false),
    stencil_read_only: WGPUBool = @intFromBool(false),
};

// wgpu-native

// TODO: This is very similar to CommandEncoder; should it go in the same file? There's a lot of duplicated import code.
pub const RenderBundleEncoder = opaque {
    pub inline fn draw(self: *RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        raw.call(void, "wgpuRenderBundleEncoderDraw", .{ self, vertex_count, instance_count, first_vertex, first_instance });
    }
    pub inline fn drawIndexed(self: *RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        raw.call(void, "wgpuRenderBundleEncoderDrawIndexed", .{ self, index_count, instance_count, first_index, base_vertex, first_instance });
    }
    pub inline fn drawIndexedIndirect(self: *RenderBundleEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        raw.call(void, "wgpuRenderBundleEncoderDrawIndexedIndirect", .{ self, indirect_buffer, indirect_offset });
    }
    pub inline fn drawIndirect(self: *RenderBundleEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        raw.call(void, "wgpuRenderBundleEncoderDrawIndirect", .{ self, indirect_buffer, indirect_offset });
    }
    pub inline fn finish(self: *RenderBundleEncoder, descriptor: *const RenderBundleDescriptor) ?*RenderBundle {
        return raw.call(?*RenderBundle, "wgpuRenderBundleEncoderFinish", .{ self, descriptor });
    }
    pub inline fn insertDebugMarker(self: *RenderBundleEncoder, marker_label: []const u8) void {
        raw.call(void, "wgpuRenderBundleEncoderInsertDebugMarker", .{ self, StringView.fromSlice(marker_label) });
    }
    pub inline fn popDebugGroup(self: *RenderBundleEncoder) void {
        raw.call(void, "wgpuRenderBundleEncoderPopDebugGroup", .{self});
    }
    pub inline fn pushDebugGroup(self: *RenderBundleEncoder, group_label: []const u8) void {
        raw.call(void, "wgpuRenderBundleEncoderPushDebugGroup", .{ self, StringView.fromSlice(group_label) });
    }
    pub inline fn setBindGroup(self: *RenderBundleEncoder, group_index: u32, group: *BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        raw.call(void, "wgpuRenderBundleEncoderSetBindGroup", .{ self, group_index, group, dynamic_offset_count, dynamic_offsets });
    }
    pub inline fn setIndexBuffer(self: *RenderBundleEncoder, buffer: *Buffer, format: IndexFormat, offset: u64, size: u64) void {
        raw.call(void, "wgpuRenderBundleEncoderSetIndexBuffer", .{ self, buffer, format, offset, size });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *RenderBundleEncoder, label: []const u8) void {
    //     wgpuRenderBundleEncoderSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn setPipeline(self: *RenderBundleEncoder, pipeline: *RenderPipeline) void {
        raw.call(void, "wgpuRenderBundleEncoderSetPipeline", .{ self, pipeline });
    }
    pub inline fn setVertexBuffer(self: *RenderBundleEncoder, slot: u32, buffer: *Buffer, offset: u64, size: u64) void {
        raw.call(void, "wgpuRenderBundleEncoderSetVertexBuffer", .{ self, slot, buffer, offset, size });
    }
    pub inline fn addRef(self: *RenderBundleEncoder) void {
        raw.call(void, "wgpuRenderBundleEncoderAddRef", .{self});
    }
    pub inline fn release(self: *RenderBundleEncoder) void {
        raw.call(void, "wgpuRenderBundleEncoderRelease", .{self});
    }

    // wgpu-native
    pub inline fn setImmediates(self: *RenderBundleEncoder, offset: u32, size_bytes: u32, data: *const anyopaque) void {
        raw.call(void, "wgpuRenderBundleEncoderSetImmediates", .{ self, offset, size_bytes, data });
    }
};

pub const RenderBundleDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
};

pub const RenderBundle = opaque {
    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *RenderBundle, label: []const u8) void {
    //     wgpuRenderBundleSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *RenderBundle) void {
        raw.call(void, "wgpuRenderBundleAddRef", .{self});
    }
    pub inline fn release(self: *RenderBundle) void {
        raw.call(void, "wgpuRenderBundleRelease", .{self});
    }
};
