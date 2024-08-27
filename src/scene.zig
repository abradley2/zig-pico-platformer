const std = @import("std");
const World = @import("World.zig");
const tiled = @import("tiled.zig");
const entity = @import("entity.zig");

pub fn init(tile_map: tiled.TileMap, world: *World) !void {
    for (tile_map.layers) |layer| {
        for (layer.tiles) |tile_slot| {
            const tile = tile_slot orelse continue;
            const custom_properties = tile.custom_properties orelse continue;

            if (layer.layer_type == tiled.LayerType.Display) {}

            if (layer.layer_type == tiled.LayerType.Logic) {
                const is_player_spawn = try tiled.CustomProperty.getIsPlayerSpawn(custom_properties);
                if (is_player_spawn) {
                    std.debug.print("Found player spawn\n", .{});
                    _ = try entity.makePlayerEntity(world);
                }
            }
        }
    }
}
