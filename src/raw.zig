const std = @import("std");

pub const header = @import("wgpu-header");

pub inline fn call(
    comptime Return: type,
    comptime name: []const u8,
    args: anytype,
) Return {
    const function = @field(header, name);
    const Function = @TypeOf(function);
    const function_info = @typeInfo(Function).@"fn";
    const Args = std.meta.ArgsTuple(Function);
    const args_info = @typeInfo(@TypeOf(args)).@"struct";

    comptime std.debug.assert(args_info.fields.len == function_info.params.len);

    var converted: Args = undefined;
    inline for (args_info.fields, 0..) |field, index| {
        converted[index] = convert(
            function_info.params[index].type.?,
            @field(args, field.name),
        );
    }

    if (Return == void) {
        @call(.auto, function, converted);
        return;
    }
    return convert(Return, @call(.auto, function, converted));
}

fn convert(comptime To: type, value: anytype) To {
    const From = @TypeOf(value);
    if (To == From) return value;
    if (From == @TypeOf(null)) return null;

    return switch (@typeInfo(To)) {
        .optional, .pointer => @ptrCast(value),
        .@"enum" => switch (@typeInfo(From)) {
            .@"enum" => @enumFromInt(@intFromEnum(value)),
            .int, .comptime_int => @enumFromInt(value),
            else => conversionError(To, From),
        },
        .int => switch (@typeInfo(From)) {
            .@"enum" => @intFromEnum(value),
            .int, .comptime_int => @intCast(value),
            else => conversionError(To, From),
        },
        .@"struct", .@"union" => @bitCast(value),
        else => conversionError(To, From),
    };
}

fn conversionError(comptime To: type, comptime From: type) noreturn {
    @compileError(std.fmt.comptimePrint(
        "cannot convert wgpu header argument from {s} to {s}",
        .{ @typeName(From), @typeName(To) },
    ));
}

const wrapper_sources = .{
    .{ "adapter.zig", @embedFile("adapter.zig") },
    .{ "bind_group.zig", @embedFile("bind_group.zig") },
    .{ "buffer.zig", @embedFile("buffer.zig") },
    .{ "command_encoder.zig", @embedFile("command_encoder.zig") },
    .{ "device.zig", @embedFile("device.zig") },
    .{ "instance.zig", @embedFile("instance.zig") },
    .{ "log.zig", @embedFile("log.zig") },
    .{ "misc.zig", @embedFile("misc.zig") },
    .{ "pipeline.zig", @embedFile("pipeline.zig") },
    .{ "query_set.zig", @embedFile("query_set.zig") },
    .{ "queue.zig", @embedFile("queue.zig") },
    .{ "render_bundle.zig", @embedFile("render_bundle.zig") },
    .{ "sampler.zig", @embedFile("sampler.zig") },
    .{ "shader.zig", @embedFile("shader.zig") },
    .{ "surface.zig", @embedFile("surface.zig") },
    .{ "texture.zig", @embedFile("texture.zig") },
};

test "all wrapper calls are declared by wgpu headers" {
    comptime {
        @setEvalBranchQuota(10_000_000);
        for (wrapper_sources) |source| validateWrapperSource(source[0], source[1]);
    }
}

fn validateWrapperSource(comptime file_name: []const u8, comptime source: []const u8) void {
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
        cursor = name_end + 1;
    }
}
