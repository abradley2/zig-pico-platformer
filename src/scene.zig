const std = @import("std");
const World = @import("World.zig");
const tiled = @import("tiled.zig");
const entity = @import("entity.zig");
const rl = @import("raylib");
const component = @import("component.zig");

pub const Scene = @This();

allocator: std.mem.Allocator,
player_entity_id: ?usize,
collision_boxes: std.ArrayList(rl.Rectangle),
entity_collisions: std.SinglyLinkedList(component.EntityCollision),

pub fn addCollision(self: *Scene, entity_collision: component.EntityCollision) !void {
    const node = try self.allocator.create(
        std.SinglyLinkedList(component.EntityCollision).Node,
    );
    node.* = std.SinglyLinkedList(component.EntityCollision).Node{
        .data = entity_collision,
    };
    self.entity_collisions.append(node);
}

pub fn clearCollisions(self: *Scene) void {
    while (self.entity_collisions.popFirst()) |node| {
        self.allocator.free(node);
    }
}

pub fn init(
    allocator: std.mem.Allocator,
    texture_map: tiled.TextureMap,
    tile_map: tiled.TileMap,
    world: *World,
) !Scene {
    const entity_collisions = std.SinglyLinkedList(component.EntityCollision){};

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
                    player_entity_id = try entity.makePlayerEntity(start_x, start_y, texture_map, world);
                }

                const is_bouncer_spawn = try tiled.CustomProperty.getIsBouncerSpawn(custom_properties);
                if (is_bouncer_spawn) {
                    const start_x = @as(f32, @floatFromInt(tile_map.tile_width)) * @as(f32, @floatFromInt(tile.tile_map_column));
                    const start_y = @as(f32, @floatFromInt(tile_map.tile_height)) * @as(f32, @floatFromInt(tile.tile_map_row));
                    _ = try entity.makeBouncerEntity(start_x, start_y, texture_map, world);
                }

                const is_x_button_spawn = try tiled.CustomProperty.getIsXButtonSpawn(custom_properties);
                if (is_x_button_spawn) {
                    const start_x = @as(f32, @floatFromInt(tile_map.tile_width)) * @as(f32, @floatFromInt(tile.tile_map_column));
                    const start_y = @as(f32, @floatFromInt(tile_map.tile_height)) * @as(f32, @floatFromInt(tile.tile_map_row));
                    _ = try entity.makeXButtonEntity(start_x, start_y, texture_map, world);
                }

                const is_x_block_spawn = try tiled.CustomProperty.getIsXBlockSpawn(custom_properties);
                if (is_x_block_spawn) {
                    const start_x = @as(f32, @floatFromInt(tile_map.tile_width)) * @as(f32, @floatFromInt(tile.tile_map_column));
                    const start_y = @as(f32, @floatFromInt(tile_map.tile_height)) * @as(f32, @floatFromInt(tile.tile_map_row));
                    _ = try entity.makeXBlockEntity(start_x, start_y, texture_map, world);
                }
            }
        }
    }

    return Scene{
        .entity_collisions = entity_collisions,
        .allocator = allocator,
        .player_entity_id = player_entity_id,
        .collision_boxes = collision_box_list,
    };
}
