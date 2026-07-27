const Library = @import("../build/Library.zig");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const library = Library.build(b, Library.standardOptions(b)) orelse return;
    if (library.isOhos()) return;

    const bmp_mod = b.createModule(.{
        .root_source_file = b.path("examples/bmp.zig"),
    });
    const triangle_mod = b.createModule(.{
        .root_source_file = b.path("examples/triangle/triangle.zig"),
        .target = library.target,
        .optimize = library.optimize,
    });
    triangle_mod.addImport("wgpu", library.wgpu_mod);
    triangle_mod.addImport("bmp", bmp_mod);

    const triangle = b.addExecutable(.{
        .name = "triangle-example",
        .root_module = triangle_mod,
    });
    library.configureCompile(triangle);
    const check_step = b.step("check", "Compile all examples without running them");
    check_step.dependOn(&triangle.step);

    const run_triangle = b.addRunArtifact(triangle);
    library.configureRun(b, run_triangle);
    const run_step = b.step("run-triangle-example", "Run the triangle example");
    run_step.dependOn(&run_triangle.step);
}
