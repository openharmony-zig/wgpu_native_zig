const std = @import("std");

const WGPUBool = @import("misc.zig").WGPUBool;

//
// The callback mode controls how a callback for an asynchronous operation may be fired.
//
pub const CallbackMode = enum(u32) {
    //
    //`0x00000001`.
    // Callbacks created with `wait_any_only`:
    // - fire when the asynchronous operation's future is passed to a call to `::wgpuInstanceWaitAny`
    //   AND the operation has already completed or it completes inside the call to `::wgpuInstanceWaitAny`.
    //
    wait_any_only = 0x00000001,
    //
    // `0x00000002`.
    // Callbacks created with `allow_process_events`:
    // - fire for the same reasons as callbacks created with `wait_any_only`
    // - fire inside a call to `::wgpuInstanceProcessEvents` if the asynchronous operation is complete.
    //
    allow_process_events = 0x00000002,
    //
    // `0x00000003`.
    // Callbacks created with `allow_spontaneous`:
    // - fire for the same reasons as callbacks created with `allow_process_events`
    // - **may** fire spontaneously on an arbitrary or application thread, when the WebGPU implementations discovers that the asynchronous operation is complete.
    //
    //   Implementations _should_ fire spontaneous callbacks as soon as possible.
    //
    // Because spontaneous callbacks may fire at an arbitrary time on an arbitrary thread, applications should take extra care when acquiring locks or mutating state inside the callback.
    // It undefined behavior to re-entrantly call into the webgpu.h API if the callback fires while inside the callstack of another webgpu.h function that is not `wgpuInstanceWaitAny` or `wgpuInstanceProcessEvents`.
    //
    allow_spontaneous = 0x00000003,
};

// Status returned from a call to ::wgpuInstanceWaitAny.
pub const WaitStatus = enum(u32) {
    // At least one Future completed successfully.
    success = 0x00000001,

    // No Futures completed within the timeout.
    timed_out = 0x00000002,

    // The call was invalid for some reason.
    @"error" = 0x00000003,
};

//
// Opaque handle to an asynchronous operation.
//
pub const Future = extern struct {
    //
    // Opaque id of the Future
    //
    id: u64,
};

//
// Struct holding a future to wait on, and a `completed` boolean flag.
//
pub const FutureWaitInfo = extern struct {
    // The future to wait on.
    future: Future,

    // Whether or not the future completed.
    completed: WGPUBool,
};

/// Drives an `allow_process_events` callback to completion.
///
/// If `io` is cancelled, the error is returned only after the callback has
/// completed. This keeps callback userdata valid for its full native lifetime.
/// The drain phase yields the current thread between event-processing calls so
/// cancellation does not turn into a busy loop.
pub fn waitForCallback(
    event_source: anytype,
    completed: *const bool,
    io: std.Io,
    polling_interval_nanoseconds: u64,
) std.Io.Cancelable!void {
    var cancellation_error: ?std.Io.Cancelable = null;

    event_source.processEvents();
    while (!completed.*) {
        if (cancellation_error == null) {
            io.sleep(.fromNanoseconds(polling_interval_nanoseconds), .awake) catch |err| {
                cancellation_error = err;
            };
        } else {
            std.Thread.yield() catch std.atomic.spinLoopHint();
        }
        event_source.processEvents();
    }

    if (cancellation_error) |err| return err;
}

test "waitForCallback drives events until completion" {
    const testing = std.testing;

    var completed = false;
    var event_source = TestEventSource{ .completed = &completed };

    try waitForCallback(&event_source, &completed, testing.io, 0);

    try testing.expect(completed);
    try testing.expectEqual(2, event_source.process_count);
}

test "waitForCallback drains events before returning cancellation" {
    const testing = std.testing;

    var completed = false;
    var event_source = TestEventSource{
        .completed = &completed,
        .complete_after = 3,
    };
    var vtable = testing.io.vtable.*;
    vtable.sleep = cancelSleep;
    const canceled_io = std.Io{
        .userdata = null,
        .vtable = &vtable,
    };

    try testing.expectError(
        error.Canceled,
        waitForCallback(&event_source, &completed, canceled_io, 0),
    );

    try testing.expect(completed);
    try testing.expectEqual(3, event_source.process_count);
}

const TestEventSource = struct {
    completed: *bool,
    process_count: usize = 0,
    complete_after: usize = 2,

    fn processEvents(self: *TestEventSource) void {
        self.process_count += 1;
        if (self.process_count == self.complete_after) self.completed.* = true;
    }
};

fn cancelSleep(_: ?*anyopaque, _: std.Io.Timeout) std.Io.Cancelable!void {
    return error.Canceled;
}
