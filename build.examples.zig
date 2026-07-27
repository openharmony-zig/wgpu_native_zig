const std = @import("std");
const Examples = @import("examples/build.zig");

// Keep the package root at the repository while example build logic lives in examples/.
pub fn build(b: *std.Build) void {
    Examples.build(b);
}
