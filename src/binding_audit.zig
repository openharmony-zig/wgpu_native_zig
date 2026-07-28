const std = @import("std");
const header = @import("wgpu-header");
const wrapper = @import("wgpu-wrapper");

const wrapper_sources = .{
    .{ "adapter.zig", @embedFile("adapter.zig") },
    .{ "async.zig", @embedFile("async.zig") },
    .{ "bind_group.zig", @embedFile("bind_group.zig") },
    .{ "buffer.zig", @embedFile("buffer.zig") },
    .{ "chained_struct.zig", @embedFile("chained_struct.zig") },
    .{ "command_encoder.zig", @embedFile("command_encoder.zig") },
    .{ "device.zig", @embedFile("device.zig") },
    .{ "instance.zig", @embedFile("instance.zig") },
    .{ "limits.zig", @embedFile("limits.zig") },
    .{ "log.zig", @embedFile("log.zig") },
    .{ "misc.zig", @embedFile("misc.zig") },
    .{ "pipeline.zig", @embedFile("pipeline.zig") },
    .{ "query_set.zig", @embedFile("query_set.zig") },
    .{ "queue.zig", @embedFile("queue.zig") },
    .{ "raw.zig", @embedFile("raw.zig") },
    .{ "render_bundle.zig", @embedFile("render_bundle.zig") },
    .{ "root.zig", @embedFile("root.zig") },
    .{ "sampler.zig", @embedFile("sampler.zig") },
    .{ "shader.zig", @embedFile("shader.zig") },
    .{ "surface.zig", @embedFile("surface.zig") },
    .{ "texture.zig", @embedFile("texture.zig") },
};

// These functions are declared by the pinned v29 headers but do not provide a
// usable implementation in wgpu-native v29.0.0.0. Most panic through Rust's
// `unimplemented!()`; the native Metal command queue accessor logs a warning
// and always returns null. They remain available through `wgpu.raw`, but are
// intentionally not promoted to the Zig-friendly wrapper.
const unavailable_v29_functions = [_][]const u8{
    "wgpuBindGroupLayoutSetLabel",
    "wgpuBindGroupSetLabel",
    "wgpuBufferGetMapState",
    "wgpuBufferReadMappedRange",
    "wgpuBufferSetLabel",
    "wgpuBufferWriteMappedRange",
    "wgpuCommandBufferSetLabel",
    "wgpuCommandEncoderSetLabel",
    "wgpuComputePassEncoderSetLabel",
    "wgpuComputePipelineSetLabel",
    "wgpuDeviceCreateComputePipelineAsync",
    "wgpuDeviceCreateRenderPipelineAsync",
    "wgpuDeviceGetAdapterInfo",
    "wgpuDeviceGetLostFuture",
    "wgpuDeviceSetLabel",
    "wgpuExternalTextureAddRef",
    "wgpuExternalTextureRelease",
    "wgpuExternalTextureSetLabel",
    "wgpuGetInstanceFeatures",
    "wgpuGetProcAddress",
    "wgpuHasInstanceFeature",
    "wgpuInstanceGetWGSLLanguageFeatures",
    "wgpuInstanceHasWGSLLanguageFeature",
    "wgpuInstanceWaitAny",
    "wgpuPipelineLayoutSetLabel",
    "wgpuQuerySetSetLabel",
    "wgpuQueueGetNativeMetalCommandQueue",
    "wgpuQueueSetLabel",
    "wgpuRenderBundleEncoderSetLabel",
    "wgpuRenderBundleSetLabel",
    "wgpuRenderPassEncoderSetLabel",
    "wgpuRenderPipelineSetLabel",
    "wgpuSamplerSetLabel",
    "wgpuShaderModuleGetCompilationInfo",
    "wgpuShaderModuleSetLabel",
    "wgpuSupportedInstanceFeaturesFreeMembers",
    "wgpuSupportedWGSLLanguageFeaturesFreeMembers",
    "wgpuSurfaceSetLabel",
    "wgpuTextureGetTextureBindingViewDimension",
    "wgpuTextureSetLabel",
    "wgpuTextureViewSetLabel",
};

pub fn validate() void {
    var wrapper_functions: [256][]const u8 = undefined;
    var wrapper_function_count: usize = 0;
    for (wrapper_sources) |source| {
        validateWrapperSource(
            source[0],
            source[1],
            &wrapper_functions,
            &wrapper_function_count,
        );
    }

    for (unavailable_v29_functions) |name| {
        if (!@hasDecl(header, name)) {
            @compileError("v29 unavailable-function list contains missing header function " ++ name);
        }
    }

    var header_function_count: usize = 0;
    for (std.meta.declarations(header)) |declaration| {
        if (!std.mem.startsWith(u8, declaration.name, "wgpu")) continue;
        if (@typeInfo(@TypeOf(@field(header, declaration.name))) != .@"fn") continue;
        header_function_count += 1;
    }

    const covered_function_count =
        wrapper_function_count + unavailable_v29_functions.len;
    if (covered_function_count != header_function_count) {
        @compileError(std.fmt.comptimePrint(
            "v29 function coverage mismatch: {d} wrapper + {d} unavailable != {d} header functions",
            .{
                wrapper_function_count,
                unavailable_v29_functions.len,
                header_function_count,
            },
        ));
    }

    validateTypes();
    validateCallbacks();
}

fn validateTypes() void {
    for (std.meta.declarations(header)) |declaration| {
        if (!std.mem.startsWith(u8, declaration.name, "WGPU")) continue;
        if (std.mem.indexOfScalar(u8, declaration.name, '_') != null) continue;
        if (std.mem.startsWith(u8, declaration.name, "WGPUProc")) continue;
        if (std.mem.endsWith(u8, declaration.name, "Impl")) continue;

        const header_declaration = @field(header, declaration.name);
        if (@TypeOf(header_declaration) != type) continue;

        _ = wrapperType(declaration.name);
    }
}

fn wrapperType(comptime c_name: []const u8) type {
    if (std.mem.eql(u8, c_name, "WGPUBufferMapState"))
        return wrapper.Buffer.MapState;
    if (std.mem.eql(u8, c_name, "WGPUMapMode"))
        return wrapper.Buffer.MapMode;
    if (std.mem.eql(u8, c_name, "WGPUMapAsyncStatus"))
        return wrapper.Buffer.MapAsyncStatus;
    if (std.mem.eql(u8, c_name, "WGPUBufferMapCallback"))
        return wrapper.Buffer.MapCallback;
    if (std.mem.eql(u8, c_name, "WGPUBufferMapCallbackInfo"))
        return wrapper.Buffer.MapCallbackInfo;
    if (std.mem.eql(u8, c_name, "WGPURequestAdapterStatus") or
        std.mem.eql(u8, c_name, "WGPURequestAdapterCallback") or
        std.mem.eql(u8, c_name, "WGPURequestAdapterCallbackInfo"))
    {
        return @field(wrapper.Instance, c_name["WGPU".len..]);
    }
    if (std.mem.eql(u8, c_name, "WGPURequestDeviceStatus") or
        std.mem.eql(u8, c_name, "WGPURequestDeviceCallback") or
        std.mem.eql(u8, c_name, "WGPURequestDeviceCallbackInfo"))
    {
        return @field(wrapper.Adapter, c_name["WGPU".len..]);
    }
    if (std.mem.eql(u8, c_name, "WGPUCreatePipelineAsyncStatus") or
        std.mem.startsWith(u8, c_name, "WGPUCreateComputePipelineAsync") or
        std.mem.startsWith(u8, c_name, "WGPUCreateRenderPipelineAsync"))
    {
        return @field(wrapper.Device, c_name["WGPU".len..]);
    }
    if (std.mem.eql(u8, c_name, "WGPUDeviceLostReason") or
        std.mem.eql(u8, c_name, "WGPUDeviceLostCallback") or
        std.mem.eql(u8, c_name, "WGPUDeviceLostCallbackInfo") or
        std.mem.eql(u8, c_name, "WGPUErrorType") or
        std.mem.eql(u8, c_name, "WGPUErrorFilter") or
        std.mem.eql(u8, c_name, "WGPUUncapturedErrorCallback") or
        std.mem.eql(u8, c_name, "WGPUUncapturedErrorCallbackInfo") or
        std.mem.eql(u8, c_name, "WGPUPopErrorScopeStatus") or
        std.mem.eql(u8, c_name, "WGPUPopErrorScopeCallback") or
        std.mem.eql(u8, c_name, "WGPUPopErrorScopeCallbackInfo"))
    {
        return @field(wrapper.Device, c_name["WGPU".len..]);
    }
    if (std.mem.eql(u8, c_name, "WGPUQueueWorkDoneStatus"))
        return wrapper.Queue.WorkDoneStatus;
    if (std.mem.eql(u8, c_name, "WGPUQueueWorkDoneCallback"))
        return wrapper.Queue.WorkDoneCallback;
    if (std.mem.eql(u8, c_name, "WGPUQueueWorkDoneCallbackInfo"))
        return wrapper.Queue.WorkDoneCallbackInfo;
    if (std.mem.eql(u8, c_name, "WGPUCompilationInfoRequestStatus") or
        std.mem.eql(u8, c_name, "WGPUCompilationMessageType") or
        std.mem.eql(u8, c_name, "WGPUCompilationMessage") or
        std.mem.eql(u8, c_name, "WGPUCompilationInfo") or
        std.mem.eql(u8, c_name, "WGPUCompilationInfoCallback") or
        std.mem.eql(u8, c_name, "WGPUCompilationInfoCallbackInfo"))
    {
        return @field(wrapper.ShaderModule, c_name["WGPU".len..]);
    }

    const wrapper_name = wrapperTypeName(c_name);
    if (!@hasDecl(wrapper, wrapper_name)) {
        @compileError(std.fmt.comptimePrint(
            "{s} has no wgpu wrapper type ({s})",
            .{ c_name, wrapper_name },
        ));
    }
    return @field(wrapper, wrapper_name);
}

fn wrapperTypeName(comptime c_name: []const u8) []const u8 {
    if (std.mem.eql(u8, c_name, "WGPUBool")) return "WGPUBool";
    if (std.mem.eql(u8, c_name, "WGPUFlags")) return "WGPUFlags";
    if (std.mem.eql(u8, c_name, "WGPUInstanceEnumerateAdapterOptions"))
        return "EnumerateAdapterOptions";
    if (std.mem.eql(u8, c_name, "WGPUNativeFeature"))
        return "FeatureName";
    if (std.mem.eql(u8, c_name, "WGPUNativeLimits"))
        return "WGPUNativeLimits";
    if (std.mem.eql(u8, c_name, "WGPUNativeQueryType"))
        return "QueryType";
    if (std.mem.eql(u8, c_name, "WGPUNativeSType"))
        return "SType";
    if (std.mem.eql(u8, c_name, "WGPUNativeSurfaceGetCurrentTextureStatus"))
        return "GetCurrentTextureStatus";
    if (std.mem.eql(u8, c_name, "WGPUNativeTextureFormat"))
        return "TextureFormat";
    if (std.mem.eql(u8, c_name, "WGPURenderPassColorAttachment"))
        return "ColorAttachment";
    if (std.mem.eql(u8, c_name, "WGPURenderPassDepthStencilAttachment"))
        return "DepthStencilAttachment";
    if (std.mem.eql(u8, c_name, "WGPUStringView")) return "StringView";
    if (std.mem.eql(u8, c_name, "WGPUSurfaceGetCurrentTextureStatus"))
        return "GetCurrentTextureStatus";
    if (std.mem.eql(u8, c_name, "WGPUTextureViewDimension"))
        return "ViewDimension";
    return c_name[4..];
}

fn validateCallbacks() void {
    for (std.meta.declarations(header)) |declaration| {
        if (!std.mem.startsWith(u8, declaration.name, "WGPU")) continue;
        if (!std.mem.endsWith(u8, declaration.name, "Callback")) continue;
        if (std.mem.startsWith(u8, declaration.name, "WGPUProc")) continue;

        const HeaderFn = callbackFunctionType(@field(header, declaration.name));
        const WrapperFn = callbackFunctionType(wrapperType(declaration.name));
        const header_info = @typeInfo(HeaderFn).@"fn";
        const wrapper_info = @typeInfo(WrapperFn).@"fn";

        if (std.meta.activeTag(header_info.calling_convention) !=
            std.meta.activeTag(wrapper_info.calling_convention))
        {
            @compileError(declaration.name ++ " has a mismatched calling convention");
        }
        if (header_info.params.len != wrapper_info.params.len) {
            @compileError(declaration.name ++ " has a mismatched parameter count");
        }
        for (header_info.params, wrapper_info.params, 0..) |header_param, wrapper_param, index| {
            const HeaderParam = header_param.type.?;
            const WrapperParam = wrapper_param.type.?;
            if (@sizeOf(HeaderParam) != @sizeOf(WrapperParam) or
                @alignOf(HeaderParam) != @alignOf(WrapperParam))
            {
                @compileError(std.fmt.comptimePrint(
                    "{s} parameter {d} has a mismatched ABI",
                    .{ declaration.name, index },
                ));
            }
        }

        const HeaderReturn = header_info.return_type.?;
        const WrapperReturn = wrapper_info.return_type.?;
        if (@sizeOf(HeaderReturn) != @sizeOf(WrapperReturn) or
            @alignOf(HeaderReturn) != @alignOf(WrapperReturn))
        {
            @compileError(declaration.name ++ " has a mismatched return ABI");
        }
    }
}

fn callbackFunctionType(comptime Callback: type) type {
    return switch (@typeInfo(Callback)) {
        .optional => |optional| callbackFunctionType(optional.child),
        .pointer => |pointer| callbackFunctionType(pointer.child),
        .@"fn" => Callback,
        else => @compileError(@typeName(Callback) ++ " is not a callback function pointer"),
    };
}

fn isUnavailableV29Function(comptime name: []const u8) bool {
    inline for (unavailable_v29_functions) |unavailable| {
        if (std.mem.eql(u8, name, unavailable)) return true;
    }
    return false;
}

fn validateWrapperSource(
    comptime file_name: []const u8,
    comptime source: []const u8,
    wrapper_functions: *[256][]const u8,
    wrapper_function_count: *usize,
) void {
    if (std.mem.indexOf(u8, source, "extern fn wgpu") != null) {
        @compileError(file_name ++ " contains a handwritten wgpu extern");
    }

    var cursor: usize = 0;
    while (std.mem.indexOfPos(u8, source, cursor, "raw.call(")) |call_start| {
        const name_start = std.mem.indexOfPos(u8, source, call_start, "\"wgpu") orelse
            @compileError(file_name ++ " contains an invalid raw.call");
        const name_end = std.mem.indexOfScalarPos(
            u8,
            source,
            name_start + 1,
            '"',
        ) orelse @compileError(file_name ++ " contains an unterminated function name");
        const name = source[name_start + 1 .. name_end];
        if (!@hasDecl(header, name)) {
            @compileError(file_name ++ " references missing header function " ++ name);
        }
        if (isUnavailableV29Function(name)) {
            @compileError(file_name ++ " exposes unavailable wgpu-native v29 function " ++ name);
        }
        var already_registered = false;
        for (wrapper_functions[0..wrapper_function_count.*]) |registered| {
            if (std.mem.eql(u8, registered, name)) {
                already_registered = true;
                break;
            }
        }
        if (!already_registered) {
            wrapper_functions[wrapper_function_count.*] = name;
            wrapper_function_count.* += 1;
        }
        cursor = name_end + 1;
    }
}
