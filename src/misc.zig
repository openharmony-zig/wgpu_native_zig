const raw = @import("raw.zig");
const std = @import("std");

pub const U32_MAX: u32 = std.math.maxInt(u32);
pub const U64_MAX: u64 = std.math.maxInt(u64);
pub const USIZE_MAX: usize = std.math.maxInt(usize);

pub const WGPU_WHOLE_SIZE = U64_MAX;

pub const WGPUBool = u32;
pub const WGPUFlags = u64;

pub fn sliceFromOptional(
    comptime T: type,
    items: ?[*]const T,
    count: usize,
) []const T {
    if (count == 0) return &.{};
    return items.?[0..count];
}

// Status code returned (synchronously) from many operations.
// Generally indicates an invalid input like an unknown enum value or OutStructChainError.
pub const Status = enum(u32) {
    success = 0x00000001,
    @"error" = 0x00000002,
};

pub const OptionalBool = enum(u32) {
    false = 0x00000000,
    true = 0x00000001,
    undefined = 0x00000002,
};

pub const IndexFormat = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument.
    uint16 = 0x00000001,
    uint32 = 0x00000002,
};

pub const CompareFunction = enum(u32) {
    undefined = 0x00000000, // Indicates no value is passed for this argument
    never = 0x00000001,
    less = 0x00000002,
    equal = 0x00000003,
    less_equal = 0x00000004,
    greater = 0x00000005,
    not_equal = 0x00000006,
    greater_equal = 0x00000007,
    always = 0x00000008,
};

pub inline fn getVersion() u32 {
    return raw.call(u32, "wgpuGetVersion", .{});
}

// Max of usize
pub const WGPU_STRLEN = USIZE_MAX;

// Nullable value defining a pointer+length view into a UTF-8 encoded string.
//
// Values passed into the API may use the special length value WGPU_STRLEN
// to indicate a null-terminated string.
// Non-null values passed out of the API (for example as callback arguments)
// always provide an explicit length and **may or may not be null-terminated**.
//
// Some inputs to the API accept null values. Those which do not accept null
// values "default" to the empty string when null values are passed.
//
// Values are encoded as follows:
// - `.{ .data = null, .length = WGPU_STRLEN }`: the null value.
// - `.{ .data = <non_null_pointer>, .length = WGPU_STRLEN }`: a null-terminated string view.
// - `.{ .data = <any>, .length = 0 }`: the empty string.
// - `.{ .data = null, .length = <non_zero_length> }`: not allowed (null dereference).
// - `.{ .data = <non_null_pointer>, .length = <non_zero_length> }`: an explictly-sized string view with
//   size `non_zero_length` (in bytes).
//
pub const StringView = extern struct {
    data: ?[*]const u8 = null,
    length: usize = WGPU_STRLEN,

    pub inline fn fromSlice(slice: []const u8) StringView {
        return StringView{
            .data = slice.ptr,
            .length = slice.len,
        };
    }

    pub fn toSlice(self: StringView) ?[]const u8 {
        const data = self.data orelse return nullDataToSlice(self.length) catch {
            std.debug.panic(
                "invalid StringView: null data with non-zero length {d}",
                .{self.length},
            );
        };

        if (self.length == WGPU_STRLEN) {
            return std.mem.sliceTo(@as([*:0]const u8, @ptrCast(data)), 0);
        }

        return data[0..self.length];
    }

    const NullDataError = error{InvalidLength};

    fn nullDataToSlice(length: usize) NullDataError!?[]const u8 {
        return switch (length) {
            WGPU_STRLEN => null,
            0 => "",
            else => error.InvalidLength,
        };
    }
};

test "StringView can be constructed from slice" {
    const test_slice = "test";
    try std.testing.expectEqualDeep(StringView{
        .data = test_slice.ptr,
        .length = test_slice.len,
    }, StringView.fromSlice("test"));
}

test "slice can be constructed from normal StringView" {
    const test_slice = "test";
    const sv = StringView{
        .data = test_slice.ptr,
        .length = test_slice.len,
    };

    try std.testing.expectEqualSlices(u8, "test", sv.toSlice().?);
}

test "slice can be constructed from null-terminated StringView" {
    const test_slice = "test";
    const sv = StringView{
        .data = test_slice.ptr,
        .length = WGPU_STRLEN,
    };

    try std.testing.expectEqualSlices(u8, "test", sv.toSlice().?);
}

test "StringView.toSlice distinguishes null from an empty string" {
    const empty = StringView{
        .data = null,
        .length = 0,
    };
    try std.testing.expectEqualSlices(u8, "", empty.toSlice().?);

    const sv = StringView{
        .data = null,
        .length = WGPU_STRLEN,
    };

    try std.testing.expectEqual(null, sv.toSlice());
}

test "StringView rejects null data with a non-zero explicit length" {
    try std.testing.expectError(
        error.InvalidLength,
        StringView.nullDataToSlice(1),
    );
}
