const std = @import("std");
const wgpu = @import("wgpu");
const c = @import("wgpu-c");

fn cTypeName(comptime zig_name: []const u8) []const u8 {
    if (std.mem.eql(u8, zig_name, "ColorAttachment"))
        return "WGPURenderPassColorAttachment";
    if (std.mem.eql(u8, zig_name, "DepthStencilAttachment"))
        return "WGPURenderPassDepthStencilAttachment";
    if (std.mem.eql(u8, zig_name, "EnumerateAdapterOptions"))
        return "WGPUInstanceEnumerateAdapterOptions";
    if (std.mem.eql(u8, zig_name, "GetCurrentTextureStatus"))
        return "WGPUSurfaceGetCurrentTextureStatus";
    if (std.mem.eql(u8, zig_name, "SampleType"))
        return "WGPUTextureSampleType";
    if (std.mem.eql(u8, zig_name, "ViewDimension"))
        return "WGPUTextureViewDimension";
    if (std.mem.eql(u8, zig_name, "WorkDoneStatus"))
        return "WGPUQueueWorkDoneStatus";
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

test "pure Zig structs match the C ABI" {
    comptime {
        @setEvalBranchQuota(10_000_000);
        for (std.meta.declarations(wgpu)) |declaration| {
            const zig_declaration = @field(wgpu, declaration.name);
            if (@TypeOf(zig_declaration) != type) continue;

            const c_name = cTypeName(declaration.name);
            if (!@hasDecl(c, c_name)) continue;

            const ZigType = zig_declaration;
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

            if (@typeInfo(ZigType) == .@"enum") {
                const zig_fields = @typeInfo(ZigType).@"enum".fields;
                var c_values: [256]u64 = undefined;
                var c_names: [256][]const u8 = undefined;
                var c_value_count = 0;
                for (std.meta.declarations(c)) |c_declaration| {
                    if (!isEnumConstant(
                        c_declaration.name,
                        declaration.name,
                        c_name,
                    )) continue;
                    const c_value = @field(c, c_declaration.name);
                    if (@TypeOf(c_value) == type) continue;

                    c_values[c_value_count] = @intCast(c_value);
                    c_names[c_value_count] = c_declaration.name;
                    c_value_count += 1;
                }
                for (
                    c_values[0..c_value_count],
                    c_names[0..c_value_count],
                ) |c_value, c_declaration_name| {
                    var found = false;
                    for (zig_fields) |zig_field| {
                        const zig_value: u64 = @intFromEnum(
                            @field(ZigType, zig_field.name),
                        );
                        if (zig_value == c_value) found = true;
                    }
                    if (!found) {
                        @compileError(std.fmt.comptimePrint(
                            "{s} is missing {s} ({d})",
                            .{ declaration.name, c_declaration_name, c_value },
                        ));
                    }
                }
                for (zig_fields) |zig_field| {
                    const zig_value: u64 = @intFromEnum(
                        @field(ZigType, zig_field.name),
                    );
                    var found = false;
                    for (c_values[0..c_value_count]) |c_value| {
                        if (zig_value == c_value) found = true;
                    }
                    if (!found) {
                        @compileError(std.fmt.comptimePrint(
                            "{s}.{s} ({d}) is not present in the C API",
                            .{ declaration.name, zig_field.name, zig_value },
                        ));
                    }
                }
            }

            if (@sizeOf(ZigType) != @sizeOf(CType)) {
                @compileError(std.fmt.comptimePrint(
                    "{s} has size {d}, but {s} has size {d}",
                    .{
                        declaration.name,
                        @sizeOf(ZigType),
                        c_name,
                        @sizeOf(CType),
                    },
                ));
            }
            if (@alignOf(ZigType) != @alignOf(CType)) {
                @compileError(std.fmt.comptimePrint(
                    "{s} has alignment {d}, but {s} has alignment {d}",
                    .{
                        declaration.name,
                        @alignOf(ZigType),
                        c_name,
                        @alignOf(CType),
                    },
                ));
            }

            if (@typeInfo(ZigType) == .@"struct" and
                @typeInfo(CType) == .@"struct")
            {
                const zig_fields = @typeInfo(ZigType).@"struct".fields;
                const c_fields = @typeInfo(CType).@"struct".fields;
                if (zig_fields.len != c_fields.len) {
                    @compileError(std.fmt.comptimePrint(
                        "{s} has {d} fields, but {s} has {d}",
                        .{
                            declaration.name,
                            zig_fields.len,
                            c_name,
                            c_fields.len,
                        },
                    ));
                }
                for (zig_fields, 0..) |zig_field, index| {
                    if (index >= c_fields.len) continue;
                    const c_field = c_fields[index];
                    if (@offsetOf(ZigType, zig_field.name) !=
                        @offsetOf(CType, c_field.name))
                    {
                        @compileError(std.fmt.comptimePrint(
                            "{s}.{s} has offset {d}, but {s}.{s} has offset {d}",
                            .{
                                declaration.name,
                                zig_field.name,
                                @offsetOf(ZigType, zig_field.name),
                                c_name,
                                c_field.name,
                                @offsetOf(CType, c_field.name),
                            },
                        ));
                    }
                    if (@sizeOf(zig_field.type) != @sizeOf(c_field.type)) {
                        @compileError(std.fmt.comptimePrint(
                            "{s}.{s} has size {d}, but {s}.{s} has size {d}",
                            .{
                                declaration.name,
                                zig_field.name,
                                @sizeOf(zig_field.type),
                                c_name,
                                c_field.name,
                                @sizeOf(c_field.type),
                            },
                        ));
                    }
                }
            }
        }
    }
}
