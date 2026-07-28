const raw = @import("raw.zig");
const std = @import("std");

const _chained_struct = @import("chained_struct.zig");
const ChainedStruct = _chained_struct.ChainedStruct;
const SType = _chained_struct.SType;

const _adapter = @import("adapter.zig");
const Adapter = _adapter.Adapter;
const RequestAdapterOptions = _adapter.RequestAdapterOptions;
const RequestAdapterCallbackInfo = _adapter.RequestAdapterCallbackInfo;
const RequestAdapterCallback = _adapter.RequestAdapterCallback;
const RequestAdapterStatus = _adapter.RequestAdapterStatus;
const RequestAdapterResponse = _adapter.RequestAdapterResponse;
const BackendType = _adapter.BackendType;

const _surface = @import("surface.zig");
const Surface = _surface.Surface;
const SurfaceDescriptor = _surface.SurfaceDescriptor;

const _misc = @import("misc.zig");
const WGPUFlags = _misc.WGPUFlags;
const StringView = _misc.StringView;
const Status = _misc.Status;

const _async = @import("async.zig");
const Future = _async.Future;
const WaitStatus = _async.WaitStatus;
const FutureWaitInfo = _async.FutureWaitInfo;

pub const InstanceBackend = WGPUFlags;
pub const InstanceBackends = struct {
    pub const all = @as(InstanceBackend, 0x00000000);
    pub const vulkan = @as(InstanceBackend, 0x00000001);
    pub const gl = @as(InstanceBackend, 0x00000002);
    pub const metal = @as(InstanceBackend, 0x00000004);
    pub const dx12 = @as(InstanceBackend, 0x00000008);
    pub const dx11 = @as(InstanceBackend, 0x00000010);
    pub const browser_webgpu = @as(InstanceBackend, 0x00000020);
    pub const primary = vulkan | metal | dx12 | browser_webgpu;
    pub const secondary = gl | dx11;
};

pub const InstanceFlag = WGPUFlags;
pub const InstanceFlags = struct {
    pub const default = @as(InstanceFlag, 0x00000000);
    pub const debug = @as(InstanceFlag, 0x00000001);
    pub const validation = @as(InstanceFlag, 0x00000002);
    pub const discard_hal_labels = @as(InstanceFlag, 0x00000004);
};

pub const Dx12Compiler = enum(u32) {
    undefined = 0x00000000,
    fxc = 0x00000001,
    dxc = 0x00000002,
};

pub const Gles3MinorVersion = enum(u32) {
    automatic = 0x00000000,
    version_0 = 0x00000001,
    version_1 = 0x00000002,
    version_2 = 0x00000003,
};

pub const DxcMaxShaderModel = enum(u32) {
    dxc_max_shader_model_v6_0 = 0x00000000,
    dxc_max_shader_model_v6_1 = 0x00000001,
    dxc_max_shader_model_v6_2 = 0x00000002,
    dxc_max_shader_model_v6_3 = 0x00000003,
    dxc_max_shader_model_v6_4 = 0x00000004,
    dxc_max_shader_model_v6_5 = 0x00000005,
    dxc_max_shader_model_v6_6 = 0x00000006,
    dxc_max_shader_model_v6_7 = 0x00000007,
};

pub const GLFenceBehaviour = enum(u32) {
    gl_fence_behaviour_normal = 0x00000000,
    gl_fence_behaviour_auto_finish = 0x00000001,
};

pub const Dx12SwapchainKind = enum(u32) {
    undefined = 0x00000000,
    dxgi_from_hwnd = 0x00000001,
    dxgi_from_visual = 0x00000002,
};

pub const NativeDisplayHandleType = enum(u32) {
    none = 0x00000000,
    xlib = 0x00000001,
    xcb = 0x00000002,
    wayland = 0x00000003,
};

pub const XlibDisplayHandle = extern struct {
    display: ?*anyopaque = null,
    screen: c_int = 0,
};

pub const XcbDisplayHandle = extern struct {
    connection: ?*anyopaque = null,
    screen: c_int = 0,
};

pub const WaylandDisplayHandle = extern struct {
    display: ?*anyopaque = null,
};

pub const NativeDisplayHandleData = extern union {
    xlib: XlibDisplayHandle,
    xcb: XcbDisplayHandle,
    wayland: WaylandDisplayHandle,
};

pub const NativeDisplayHandle = extern struct {
    type: NativeDisplayHandleType = .none,
    data: NativeDisplayHandleData = .{
        .wayland = .{},
    },
};

pub const InstanceExtras = extern struct {
    chain: ChainedStruct = ChainedStruct{
        .s_type = SType.instance_extras,
    },
    backends: InstanceBackend,
    flags: InstanceFlag,
    dx12_shader_compiler: Dx12Compiler,
    gles3_minor_version: Gles3MinorVersion,
    gl_fence_behavior: GLFenceBehaviour,
    dxc_path: StringView = StringView{},
    dxc_max_shader_model: DxcMaxShaderModel,
    dx12_presentation_system: Dx12SwapchainKind = .undefined,
    budget_for_device_creation: ?*const u8 = null,
    budget_for_device_loss: ?*const u8 = null,
    display_handle: NativeDisplayHandle = .{},
};

pub const InstanceFeatureName = enum(u32) {
    timed_wait_any = 0x00000001,
    shader_source_spirv = 0x00000002,
    multiple_devices_per_adapter = 0x00000003,
};

pub const SupportedInstanceFeatures = extern struct {
    feature_count: usize = 0,
    features: [*]const InstanceFeatureName = &[0]InstanceFeatureName{},
};

pub const InstanceLimits = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    timed_wait_any_max_count: usize = 0,
};

pub const InstanceDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    required_feature_count: usize = 0,
    required_features: [*]const InstanceFeatureName = &[0]InstanceFeatureName{},
    required_limits: ?*const InstanceLimits = null,

    pub inline fn withNativeExtras(self: InstanceDescriptor, extras: *InstanceExtras) InstanceDescriptor {
        var id = self;
        id.next_in_chain = @ptrCast(extras);
        return id;
    }
};

pub const WGSLLanguageFeatureName = enum(u32) {
    readonly_and_readwrite_storage_textures = 0x00000001,
    packed4x8_integer_dot_product = 0x00000002,
    unrestricted_pointer_parameters = 0x00000003,
    pointer_composite_access = 0x00000004,
    uniform_buffer_standard_layout = 0x00000005,
    subgroup_id = 0x00000006,
    texture_and_sampler_let = 0x00000007,
    subgroup_uniformity = 0x00000008,
    texture_formats_tier_1 = 0x00000009,
};

pub const SupportedWGSLLanguageFeatures = extern struct {
    feature_count: usize,
    features: [*]const WGSLLanguageFeatureName,

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn freeMembers(self: SupportedWGSLLanguageFeatures) void {
    //     wgpuSupportedWGSLLanguageFeaturesFreeMembers(self);
    // }
};

pub const RegistryReport = extern struct {
    num_allocated: usize,
    num_kept_from_user: usize,
    num_released_from_user: usize,
    element_size: usize,
};

pub const HubReport = extern struct {
    adapters: RegistryReport,
    devices: RegistryReport,
    queues: RegistryReport,
    pipeline_layouts: RegistryReport,
    shader_modules: RegistryReport,
    bind_group_layouts: RegistryReport,
    bind_groups: RegistryReport,
    command_buffers: RegistryReport,
    render_bundles: RegistryReport,
    render_pipelines: RegistryReport,
    compute_pipelines: RegistryReport,
    pipeline_caches: RegistryReport,
    query_sets: RegistryReport,
    buffers: RegistryReport,
    textures: RegistryReport,
    texture_views: RegistryReport,
    samplers: RegistryReport,
};

pub const GlobalReport = extern struct {
    surfaces: RegistryReport,
    hub: HubReport,
};

pub const EnumerateAdapterOptions = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    backends: InstanceBackend,
};

// wgpu-native

pub const Instance = opaque {
    // This is a global function, but it creates an instance so I put it here.
    pub inline fn create(descriptor: ?*const InstanceDescriptor) ?*Instance {
        return raw.call(?*Instance, "wgpuCreateInstance", .{descriptor});
    }

    pub inline fn getLimits(limits: *InstanceLimits) Status {
        return raw.call(Status, "wgpuGetInstanceLimits", .{limits});
    }

    pub inline fn createSurface(self: *Instance, descriptor: *const SurfaceDescriptor) ?*Surface {
        return raw.call(?*Surface, "wgpuInstanceCreateSurface", .{ self, descriptor });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn getWGSLLanguageFeatures(self: *Instance, features: *SupportedWGSLLanguageFeatures) void {
    //     wgpuInstanceGetWGSLLanguageFeatures(self, features);
    // }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // pub inline fn hasWGSLLanguageFeature(self: *Instance, feature: WGSLLanguageFeatureName) bool {
    //     return wgpuInstanceHasWGSLLanguageFeature(self, feature) != 0;
    // }

    // Processes asynchronous events on this Instance, calling any callbacks for asynchronous operations created with `CallbackMode.allow_process_events`.
    pub inline fn processEvents(self: *Instance) void {
        raw.call(void, "wgpuInstanceProcessEvents", .{self});
    }

    fn defaultAdapterCallback(status: RequestAdapterStatus, adapter: ?*Adapter, message: StringView, userdata1: ?*anyopaque, userdata2: ?*anyopaque) callconv(.c) void {
        const ud_response: *RequestAdapterResponse = @ptrCast(@alignCast(userdata1));
        ud_response.* = RequestAdapterResponse{
            .status = status,
            .message = message.toSlice(),
            .adapter = adapter,
        };

        const completed: *bool = @ptrCast(@alignCast(userdata2));
        completed.* = true;
    }

    // This is a synchronous wrapper that handles asynchronous (callback) logic.
    // It uses polling to see when the request has been fulfilled, so needs a polling interval parameter.
    pub fn requestAdapterSync(
        self: *Instance,
        io: std.Io,
        options: ?*const RequestAdapterOptions,
        polling_interval_nanoseconds: u64,
    ) std.Io.Cancelable!RequestAdapterResponse {
        var response: RequestAdapterResponse = undefined;
        var completed = false;
        const callback_info = RequestAdapterCallbackInfo{
            .callback = defaultAdapterCallback,
            .userdata1 = @ptrCast(&response),
            .userdata2 = @ptrCast(&completed),
        };
        const adapter_future = raw.call(Future, "wgpuInstanceRequestAdapter", .{ self, options, callback_info });

        // TODO: Revisit once Instance.waitAny() is implemented in wgpu-native,
        //       it takes in futures and returns when one of them completes.
        _ = adapter_future;
        self.processEvents();
        while (!completed) {
            try io.sleep(.fromNanoseconds(polling_interval_nanoseconds), .awake);
            self.processEvents();
        }

        return response;
    }

    pub inline fn requestAdapter(self: *Instance, options: ?*const RequestAdapterOptions, callback_info: RequestAdapterCallbackInfo) Future {
        return raw.call(Future, "wgpuInstanceRequestAdapter", .{ self, options, callback_info });
    }

    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/d2e3330ade4ae1bb238d76b485926f067e7ee64c/src/unimplemented.rs
    // Wait for at least one Future in `futures` to complete, and call callbacks of the respective completed asynchronous operations.
    // pub inline fn waitAny(self: *Instance, future_count: usize, futures: ?[*] FutureWaitInfo, timeout_ns: u64) WaitStatus {
    //     return wgpuInstanceWaitAny(self, future_count, futures, timeout_ns);
    // }

    pub inline fn addRef(self: *Instance) void {
        raw.call(void, "wgpuInstanceAddRef", .{self});
    }

    pub inline fn release(self: *Instance) void {
        raw.call(void, "wgpuInstanceRelease", .{self});
    }

    // wgpu-native
    pub inline fn generateReport(self: *Instance, report: *GlobalReport) void {
        raw.call(void, "wgpuGenerateReport", .{ self, report });
    }
    pub inline fn enumerateAdapters(self: *Instance, options: ?*EnumerateAdapterOptions, adapters: ?[*]*Adapter) usize {
        return raw.call(usize, "wgpuInstanceEnumerateAdapters", .{ self, options, adapters });
    }
};

test "can create instance (and release it afterwards)" {
    const testing = @import("std").testing;

    const instance = Instance.create(null);
    try testing.expect(instance != null);
    instance.?.release();
}

test "can request adapter" {
    const testing = @import("std").testing;

    const instance = Instance.create(null).?;
    defer instance.release();
    const response = try instance.requestAdapterSync(std.testing.io, null, 200_000_000);
    const adapter: ?*Adapter = switch (response.status) {
        .success => response.adapter,
        else => null,
    };
    if (adapter == null) return error.SkipZigTest;
    defer adapter.?.release();
    try testing.expect(response.status == .success);
}
