const std = @import("std");
const component = @import("./component.zig");

const max_entity_count: usize = 1000;

const World = @This();

active_ids: std.AutoHashMap(usize, bool),
inactive_ids: std.AutoHashMap(usize, bool),

is_toggle_for_components: []?component.IsToggleFor,
is_block_components: []?component.IsBlock,
pressable_components: []?component.Pressable,
entity_collision_components: []?component.EntityCollision,
direction_components: []?component.Direction,
grounded_wander_components: []?component.GroundedWander,
animated_sprite_components: []?component.AnimatedSprite,
texture_render_components: []?component.TextureRender,
debug_render_components: []?component.DebugRender,
position_components: []?component.Position,
velocity_components: []?component.Velocity,
collision_box_components: []?component.CollisionBox,

pub fn freeEntity(self: *World, entity_id: usize) void {
    self.is_block_components[entity_id] = null;
    self.is_toggle_for_components[entity_id] = null;
    self.pressable_components[entity_id] = null;
    self.entity_collision_components[entity_id] = null;
    self.grounded_wander_components[entity_id] = null;
    self.direction_components[entity_id] = null;
    self.animated_sprite_components[entity_id] = null;
    self.texture_components[entity_id] = null;
    self.debug_render_components[entity_id] = null;
    self.position_components[entity_id] = null;
    self.velocity_components[entity_id] = null;
    self.collision_box_components[entity_id] = null;

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
    const is_toggle_for_components = try allocator.alloc(?component.IsToggleFor, max_entity_count);
    const is_block_components = try allocator.alloc(?component.IsBlock, max_entity_count);
    const pressable_components = try allocator.alloc(?component.Pressable, max_entity_count);
    const entity_collision_components = try allocator.alloc(?component.EntityCollision, max_entity_count);
    const direction_components = try allocator.alloc(?component.Direction, max_entity_count);
    const grounded_wander_components = try allocator.alloc(?component.GroundedWander, max_entity_count);
    const animated_sprite_components = try allocator.alloc(?component.AnimatedSprite, max_entity_count);
    const texture_render_components = try allocator.alloc(?component.TextureRender, max_entity_count);
    const debug_render_components = try allocator.alloc(?component.DebugRender, max_entity_count);
    const position_components = try allocator.alloc(?component.Position, max_entity_count);
    const velocity_components = try allocator.alloc(?component.Velocity, max_entity_count);
    const collision_box_components = try allocator.alloc(?component.CollisionBox, max_entity_count);

    initToNull(component.IsToggleFor, is_toggle_for_components);
    initToNull(component.IsBlock, is_block_components);
    initToNull(component.Pressable, pressable_components);
    initToNull(component.EntityCollision, entity_collision_components);
    initToNull(component.Direction, direction_components);
    initToNull(component.GroundedWander, grounded_wander_components);
    initToNull(component.AnimatedSprite, animated_sprite_components);
    initToNull(component.TextureRender, texture_render_components);
    initToNull(component.DebugRender, debug_render_components);
    initToNull(component.Position, position_components);
    initToNull(component.Velocity, velocity_components);
    initToNull(component.CollisionBox, collision_box_components);

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
        .pressable_components = pressable_components,
        .entity_collision_components = entity_collision_components,
        .direction_components = direction_components,
        .grounded_wander_components = grounded_wander_components,
        .animated_sprite_components = animated_sprite_components,
        .texture_render_components = texture_render_components,
        .debug_render_components = debug_render_components,
        .position_components = position_components,
        .velocity_components = velocity_components,
        .collision_box_components = collision_box_components,
    };
}

fn initToNull(comptime T: anytype, slice: []?T) void {
    for (0..slice.len) |idx| {
        slice[idx] = null;
    }
}
