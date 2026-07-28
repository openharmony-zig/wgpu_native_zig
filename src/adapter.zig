const raw = @import("raw.zig");
const std = @import("std");

const _chained_struct = @import("chained_struct.zig");
const ChainedStruct = _chained_struct.ChainedStruct;
const ChainedStructOut = _chained_struct.ChainedStructOut;

const _misc = @import("misc.zig");
const WGPUBool = _misc.WGPUBool;
const StringView = _misc.StringView;
const Status = _misc.Status;

const _feature = @import("feature.zig");
const FeatureName = _feature.FeatureName;
const SupportedFeatures = _feature.SupportedFeatures;

const Limits = @import("limits.zig").Limits;

const Surface = @import("surface.zig").Surface;

const Instance = @import("instance.zig").Instance;

const _device = @import("device.zig");
const Device = _device.Device;
const DeviceDescriptor = _device.DeviceDescriptor;

const _async = @import("async.zig");
const CallbackMode = _async.CallbackMode;
const Future = _async.Future;

pub const PowerPreference = enum(u32) {
    undefined = 0x00000000, // No preference.
    low_power = 0x00000001,
    high_performance = 0x00000002,
};

pub const AdapterType = enum(u32) {
    discrete_gpu = 0x00000001,
    integrated_gpu = 0x00000002,
    cpu = 0x00000003,
    unknown = 0x00000004,
};

pub const BackendType = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument
    null = 0x00000001,
    webgpu = 0x00000002,
    d3d11 = 0x00000003,
    d3d12 = 0x00000004,
    metal = 0x00000005,
    vulkan = 0x00000006,
    opengl = 0x00000007,
    opengl_es = 0x00000008,
};

pub const FeatureLevel = enum(u32) {
    undefined = 0x00000000,
    compatibility = 0x00000001, // "Compatibility" profile which can be supported on OpenGL ES 3.1.
    core = 0x00000002, // "Core" profile which can be supported on Vulkan/Metal/D3D12.
};

pub const RequestAdapterOptions = extern struct {
    next_in_chain: ?*const ChainedStruct = null,

    // "Feature level" for the adapter request. If an adapter is returned,
    // it must support the features and limits in the requested feature level.
    //
    // Implementations may ignore FeatureLevel.compatibility and provide FeatureLevel.core instead.
    // FeatureLevel.core is the default in the JS API, but in C, this field is **required** (must not be undefined).
    feature_level: FeatureLevel = FeatureLevel.core,

    power_preference: PowerPreference = PowerPreference.undefined,

    // If true, requires the adapter to be a "fallback" adapter as defined by the JS spec.
    // If this is not possible, the request returns null.
    force_fallback_adapter: WGPUBool = @intFromBool(false),

    // If set, requires the adapter to have a particular backend type.
    // If this is not possible, the request returns null.
    backend_type: BackendType = BackendType.undefined,

    // If set, requires the adapter to be able to output to a particular surface.
    // If this is not possible, the request returns null.
    compatible_surface: ?*Surface = null,
};

pub const RequestAdapterWebXROptions = extern struct {
    chain: ChainedStruct = .{
        .s_type = .request_adapter_webxr_options,
    },
    xr_compatible: WGPUBool = @intFromBool(false),
};

pub const AdapterInfo = extern struct {
    next_in_chain: ?*ChainedStructOut = null,
    vendor: StringView,
    architecture: StringView,
    device: StringView,
    description: StringView,
    backend_type: BackendType,
    adapter_type: AdapterType,
    vendor_id: u32,
    device_id: u32,
    subgroup_min_size: u32,
    subgroup_max_size: u32,

    pub inline fn freeMembers(self: AdapterInfo) void {
        raw.call(void, "wgpuAdapterInfoFreeMembers", .{self});
    }
};

pub const Adapter = opaque {
    pub const RequestDeviceStatus = enum(u32) {
        success = 0x00000001,
        callback_cancelled = 0x00000002,
        @"error" = 0x00000003,
    };

    pub const RequestDeviceCallback = *const fn (
        status: RequestDeviceStatus,
        device: ?*Device,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void;

    pub const RequestDeviceCallbackInfo = extern struct {
        next_in_chain: ?*ChainedStruct = null,

        // TODO: Revisit this default if/when Instance.waitAny() is implemented.
        mode: CallbackMode = .allow_process_events,

        callback: RequestDeviceCallback,
        userdata1: ?*anyopaque = null,
        userdata2: ?*anyopaque = null,
    };

    pub const RequestDeviceResponse = struct {
        status: RequestDeviceStatus,
        message: ?[]const u8,
        device: ?*Device,
    };

    pub inline fn getFeatures(self: *Adapter, features: *SupportedFeatures) void {
        raw.call(void, "wgpuAdapterGetFeatures", .{ self, features });
    }
    pub inline fn getLimits(self: *Adapter, limits: *Limits) Status {
        return raw.call(Status, "wgpuAdapterGetLimits", .{ self, limits });
    }
    pub inline fn getInfo(self: *Adapter, info: *AdapterInfo) Status {
        return raw.call(Status, "wgpuAdapterGetInfo", .{ self, info });
    }
    pub inline fn hasFeature(self: *Adapter, feature: FeatureName) bool {
        return raw.call(WGPUBool, "wgpuAdapterHasFeature", .{ self, feature }) != 0;
    }

    fn defaultDeviceCallback(status: RequestDeviceStatus, device: ?*Device, message: StringView, userdata1: ?*anyopaque, userdata2: ?*anyopaque) callconv(.c) void {
        const ud_response: *RequestDeviceResponse = @ptrCast(@alignCast(userdata1));
        ud_response.* = RequestDeviceResponse{
            .status = status,
            .message = message.toSlice(),
            .device = device,
        };

        const completed: *bool = @ptrCast(@alignCast(userdata2));
        completed.* = true;
    }

    // This is a synchronous wrapper that handles asynchronous (callback) logic.
    // It uses polling to see when the request has been fulfilled, so needs a polling interval parameter.
    pub fn requestDeviceSync(
        self: *Adapter,
        io: std.Io,
        instance: *Instance,
        descriptor: ?*const DeviceDescriptor,
        polling_interval_nanoseconds: u64,
    ) std.Io.Cancelable!RequestDeviceResponse {
        var response: RequestDeviceResponse = undefined;
        var completed = false;
        const callback_info = RequestDeviceCallbackInfo{
            .callback = defaultDeviceCallback,
            .userdata1 = @ptrCast(&response),
            .userdata2 = @ptrCast(&completed),
        };
        const device_future = raw.call(Future, "wgpuAdapterRequestDevice", .{ self, descriptor, callback_info });

        // TODO: Revisit once Instance.waitAny() is implemented in wgpu-native,
        //       it takes in futures and returns when one of them completes.
        _ = device_future;
        instance.processEvents();
        while (!completed) {
            try io.sleep(.fromNanoseconds(polling_interval_nanoseconds), .awake);
            instance.processEvents();
        }

        return response;
    }

    pub inline fn requestDevice(self: *Adapter, descriptor: ?*const DeviceDescriptor, callback_info: RequestDeviceCallbackInfo) Future {
        return raw.call(Future, "wgpuAdapterRequestDevice", .{ self, descriptor, callback_info });
    }
    pub inline fn addRef(self: *Adapter) void {
        raw.call(void, "wgpuAdapterAddRef", .{self});
    }
    pub inline fn release(self: *Adapter) void {
        raw.call(void, "wgpuAdapterRelease", .{self});
    }
};

test "can request device" {
    const testing = @import("std").testing;

    const instance = Instance.create(null).?;
    defer instance.release();
    const adapter_response = try instance.requestAdapterSync(std.testing.io, null, 200_000_000);
    const adapter: ?*Adapter = switch (adapter_response.status) {
        .success => adapter_response.adapter,
        else => null,
    };
    if (adapter == null) return error.SkipZigTest;
    defer adapter.?.release();
    const device_response = try adapter.?.requestDeviceSync(std.testing.io, instance, null, 200_000_000);
    const device: ?*Device = switch (device_response.status) {
        .success => device_response.device,
        else => null,
    };
    if (device == null) return error.SkipZigTest;
    defer device.?.release();
    try testing.expect(device != null);
}
