const std = @import("std");
const component = @import("./component.zig");

const max_entity_count: usize = 1000;

const World = @This();

active_ids: std.AutoHashMap(usize, bool),
inactive_ids: std.AutoHashMap(usize, bool),

texture_render_components: []?component.TextureRender,
debug_render_components: []?component.DebugRender,
position_components: []?component.Position,
velocity_components: []?component.Velocity,
collision_box_components: []?component.CollisionBox,

pub fn freeEntity(self: *World, entity_id: usize) void {
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
    const texture_render_components = try allocator.alloc(?component.TextureRender, max_entity_count);
    const debug_render_components = try allocator.alloc(?component.DebugRender, max_entity_count);
    const position_components = try allocator.alloc(?component.Position, max_entity_count);
    const velocity_components = try allocator.alloc(?component.Velocity, max_entity_count);
    const collision_box_components = try allocator.alloc(?component.CollisionBox, max_entity_count);

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
