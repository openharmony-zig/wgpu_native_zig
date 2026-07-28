const Library = @import("../build/Library.zig");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const library = Library.build(b, Library.standardOptions(b)) orelse return;
    const check_step = b.step(
        "check",
        "Compile the bindings and all target-compatible tests",
    );

    bindingTest(b, library, check_step);
    abiTest(b, library, check_step);

    if (library.isOhos()) {
        linkProbe(b, library, check_step);
        return;
    }
    if (library.isAndroid()) return;

    unitTests(b, library, check_step);
    computeTests(b, library, check_step);
}

fn bindingTest(
    b: *std.Build,
    library: Library.Result,
    check_step: *std.Build.Step,
) void {
    const test_mod = b.createModule(.{
        .root_source_file = b.path("tests/bindings.zig"),
        .target = library.target,
        .optimize = library.optimize,
    });
    test_mod.addImport("binding-audit", bindingAuditModule(b, library));
    const test_exe = b.addTest(.{
        .name = "bindings-test",
        .root_module = test_mod,
    });
    library.configureCompile(test_exe);
    check_step.dependOn(&test_exe.step);
}

fn abiTest(
    b: *std.Build,
    library: Library.Result,
    check_step: *std.Build.Step,
) void {
    const test_mod = b.createModule(.{
        .root_source_file = b.path("tests/abi.zig"),
        .target = library.target,
        .optimize = library.optimize,
    });
    test_mod.addImport("wgpu", library.wgpu_mod);
    test_mod.addImport("wgpu-c", library.wgpu_c_mod);
    const test_exe = b.addTest(.{
        .name = "abi-test",
        .root_module = test_mod,
    });
    library.configureCompile(test_exe);
    check_step.dependOn(&test_exe.step);
}

fn unitTests(
    b: *std.Build,
    library: Library.Result,
    check_step: *std.Build.Step,
) void {
    const unit_test_step = b.step("test", "Run unit tests");
    const unit_tests = .{
        .{ .path = "src/misc.zig", .name = "misc-test" },
        .{ .path = "src/instance.zig", .name = "instance-test" },
        .{ .path = "src/adapter.zig", .name = "adapter-test" },
        .{ .path = "src/pipeline.zig", .name = "pipeline-test" },
        .{ .path = "tests/lifetimes.zig", .name = "lifetimes-test" },
    };

    inline for (unit_tests) |unit_test| {
        const test_mod = b.createModule(.{
            .root_source_file = b.path(unit_test.path),
            .target = library.target,
            .optimize = library.optimize,
        });
        test_mod.addImport("wgpu-header", library.wgpu_c_mod);
        if (std.mem.eql(u8, unit_test.path, "tests/lifetimes.zig")) {
            test_mod.addImport("wgpu", library.wgpu_mod);
        }
        library.linkTestModule(b, test_mod);
        const test_exe = b.addTest(.{
            .name = unit_test.name,
            .root_module = test_mod,
        });
        library.configureCompile(test_exe);
        check_step.dependOn(&test_exe.step);

        const run_test = b.addRunArtifact(test_exe);
        library.configureRun(b, run_test);
        unit_test_step.dependOn(&run_test.step);
    }
}

fn computeTests(
    b: *std.Build,
    library: Library.Result,
    check_step: *std.Build.Step,
) void {
    const compute_test_mod = b.createModule(.{
        .root_source_file = b.path("tests/compute.zig"),
        .target = library.target,
        .optimize = library.optimize,
    });
    compute_test_mod.addImport("wgpu", library.wgpu_mod);
    const compute_test = b.addTest(.{
        .name = "compute-test",
        .root_module = compute_test_mod,
    });
    library.configureCompile(compute_test);
    check_step.dependOn(&compute_test.step);
    const run_compute_test = b.addRunArtifact(compute_test);
    library.configureRun(b, run_compute_test);

    const compute_test_c_mod = b.createModule(.{
        .root_source_file = b.path("tests/compute_c.zig"),
        .target = library.target,
        .optimize = library.optimize,
    });
    compute_test_c_mod.addImport("wgpu-c", library.wgpu_c_mod);
    const compute_test_c = b.addTest(.{
        .name = "compute-test-c",
        .root_module = compute_test_c_mod,
    });
    library.configureCompile(compute_test_c);
    check_step.dependOn(&compute_test_c.step);
    const run_compute_test_c = b.addRunArtifact(compute_test_c);
    library.configureRun(b, run_compute_test_c);

    const compute_test_step = b.step("compute-tests", "Run compute shader tests");
    compute_test_step.dependOn(&run_compute_test.step);
    compute_test_step.dependOn(&run_compute_test_c.step);
}

fn linkProbe(
    b: *std.Build,
    library: Library.Result,
    check_step: *std.Build.Step,
) void {
    const probe_mod = b.createModule(.{
        .root_source_file = b.path("tests/link_probe.zig"),
        .target = library.target,
        .optimize = library.optimize,
    });
    probe_mod.addImport("wgpu", library.wgpu_mod);
    const probe = b.addLibrary(.{
        .name = "wgpu-native-zig-link-probe",
        .root_module = probe_mod,
        .linkage = .dynamic,
    });
    library.configureCompile(probe);
    _ = probe.getEmittedBin();
    check_step.dependOn(&probe.step);
}

fn bindingAuditModule(
    b: *std.Build,
    library: Library.Result,
) *std.Build.Module {
    const audit_mod = b.createModule(.{
        .root_source_file = b.path("src/binding_audit.zig"),
        .target = library.target,
        .optimize = library.optimize,
    });
    audit_mod.addImport("wgpu-header", library.wgpu_c_mod);
    audit_mod.addImport("wgpu-wrapper", library.wgpu_mod);
    return audit_mod;
}
