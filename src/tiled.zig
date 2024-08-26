const std = @import("std");
const rl = @import("raylib");

const CustomProperty = struct {
    name: []const u8,
    type: []const u8,
    value: std.json.Value,

    pub fn getLayerType(properties: []CustomProperty) !?LayerType {
        for (properties) |property| {
            if (std.mem.eql(u8, "layer_type", property.name)) {
                switch (property.value) {
                    std.json.Value.String => |v| return LayerType.fromString(v),
                    _ => return error.UnexpectedCustomPropertyType,
                }
            }
        }
    }

    pub fn getIsCollidable(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_collidable", property.name)) {
                switch (property.value) {
                    std.json.Value.Bool => |v| return v,
                    _ => return error.UnexpectedCustomPropertyType,
                }
            }
        }
    }
};

pub const TileSetID = enum(u8) {
    TileMap,
    pub fn fromString(s: []const u8) !TileSetID {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var tile_map_segments = [3][]const u8{ "assets", "image", "tile_map.json" };
        const tile_map_path = try std.fs.path.join(gpa.allocator(), &tile_map_segments);
        defer gpa.allocator().free(tile_map_path);

        if (std.mem.eql(u8, tile_map_path, s)) {
            return TileSetID.TileMap;
        }

        return error.UnknownTileMap;
    }
};

pub const TextureMap = std.AutoHashMap(TileSetID, *const rl.Texture2D);

pub const LayerType = enum {
    Display,
    Logic,
    pub fn fromString(s: []const u8) !LayerType {
        if (std.mem.eql("display", s)) {
            return LayerType.Display;
        }
        if (std.mem.eql("logic", s)) {
            return LayerType.Logic;
        }
        return error.UnknownLayerType;
    }
};

const TileSetData = struct {
    firstgid: u32 = 123456789,
    image: []const u8,
    columns: u32,
    tilecount: u32,
};

const TileSetRefData = struct {
    firstgid: u32,
    source: []const u8,
};

const LayerData = struct {
    data: []u32,
    properties: []CustomProperty,
    height: u32,
    width: u32,
};

const TileMapData = struct {
    tilewidth: u32,
    tileheight: u32,
    tilesets: []TileSetRefData,
    layers: []LayerData,
};

pub const LayerTile = struct {
    global_id: u32,
    local_id: u32,
    tile_set_row: u32,
    tile_set_column: u32,
    tile_set_id: TileSetID,
};

pub const Layer = struct {
    layer_type: LayerType,
    tiles: []LayerTile,
};

pub const TileMap = struct {
    tile_width: u32,
    tile_height: u32,
    rows: u32,
    columns: u32,
    layers: []Layer,
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
    var texture_map = TextureMap.init(allocator);

    var leaky_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer leaky_allocator.deinit();

    const file_directory_segments = file_path_segments[0 .. file_path_segments.len - 1];

    const file_path = try std.fs.path.join(allocator, file_path_segments);
    defer allocator.free(file_path);

    const file_directory_path = try std.fs.path.join(allocator, file_directory_segments);
    defer allocator.free(file_directory_path);

    const file_data = try readFile(allocator, file_path);

    const tile_map_json = try std.json.parseFromSliceLeaky(
        TileMapData,
        leaky_allocator.allocator(),
        file_data,
        std.json.ParseOptions{
            .ignore_unknown_fields = true,
        },
    );

    var tile_sets = try allocator.alloc(TileSetData, tile_map_json.tilesets.len);
    defer allocator.free(tile_sets);

    for (0.., tile_map_json.tilesets) |idx, tile_set_ref| {
        var path_segments = std.ArrayList([]const u8).init(allocator);
        defer path_segments.deinit();

        var path_segments_iterator = std.mem.splitAny(u8, tile_set_ref.source, "/\\");
        while (path_segments_iterator.next()) |path_segment| {
            if (std.mem.eql(u8, path_segment, "..")) continue;
            try path_segments.append(path_segment);
        }

        const tile_set_path = try std.fs.path.join(allocator, path_segments.items);
        defer allocator.free(tile_set_path);

        const tile_set_id = try TileSetID.fromString(tile_set_path);

        const tile_set_file = try readFile(allocator, tile_set_path);

        var parsed_tile_set = try std.json.parseFromSliceLeaky(
            TileSetData,
            leaky_allocator.allocator(),
            tile_set_file,
            std.json.ParseOptions{
                .ignore_unknown_fields = true,
            },
        );

        const tile_set_dir_path = std.fs.path.dirname(tile_set_path) orelse "";
        var image_path_segments: [2][]const u8 = undefined;
        image_path_segments[0] = tile_set_dir_path;
        image_path_segments[1] = parsed_tile_set.image;
        const image_path = try std.fs.path.joinZ(allocator, &image_path_segments);
        defer allocator.free(image_path);

        const texture = rl.loadTexture(image_path);
        try texture_map.put(tile_set_id, &texture);

        parsed_tile_set.firstgid = tile_set_ref.firstgid;
        tile_sets[idx] = parsed_tile_set;
    }

    for (tile_sets) |tile_set| {
        std.debug.print("{?}\n", .{tile_set});
    }

    std.debug.print("file_data: {?}\n", .{tile_map_json});

    var layers = try allocator.alloc(Layer, tile_map_json.layers.len);

    for (0.., tile_map_json.layers) |idx, raw_layer| {
        var layer_tiles = try allocator.alloc(LayerTile, raw_layer.data.len);
        for (0.., raw_layer.data) |tile_idx, global_id| {
            if (global_id == 0) continue;
            const tile_set = try tileSetForGid(global_id, tile_sets);
            const layer_tile = LayerTile{
                .tile_set_id = TileSetID.TileMap,
                .global_id = global_id,
                .local_id = global_id - tile_set.firstgid,
                .tile_set_row = @as(u32, @intCast(tile_idx)) / raw_layer.width,
                .tile_set_column = @as(u32, @intCast(tile_idx)) % raw_layer.width,
            };
            layer_tiles[tile_idx] = layer_tile;
        }
        layers[idx] = Layer{
            .layer_type = LayerType.Display,
            .tiles = layer_tiles,
        };
    }
}

fn tileSetForGid(gid: u32, tile_sets: []TileSetData) !TileSetData {
    for (tile_sets) |tile_set| {
        if (gid >= tile_set.firstgid and gid < tile_set.firstgid + tile_set.tilecount) {
            return tile_set;
        }
    }
    return error.TileSetNotFound;
}
