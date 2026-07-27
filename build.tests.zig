const std = @import("std");
const Tests = @import("tests/build.zig");

// Keep the package root at the repository while test build logic lives in tests/.
pub fn build(b: *std.Build) void {
    Tests.build(b);
}
