const std = @import("std");
const component = @import("./component.zig");

const max_entity_count: usize = 1000;

const World = @This();

active_ids: std.AutoHashMap(usize, bool),
inactive_ids: std.AutoHashMap(usize, bool),

is_toggle_for_components: []?component.IsToggleFor,
is_block_components: []?component.IsBlock,
entity_collision_components: []?component.EntityCollision,
direction_components: []?component.Direction,
grounded_wander_components: []?component.GroundedWander,
animated_sprite_components: []?component.AnimatedSprite,
texture_render_components: []?component.TextureRender,
debug_render_components: []?component.DebugRender,
position_components: []?component.Position,
velocity_components: []?component.Velocity,
collision_box_components: []?component.CollisionBox,
respawn_point_components: []?component.RespawnPoint,
bouncy_components: []?component.Bouncy,

pub fn freeEntity(self: *World, entity_id: usize) void {
    self.is_block_components[entity_id] = null;
    self.is_toggle_for_components[entity_id] = null;
    self.entity_collision_components[entity_id] = null;
    self.grounded_wander_components[entity_id] = null;
    self.direction_components[entity_id] = null;
    self.animated_sprite_components[entity_id] = null;
    self.texture_components[entity_id] = null;
    self.debug_render_components[entity_id] = null;
    self.position_components[entity_id] = null;
    self.velocity_components[entity_id] = null;
    self.collision_box_components[entity_id] = null;
    self.respawn_point_components[entity_id] = null;
    self.bouncy_components[entity_id] = null;

    self.active_ids.remove(entity_id);
    self.inactive_ids.put(entity_id, true);
}

pub fn createEntity(self: *World) error{OutOfMemory}!usize {
    var inactive_id_iter = self.inactive_ids.iterator();
    if (inactive_id_iter.next()) |entity_id_entry| {
        const entity_id = entity_id_entry.key_ptr.*;
        _ = self.inactive_ids.remove(entity_id);
        try self.active_ids.put(entity_id, true);
        return entity_id;
    }
    return error.OutOfMemory;
}

pub fn init(allocator: std.mem.Allocator) error{OutOfMemory}!World {
    const is_toggle_for_components = try ComponentSet(component.IsToggleFor).init(allocator);
    const is_block_components = try ComponentSet(component.IsBlock).init(allocator);
    const entity_collision_components = try ComponentSet(component.EntityCollision).init(allocator);
    const direction_components = try ComponentSet(component.Direction).init(allocator);
    const grounded_wander_components = try ComponentSet(component.GroundedWander).init(allocator);
    const animated_sprite_components = try ComponentSet(component.AnimatedSprite).init(allocator);
    const texture_render_components = try ComponentSet(component.TextureRender).init(allocator);
    const debug_render_components = try ComponentSet(component.DebugRender).init(allocator);
    const position_components = try ComponentSet(component.Position).init(allocator);
    const velocity_components = try ComponentSet(component.Velocity).init(allocator);
    const collision_box_components = try ComponentSet(component.CollisionBox).init(allocator);
    const respawn_point_components = try ComponentSet(component.RespawnPoint).init(allocator);
    const bouncy_components = try ComponentSet(component.Bouncy).init(allocator);

    const active_ids = std.AutoHashMap(usize, bool).init(allocator);
    var inactive_ids = std.AutoHashMap(usize, bool).init(allocator);

    for (0..max_entity_count) |entity_id| {
        _ = try inactive_ids.put(entity_id, true);
    }

    return World{
        .active_ids = active_ids,
        .inactive_ids = inactive_ids,
        .is_block_components = is_block_components,
        .is_toggle_for_components = is_toggle_for_components,
        .entity_collision_components = entity_collision_components,
        .direction_components = direction_components,
        .grounded_wander_components = grounded_wander_components,
        .animated_sprite_components = animated_sprite_components,
        .texture_render_components = texture_render_components,
        .debug_render_components = debug_render_components,
        .position_components = position_components,
        .velocity_components = velocity_components,
        .collision_box_components = collision_box_components,
        .respawn_point_components = respawn_point_components,
        .bouncy_components = bouncy_components,
    };
}

pub fn ComponentSet(
    comptime T: anytype,
) type {
    return struct {
        const Self = @This();
        pub fn initToNull(slice: []?T) void {
            for (0..slice.len) |idx| {
                slice[idx] = null;
            }
        }
        pub fn init(alloc: std.mem.Allocator) ![]?T {
            const slice = try alloc.alloc(?T, max_entity_count);
            Self.initToNull(slice);
            return slice;
        }
    };
}
