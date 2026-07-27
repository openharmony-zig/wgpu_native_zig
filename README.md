# wgpu_native_zig
Zig bindings for [wgpu-native](https://github.com/gfx-rs/wgpu-native)

Requires Zig 0.16.x.

This package exposes two modules: `wgpu-c` and `wgpu`.

`wgpu-c` is just `wgpu.h` (and by extension `webgpu.h`) run through `translate-c`, so as close to wgpu-native's original C API as is possible in Zig.

`wgpu` is a module full of pure Zig bindings for `libwgpu_native`, it does not import any C code and instead relies on `extern fn` declarations to hook up to `wgpu-native`.

## Adding this package to your build
Add the package to your dependencies, either with:
```sh
zig fetch --save https://github.com/bronter/wgpu_native_zig/archive/refs/tags/v6.5.0.tar.gz
```
or by manually adding to your `build.zig.zon`:
```zig
.{
    // ...other stuff
    .dependencies = .{
        // ...other dependencies
        .wgpu_native_zig = .{
            // You can either use a commit hash:
            .url="https://github.com/bronter/wgpu_native_zig/archive/<commit_hash>.tar.gz",
            // or a tagged release:
            // .url = "https://github.com/bronter/wgpu_native_zig/archive/refs/tags/v6.5.0.tar.gz`
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

`wgpu-native` v25.0.2.1 is built from its pinned source commit by default. The matching
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

| Platform | Architectures / ABIs | Source build | Published prebuilt |
| --- | --- | --- | --- |
| Android | arm64-v8a, armeabi-v7a, x86, x86_64 | Yes, with `ANDROID_NDK_HOME` | Yes |
| iOS | arm64 device, arm64 simulator, x86_64 simulator | Yes, on macOS | Yes |
| Linux | aarch64, x86_64 (GNU); aarch64, x86_64 (musl) | Yes | GNU targets |
| macOS | aarch64, x86_64 | Yes, on macOS | Yes |
| Windows | aarch64/x86/x86_64 MSVC, x86/x86_64 GNU | Yes, on Windows | All except x86 GNU |
| OpenHarmony | arm64-v8a, armeabi-v7a, x86_64 | Yes, with `OHOS_NDK_HOME` | Local CI artifact |

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
arm64/Intel, Windows, Android, and OpenHarmony runners. Every artifact prefix contains
both link modes and the matching headers.


## How the `wgpu` module differs from `wgpu-c`
* Names are shortened to remove redundancy.
  * For example `wgpu.WGPUSurfaceDescriptor` becomes `wgpu.SurfaceDescriptor`
* C pointers (`[*c]`) are replaced with more specific pointer types.
  * For example `[*c]const u8` is replaced with `?[*:0]const u8`.
* Pointers to opaque structs are made explicit (and only optional when they need to be).
  * For example `wgpu.WGPUAdapter` from `webgpu.h` would instead be expressed as `*wgpu.Adapter` or `?*wgpu.Adapter`, depending on the context.
* Methods are expressed as decls inside of structs
  * For example 
    ```zig
    wgpu.wgpuInstanceCreateSurface(instance: WGPUInstance, descriptor: [*c]const WGPUSurfaceDescriptor) WGPUSurface
    ``` 
    becomes
    ```zig
    Instance.createSurface(self: *Instance, descriptor: *const SurfaceDescriptor) ?*Surface
    ```
* Certain asynchronous methods such as requestAdapter and requestDevice are provided with wrapper methods.
  * For example, requesting an adapter with a callback looks something like
    ```zig
    fn handleRequestAdapter(
        status: RequestAdapterStatus,
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
    const request_adapter_info = RequestAdapterInfo {
        .callback = handleRequestAdapter,
        .userdata1 = @ptrCast(&adapter_ptr),
        .userdata2 = @ptrCast(&completed),
    }
    const ra_future = instance.requestAdapter(null, request_adapter_info);

    // There is currently no way to use a `Future`,
    // it's supposed to be passed into `Instance.waitAny()`,
    // which is unimplemented as of `wgpu_native` v24.0.3.1.
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
    const response = try instance.requestAdapterSync(io, null, 200_000_000);

    const adapter_ptr: ?*Adapter = switch (response.status) {
        .success => response.adapter,
        else => blk: {
            std.log.err("{s}\n", .{response.message});
            break :blk null;
        }
    };
    ```
* Chained structs are provided with inline functions for constructing them, which come in two forms depending on whether or not the chained struct is likely to always be required.
  * For required chained structs, you can either write them explicitely:
    ```zig
    SurfaceDescriptor{
        .next_in_chain = @ptrCast(&SurfaceDescriptorFromXlibWindow {
            .chain = ChainedStruct {
                .s_type = SType.surface_descriptor_from_xlib_window,
            },
            .display = display,
            .window = window,
        }),
        .label = "xlib_surface_descriptor",
    };
    ```
    or use a function to construct them:
    ```zig
    // Here the descriptors from SurfaceDescriptor and SurfaceDescriptorFromXlibWindow have been merged,
    // so just pass in an anonymous struct with the things that you need; default values will take care of the rest.
    surfaceDescriptorFromXlibWindow(.{
        .label = "xlib_surface_descriptor",
        .display = display,
        .window = window
    });
    ```
  * For optional chained structs, you can either write them explicitely like in the example above, or you can use a method of the parent struct instance to add them, for example:
    ```zig
    &(SurfaceConfiguration {
      .device = device,
      // other stuff
    }).withDesiredMaxFrameLatency(2);
    ```
* `WGPUBool` is replaced with `bool` whenever possible.
  * This pretty much means, it is replaced with `bool` in the parameters and return values of methods, but not in structs or the parameters/return values of procs (which are supposed to be function pointers to things returned by `wgpuGetProcAddress`).

## TODO
* Cleanup/organization: 
  * If types are only tied to a specific opaque struct, they should be decls inside that struct.
  * The associated Procs struct should probably be a decl of the opaque struct as well.
  * There are many things that seem to be in the wrong file.
    * For example a lot of what is in `pipeline.zig` is actually only used by `Device`, and should probably be in `device.zig` instead.
  * Since pointers to opaque structs are made explicit, it would be more consistent if pointers to callback functions are explicit as well.
* Port [wgpu-native-examples](https://github.com/samdauwe/webgpu-native-examples) using wrapper code, as a basic form of documentation.
* Bindgen using [the webgpu-headers yaml](https://github.com/webgpu-native/webgpu-headers/blob/main/webgpu.yml)?
* The proc definitions are mainly there since they are also present in the webgpu headers and I didn't fully understand what they were for when I started working on this project. However, I know better now and they aren't really used for anything currently. They're supposed to be used with `wgpuGetProcAddress` but it's [unimplemented in `wgpu-native`](https://github.com/gfx-rs/wgpu-native/issues/223). They are a pain to update by hand, so maybe they should be removed for now and made optional once we have a working bindings generator? Like the bindgen could put them in a separate `wgpu-procs` module.
