const std = @import("std");

const raw = @import("raw.zig");
const ChainedStruct = @import("chained_struct.zig").ChainedStruct;
const CommandBuffer = @import("command_encoder.zig").CommandBuffer;
const Buffer = @import("buffer.zig").Buffer;

const _copy = @import("copy.zig");
const TexelCopyTextureInfo = _copy.TexelCopyTextureInfo;
const TexelCopyBufferLayout = _copy.TexelCopyBufferLayout;

const _texture = @import("texture.zig");
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

// wgpu-native

pub const Queue = opaque {
    pub const WorkDoneStatus = enum(u32) {
        success = 0x00000001,
        callback_cancelled = 0x00000002,
        @"error" = 0x00000003,
    };

    pub const WorkDoneCallback = *const fn (
        status: WorkDoneStatus,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void;

    pub const WorkDoneCallbackInfo = extern struct {
        next_in_chain: ?*ChainedStruct = null,

        // TODO: Revisit this default if/when Instance.waitAny() is implemented.
        mode: CallbackMode = .allow_process_events,

        callback: WorkDoneCallback,
        userdata1: ?*anyopaque = null,
        userdata2: ?*anyopaque = null,
    };

    pub const WorkDoneResponse = struct {
        status: WorkDoneStatus,
        message: ?[]const u8,

        pub fn deinit(
            self: *WorkDoneResponse,
            allocator: std.mem.Allocator,
        ) void {
            if (self.message) |message| allocator.free(message);
            self.message = null;
        }
    };

    pub const WorkDoneSyncError =
        std.Io.Cancelable || std.mem.Allocator.Error;

    const WorkDoneSyncState = struct {
        allocator: std.mem.Allocator,
        response: WorkDoneResponse = undefined,
        message_error: ?std.mem.Allocator.Error = null,
        completed: bool = false,
    };

    fn defaultWorkDoneCallback(
        status: WorkDoneStatus,
        message: StringView,
        userdata1: ?*anyopaque,
        _: ?*anyopaque,
    ) callconv(.c) void {
        const state: *WorkDoneSyncState = @ptrCast(@alignCast(userdata1));
        state.response = .{
            .status = status,
            .message = null,
        };
        state.response.message = _async.copyCallbackMessage(
            state.allocator,
            message,
        ) catch |err| {
            state.message_error = err;
            state.completed = true;
            return;
        };
        state.completed = true;
    }

    pub inline fn onSubmittedWorkDone(self: *Queue, callback_info: WorkDoneCallbackInfo) Future {
        return raw.call(Future, "wgpuQueueOnSubmittedWorkDone", .{ self, callback_info });
    }

    /// Waits for previously submitted work while safely driving an
    /// allow_process_events callback. The response owns its copied message.
    pub fn onSubmittedWorkDoneSync(
        self: *Queue,
        allocator: std.mem.Allocator,
        io: std.Io,
        event_source: anytype,
        polling_interval_nanoseconds: u64,
    ) WorkDoneSyncError!WorkDoneResponse {
        var state = WorkDoneSyncState{ .allocator = allocator };
        _ = self.onSubmittedWorkDone(.{
            .callback = defaultWorkDoneCallback,
            .userdata1 = @ptrCast(&state),
        });

        var wait_error: ?std.Io.Cancelable = null;
        _async.waitForCallback(
            event_source,
            &state.completed,
            io,
            polling_interval_nanoseconds,
        ) catch |err| {
            wait_error = err;
        };

        if (state.message_error) |err| {
            state.response.deinit(allocator);
            return err;
        }
        if (wait_error) |err| {
            state.response.deinit(allocator);
            return err;
        }
        return state.response;
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/4a26b5b0757fe281c07dac4f3a6e2078c811f635/src/unimplemented.rs
    // pub inline fn setLabel(self: *Queue, label: []const u8) void {
    //     wgpuQueueSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn submit(self: *Queue, commands: []const *const CommandBuffer) void {
        raw.call(void, "wgpuQueueSubmit", .{ self, commands.len, commands.ptr });
    }

    pub inline fn writeBuffer(
        self: *Queue,
        buffer: *Buffer,
        buffer_offset: u64,
        data: []const u8,
    ) void {
        raw.call(void, "wgpuQueueWriteBuffer", .{
            self,
            buffer,
            buffer_offset,
            data.ptr,
            data.len,
        });
    }

    pub inline fn writeTexture(
        self: *Queue,
        destination: *const TexelCopyTextureInfo,
        data: []const u8,
        data_layout: *const TexelCopyBufferLayout,
        write_size: *const Extent3D,
    ) void {
        raw.call(void, "wgpuQueueWriteTexture", .{
            self,
            destination,
            data.ptr,
            data.len,
            data_layout,
            write_size,
        });
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

    /// Returns the number of nanoseconds represented by one timestamp-query tick.
    pub inline fn getTimestampPeriod(self: *Queue) f32 {
        return raw.call(f32, "wgpuQueueGetTimestampPeriod", .{self});
    }
};

test "synchronous work-done callback copies its message" {
    var callback_message = [_]u8{ 'o', 'l', 'd' };
    var state = Queue.WorkDoneSyncState{ .allocator = std.testing.allocator };
    Queue.defaultWorkDoneCallback(
        .@"error",
        StringView.fromSlice(&callback_message),
        @ptrCast(&state),
        null,
    );
    defer state.response.deinit(std.testing.allocator);

    callback_message[0] = 'n';
    try std.testing.expect(state.completed);
    try std.testing.expectEqualStrings("old", state.response.message.?);
}
