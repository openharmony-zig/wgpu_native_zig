const std = @import("std");
const wgpu = @import("wgpu");
const c = @import("wgpu-c");

const wrapper_namespaces = .{
    wgpu,
    wgpu.Instance,
    wgpu.Adapter,
    wgpu.Buffer,
    wgpu.Device,
    wgpu.Queue,
    wgpu.ShaderModule,
};

fn cTypeName(comptime zig_name: []const u8) []const u8 {
    if (std.mem.eql(u8, zig_name, "ColorAttachment"))
        return "WGPURenderPassColorAttachment";
    if (std.mem.eql(u8, zig_name, "DepthStencilAttachment"))
        return "WGPURenderPassDepthStencilAttachment";
    if (std.mem.eql(u8, zig_name, "EnumerateAdapterOptions"))
        return "WGPUInstanceEnumerateAdapterOptions";
    if (std.mem.eql(u8, zig_name, "GetCurrentTextureStatus"))
        return "WGPUSurfaceGetCurrentTextureStatus";
    if (std.mem.eql(u8, zig_name, "MapState"))
        return "WGPUBufferMapState";
    if (std.mem.eql(u8, zig_name, "MapCallbackInfo"))
        return "WGPUBufferMapCallbackInfo";
    if (std.mem.eql(u8, zig_name, "ViewDimension"))
        return "WGPUTextureViewDimension";
    if (std.mem.eql(u8, zig_name, "WorkDoneStatus"))
        return "WGPUQueueWorkDoneStatus";
    if (std.mem.eql(u8, zig_name, "WorkDoneCallbackInfo"))
        return "WGPUQueueWorkDoneCallbackInfo";
    if (std.mem.startsWith(u8, zig_name, "WGPU"))
        return zig_name;
    return "WGPU" ++ zig_name;
}

fn isEnumConstant(
    comptime declaration_name: []const u8,
    comptime zig_name: []const u8,
    comptime c_name: []const u8,
) bool {
    if (std.mem.endsWith(u8, declaration_name, "_Force32")) return false;
    if (std.mem.startsWith(u8, declaration_name, c_name ++ "_")) return true;
    if (std.mem.eql(u8, zig_name, "FeatureName") and
        std.mem.startsWith(u8, declaration_name, "WGPUNativeFeature_"))
    {
        return true;
    }
    if (std.mem.eql(u8, zig_name, "TextureFormat") and
        std.mem.startsWith(u8, declaration_name, "WGPUNativeTextureFormat_"))
    {
        return true;
    }
    if (std.mem.eql(u8, zig_name, "QueryType") and
        std.mem.startsWith(u8, declaration_name, "WGPUNativeQueryType_"))
    {
        return true;
    }
    return false;
}

test "all wrapper methods compile against the C headers" {
    comptime {
        @setEvalBranchQuota(10_000_000);
        for (std.meta.declarations(wgpu)) |declaration| {
            if (std.mem.eql(u8, declaration.name, "raw")) continue;

            const value = @field(wgpu, declaration.name);
            if (@TypeOf(value) != type) continue;
            switch (@typeInfo(value)) {
                .@"struct", .@"union", .@"enum", .@"opaque" => {},
                else => continue,
            }
            std.testing.refAllDecls(value);
        }
    }
}

test "wrapper types match the C ABI" {
    comptime {
        @setEvalBranchQuota(50_000_000);
        for (wrapper_namespaces) |namespace| {
            validateNamespaceAbi(namespace);
        }
    }
}

test "wrapper defaults and pointer qualifiers match header semantics" {
    comptime {
        const descriptor = wgpu.DeviceDescriptor{};
        if (descriptor.required_limits != null) {
            @compileError("DeviceDescriptor.required_limits must default to null");
        }
        const extras = wgpu.DeviceExtras{};
        if (extras.trace_path.data != null or
            extras.trace_path.length != wgpu.WGPU_STRLEN)
        {
            @compileError("DeviceExtras.trace_path must use the StringView initializer");
        }

        const instance_features = wgpu.SupportedInstanceFeatures{};
        if (instance_features.feature_count != 0 or
            instance_features.features != null)
        {
            @compileError("SupportedInstanceFeatures must use the C initializer defaults");
        }
        const wgsl_features = wgpu.SupportedWGSLLanguageFeatures{};
        if (wgsl_features.feature_count != 0 or wgsl_features.features != null) {
            @compileError("SupportedWGSLLanguageFeatures must use the C initializer defaults");
        }

        requireOptionalConstManyPointer(
            @FieldType(wgpu.ShaderSourceGLSL, "defines"),
            wgpu.ShaderDefine,
            "ShaderSourceGLSL.defines",
        );
        const enumerate_info = @typeInfo(@TypeOf(
            wgpu.Instance.enumerateAdapters,
        )).@"fn";
        requireOptionalConstOnePointer(
            enumerate_info.params[2].type.?,
            wgpu.EnumerateAdapterOptions,
            "Instance.enumerateAdapters options",
        );
    }
}

fn requireOptionalConstManyPointer(
    comptime Pointer: type,
    comptime Child: type,
    comptime name: []const u8,
) void {
    const optional = switch (@typeInfo(Pointer)) {
        .optional => |info| info,
        else => @compileError(name ++ " must be optional"),
    };
    const pointer = switch (@typeInfo(optional.child)) {
        .pointer => |info| info,
        else => @compileError(name ++ " must contain a pointer"),
    };
    if (pointer.size != .many or !pointer.is_const or pointer.child != Child) {
        @compileError(name ++ " must be a const many-item pointer");
    }
}

fn requireOptionalConstOnePointer(
    comptime Pointer: type,
    comptime Child: type,
    comptime name: []const u8,
) void {
    const optional = switch (@typeInfo(Pointer)) {
        .optional => |info| info,
        else => @compileError(name ++ " must be optional"),
    };
    const pointer = switch (@typeInfo(optional.child)) {
        .pointer => |info| info,
        else => @compileError(name ++ " must contain a pointer"),
    };
    if (pointer.size != .one or !pointer.is_const or pointer.child != Child) {
        @compileError(name ++ " must be a const single-item pointer");
    }
}

fn validateNamespaceAbi(comptime namespace: type) void {
    for (std.meta.declarations(namespace)) |declaration| {
        const ZigType = @field(namespace, declaration.name);
        if (@TypeOf(ZigType) != type) continue;

        const c_name = cTypeName(declaration.name);
        if (!@hasDecl(c, c_name)) continue;
        const CType = @field(c, c_name);
        if (@TypeOf(CType) != type) continue;

        switch (@typeInfo(ZigType)) {
            .@"struct", .@"union", .@"enum" => {},
            else => continue,
        }
        switch (@typeInfo(CType)) {
            .@"struct", .@"union", .@"enum", .int => {},
            else => continue,
        }

        if (@sizeOf(ZigType) != @sizeOf(CType) or
            @alignOf(ZigType) != @alignOf(CType))
        {
            @compileError(std.fmt.comptimePrint(
                "{s}.{s} does not match the ABI of {s}",
                .{ @typeName(namespace), declaration.name, c_name },
            ));
        }

        if (@typeInfo(ZigType) == .@"enum") {
            validateEnumValues(
                namespace,
                declaration.name,
                c_name,
                ZigType,
            );
        }
        if (@typeInfo(ZigType) == .@"struct" and
            @typeInfo(CType) == .@"struct")
        {
            validateStructFields(
                namespace,
                declaration.name,
                c_name,
                ZigType,
                CType,
            );
        }
    }
}

fn validateEnumValues(
    comptime namespace: type,
    comptime zig_name: []const u8,
    comptime c_name: []const u8,
    comptime ZigType: type,
) void {
    const zig_fields = @typeInfo(ZigType).@"enum".fields;
    for (std.meta.declarations(c)) |c_declaration| {
        if (!isEnumConstant(c_declaration.name, zig_name, c_name)) continue;
        const c_value = @field(c, c_declaration.name);
        if (@TypeOf(c_value) == type) continue;

        var found = false;
        for (zig_fields) |zig_field| {
            const zig_value: u64 = @intFromEnum(
                @field(ZigType, zig_field.name),
            );
            if (zig_value == @as(u64, @intCast(c_value))) found = true;
        }
        if (!found) {
            @compileError(std.fmt.comptimePrint(
                "{s}.{s} is missing {s}",
                .{ @typeName(namespace), zig_name, c_declaration.name },
            ));
        }
    }

    for (zig_fields) |zig_field| {
        const zig_value: u64 = @intFromEnum(
            @field(ZigType, zig_field.name),
        );
        var found = false;
        for (std.meta.declarations(c)) |c_declaration| {
            if (!isEnumConstant(c_declaration.name, zig_name, c_name)) continue;
            const c_value = @field(c, c_declaration.name);
            if (@TypeOf(c_value) == type) continue;
            if (zig_value == @as(u64, @intCast(c_value))) found = true;
        }
        if (!found) {
            @compileError(std.fmt.comptimePrint(
                "{s}.{s}.{s} is not present in {s}",
                .{ @typeName(namespace), zig_name, zig_field.name, c_name },
            ));
        }
    }
}

fn validateStructFields(
    comptime namespace: type,
    comptime zig_name: []const u8,
    comptime c_name: []const u8,
    comptime ZigType: type,
    comptime CType: type,
) void {
    const zig_fields = @typeInfo(ZigType).@"struct".fields;
    const c_fields = @typeInfo(CType).@"struct".fields;
    if (zig_fields.len != c_fields.len) {
        @compileError(std.fmt.comptimePrint(
            "{s}.{s} has {d} fields, but {s} has {d}",
            .{
                @typeName(namespace),
                zig_name,
                zig_fields.len,
                c_name,
                c_fields.len,
            },
        ));
    }
    for (zig_fields, c_fields) |zig_field, c_field| {
        if (@offsetOf(ZigType, zig_field.name) !=
            @offsetOf(CType, c_field.name) or
            @sizeOf(zig_field.type) != @sizeOf(c_field.type))
        {
            @compileError(std.fmt.comptimePrint(
                "{s}.{s}.{s} does not match {s}.{s}",
                .{
                    @typeName(namespace),
                    zig_name,
                    zig_field.name,
                    c_name,
                    c_field.name,
                },
            ));
        }
    }
}
