const std = @import("std");

const _misc = @import("misc.zig");
const WGPUBool = _misc.WGPUBool;
const WGPUFlags = _misc.WGPUFlags;
const StringView = _misc.StringView;
const USIZE_MAX = _misc.USIZE_MAX;

pub const WGPU_WHOLE_MAP_SIZE = USIZE_MAX;

const _async = @import("async.zig");
const CallbackMode = _async.CallbackMode;
const Future = _async.Future;

const ChainedStruct = @import("chained_struct.zig").ChainedStruct;
const raw = @import("raw.zig");

pub const BufferBindingType = enum(u32) {
    binding_not_used = 0x00000000, // Indicates that this BufferBindingLayout member of its parent BindGroupLayoutEntry is not used.
    undefined = 0x00000001, // Indicates no value is passed for this argument
    uniform = 0x00000002,
    storage = 0x00000003,
    read_only_storage = 0x00000004,
};

pub const BufferBindingLayout = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    type: BufferBindingType = BufferBindingType.undefined,
    has_dynamic_offset: WGPUBool = @intFromBool(false),
    min_binding_size: u64 = 0,
};

pub const BufferUsage = WGPUFlags;
pub const BufferUsages = struct {
    pub const none = @as(BufferUsage, 0x0000000000000000);
    pub const map_read = @as(BufferUsage, 0x0000000000000001);
    pub const map_write = @as(BufferUsage, 0x0000000000000002);
    pub const copy_src = @as(BufferUsage, 0x0000000000000004);
    pub const copy_dst = @as(BufferUsage, 0x0000000000000008);
    pub const index = @as(BufferUsage, 0x0000000000000010);
    pub const vertex = @as(BufferUsage, 0x0000000000000020);
    pub const uniform = @as(BufferUsage, 0x0000000000000040);
    pub const storage = @as(BufferUsage, 0x0000000000000080);
    pub const indirect = @as(BufferUsage, 0x0000000000000100);
    pub const query_resolve = @as(BufferUsage, 0x0000000000000200);
};

pub const BufferDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    usage: BufferUsage,
    size: u64,
    mapped_at_creation: WGPUBool = @intFromBool(false),
};

pub const Buffer = opaque {
    pub const MapState = enum(u32) {
        unmapped = 0x00000001,
        pending = 0x00000002,
        mapped = 0x00000003,
    };

    pub const MapMode = WGPUFlags;
    pub const MapModes = struct {
        pub const none = @as(MapMode, 0x0000000000000000);
        pub const read = @as(MapMode, 0x0000000000000001);
        pub const write = @as(MapMode, 0x0000000000000002);
    };

    pub const MapAsyncStatus = enum(u32) {
        success = 0x00000001,
        callback_cancelled = 0x00000002,
        @"error" = 0x00000003,
        aborted = 0x00000004,
    };

    pub const MapCallback = *const fn (
        status: MapAsyncStatus,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void;

    pub const MapCallbackInfo = extern struct {
        next_in_chain: ?*ChainedStruct = null,

        // TODO: Revisit this default if/when Instance.waitAny() is implemented.
        mode: CallbackMode = .allow_process_events,

        callback: MapCallback,
        userdata1: ?*anyopaque = null,
        userdata2: ?*anyopaque = null,
    };

    pub const MapResponse = struct {
        status: MapAsyncStatus,
        message: ?[]const u8,

        pub fn deinit(
            self: *MapResponse,
            allocator: std.mem.Allocator,
        ) void {
            if (self.message) |message| allocator.free(message);
            self.message = null;
        }
    };

    pub const MapSyncError =
        std.Io.Cancelable || std.mem.Allocator.Error;

    const MapSyncState = struct {
        allocator: std.mem.Allocator,
        response: MapResponse = undefined,
        message_error: ?std.mem.Allocator.Error = null,
        completed: bool = false,
    };

    fn defaultMapCallback(
        status: MapAsyncStatus,
        message: StringView,
        userdata1: ?*anyopaque,
        _: ?*anyopaque,
    ) callconv(.c) void {
        const state: *MapSyncState = @ptrCast(@alignCast(userdata1));
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

    pub inline fn destroy(self: *Buffer) void {
        raw.call(void, "wgpuBufferDestroy", .{self});
    }

    // offset
    // Byte offset relative to the beginning of the buffer.
    //
    // size
    // Byte size of the range to get. The returned pointer is valid for exactly this many bytes.
    //
    // Returns a const byte slice covering the mapped range.
    // It must not be written; writing to this range causes undefined behavior.
    // Returns `NULL` with ImplementationDefinedLogging if:
    //
    // - There is any content-timeline error as defined in the WebGPU specification for `getMappedRange()` (alignments, overlaps, etc.)
    //   **except** for overlaps with other *const* ranges, which are allowed in C.
    //   (JS does not allow this because const ranges do not exist.)
    //
    // wgpu-native translates a size of WGPU_WHOLE_MAP_SIZE to "None" internally
    pub inline fn getConstMappedRange(
        self: *Buffer,
        offset: usize,
        size: usize,
    ) ?[]const u8 {
        const length = self.mappedRangeLength(offset, size) orelse return null;
        const data = raw.call(
            ?*const anyopaque,
            "wgpuBufferGetConstMappedRange",
            .{ self, offset, size },
        ) orelse return null;
        return @as([*]const u8, @ptrCast(data))[0..length];
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn getMapState(self: *Buffer) MapState {
    //     return wgpuBufferGetMapState(self);
    // }

    // offset
    // Byte offset relative to the beginning of the buffer.
    //
    // size
    // Byte size of the range to get. The returned pointer is valid for exactly this many bytes.
    //
    // Returns a mutable byte slice covering the mapped range.
    // Returns `NULL` with ImplementationDefinedLogging if:
    //
    // - There is any content-timeline error as defined in the WebGPU specification for `getMappedRange()` (alignments, overlaps, etc.)
    // - The buffer is not mapped with MapMode.write.
    //
    // wgpu-native translates a size of WGPU_WHOLE_MAP_SIZE to "None" internally
    pub inline fn getMappedRange(
        self: *Buffer,
        offset: usize,
        size: usize,
    ) ?[]u8 {
        const length = self.mappedRangeLength(offset, size) orelse return null;
        const data = raw.call(
            ?*anyopaque,
            "wgpuBufferGetMappedRange",
            .{ self, offset, size },
        ) orelse return null;
        return @as([*]u8, @ptrCast(data))[0..length];
    }

    fn mappedRangeLength(
        self: *Buffer,
        offset: usize,
        size: usize,
    ) ?usize {
        if (size != WGPU_WHOLE_MAP_SIZE) return size;
        const buffer_size = std.math.cast(usize, self.getSize()) orelse
            return null;
        if (offset > buffer_size) return null;
        return buffer_size - offset;
    }

    pub inline fn getSize(self: *Buffer) u64 {
        return raw.call(u64, "wgpuBufferGetSize", .{self});
    }
    pub inline fn getUsage(self: *Buffer) BufferUsage {
        return raw.call(BufferUsage, "wgpuBufferGetUsage", .{self});
    }

    pub inline fn mapAsync(self: *Buffer, mode: MapMode, offset: usize, size: usize, callback_info: MapCallbackInfo) Future {
        return raw.call(Future, "wgpuBufferMapAsync", .{ self, mode, offset, size, callback_info });
    }

    /// Maps a buffer while safely driving an allow_process_events callback.
    /// The returned response owns its copied message until deinit() is called.
    pub fn mapSync(
        self: *Buffer,
        allocator: std.mem.Allocator,
        io: std.Io,
        event_source: anytype,
        mode: MapMode,
        offset: usize,
        size: usize,
        polling_interval_nanoseconds: u64,
    ) MapSyncError!MapResponse {
        var state = MapSyncState{ .allocator = allocator };
        _ = self.mapAsync(mode, offset, size, .{
            .callback = defaultMapCallback,
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
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *Buffer, label: []const u8) void {
    //     wgpuBufferSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn unmap(self: *Buffer) void {
        raw.call(void, "wgpuBufferUnmap", .{self});
    }
    pub inline fn addRef(self: *Buffer) void {
        raw.call(void, "wgpuBufferAddRef", .{self});
    }
    pub inline fn release(self: *Buffer) void {
        raw.call(void, "wgpuBufferRelease", .{self});
    }
};

test "synchronous map callback copies its message" {
    var callback_message = [_]u8{ 'o', 'l', 'd' };
    var state = Buffer.MapSyncState{ .allocator = std.testing.allocator };
    Buffer.defaultMapCallback(
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
