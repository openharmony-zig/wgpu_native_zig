const std = @import("std");
const testing = std.testing;

const wgpu = @import("wgpu");

fn compute_collatz() ![4]u32 {
    const numbers = [_]u32{ 1, 2, 3, 4 };
    const numbers_size = @sizeOf(@TypeOf(numbers));
    const numbers_length = numbers_size / @sizeOf(u32);

    const instance = wgpu.Instance.create(null).?;
    defer instance.release();

    var adapter_response = try instance.requestAdapterSync(testing.allocator, testing.io, null, 200_000_000);
    defer adapter_response.deinit(testing.allocator);
    const adapter = switch (adapter_response.status) {
        .success => adapter_response.takeAdapter().?,
        else => return error.NoAdapter,
    };
    defer adapter.release();

    var device_response = try adapter.requestDeviceSync(testing.allocator, testing.io, instance, null, 200_000_000);
    defer device_response.deinit(testing.allocator);
    const device = switch (device_response.status) {
        .success => device_response.takeDevice().?,
        else => return error.NoDevice,
    };
    defer device.release();

    device.pushErrorScope(.validation);
    var error_scope = try device.popErrorScopeSync(
        testing.allocator,
        testing.io,
        instance,
        200_000_000,
    );
    defer error_scope.deinit(testing.allocator);
    try testing.expectEqual(
        wgpu.Device.PopErrorScopeStatus.success,
        error_scope.status,
    );
    try testing.expectEqual(wgpu.Device.ErrorType.no_error, error_scope.error_type);

    const queue = device.getQueue().?;
    defer queue.release();
    try testing.expect(queue.getTimestampPeriod() > 0);

    const shader_source = wgpu.ShaderSourceWGSL{
        .code = wgpu.StringView.fromSlice(@embedFile("./compute.wgsl")),
    };
    const shader_descriptor = wgpu.shaderModuleWGSLDescriptor(&shader_source, "compute.wgsl");
    const shader_module = device.createShaderModule(&shader_descriptor).?;
    defer shader_module.release();

    const staging_buffer = device.createBuffer(&wgpu.BufferDescriptor{
        .label = wgpu.StringView.fromSlice("staging_buffer"),
        .usage = wgpu.BufferUsages.map_read | wgpu.BufferUsages.copy_dst,
        .size = numbers_size,
        .mapped_at_creation = @as(u32, @intFromBool(false)),
    }).?;
    defer staging_buffer.release();

    const storage_buffer = device.createBuffer(&wgpu.BufferDescriptor{
        .label = wgpu.StringView.fromSlice("storage_buffer"),
        .usage = wgpu.BufferUsages.storage | wgpu.BufferUsages.copy_dst | wgpu.BufferUsages.copy_src,
        .size = numbers_size,
        .mapped_at_creation = @as(u32, @intFromBool(false)),
    }).?;
    defer storage_buffer.release();

    const compute_pipeline = device.createComputePipeline(&wgpu.ComputePipelineDescriptor{
        .label = wgpu.StringView.fromSlice("compute_pipeline"),
        .compute = wgpu.ComputeState{
            .module = shader_module,
            .entry_point = wgpu.StringView.fromSlice("main"),
        },
    }).?;
    defer compute_pipeline.release();

    const bind_group_layout = compute_pipeline.getBindGroupLayout(0).?;
    defer bind_group_layout.release();

    const bind_group = device.createBindGroup(&wgpu.BindGroupDescriptor{
        .label = wgpu.StringView.fromSlice("bind_group"),
        .layout = bind_group_layout,
        .entry_count = 1,
        .entries = &[_]wgpu.BindGroupEntry{wgpu.BindGroupEntry{
            .binding = 0,
            .buffer = storage_buffer,
            .offset = 0,
            .size = numbers_size,
        }},
    }).?;
    defer bind_group.release();

    const command_encoder = device.createCommandEncoder(&wgpu.CommandEncoderDescriptor{
        .label = wgpu.StringView.fromSlice("command_encoder"),
    }).?;
    defer command_encoder.release();

    const compute_pass_encoder = command_encoder.beginComputePass(&wgpu.ComputePassDescriptor{
        .label = wgpu.StringView.fromSlice("compute_pass"),
    }).?;

    compute_pass_encoder.setPipeline(compute_pipeline);
    compute_pass_encoder.setBindGroup(0, bind_group, &.{});
    compute_pass_encoder.dispatchWorkgroups(numbers_length, 1, 1);
    compute_pass_encoder.end();

    // Must be released here: https://github.com/gfx-rs/wgpu-native/issues/412#issuecomment-2311719154
    compute_pass_encoder.release();

    command_encoder.copyBufferToBuffer(storage_buffer, 0, staging_buffer, 0, numbers_size);

    const command_buffer = command_encoder.finish(&wgpu.CommandBufferDescriptor{
        .label = wgpu.StringView.fromSlice("command_buffer"),
    }).?;
    defer command_buffer.release();

    queue.writeBuffer(storage_buffer, 0, std.mem.asBytes(&numbers));
    queue.submit(&[_]*const wgpu.CommandBuffer{command_buffer});

    var work_done = try queue.onSubmittedWorkDoneSync(
        testing.allocator,
        testing.io,
        instance,
        200_000_000,
    );
    defer work_done.deinit(testing.allocator);
    try testing.expectEqual(wgpu.Queue.WorkDoneStatus.success, work_done.status);

    var map_response = try staging_buffer.mapSync(
        testing.allocator,
        testing.io,
        instance,
        wgpu.Buffer.MapModes.read,
        0,
        numbers_size,
        200_000_000,
    );
    defer map_response.deinit(testing.allocator);
    try testing.expectEqual(wgpu.Buffer.MapAsyncStatus.success, map_response.status);

    const mapped = staging_buffer.getConstMappedRange(
        0,
        wgpu.WGPU_WHOLE_MAP_SIZE,
    ).?;
    const buf: [*]const u32 = @ptrCast(@alignCast(mapped.ptr));
    defer staging_buffer.unmap();

    const ret = [4]u32{ buf[0], buf[1], buf[2], buf[3] };
    return ret;
}

test "compute functionality" {
    const values = compute_collatz() catch |err| switch (err) {
        error.NoAdapter, error.NoDevice => return error.SkipZigTest,
        else => return err,
    };

    try testing.expect(values[0] == 0);
    try testing.expect(values[1] == 1);
    try testing.expect(values[2] == 7);
    try testing.expect(values[3] == 2);
}
