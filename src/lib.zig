const std = @import("std");
const c = @import("c.zig").c;
const log = std.log.scoped(.nfd);

pub const Error = error{
    NfdError,
};

pub fn makeError() Error {
    if (c.NFD_GetError()) |ptr| {
        log.debug("{s}\n", .{
            std.mem.sliceTo(ptr, 0),
        });
    }
    return error.NfdError;
}

/// Open single file dialog
pub fn openFileDialog(filter: ?[:0]const u8, default_path: ?[:0]const u8) Error!?[:0]const u8 {
    var out_path: [*c]u8 = null;

    // allocates using malloc
    const result = c.NFD_OpenDialog(if (filter != null) filter.? else null, if (default_path != null) default_path.? else null, &out_path);

    return switch (result) {
        c.NFD_OKAY => if (out_path == null) null else std.mem.sliceTo(out_path, 0),
        c.NFD_ERROR => makeError(),
        else => null,
    };
}

/// Open multiple file dialog
/// Make sure to call freePaths on it
pub fn openFilesDialog(filter: ?[:0]const u8, default_path: ?[:0]const u8) !std.ArrayList([]const u8) {
    var out_paths: ?[*c]c.nfdpathset_t = null;

    // allocates using malloc
    const result = c.NFD_OpenDialogMultiple(if (filter != null) filter.? else null, if (default_path != null) default_path.? else null, &out_paths);

    if (result == c.NFD_ERROR) {
        return makeError();
    }

    const path_count = c.NFD_PathSet_GetCount(out_paths);

    var paths = try std.ArrayList([]const u8).initCapacity(std.heap.page_allocator, 1);

    for (0..path_count) |i| {
        const path_ptr = c.NFD_PathSet_GetPath(out_paths, i);
        if (path_ptr != null) {
            const path = std.mem.span(path_ptr);
            try paths.append(std.heap.page_allocator, path);
        }
    }

    c.NFD_PathSet_Free(out_paths);

    return paths;
}

/// Open save dialog
pub fn saveFileDialog(filter: ?[:0]const u8, default_path: ?[:0]const u8) Error!?[:0]const u8 {
    var out_path: [*c]u8 = null;

    // allocates using malloc
    const result = c.NFD_SaveDialog(if (filter != null) filter.?.ptr else null, if (default_path != null) default_path.?.ptr else null, &out_path);

    return switch (result) {
        c.NFD_OKAY => if (out_path == null) null else std.mem.sliceTo(out_path, 0),
        c.NFD_ERROR => makeError(),
        else => null,
    };
}

/// Open folder dialog
pub fn openFolderDialog(default_path: ?[:0]const u8) Error!?[:0]const u8 {
    var out_path: [*c]u8 = null;

    // allocates using malloc
    const result = c.NFD_PickFolder(if (default_path != null) default_path.?.ptr else null, &out_path);

    return switch (result) {
        c.NFD_OKAY => if (out_path == null) null else std.mem.sliceTo(out_path, 0),
        c.NFD_ERROR => makeError(),
        else => null,
    };
}

pub fn freePath(path: []const u8) void {
    std.c.free(@constCast(path.ptr));
}

pub fn freePaths(paths: std.ArrayList([]const u8)) void {
    paths.deinit();
}
