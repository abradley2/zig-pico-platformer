const std = @import("std");
const rl = @import("raylib");
const Logger = @import("Logger.zig");

const TileCustomProperty: type = struct {
    id: u32,
    properties: []CustomProperty,
};

pub const CustomProperty = struct {
    name: []const u8,
    type: []const u8,
    value: std.json.Value,

    pub fn getLayerType(properties: []CustomProperty) !?LayerType {
        for (properties) |property| {
            if (std.mem.eql(u8, "layer_type", property.name)) {
                switch (property.value) {
                    std.json.Value.string => |v| return try LayerType.fromString(v),
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return null;
    }

    pub fn getIsXButtonSpawn(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_x_button", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }

    pub fn getIsXBlockSpawn(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_x_block", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }

    pub fn getIsOButtonSpawn(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_o_button", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }

    pub fn getIsOBlockSpawn(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_o_block", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }

    pub fn getIsToggled(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_toggled", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }

    pub fn getIsBouncerSpawn(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_bouncer_spawn", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }

    pub fn getIsPlayerSpawn(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_player_spawn", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }

    pub fn getIsGoalSpawn(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_goal_spawn", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }

    pub fn getIsCollisionBox(properties: []CustomProperty) !bool {
        for (properties) |property| {
            if (std.mem.eql(u8, "is_collision_box", property.name)) {
                switch (property.value) {
                    std.json.Value.bool => |v| return v,
                    else => return error.UnexpectedCustomPropertyType,
                }
            }
        }
        return false;
    }
};

pub const TileSetID = enum(u8) {
    TileMap,
    pub fn getPathComparator(
        comptime segment_len: usize,
        comptime segments: [segment_len][]const u8,
    ) type {
        return struct {
            pub fn compare(str: []const u8) bool {
                var buffer: [128]u8 = undefined;
                var fba = std.heap.FixedBufferAllocator.init(&buffer);
                const expected_path = std.fs.path.join(fba.allocator(), &segments) catch "";

                return std.mem.eql(u8, expected_path, str);
            }
        };
    }
    pub fn fromString(s: []const u8) !TileSetID {
        if (getPathComparator(
            4,
            [_][]const u8{ "../", "assets", "image", "tile_map.json" },
        ).compare(s)) {
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
        if (std.mem.eql(u8, "display", s)) {
            return LayerType.Display;
        }
        if (std.mem.eql(u8, "logic", s)) {
            return LayerType.Logic;
        }
        return error.UnknownLayerType;
    }
};

const TileSetData = struct {
    tilesetid: TileSetID = TileSetID.TileMap,
    firstgid: u32 = 123456789,
    image: []const u8,
    columns: u32,
    tilecount: u32,
    tiles: []TileCustomProperty,
    pub fn getCustomPropertiesFor(self: TileSetData, local_id: u32) ?[]CustomProperty {
        for (self.tiles) |tile| {
            if (tile.id == local_id) {
                return tile.properties;
            }
        }
        return null;
    }
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
    tile_map_row: u32,
    tile_map_column: u32,
    tile_set_row: u32,
    tile_set_column: u32,
    tile_set_id: TileSetID,
    custom_properties: ?[]CustomProperty,
};

pub const Layer = struct {
    allocator: std.mem.Allocator,
    layer_type: LayerType,
    tiles: []?LayerTile,

    pub fn deinit(self: Layer) void {
        for (self.tiles) |tile_slot| {
            const tile = tile_slot orelse continue;
            if (tile.custom_properties) |properties| {
                self.allocator.free(properties);
            }
        }
        self.allocator.free(self.tiles);
    }

    pub fn init(
        allocator: std.mem.Allocator,
        raw_layer: LayerData,
        tile_sets: []TileSetData,
    ) error{
        OutOfMemory,
        TileSetNotFound,
        UnexpectedCustomPropertyType,
        UnknownLayerType,
    }!Layer {
        var layer_tiles: []?LayerTile = try allocator.alloc(?LayerTile, raw_layer.data.len);
        var tile_map_row: u32 = 0;
        var tile_map_column: u32 = 0;
        for (0.., raw_layer.data) |tile_idx, global_id| {
            defer {
                tile_map_column += 1;
                if (tile_map_column == raw_layer.width) {
                    tile_map_column = 0;
                    tile_map_row += 1;
                }
            }
            if (global_id == 0) {
                layer_tiles[tile_idx] = null;
                continue;
            }
            const tile_set = try tileSetForGid(global_id, tile_sets);
            const local_id = global_id - tile_set.firstgid;

            var tile_custom_properties: ?[]CustomProperty = null;
            if (tile_set.getCustomPropertiesFor(local_id)) |custom_properties| {
                const properties_list = try allocator.alloc(CustomProperty, custom_properties.len);

                // this data is derived from a slice that is passed in, so we need to copy it
                // as we don't know when that slice will be deallocated from here
                @memcpy(properties_list, custom_properties);
                tile_custom_properties = properties_list;
            }

            layer_tiles[tile_idx] = LayerTile{
                .tile_set_id = tile_set.tilesetid,
                .global_id = global_id,
                .tile_map_column = tile_map_column,
                .tile_map_row = tile_map_row,
                .local_id = global_id - tile_set.firstgid,
                .tile_set_row = local_id / tile_set.columns,
                .tile_set_column = local_id % tile_set.columns,
                .custom_properties = tile_custom_properties,
            };
        }
        const layer_type = try CustomProperty.getLayerType(raw_layer.properties);
        return Layer{
            .allocator = allocator,
            .layer_type = layer_type orelse LayerType.Display,
            .tiles = layer_tiles,
        };
    }
};

pub const TileMap = struct {
    allocator: std.mem.Allocator,
    tile_width: u32,
    tile_height: u32,
    rows: u32,
    columns: u32,
    layers: []Layer,

    pub fn deinit(self: TileMap) void {
        for (self.layers) |layer| {
            layer.deinit();
        }
        self.allocator.free(self.layers);
    }

    pub fn init(
        l: *const Logger,
        allocator: std.mem.Allocator,
        texture_map: *TextureMap,
        file_path_segments: [][]const u8,
    ) !TileMap {
        var leaky_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer leaky_allocator.deinit();

        const file_directory_segments = file_path_segments[0 .. file_path_segments.len - 1];

        const file_path = try std.fs.path.join(allocator, file_path_segments);
        defer allocator.free(file_path);

        const file_directory_path = try std.fs.path.join(allocator, file_directory_segments);
        defer allocator.free(file_directory_path);

        l.write("Reading map file: {s}", .{file_path});
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
            const tile_set_id = try TileSetID.fromString(tile_set_ref.source);

            const tile_set_abs_path_segments = [_][]const u8{
                file_directory_path,
                tile_set_ref.source,
            };
            const tile_set_abs_path = try std.fs.path.join(
                allocator,
                &tile_set_abs_path_segments,
            );
            defer allocator.free(tile_set_abs_path);
            l.write("file directory path: {s}", .{file_directory_path});
            l.write("Reading tile set file: {s}", .{tile_set_abs_path});
            const tile_set_file = try readFile(allocator, tile_set_abs_path);

            var parsed_tile_set = try std.json.parseFromSliceLeaky(
                TileSetData,
                leaky_allocator.allocator(),
                tile_set_file,
                std.json.ParseOptions{
                    .ignore_unknown_fields = true,
                },
            );

            const tile_set_dir_path = std.fs.path.dirname(tile_set_ref.source) orelse "";

            var image_path_segments: [3][]const u8 = undefined;
            image_path_segments[0] = file_directory_path;
            image_path_segments[1] = tile_set_dir_path;
            image_path_segments[2] = parsed_tile_set.image;

            const image_path = try std.fs.path.joinZ(allocator, &image_path_segments);
            defer allocator.free(image_path);

            const existing_texture_ptr = texture_map.get(tile_set_id);

            if (existing_texture_ptr == null) {
                const texture_ptr = try allocator.create(rl.Texture2D);

                l.write("Loading texture: {s}", .{image_path});
                texture_ptr.* = rl.loadTexture(image_path);
                try texture_map.put(tile_set_id, texture_ptr);
            }

            parsed_tile_set.tilesetid = tile_set_id;
            parsed_tile_set.firstgid = tile_set_ref.firstgid;
            tile_sets[idx] = parsed_tile_set;
        }

        var layers: []Layer = try allocator.alloc(Layer, tile_map_json.layers.len);

        for (0.., tile_map_json.layers) |idx, raw_layer| {
            layers[idx] = try Layer.init(allocator, raw_layer, tile_sets);
        }

        const tile_map = TileMap{
            .allocator = allocator,
            .tile_width = tile_map_json.tilewidth,
            .tile_height = tile_map_json.tileheight,
            .rows = tile_map_json.layers[0].height,
            .columns = tile_map_json.layers[0].width,
            .layers = layers,
        };

        return tile_map;
    }
};

fn readFile(alloc: std.mem.Allocator, file_path: []const u8) ![]const u8 {
    const buf = try std.fs.cwd().readFileAlloc(
        alloc,
        file_path,
        1024 * 64,
    );
    return buf;
}

fn tileSetForGid(gid: u32, tile_sets: []TileSetData) !TileSetData {
    for (tile_sets) |tile_set| {
        if (gid >= tile_set.firstgid and gid < tile_set.firstgid + tile_set.tilecount) {
            return tile_set;
        }
    }
    return error.TileSetNotFound;
}
