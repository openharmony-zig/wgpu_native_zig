const Buffer = @import("buffer.zig").Buffer;
const U32_MAX = @import("misc.zig").U32_MAX;

const _texture = @import("texture.zig");
const Texture = _texture.Texture;
const TextureAspect = _texture.TextureAspect;

pub const WGPU_COPY_STRIDE_UNDEFINED = U32_MAX;

pub const Origin3D = extern struct {
    x: u32 = 0,
    y: u32 = 0,
    z: u32 = 0,
};

pub const TexelCopyTextureInfo = extern struct {
    texture: *Texture,
    mip_level: u32 = 0,
    origin: Origin3D,
    aspect: TextureAspect = .all,
};

pub const TexelCopyBufferLayout = extern struct {
    offset: u64 = 0,
    bytes_per_row: u32 = WGPU_COPY_STRIDE_UNDEFINED,
    rows_per_image: u32 = WGPU_COPY_STRIDE_UNDEFINED,
};

pub const TexelCopyBufferInfo = extern struct {
    layout: TexelCopyBufferLayout,
    buffer: *Buffer,
};
