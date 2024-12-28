const std = @import("std");

log_file: std.fs.File,

const Self = @This();

pub fn write(self: *const Self, comptime fmt: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const printed = std.fmt.bufPrintZ(&buf, fmt, args) catch "LogError";
    _ = self.log_file.write(printed) catch 0;
    _ = self.log_file.write("\n") catch 0;
}

pub fn initLogFile() !std.fs.File {
    var exe_path_buff: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&exe_path_buff);

    const exe_path = try std.fs.selfExeDirPathAlloc(fba.allocator());

    var log_path_segments = [_][]const u8{
        exe_path,
        "..",
        "Resources",
        "log.txt",
    };

    const log_path = try std.fs.path.join(fba.allocator(), &log_path_segments);

    _ = std.fs.cwd().createFile(log_path, .{}) catch {};
    return try std.fs.cwd().openFile(log_path, .{
        .mode = std.fs.File.OpenMode.write_only,
    });
}

pub fn create() !Self {
    return Self{
        .log_file = try initLogFile(),
    };
}

pub fn destroy(self: Self) void {
    self.log_file.close();
}
