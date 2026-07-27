const std = @import("std");

pub fn addDirectoryFiles(
    b: *std.Build,
    staged_source: *std.Build.Step.WriteFile,
    source: std.Build.LazyPath,
    destination: []const u8,
) void {
    const resolved = source.getPath3(b, null);
    var directory = resolved.root_dir.handle.openDir(
        b.graph.io,
        resolved.subPathOrDot(),
        .{ .iterate = true },
    ) catch |err| std.debug.panic(
        "unable to open {s}: {s}",
        .{ source.getPath(b), @errorName(err) },
    );
    defer directory.close(b.graph.io);

    var iterator = directory.walk(b.allocator) catch @panic("out of memory");
    defer iterator.deinit();
    while (iterator.next(b.graph.io) catch |err| std.debug.panic(
        "unable to walk {s}: {s}",
        .{ source.getPath(b), @errorName(err) },
    )) |entry| {
        if (entry.kind != .file) continue;
        _ = staged_source.addCopyFile(
            source.path(b, entry.path),
            b.pathJoin(&.{ destination, entry.path }),
        );
    }
}
