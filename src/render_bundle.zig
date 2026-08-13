const raw = @import("raw.zig");
const StringView = @import("misc.zig").StringView;
const ChainedStruct = @import("chained_struct.zig").ChainedStruct;

pub const RenderBundleDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = StringView{},
};

pub const RenderBundle = opaque {
    // Unimplemented as of wgpu-native v29.0.0.0,
    // see https://github.com/gfx-rs/wgpu-native/blob/4a26b5b0757fe281c07dac4f3a6e2078c811f635/src/unimplemented.rs
    // pub inline fn setLabel(self: *RenderBundle, label: []const u8) void {
    //     wgpuRenderBundleSetLabel(self, StringView.fromSlice(label));
    // }

    pub inline fn addRef(self: *RenderBundle) void {
        raw.call(void, "wgpuRenderBundleAddRef", .{self});
    }
    pub inline fn release(self: *RenderBundle) void {
        raw.call(void, "wgpuRenderBundleRelease", .{self});
    }
};
