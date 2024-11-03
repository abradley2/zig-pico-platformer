const std = @import("std");
const World = @import("World.zig");
const tiled = @import("tiled.zig");
const entity = @import("entity.zig");
const rl = @import("raylib");
const component = @import("component.zig");

pub const Scene = @This();

dialogue_text: ?usize = null,

allocator: std.mem.Allocator,
player_entity_id: ?usize,
collision_boxes: std.ArrayList(rl.Rectangle),

entity_collisions_hash: std.AutoHashMap(component.EntityCollision, bool),
prev_entity_collisions_hash: std.AutoHashMap(component.EntityCollision, bool),

pub fn addCollision(self: *Scene, entity_collision: component.EntityCollision) !void {
    try self.entity_collisions_hash.put(entity_collision, true);
}

pub fn init(
    allocator: std.mem.Allocator,
    texture_map: tiled.TextureMap,
    tile_map: tiled.TileMap,
    world: *World,
) !Scene {
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
                    const start_x = @as(f32, @floatFromInt(tile_map.tile_width * tile.tile_map_column));
                    const start_y = @as(f32, @floatFromInt(tile_map.tile_height * tile.tile_map_row));
                    _ = try entity.makeXButtonEntity(start_x, start_y, texture_map, world);
                }

                const is_x_block_spawn = try tiled.CustomProperty.getIsXBlockSpawn(custom_properties);
                if (is_x_block_spawn) {
                    const start_x = @as(f32, @floatFromInt(tile_map.tile_width)) * @as(f32, @floatFromInt(tile.tile_map_column));
                    const start_y = @as(f32, @floatFromInt(tile_map.tile_height)) * @as(f32, @floatFromInt(tile.tile_map_row));
                    const toggled = try tiled.CustomProperty.getIsToggled(custom_properties);
                    _ = try entity.makeXBlockEntity(start_x, start_y, toggled, texture_map, world);
                }

                const is_o_block_spawn = try tiled.CustomProperty.getIsOBlockSpawn(custom_properties);
                if (is_o_block_spawn) {
                    const start_x = @as(f32, @floatFromInt(tile_map.tile_width)) * @as(f32, @floatFromInt(tile.tile_map_column));
                    const start_y = @as(f32, @floatFromInt(tile_map.tile_height)) * @as(f32, @floatFromInt(tile.tile_map_row));
                    const toggled = try tiled.CustomProperty.getIsToggled(custom_properties);
                    _ = try entity.makeOBlockEntity(start_x, start_y, toggled, texture_map, world);
                }

                const is_o_button_spawn = try tiled.CustomProperty.getIsOButtonSpawn(custom_properties);
                if (is_o_button_spawn) {
                    const start_x = @as(f32, @floatFromInt(tile_map.tile_width)) * @as(f32, @floatFromInt(tile.tile_map_column));
                    const start_y = @as(f32, @floatFromInt(tile_map.tile_height)) * @as(f32, @floatFromInt(tile.tile_map_row));
                    _ = try entity.makeOButtonEntity(start_x, start_y, texture_map, world);
                }
            }
        }
    }

    const entity_collisions_hash = std.AutoHashMap(component.EntityCollision, bool).init(allocator);
    const prev_entity_collisions_hash = std.AutoHashMap(component.EntityCollision, bool).init(allocator);

    return Scene{
        .prev_entity_collisions_hash = prev_entity_collisions_hash,
        .entity_collisions_hash = entity_collisions_hash,
        .allocator = allocator,
        .player_entity_id = player_entity_id,
        .collision_boxes = collision_box_list,
    };
}

test "newCollision memory" {
    const test_allocator = std.testing.allocator;

    var prev_collisions = std.AutoHashMap(component.EntityCollision, bool)
        .init(test_allocator);

    var current_collisions = std.AutoHashMap(component.EntityCollision, bool)
        .init(test_allocator);

    const entity_collision = component.EntityCollision{
        .entity_a = 0,
        .entity_b = 1,
        .atb_dir = component.Direction.Left,
    };

    try current_collisions.put(
        entity_collision,
        true,
    );

    try advanceCollisions(
        test_allocator,
        &prev_collisions,
        &current_collisions,
    );

    var prev_iter = prev_collisions.iterator();
    const moved_collision = prev_iter.next().?;

    try std.testing.expect(
        moved_collision.key_ptr.entity_b == entity_collision.entity_b,
    );

    try advanceCollisions(
        test_allocator,
        &prev_collisions,
        &current_collisions,
    );

    try std.testing.expectEqual(
        0,
        prev_collisions.count(),
    );

    try std.testing.expectEqual(
        0,
        current_collisions.count(),
    );

    current_collisions.deinit();
    prev_collisions.deinit();
}

pub fn advanceCollisions(
    self: *Scene,
) error{OutOfMemory}!void {
    const allocator = self.allocator;
    const prev_collisions = &self.prev_entity_collisions_hash;
    const current_collisions = &self.entity_collisions_hash;

    var prev_iter = prev_collisions.iterator();
    while (prev_iter.next()) |entry| {
        prev_collisions.removeByPtr(entry.key_ptr);
    }

    var current_iter = current_collisions.iterator();
    while (current_iter.next()) |entry| {
        try prev_collisions.unmanaged.put(allocator, entry.key_ptr.*, true);
        _ = current_collisions.remove(entry.key_ptr.*);
    }
}
