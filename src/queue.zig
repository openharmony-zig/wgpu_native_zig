const raw = @import("raw.zig");
const ChainedStruct = @import("chained_struct.zig").ChainedStruct;
const CommandBuffer = @import("command_encoder.zig").CommandBuffer;
const Buffer = @import("buffer.zig").Buffer;

const _texture = @import("texture.zig");
const TexelCopyTextureInfo = _texture.TexelCopyTextureInfo;
const TexelCopyBufferLayout = _texture.TexelCopyBufferLayout;
const Extent3D = _texture.Extent3D;

const _async = @import("async.zig");
const CallbackMode = _async.CallbackMode;
const Future = _async.Future;

const StringView = @import("misc.zig").StringView;

pub const SubmissionIndex = u64;

pub const QueueDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
};

pub const WorkDoneStatus = enum(u32) {
    success = 0x00000001,
    callback_cancelled = 0x00000002,
    @"error" = 0x00000003,
};

pub const QueueWorkDoneCallbackInfo = extern struct {
    next_in_chain: ?*ChainedStruct = null,

    // TODO: Revisit this default if/when Instance.waitAny() is implemented.
    mode: CallbackMode = CallbackMode.allow_process_events,

    callback: QueueWorkDoneCallback,
    userdata1: ?*anyopaque = null,
    userdata2: ?*anyopaque = null,
};

pub const QueueWorkDoneCallback = *const fn (status: WorkDoneStatus, message: StringView, userdata1: ?*anyopaque, userdata2: ?*anyopaque) callconv(.c) void;

// wgpu-native

pub const Queue = opaque {
    pub inline fn onSubmittedWorkDone(self: *Queue, callback_info: QueueWorkDoneCallbackInfo) Future {
        return raw.call(Future, "wgpuQueueOnSubmittedWorkDone", .{ self, callback_info });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *Queue, label: []const u8) void {
    //     wgpuQueueSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn submit(self: *Queue, commands: []const *const CommandBuffer) void {
        raw.call(void, "wgpuQueueSubmit", .{ self, commands.len, commands.ptr });
    }

    pub inline fn writeBuffer(self: *Queue, buffer: *Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) void {
        raw.call(void, "wgpuQueueWriteBuffer", .{ self, buffer, buffer_offset, data, size });
    }

    pub inline fn writeTexture(self: *Queue, destination: *const TexelCopyTextureInfo, data: *const anyopaque, data_size: usize, data_layout: *const TexelCopyBufferLayout, write_size: *const Extent3D) void {
        raw.call(void, "wgpuQueueWriteTexture", .{ self, destination, data, data_size, data_layout, write_size });
    }
    pub inline fn addRef(self: *Queue) void {
        raw.call(void, "wgpuQueueAddRef", .{self});
    }
    pub inline fn release(self: *Queue) void {
        raw.call(void, "wgpuQueueRelease", .{self});
    }

    // wgpu-native
    pub inline fn submitForIndex(self: *Queue, commands: []const *const CommandBuffer) SubmissionIndex {
        return raw.call(SubmissionIndex, "wgpuQueueSubmitForIndex", .{ self, commands.len, commands.ptr });
    }
};
