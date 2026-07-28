const raw = @import("raw.zig");
const std = @import("std");

const _chained_struct = @import("chained_struct.zig");
const ChainedStruct = _chained_struct.ChainedStruct;
const SType = _chained_struct.SType;

const _misc = @import("misc.zig");
const WGPUBool = _misc.WGPUBool;
const StringView = _misc.StringView;
const Status = _misc.Status;

const _feature = @import("feature.zig");
const FeatureName = _feature.FeatureName;
const SupportedFeatures = _feature.SupportedFeatures;

const _async = @import("async.zig");
const CallbackMode = _async.CallbackMode;
const Future = _async.Future;

const _limits = @import("limits.zig");
const Limits = _limits.Limits;

const AdapterInfo = @import("adapter.zig").AdapterInfo;

const _bind_group = @import("bind_group.zig");
const BindGroupDescriptor = _bind_group.BindGroupDescriptor;
const BindGroup = _bind_group.BindGroup;
const BindGroupLayoutDescriptor = _bind_group.BindGroupLayoutDescriptor;
const BindGroupLayout = _bind_group.BindGroupLayout;

const _buffer = @import("buffer.zig");
const BufferDescriptor = _buffer.BufferDescriptor;
const Buffer = _buffer.Buffer;

const _queue = @import("queue.zig");
const QueueDescriptor = _queue.QueueDescriptor;
const Queue = _queue.Queue;
const SubmissionIndex = _queue.SubmissionIndex;

const _command_encoder = @import("command_encoder.zig");
const CommandEncoderDescriptor = _command_encoder.CommandEncoderDescriptor;
const CommandEncoder = _command_encoder.CommandEncoder;

const _pipeline = @import("pipeline.zig");
const ComputePipelineDescriptor = _pipeline.ComputePipelineDescriptor;
const ComputePipeline = _pipeline.ComputePipeline;
const PipelineLayoutDescriptor = _pipeline.PipelineLayoutDescriptor;
const PipelineLayout = _pipeline.PipelineLayout;
const RenderPipelineDescriptor = _pipeline.RenderPipelineDescriptor;
const RenderPipeline = _pipeline.RenderPipeline;

const _query_set = @import("query_set.zig");
const QuerySetDescriptor = _query_set.QuerySetDescriptor;
const QuerySet = _query_set.QuerySet;

const RenderBundleEncoderDescriptor = _command_encoder.RenderBundleEncoderDescriptor;
const RenderBundleEncoder = _command_encoder.RenderBundleEncoder;

const _sampler = @import("sampler.zig");
const SamplerDescriptor = _sampler.SamplerDescriptor;
const Sampler = _sampler.Sampler;

const _shader = @import("shader.zig");
const ShaderModuleDescriptor = _shader.ShaderModuleDescriptor;
const ShaderModuleDescriptorSpirV = _shader.ShaderModuleDescriptorSpirV;
const ShaderModule = _shader.ShaderModule;

const _texture = @import("texture.zig");
const TextureDescriptor = _texture.TextureDescriptor;
const Texture = _texture.Texture;

/// Borrowed backend-native `id<MTLDevice>` returned by wgpu-native.
pub const NativeMetalDevice = opaque {};

pub const DeviceExtras = extern struct {
    chain: ChainedStruct = ChainedStruct{
        .s_type = SType.device_extras,
    },
    trace_path: StringView,
};

pub const DeviceDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
    required_feature_count: usize = 0,
    required_features: [*]const FeatureName = &[0]FeatureName{},
    required_limits: ?*const Limits,
    default_queue: QueueDescriptor = QueueDescriptor{},
    device_lost_callback_info: Device.DeviceLostCallbackInfo = .{},
    uncaptured_error_callback_info: Device.UncapturedErrorCallbackInfo = .{},

    pub inline fn withTracePath(self: DeviceDescriptor, trace_path: []const u8) DeviceDescriptor {
        var dd = self;
        dd.next_in_chain = @ptrCast(&DeviceExtras{
            .trace_path = StringView.fromSlice(trace_path),
        });
        return dd;
    }
};

// wgpu-native

pub const Device = opaque {
    pub const DeviceLostReason = enum(u32) {
        unknown = 0x00000001,
        destroyed = 0x00000002,
        callback_cancelled = 0x00000003,
        failed_creation = 0x00000004,
    };

    // `device` is a reference to the device which was lost. If, and only if,
    // `reason` is `failed_creation`, it points to a null Device handle.
    pub const DeviceLostCallback = *const fn (
        device: *const ?*Device,
        reason: DeviceLostReason,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void;

    pub const DeviceLostCallbackInfo = extern struct {
        next_in_chain: ?*ChainedStruct = null,

        // TODO: Revisit this default if/when Instance.waitAny() is implemented.
        mode: CallbackMode = .allow_process_events,
        callback: DeviceLostCallback = defaultDeviceLostCallback,
        userdata1: ?*anyopaque = null,
        userdata2: ?*anyopaque = null,
    };

    pub fn defaultDeviceLostCallback(
        device: *const ?*Device,
        reason: DeviceLostReason,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void {
        _ = device;
        _ = userdata1;
        _ = userdata2;
        std.debug.panic(
            "Device lost: reason={s} message=\"{s}\"\n",
            .{ @tagName(reason), message.toSlice() orelse "" },
        );
    }

    pub const ErrorType = enum(u32) {
        no_error = 0x00000001,
        validation = 0x00000002,
        out_of_memory = 0x00000003,
        internal = 0x00000004,
        unknown = 0x00000005,
    };

    pub const UncapturedErrorCallback = *const fn (
        device: ?*Device,
        error_type: ErrorType,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void;

    pub const ErrorFilter = enum(u32) {
        validation = 0x00000001,
        out_of_memory = 0x00000002,
        internal = 0x00000003,
    };

    pub const UncapturedErrorCallbackInfo = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        callback: ?UncapturedErrorCallback = null,
        userdata1: ?*anyopaque = null,
        userdata2: ?*anyopaque = null,
    };

    pub const PopErrorScopeStatus = enum(u32) {
        success = 0x00000001,
        callback_cancelled = 0x00000002,
        @"error" = 0x00000003,
    };

    pub const PopErrorScopeCallback = *const fn (
        status: PopErrorScopeStatus,
        error_type: ErrorType,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void;

    pub const PopErrorScopeCallbackInfo = extern struct {
        next_in_chain: ?*ChainedStruct = null,

        // TODO: Revisit this default if/when Instance.waitAny() is implemented.
        mode: CallbackMode = .allow_process_events,

        callback: PopErrorScopeCallback,
        userdata1: ?*anyopaque = null,
        userdata2: ?*anyopaque = null,
    };

    pub const CreatePipelineAsyncStatus = enum(u32) {
        success = 0x00000001,
        callback_cancelled = 0x00000002,
        validation_error = 0x00000003,
        internal_error = 0x00000004,
    };

    pub const CreateComputePipelineAsyncCallback = *const fn (
        status: CreatePipelineAsyncStatus,
        pipeline: ?*ComputePipeline,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void;

    pub const CreateComputePipelineAsyncCallbackInfo = extern struct {
        next_in_chain: ?*ChainedStruct = null,

        // TODO: Revisit this default if/when Instance.waitAny() is implemented.
        mode: CallbackMode = .allow_process_events,

        callback: CreateComputePipelineAsyncCallback,
        userdata1: ?*anyopaque = null,
        userdata2: ?*anyopaque = null,
    };

    pub const CreateRenderPipelineAsyncCallback = *const fn (
        status: CreatePipelineAsyncStatus,
        pipeline: ?*RenderPipeline,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.c) void;

    pub const CreateRenderPipelineAsyncCallbackInfo = extern struct {
        next_in_chain: ?*ChainedStruct = null,

        // TODO: Revisit this default if/when Instance.waitAny() is implemented.
        mode: CallbackMode = .allow_process_events,

        callback: CreateRenderPipelineAsyncCallback,
        userdata1: ?*anyopaque = null,
        userdata2: ?*anyopaque = null,
    };

    pub inline fn createBindGroup(self: *Device, descriptor: *const BindGroupDescriptor) ?*BindGroup {
        return raw.call(?*BindGroup, "wgpuDeviceCreateBindGroup", .{ self, descriptor });
    }
    pub inline fn createBindGroupLayout(self: *Device, descriptor: *const BindGroupLayoutDescriptor) ?*BindGroupLayout {
        return raw.call(?*BindGroupLayout, "wgpuDeviceCreateBindGroupLayout", .{ self, descriptor });
    }
    pub inline fn createBuffer(self: *Device, descriptor: *const BufferDescriptor) ?*Buffer {
        return raw.call(?*Buffer, "wgpuDeviceCreateBuffer", .{ self, descriptor });
    }
    pub inline fn createCommandEncoder(self: *Device, descriptor: ?*const CommandEncoderDescriptor) ?*CommandEncoder {
        return raw.call(?*CommandEncoder, "wgpuDeviceCreateCommandEncoder", .{ self, descriptor });
    }
    pub inline fn createComputePipeline(self: *Device, descriptor: *const ComputePipelineDescriptor) ?*ComputePipeline {
        return raw.call(?*ComputePipeline, "wgpuDeviceCreateComputePipeline", .{ self, descriptor });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn createComputePipelineAsync(self: *Device, descriptor: *const ComputePipelineDescriptor, callback_info: CreateComputePipelineAsyncCallbackInfo) Future {
    //     return wgpuDeviceCreateComputePipelineAsync(self, descriptor, callback_info);
    // }

    pub inline fn createPipelineLayout(self: *Device, descriptor: *const PipelineLayoutDescriptor) ?*PipelineLayout {
        return raw.call(?*PipelineLayout, "wgpuDeviceCreatePipelineLayout", .{ self, descriptor });
    }
    pub inline fn createQuerySet(self: *Device, descriptor: *const QuerySetDescriptor) ?*QuerySet {
        return raw.call(?*QuerySet, "wgpuDeviceCreateQuerySet", .{ self, descriptor });
    }
    pub inline fn createRenderBundleEncoder(self: *Device, descriptor: *const RenderBundleEncoderDescriptor) ?*RenderBundleEncoder {
        return raw.call(?*RenderBundleEncoder, "wgpuDeviceCreateRenderBundleEncoder", .{ self, descriptor });
    }
    pub inline fn createRenderPipeline(self: *Device, descriptor: *const RenderPipelineDescriptor) ?*RenderPipeline {
        return raw.call(?*RenderPipeline, "wgpuDeviceCreateRenderPipeline", .{ self, descriptor });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn createRenderPipelineAsync(self: *Device, descriptor: *const RenderPipelineDescriptor, callback_info: CreateRenderPipelineAsyncCallbackInfo) Future {
    //     return wgpuDeviceCreateRenderPipelineAsync(self, descriptor, callback_info);
    // }

    pub inline fn createSampler(self: *Device, descriptor: ?*const SamplerDescriptor) ?*Sampler {
        return raw.call(?*Sampler, "wgpuDeviceCreateSampler", .{ self, descriptor });
    }
    pub inline fn createShaderModule(self: *Device, descriptor: *const ShaderModuleDescriptor) ?*ShaderModule {
        return raw.call(?*ShaderModule, "wgpuDeviceCreateShaderModule", .{ self, descriptor });
    }
    pub inline fn createTexture(self: *Device, descriptor: *const TextureDescriptor) ?*Texture {
        return raw.call(?*Texture, "wgpuDeviceCreateTexture", .{ self, descriptor });
    }
    pub inline fn destroy(self: *Device) void {
        raw.call(void, "wgpuDeviceDestroy", .{self});
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn getAdapterInfo(self: *Device, adapter_info: *AdapterInfo) Status {
    //     return wgpuDeviceGetAdapterInfo(self, adapter_info);
    // }

    pub inline fn getFeatures(self: *Device, features: *SupportedFeatures) void {
        raw.call(void, "wgpuDeviceGetFeatures", .{ self, features });
    }
    pub inline fn getLimits(self: *Device, limits: *Limits) Status {
        return raw.call(Status, "wgpuDeviceGetLimits", .{ self, limits });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // Returns the Future for the device-lost event of the device.
    // pub inline fn getLostFuture(self: *Device) Future {
    //     return wgpuDeviceGetLostFuture(self);
    // }

    pub inline fn getQueue(self: *Device) ?*Queue {
        return raw.call(?*Queue, "wgpuDeviceGetQueue", .{self});
    }
    pub inline fn hasFeature(self: *Device, feature: FeatureName) bool {
        return raw.call(WGPUBool, "wgpuDeviceHasFeature", .{ self, feature }) != 0;
    }

    pub inline fn popErrorScope(self: *Device, callback_info: PopErrorScopeCallbackInfo) Future {
        return raw.call(Future, "wgpuDevicePopErrorScope", .{ self, callback_info });
    }
    pub inline fn pushErrorScope(self: *Device, filter: ErrorFilter) void {
        raw.call(void, "wgpuDevicePushErrorScope", .{ self, filter });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn setLabel(self: *Device, label: []const u8) void {
    //     wgpuDeviceSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *Device) void {
        raw.call(void, "wgpuDeviceAddRef", .{self});
    }
    pub inline fn release(self: *Device) void {
        raw.call(void, "wgpuDeviceRelease", .{self});
    }

    // wgpu-native
    pub inline fn poll(self: *Device, wait: bool, submission_index: ?*const SubmissionIndex) bool {
        return raw.call(WGPUBool, "wgpuDevicePoll", .{ self, @intFromBool(wait), submission_index }) != 0;
    }
    pub inline fn createShaderModuleSpirV(self: *Device, descriptor: *const ShaderModuleDescriptorSpirV) ?*ShaderModule {
        return raw.call(?*ShaderModule, "wgpuDeviceCreateShaderModuleSpirV", .{ self, descriptor });
    }

    /// Returns a borrowed Metal device when this device uses the Metal backend.
    /// The pointer remains valid only while `self` is alive and must not be released.
    pub inline fn getNativeMetalDevice(self: *Device) ?*NativeMetalDevice {
        return raw.call(?*NativeMetalDevice, "wgpuDeviceGetNativeMetalDevice", .{self});
    }

    /// Starts a platform graphics-debugger capture when supported.
    pub inline fn startGraphicsDebuggerCapture(self: *Device) bool {
        return raw.call(WGPUBool, "wgpuDeviceStartGraphicsDebuggerCapture", .{self}) != 0;
    }

    pub inline fn stopGraphicsDebuggerCapture(self: *Device) void {
        raw.call(void, "wgpuDeviceStopGraphicsDebuggerCapture", .{self});
    }
};

// TODO: Test methods of Device (as long as they can be tested headlessly: see https://eliemichel.github.io/LearnWebGPU/advanced-techniques/headless.html)
