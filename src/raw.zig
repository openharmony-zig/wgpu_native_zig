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
