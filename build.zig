const Library = @import("build/Library.zig");
const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = Library.build(b, Library.standardOptions(b));
}
