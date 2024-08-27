const std = @import("std");
const World = @import("World.zig");
const tiled = @import("tiled.zig");
const entity = @import("entity.zig");
const rl = @import("raylib");

pub const Scene = @This();

allocator: std.mem.Allocator,
player_entity_id: ?usize,
collision_boxes: std.ArrayList(rl.Rectangle),

pub fn init(allocator: std.mem.Allocator, tile_map: tiled.TileMap, world: *World) !Scene {
    var player_entity_id: ?usize = null;
    var collision_box_list = std.ArrayList(rl.Rectangle).init(allocator);
    for (tile_map.layers) |layer| {
        for (layer.tiles) |tile_slot| {
            const tile = tile_slot orelse continue;
            const custom_properties = tile.custom_properties orelse continue;

            if (layer.layer_type == tiled.LayerType.Display) {
                const is_collision_box = try tiled.CustomProperty.getIsCollisionBox(custom_properties);
                if (is_collision_box) {
                    const rec = rl.Rectangle{
                        .x = @as(f32, @floatFromInt(tile.tile_map_column * tile_map.tile_width)),
                        .y = @as(f32, @floatFromInt(tile.tile_map_row * tile_map.tile_height)),
                        .width = @as(f32, @floatFromInt(tile_map.tile_width)),
                        .height = @as(f32, @floatFromInt(tile_map.tile_height)),
                    };
                    try collision_box_list.append(rec);
                }
            }

            if (layer.layer_type == tiled.LayerType.Logic) {
                const is_player_spawn = try tiled.CustomProperty.getIsPlayerSpawn(custom_properties);
                if (is_player_spawn) {
                    const start_x = @as(f32, @floatFromInt(tile_map.tile_width)) * @as(f32, @floatFromInt(tile.tile_map_column));
                    const start_y = @as(f32, @floatFromInt(tile_map.tile_height)) * @as(f32, @floatFromInt(tile.tile_map_row));
                    player_entity_id = try entity.makePlayerEntity(start_x, start_y, world);
                }
            }
        }
    }

    return Scene{
        .allocator = allocator,
        .player_entity_id = player_entity_id,
        .collision_boxes = collision_box_list,
    };
}
