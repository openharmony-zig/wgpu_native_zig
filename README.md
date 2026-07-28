# wgpu_native_zig

Zig bindings for [wgpu-native](https://github.com/gfx-rs/wgpu-native)

Requires Zig 0.16.x.

This package exposes two modules: `wgpu-c` and `wgpu`.

`wgpu-c` is `wgpu.h` (and therefore `webgpu.h`) translated directly by Zig, so it
tracks wgpu-native's C API without a second handwritten declaration layer.

`wgpu` is a Zig-friendly wrapper over the bindings generated directly from `wgpu.h` and
`webgpu.h`. The generated declarations are also available through `wgpu.raw`; wrapper
methods and raw calls therefore share the headers as their single ABI source of truth.

### Binding coverage

The pinned wgpu-native `v29.0.0.0` headers currently declare 226 functions. The
`wgpu` wrapper exposes every function with a usable v29 implementation, while
`wgpu.raw` and `wgpu-c` expose all function and type declarations produced by
`translate-c`. A compile-time audit checks this partition, rejects handwritten
`extern fn wgpu...` declarations, and fails when a future header update adds an
unclassified function or type.

The following v29 API groups intentionally remain raw-only because their upstream
implementations panic, are blocked, or always return an unavailable result:

- `wgpuGetProcAddress` and the currently unimplemented `*SetLabel` functions.
- Async pipeline creation, shader compilation info, device-lost futures, `waitAny`,
  WGSL-language feature queries, and global instance-feature enumeration.
- Buffer map-state and mapped-range copy helpers.
- External-texture lifecycle functions.
- Device adapter-info lookup and texture binding-view-dimension lookup.
- The native Metal command-queue accessor, which always returns null in v29.

Supported wgpu-native extensions are available as regular Zig methods, including
`Queue.getTimestampPeriod`, graphics-debugger capture control, and the borrowed Metal
device/texture accessors. Platform-native pointers are optional and must not be released
by the caller.

## Adding this package to your build

Add the package to your dependencies, either with:

```sh
zig fetch --save https://github.com/openharmony-zig/wgpu_native_zig/archive/refs/tags/v7.0.0.tar.gz
```

or by manually adding to your `build.zig.zon`:

```zig
.{
    // ...other stuff
    .dependencies = .{
        // ...other dependencies
        .wgpu_native_zig = .{
            // You can either use a commit hash:
            .url="https://github.com/openharmony-zig/wgpu_native_zig/archive/<commit_hash>.tar.gz",
            // or a tagged release:
            // .url = "https://github.com/openharmony-zig/wgpu_native_zig/archive/refs/tags/v7.0.0.tar.gz`
            .hash="<dependency hash>"
        }
    }
}
```

Then, in `build.zig` add:

```zig
    const wgpu_native_dep = b.dependency("wgpu_native_zig", .{});

    // Add module to your exe (wgpu-c can also be added like this, just pass in "wgpu-c" instead)
    exe.root_module.addImport("wgpu", wgpu_native_dep.module("wgpu"));
    // Or, add to your lib similarly:
    lib.root_module.addImport("wgpu", wgpu_native_dep.module("wgpu"));
```

### Building on Windows

Windows x86_64 has two options for ABI: GNU and MSVC. For i686 and aarch64, only the MSVC option is available.
If you need to specify the build target, you can do that with:

```zig
const target = b.standardTargetOptions(.{
    .default_target = .{
        // If not specified, defaults to the GNU abi
        .abi = .msvc,
    }
});
```

Or, specify it with your build command. For example, the triangle example in this repository can be run like so:

```sh
zig build --build-file build.examples.zig run-triangle-example -Dtarget=x86_64-windows-msvc
```

Either way, pass the resolved target to the dependency like so:

```zig
const wgpu_native_dep = b.dependency("wgpu_native_zig", .{
  .target = target
});
```

When using static linking with MSVC, you might encounter duplicate symbol errors. If so, try

```zig
if (target.result.abi == .msvc) {
  // "exe" here is the *std.Build.Step.Compile from b.addExecutable() (or b.addTest())
  exe.bundle_compiler_rt = false;
  exe.bundle_ubsan_rt = false;
}
```

An example of using `wgpu-native-zig` with static linking on Windows can be found at [wgpu-native-zig-windows-test](https://github.com/bronter/wgpu-native-zig-windows-test).

### Dynamic linking

Dynamic linking can be made to work, though it is a bit messy to use.
When you initialize your `wgpu_native_dep`, add the option for dynamic linking like so:

```zig
const wgpu_native_dep = b.dependency("wgpu_native_zig", .{
  // Defaults to .static if you don't specify
  .link_mode = .dynamic
});
```

Then add the following with your install step dependencies:

```zig
const lib_dir = wgpu_native_dep.namedWriteFiles("lib").getDirectory();

// This would also work with .so files on linux
const dll_path = lib_dir.join(b.allocator, "wgpu_native.dll") catch return;

// addInstallBinFile puts the dll in the same directory as your executable
const install_dll = b.addInstallBinFile(dll_path, "wgpu_native.dll");

// Make sure that the dll is installed when the install step is run
b.getInstallStep().dependOn(&install_dll.step);
```

## Building `wgpu-native`

`wgpu-native` v29.0.0.0 is built from its pinned source commit by default. The matching
`webgpu-headers` commit is pinned separately, so the generated C ABI does not drift when
an upstream branch changes.

The source build requires Cargo, a Rust toolchain with the selected target installed,
and the platform SDK normally required by that target. For example:

```sh
# Native source build. Installs the static library, dynamic library, and C headers.
zig build -Doptimize=ReleaseFast

# Compile the bindings and link probes without running them.
zig build --build-file build.tests.zig check -Doptimize=ReleaseFast
```

Targets that cannot legally be built on every host still require their native toolchain:
iOS requires Xcode on macOS, MSVC requires Windows, and Android/OpenHarmony require their
respective NDKs.

The root `build.zig` only builds `wgpu-native` and exposes the `wgpu`/`wgpu-c` binding
modules. `build/Library.zig` is the shared library entry point, while
`build/platform/root.zig` dispatches to the Android, Apple, Linux, OpenHarmony, or
Windows build implementation. Tests and examples are isolated behind
`build.tests.zig` and `build.examples.zig`; their implementation stays in the
corresponding directory.

### Using published prebuilt libraries

Set `WGPU_NATIVE_USE_PREBUILT=1` to skip the Cargo source build and use the published
`wgpu-native` archive for the selected target:

```sh
WGPU_NATIVE_USE_PREBUILT=1 zig build --build-file build.tests.zig check \
  -Dtarget=x86_64-linux-gnu
```

The equivalent Zig build option is `-Duse_prebuilt=true`. Downstream packages can pass it
while resolving this dependency:

```zig
const wgpu_native_dep = b.dependency("wgpu_native_zig", .{
    .target = target,
    .optimize = optimize,
    .use_prebuilt = true,
});
```

`WGPU_NATIVE_PREBUILT_DIR=/path/to/prefix` uses a local artifact directory and also
implies prebuilt mode. The prefix must use the layout produced by this package:

```text
prefix/
├── include/webgpu/{webgpu.h,wgpu.h}
└── lib/
    ├── libwgpu_native.a
    └── libwgpu_native.so
```

Use the platform-specific dynamic and import-library names on Apple and Windows.
OpenHarmony currently uses this local-directory mechanism when consuming CI artifacts,
because upstream `wgpu-native` does not publish OpenHarmony archives.

### Supported artifact targets

| Platform    | Architectures / ABIs                            | Source build                 | Published prebuilt |
| ----------- | ----------------------------------------------- | ---------------------------- | ------------------ |
| Android     | arm64-v8a, armeabi-v7a, x86, x86_64             | Yes, with `ANDROID_NDK_HOME` | Yes                |
| iOS         | arm64 device, arm64 simulator, x86_64 simulator | Yes, on macOS                | Yes                |
| Linux       | aarch64, x86_64 (GNU); aarch64, x86_64 (musl)   | Yes                          | GNU targets        |
| macOS       | aarch64, x86_64                                 | Yes, on macOS                | Yes                |
| Windows     | aarch64/x86/x86_64 MSVC, x86/x86_64 GNU         | Yes, on Windows              | All except x86 GNU |
| OpenHarmony | arm64-v8a, armeabi-v7a, x86_64                  | Yes, with `OHOS_NDK_HOME`    | Local CI artifact  |

The OpenHarmony commands are:

```sh
rustup target add \
  aarch64-unknown-linux-ohos \
  armv7-unknown-linux-ohos \
  x86_64-unknown-linux-ohos

zig build --build-file build.tests.zig check \
  -Dtarget=aarch64-linux-ohos -Doptimize=ReleaseFast
zig build --build-file build.tests.zig check \
  -Dtarget=arm-linux-ohoseabi -Doptimize=ReleaseFast
zig build --build-file build.tests.zig check \
  -Dtarget=x86_64-linux-ohos -Doptimize=ReleaseFast
```

The target-artifact workflow builds the complete matrix on Linux x86_64/aarch64, macOS
arm64/Intel, Windows, Android, and OpenHarmony runners. Android and OpenHarmony run the
binding/ABI audit for every ABI before packaging. Every artifact prefix contains both
link modes and the matching headers.

## How the `wgpu` module differs from `wgpu-c`

- Names are shortened to remove redundancy.
  - For example `wgpu.WGPUSurfaceDescriptor` becomes `wgpu.SurfaceDescriptor`
- C pointers (`[*c]`) are replaced with more specific pointer types.
  - For example `[*c]const u8` is replaced with `?[*:0]const u8`.
- Pointers to opaque structs are made explicit (and only optional when they need to be).
  - For example `wgpu.WGPUAdapter` from `webgpu.h` would instead be expressed as `*wgpu.Adapter` or `?*wgpu.Adapter`, depending on the context.
- Methods are expressed as decls inside of structs
  - For example
    ```zig
    wgpu.wgpuInstanceCreateSurface(instance: WGPUInstance, descriptor: [*c]const WGPUSurfaceDescriptor) WGPUSurface
    ```
    becomes
    ```zig
    Instance.createSurface(self: *Instance, descriptor: *const SurfaceDescriptor) ?*Surface
    ```
- Certain asynchronous methods such as requestAdapter and requestDevice are provided with wrapper methods.
  - For example, requesting an adapter with a callback looks something like
    ```zig
    fn handleRequestAdapter(
        status: Instance.RequestAdapterStatus,
        adapter: ?*Adapter,
        message: StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque
    ) callconv(.c) void {
        switch(status) {
            .success => {
                const ud_adapter: **Adapter = @ptrCast(@alignCast(userdata1));
                ud_adapter.* = adapter.?;
            },
            else => {
              std.log.err("{s}\n", .{message.toSlice()});
            }
        }
        const completed: *bool = @ptrCast(@alignCast(userdata2));
        completed.* = true;
    }
    var adapter_ptr: ?*Adapter = null;
    var completed = false;
    const request_adapter_info = Instance.RequestAdapterCallbackInfo {
        .callback = handleRequestAdapter,
        .userdata1 = @ptrCast(&adapter_ptr),
        .userdata2 = @ptrCast(&completed),
    }
    const ra_future = instance.requestAdapter(null, request_adapter_info);

    // wgpu-native v29 does not implement Instance.waitAny(), so drive
    // allow_process_events callbacks with Instance.processEvents().
    _ = ra_future;

    instance.processEvents();
    while(!completed) {
      try io.sleep(.fromNanoseconds(200_000_000), .awake);
      instance.processEvents();
    }
    ```
    whereas the non-callback version looks like
    ```zig
    // The wrapper methods use polling, so 200_000_000 is the polling interval in nanoseconds.
    var response = try instance.requestAdapterSync(allocator, io, null, 200_000_000);
    defer response.deinit(allocator);

    const adapter_ptr: ?*Adapter = switch (response.status) {
        .success => response.takeAdapter(),
        else => blk: {
            std.log.err("{s}\n", .{response.message orelse "adapter request failed"});
            break :blk null;
        }
    };
    ```
    The synchronous response owns its copied callback message and returned handle.
    Call `deinit()` on every response, and use `takeAdapter()` or `takeDevice()` to
    transfer a successful handle out of it.
    If the supplied `Io` is cancelled, the synchronous wrapper finishes draining
    the native callback before returning the cancellation error, yielding the
    polling thread between `processEvents()` calls. This is required because
    wgpu-native v29 has no `waitAny()` implementation and the callback userdata
    must remain alive until completion.
- Output structures whose members are allocated by wgpu-native use pointer-based
  `deinit()` methods. In particular, `SupportedFeatures`, `AdapterInfo`, and
  `SurfaceCapabilities` clear their owned pointers, counts, and strings after
  releasing them, so a deferred `deinit()` cannot observe stale members.
- `SurfaceTexture` owns the texture returned by `Surface.getCurrentTexture()`.
  Use `defer surface_texture.deinit()` to release it automatically, or call
  `takeTexture()` to transfer the texture to code that will release it.
- Chained structs are provided with inline functions for constructing them, which come in two forms depending on whether or not the chained struct is likely to always be required.
  - For required chained structs, you can either write them explicitely:
    ```zig
    const source = SurfaceSourceXlibWindow{
        .display = display,
        .window = window,
    };
    const descriptor = SurfaceDescriptor{
        .next_in_chain = &source.chain,
        .label = StringView.fromSlice("xlib_surface_descriptor"),
    };
    ```
    or use a function to construct the root descriptor:
    ```zig
    const source = SurfaceSourceXlibWindow{
        .display = display,
        .window = window,
    };
    const descriptor = surfaceDescriptorFromXlibWindow(
        &source,
        "xlib_surface_descriptor",
    );
    ```
  - For optional chained structs, create the extension separately and attach it
    with `withExtras()`:
    ```zig
    const extras = SurfaceConfigurationExtras{
        .desired_maximum_frame_latency = 2,
    };
    const configuration = (SurfaceConfiguration{
        .device = device,
        // other fields
    }).withExtras(&extras);
    ```
    The source or extras value must remain alive until the native API call that
    consumes the descriptor has returned.
- `WGPUBool` is replaced with `bool` whenever possible.
  - This means it is replaced with `bool` in wrapper method parameters and return values, but not in structs that preserve the C ABI.
- Callback types that belong to one handle are scoped under that handle. For example,
  use `Instance.RequestAdapterCallbackInfo`, `Adapter.RequestDeviceCallbackInfo`,
  `Buffer.MapCallbackInfo`, and `Device.PopErrorScopeCallbackInfo`.
- Wrapper names retain meaningful WebGPU prefixes. For example,
  `WGPUTextureSampleType` is exposed as `TextureSampleType`.

## TODO

- Expand headless coverage for Device creation, feature/limit queries, error scopes,
  textures, samplers, query sets, and render bundles.
- Port [wgpu-native-examples](https://github.com/samdauwe/webgpu-native-examples) using wrapper code, as a basic form of documentation.
