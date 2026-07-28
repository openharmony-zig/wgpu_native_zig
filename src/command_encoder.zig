const raw = @import("raw.zig");
const std = @import("std");

const _chained_struct = @import("chained_struct.zig");
const ChainedStruct = _chained_struct.ChainedStruct;
const SType = _chained_struct.SType;

const Buffer = @import("buffer.zig").Buffer;
const QuerySet = @import("query_set.zig").QuerySet;

const _texture = @import("texture.zig");
const TextureFormat = _texture.TextureFormat;
const TextureView = _texture.TextureView;
const TexelCopyBufferInfo = _texture.TexelCopyBufferInfo;
const TexelCopyTextureInfo = _texture.TexelCopyTextureInfo;
const Extent3D = _texture.Extent3D;

const _misc = @import("misc.zig");
const WGPUBool = _misc.WGPUBool;
const IndexFormat = _misc.IndexFormat;
const StringView = _misc.StringView;
const U32_MAX = _misc.U32_MAX;

const BindGroup = @import("bind_group.zig").BindGroup;

const _pipeline = @import("pipeline.zig");
const ComputePipeline = _pipeline.ComputePipeline;
const RenderPipeline = _pipeline.RenderPipeline;

const _render_bundle = @import("render_bundle.zig");
const RenderBundleDescriptor = _render_bundle.RenderBundleDescriptor;
const RenderBundle = _render_bundle.RenderBundle;

pub const WGPU_DEPTH_SLICE_UNDEFINED = U32_MAX;
pub const WGPU_QUERY_SET_INDEX_UNDEFINED = U32_MAX;

pub const RenderBundleEncoderDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = .{},
    color_format_count: usize,
    color_formats: [*]const TextureFormat,
    depth_stencil_format: TextureFormat = .undefined,
    sample_count: u32 = 1,
    depth_read_only: WGPUBool = @intFromBool(false),
    stencil_read_only: WGPUBool = @intFromBool(false),
};

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
    pub inline fn finish(self: *RenderBundleEncoder, descriptor: ?*const RenderBundleDescriptor) ?*RenderBundle {
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
    pub inline fn setBindGroup(self: *RenderBundleEncoder, group_index: u32, group: ?*BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
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
    pub inline fn setVertexBuffer(self: *RenderBundleEncoder, slot: u32, buffer: ?*Buffer, offset: u64, size: u64) void {
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

pub const PassTimestampWrites = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    query_set: *QuerySet,
    beginning_of_pass_write_index: u32 = WGPU_QUERY_SET_INDEX_UNDEFINED,
    end_of_pass_write_index: u32 = WGPU_QUERY_SET_INDEX_UNDEFINED,
};

pub const ComputePassDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    timestamp_writes: ?*const PassTimestampWrites = null,
};

pub const CommandEncoderDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
};

// wgpu-native

pub const ComputePassEncoder = opaque {
    pub inline fn dispatchWorkgroups(self: *ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        raw.call(void, "wgpuComputePassEncoderDispatchWorkgroups", .{ self, workgroup_count_x, workgroup_count_y, workgroup_count_z });
    }
    pub inline fn dispatchWorkgroupsIndirect(self: *ComputePassEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        raw.call(void, "wgpuComputePassEncoderDispatchWorkgroupsIndirect", .{ self, indirect_buffer, indirect_offset });
    }
    pub inline fn end(self: *ComputePassEncoder) void {
        raw.call(void, "wgpuComputePassEncoderEnd", .{self});
    }
    pub inline fn insertDebugMarker(self: *ComputePassEncoder, marker_label: []const u8) void {
        raw.call(void, "wgpuComputePassEncoderInsertDebugMarker", .{ self, StringView.fromSlice(marker_label) });
    }
    pub inline fn popDebugGroup(self: *ComputePassEncoder) void {
        raw.call(void, "wgpuComputePassEncoderPopDebugGroup", .{self});
    }
    pub inline fn pushDebugGroup(self: *ComputePassEncoder, group_label: []const u8) void {
        raw.call(void, "wgpuComputePassEncoderPushDebugGroup", .{ self, StringView.fromSlice(group_label) });
    }
    pub inline fn setBindGroup(self: *ComputePassEncoder, group_index: u32, group: ?*BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        raw.call(void, "wgpuComputePassEncoderSetBindGroup", .{ self, group_index, group, dynamic_offset_count, dynamic_offsets });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *ComputePassEncoder, label: []const u8) void {
    //     wgpuComputePassEncoderSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn setPipeline(self: *ComputePassEncoder, pipeline: *ComputePipeline) void {
        raw.call(void, "wgpuComputePassEncoderSetPipeline", .{ self, pipeline });
    }
    pub inline fn addRef(self: *ComputePassEncoder) void {
        raw.call(void, "wgpuComputePassEncoderAddRef", .{self});
    }
    pub inline fn release(self: *ComputePassEncoder) void {
        raw.call(void, "wgpuComputePassEncoderRelease", .{self});
    }

    // wgpu-native
    pub inline fn setImmediates(self: *ComputePassEncoder, offset: u32, size_bytes: u32, data: *const anyopaque) void {
        raw.call(void, "wgpuComputePassEncoderSetImmediates", .{ self, offset, size_bytes, data });
    }
    pub inline fn beginPipelineStatisticsQuery(self: *ComputePassEncoder, query_set: *QuerySet, query_index: u32) void {
        raw.call(void, "wgpuComputePassEncoderBeginPipelineStatisticsQuery", .{ self, query_set, query_index });
    }
    pub inline fn endPipelineStatisticsQuery(self: *ComputePassEncoder) void {
        raw.call(void, "wgpuComputePassEncoderEndPipelineStatisticsQuery", .{self});
    }
    pub inline fn writeTimestamp(self: *ComputePassEncoder, query_set: *QuerySet, query_index: u32) void {
        raw.call(void, "wgpuComputePassEncoderWriteTimestamp", .{ self, query_set, query_index });
    }
};

pub const LoadOp = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument.
    load = 0x00000001,
    clear = 0x00000002,
};

pub const StoreOp = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument
    store = 0x00000001,
    discard = 0x00000002,
};

pub const Color = extern struct {
    r: f64 = 0.0,
    g: f64 = 0.0,
    b: f64 = 0.0,
    a: f64 = 0.0,
};

pub const ColorAttachment = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    view: ?*TextureView,
    depth_slice: u32 = WGPU_DEPTH_SLICE_UNDEFINED,
    resolve_target: ?*TextureView = null,
    load_op: LoadOp = LoadOp.clear,
    store_op: StoreOp = StoreOp.store,
    clear_value: Color = Color{},
};

pub const DepthStencilAttachment = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    view: *TextureView,
    depth_load_op: LoadOp = LoadOp.undefined,
    depth_store_op: StoreOp = StoreOp.undefined,
    depth_clear_value: f32 = std.math.nan(f32),
    depth_read_only: WGPUBool = @intFromBool(false),
    stencil_load_op: LoadOp = LoadOp.undefined,
    stencil_store_op: StoreOp = StoreOp.undefined,
    stencil_clear_value: u32 = 0,
    stencil_read_only: WGPUBool = @intFromBool(false),
};

pub const RenderPassMaxDrawCount = extern struct {
    chain: ChainedStruct = ChainedStruct{ .s_type = SType.render_pass_max_draw_count },
    max_draw_count: u64 = 50000000,
};

pub const RenderPassDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    color_attachment_count: usize,
    color_attachments: [*]const ColorAttachment,
    depth_stencil_attachment: ?*const DepthStencilAttachment = null,
    occlusion_query_set: ?*QuerySet = null,
    timestamp_writes: ?*const PassTimestampWrites = null,

    pub inline fn withMaxDrawCount(self: RenderPassDescriptor, max_draw_count: u64) RenderPassDescriptor {
        var descriptor = self;
        descriptor.next_in_chain = @ptrCast(&RenderPassMaxDrawCount{
            .max_draw_count = max_draw_count,
        });

        return descriptor;
    }
};

// wgpu-native

pub const RenderPassEncoder = opaque {
    pub inline fn beginOcclusionQuery(self: *RenderPassEncoder, query_index: u32) void {
        raw.call(void, "wgpuRenderPassEncoderBeginOcclusionQuery", .{ self, query_index });
    }
    pub inline fn draw(self: *RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        raw.call(void, "wgpuRenderPassEncoderDraw", .{ self, vertex_count, instance_count, first_vertex, first_instance });
    }
    pub inline fn drawIndexed(self: *RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        raw.call(void, "wgpuRenderPassEncoderDrawIndexed", .{ self, index_count, instance_count, first_index, base_vertex, first_instance });
    }
    pub inline fn drawIndexedIndirect(self: *RenderPassEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        raw.call(void, "wgpuRenderPassEncoderDrawIndexedIndirect", .{ self, indirect_buffer, indirect_offset });
    }
    pub inline fn drawIndirect(self: *RenderPassEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        raw.call(void, "wgpuRenderPassEncoderDrawIndirect", .{ self, indirect_buffer, indirect_offset });
    }
    pub inline fn end(self: *RenderPassEncoder) void {
        raw.call(void, "wgpuRenderPassEncoderEnd", .{self});
    }
    pub inline fn endOcclusionQuery(self: *RenderPassEncoder) void {
        raw.call(void, "wgpuRenderPassEncoderEndOcclusionQuery", .{self});
    }
    pub inline fn executeBundles(self: *RenderPassEncoder, bundles: []const *const RenderBundle) void {
        raw.call(void, "wgpuRenderPassEncoderExecuteBundles", .{ self, bundles.len, bundles.ptr });
    }
    pub inline fn insertDebugMarker(self: *RenderPassEncoder, marker_label: []const u8) void {
        raw.call(void, "wgpuRenderPassEncoderInsertDebugMarker", .{ self, StringView.fromSlice(marker_label) });
    }
    pub inline fn popDebugGroup(self: *RenderPassEncoder) void {
        raw.call(void, "wgpuRenderPassEncoderPopDebugGroup", .{self});
    }
    pub inline fn pushDebugGroup(self: *RenderPassEncoder, group_label: []const u8) void {
        raw.call(void, "wgpuRenderPassEncoderPushDebugGroup", .{ self, StringView.fromSlice(group_label) });
    }
    pub inline fn setBindGroup(self: *RenderPassEncoder, group_index: u32, group: ?*BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        raw.call(void, "wgpuRenderPassEncoderSetBindGroup", .{ self, group_index, group, dynamic_offset_count, dynamic_offsets });
    }
    pub inline fn setBlendConstant(self: *RenderPassEncoder, color: *const Color) void {
        raw.call(void, "wgpuRenderPassEncoderSetBlendConstant", .{ self, color });
    }
    pub inline fn setIndexBuffer(self: *RenderPassEncoder, buffer: *Buffer, format: IndexFormat, offset: u64, size: u64) void {
        raw.call(void, "wgpuRenderPassEncoderSetIndexBuffer", .{ self, buffer, format, offset, size });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *RenderPassEncoder, label: []const u8) void {
    //     wgpuRenderPassEncoderSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn setPipeline(self: *RenderPassEncoder, pipeline: *RenderPipeline) void {
        raw.call(void, "wgpuRenderPassEncoderSetPipeline", .{ self, pipeline });
    }
    pub inline fn setScissorRect(self: *RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        raw.call(void, "wgpuRenderPassEncoderSetScissorRect", .{ self, x, y, width, height });
    }
    pub inline fn setStencilReference(self: *RenderPassEncoder, stencil_reference: u32) void {
        raw.call(void, "wgpuRenderPassEncoderSetStencilReference", .{ self, stencil_reference });
    }
    pub inline fn setVertexBuffer(self: *RenderPassEncoder, slot: u32, buffer: ?*Buffer, offset: u64, size: u64) void {
        raw.call(void, "wgpuRenderPassEncoderSetVertexBuffer", .{ self, slot, buffer, offset, size });
    }
    pub inline fn setViewport(self: *RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        raw.call(void, "wgpuRenderPassEncoderSetViewport", .{ self, x, y, width, height, min_depth, max_depth });
    }
    pub inline fn addRef(self: *RenderPassEncoder) void {
        raw.call(void, "wgpuRenderPassEncoderAddRef", .{self});
    }
    pub inline fn release(self: *RenderPassEncoder) void {
        raw.call(void, "wgpuRenderPassEncoderRelease", .{self});
    }

    // wgpu-native
    pub inline fn setImmediates(self: *RenderPassEncoder, offset: u32, size_bytes: u32, data: *const anyopaque) void {
        raw.call(void, "wgpuRenderPassEncoderSetImmediates", .{ self, offset, size_bytes, data });
    }
    pub inline fn multiDrawIndirect(self: *RenderPassEncoder, buffer: *Buffer, offset: u64, count: u32) void {
        raw.call(void, "wgpuRenderPassEncoderMultiDrawIndirect", .{ self, buffer, offset, count });
    }
    pub inline fn multiDrawIndexedIndirect(self: *RenderPassEncoder, buffer: *Buffer, offset: u64, count: u32) void {
        raw.call(void, "wgpuRenderPassEncoderMultiDrawIndexedIndirect", .{ self, buffer, offset, count });
    }
    pub inline fn multiDrawIndirectCount(self: *RenderPassEncoder, buffer: *Buffer, offset: u64, count_buffer: *Buffer, count_buffer_offset: u64, max_count: u32) void {
        raw.call(void, "wgpuRenderPassEncoderMultiDrawIndirectCount", .{ self, buffer, offset, count_buffer, count_buffer_offset, max_count });
    }
    pub inline fn multiDrawIndexedIndirectCount(self: *RenderPassEncoder, buffer: *Buffer, offset: u64, count_buffer: *Buffer, count_buffer_offset: u64, max_count: u32) void {
        raw.call(void, "wgpuRenderPassEncoderMultiDrawIndexedIndirectCount", .{ self, buffer, offset, count_buffer, count_buffer_offset, max_count });
    }
    pub inline fn beginPipelineStatisticsQuery(self: *RenderPassEncoder, query_set: *QuerySet, query_index: u32) void {
        raw.call(void, "wgpuRenderPassEncoderBeginPipelineStatisticsQuery", .{ self, query_set, query_index });
    }
    pub inline fn endPipelineStatisticsQuery(self: *RenderPassEncoder) void {
        raw.call(void, "wgpuRenderPassEncoderEndPipelineStatisticsQuery", .{self});
    }
    pub inline fn writeTimestamp(self: *RenderPassEncoder, query_set: *QuerySet, query_index: u32) void {
        raw.call(void, "wgpuRenderPassEncoderWriteTimestamp", .{ self, query_set, query_index });
    }
};

pub const CommandBufferDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
};

pub const CommandBuffer = opaque {
    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *CommandBuffer, label: []const u8) void {
    //     wgpuCommandBufferSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *CommandBuffer) void {
        raw.call(void, "wgpuCommandBufferAddRef", .{self});
    }
    pub inline fn release(self: *CommandBuffer) void {
        raw.call(void, "wgpuCommandBufferRelease", .{self});
    }
};

pub const CommandEncoder = opaque {
    pub inline fn beginComputePass(self: *CommandEncoder, descriptor: ?*const ComputePassDescriptor) ?*ComputePassEncoder {
        return raw.call(?*ComputePassEncoder, "wgpuCommandEncoderBeginComputePass", .{ self, descriptor });
    }
    pub inline fn beginRenderPass(self: *CommandEncoder, descriptor: *const RenderPassDescriptor) ?*RenderPassEncoder {
        return raw.call(?*RenderPassEncoder, "wgpuCommandEncoderBeginRenderPass", .{ self, descriptor });
    }
    pub inline fn clearBuffer(self: *CommandEncoder, buffer: *Buffer, offset: u64, size: u64) void {
        raw.call(void, "wgpuCommandEncoderClearBuffer", .{ self, buffer, offset, size });
    }
    pub inline fn copyBufferToBuffer(self: *CommandEncoder, source: *Buffer, source_offset: u64, destination: *Buffer, destination_offset: u64, size: u64) void {
        raw.call(void, "wgpuCommandEncoderCopyBufferToBuffer", .{ self, source, source_offset, destination, destination_offset, size });
    }
    pub inline fn copyBufferToTexture(self: *CommandEncoder, source: *const TexelCopyBufferInfo, destination: *const TexelCopyTextureInfo, copy_size: *const Extent3D) void {
        raw.call(void, "wgpuCommandEncoderCopyBufferToTexture", .{ self, source, destination, copy_size });
    }
    pub inline fn copyTextureToBuffer(self: *CommandEncoder, source: *const TexelCopyTextureInfo, destination: *const TexelCopyBufferInfo, copy_size: *const Extent3D) void {
        raw.call(void, "wgpuCommandEncoderCopyTextureToBuffer", .{ self, source, destination, copy_size });
    }
    pub inline fn copyTextureToTexture(self: *CommandEncoder, source: *const TexelCopyTextureInfo, destination: *const TexelCopyTextureInfo, copy_size: *const Extent3D) void {
        raw.call(void, "wgpuCommandEncoderCopyTextureToTexture", .{ self, source, destination, copy_size });
    }
    pub inline fn finish(self: *CommandEncoder, descriptor: ?*const CommandBufferDescriptor) ?*CommandBuffer {
        return raw.call(?*CommandBuffer, "wgpuCommandEncoderFinish", .{ self, descriptor });
    }
    pub inline fn insertDebugMarker(self: *CommandEncoder, marker_label: []const u8) void {
        raw.call(void, "wgpuCommandEncoderInsertDebugMarker", .{ self, StringView.fromSlice(marker_label) });
    }
    pub inline fn popDebugGroup(self: *CommandEncoder) void {
        raw.call(void, "wgpuCommandEncoderPopDebugGroup", .{self});
    }
    pub inline fn pushDebugGroup(self: *CommandEncoder, group_label: []const u8) void {
        raw.call(void, "wgpuCommandEncoderPushDebugGroup", .{ self, StringView.fromSlice(group_label) });
    }
    pub inline fn resolveQuerySet(self: *CommandEncoder, query_set: *QuerySet, first_query: u32, query_count: u32, destination: *Buffer, destination_offset: u64) void {
        raw.call(void, "wgpuCommandEncoderResolveQuerySet", .{ self, query_set, first_query, query_count, destination, destination_offset });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *CommandEncoder, label: []const u8) void {
    //     wgpuCommandEncoderSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn writeTimestamp(self: *CommandEncoder, query_set: *QuerySet, query_index: u32) void {
        raw.call(void, "wgpuCommandEncoderWriteTimestamp", .{ self, query_set, query_index });
    }
    pub inline fn addRef(self: *CommandEncoder) void {
        raw.call(void, "wgpuCommandEncoderAddRef", .{self});
    }
    pub inline fn release(self: *CommandEncoder) void {
        raw.call(void, "wgpuCommandEncoderRelease", .{self});
    }
};
