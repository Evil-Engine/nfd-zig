const std = @import("std");
const nfd = @import("nfd");

pub fn main() !void {
    var paths = try nfd.openFilesDialog("txt", "/");
    defer nfd.freePaths(&paths);
}
