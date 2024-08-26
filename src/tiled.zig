const std = @import("std");

const TileSetRef = struct {
    first_gid: u32,
    source: []const u8,
};

const TileMapJSON = struct {
    width: u32,
    height: u32,
    tile_width: u32,
    tile_height: u32,
    tile_sets: []TileSetRef,
    layers: [][]u32,
};

fn readFile(alloc: std.mem.Allocator, file_path: []const u8) ![]const u8 {
    const buf = try std.fs.cwd().readFileAlloc(
        alloc,
        file_path,
        1024 * 64,
    );
    return buf;
}

fn loadTileSetImage() void {}

fn loadTileSet() void {}

pub fn loadTileMap(
    allocator: std.mem.Allocator,
    file_path_segments: [][]const u8,
) !void {
    const file_directory_segments = file_path_segments[0 .. file_path_segments.len - 1];

    const file_path = try std.fs.path.join(allocator, file_path_segments);
    defer allocator.free(file_path);

    const file_directory_path = try std.fs.path.join(allocator, file_directory_segments);
    defer allocator.free(file_directory_path);

    const file_data = try readFile(allocator, file_path);

    std.debug.print("{s}", .{file_data});

    const tile_map_json = try std.json.parseFromSliceLeaky(TileMapJSON, allocator, file_data, std.json.ParseOptions{
        .ignore_unknown_fields = true,
    });

    std.debug.print("file_data: {?}\n", .{tile_map_json});
}
