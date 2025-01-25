const std = @import("std");
const component = @import("./component.zig");

const World = @This();

// TODO: lets make it so world has no non-component fields, let it all be in Scene
// this will make our macro guarantees stronger
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
transform_components: []?component.Transform,
tint_components: []?component.Tint,
text_follow_components: []?component.TextFollow,
trigger_volume_components: []?component.TriggerVolume,

pub fn hasTriggerVolume(self: *World) []?component.TriggerVolume {
    return self.trigger_volume_components;
}

pub fn hasActiveIds(self: *World) std.AutoHashMap(usize, bool) {
    return self.active_ids;
}

pub fn hasInactiveIds(self: *World) std.AutoHashMap(usize, bool) {
    return self.inactive_ids;
}

pub fn hasIsToggleFor(self: *World) []?component.IsToggleFor {
    return self.is_toggle_for_components;
}

pub fn hasIsBlock(self: *World) []?component.IsBlock {
    return self.is_block_components;
}

pub fn hasEntityCollision(self: *World) []?component.EntityCollision {
    return self.entity_collision_components;
}

pub fn hasDirection(self: *World) []?component.Direction {
    return self.direction_components;
}

pub fn hasGroundedWander(self: *World) []?component.GroundedWander {
    return self.grounded_wander_components;
}

pub fn hasAnimatedSprite(self: *World) []?component.AnimatedSprite {
    return self.animated_sprite_components;
}

pub fn hasTextureRender(self: *World) []?component.TextureRender {
    return self.texture_render_components;
}

pub fn hasDebugRender(self: *World) []?component.DebugRender {
    return self.debug_render_components;
}

pub fn hasPosition(self: *World) []?component.Position {
    return self.position_components;
}

pub fn hasVelocity(self: *World) []?component.Velocity {
    return self.velocity_components;
}

pub fn hasCollisionBox(self: *World) []?component.CollisionBox {
    return self.collision_box_components;
}

pub fn hasRespawnPoint(self: *World) []?component.RespawnPoint {
    return self.respawn_point_components;
}

pub fn hasBouncy(self: *World) []?component.Bouncy {
    return self.bouncy_components;
}

pub fn hasTransform(self: *World) []?component.Transform {
    return self.transform_components;
}

pub fn hasTint(self: *World) []?component.Tint {
    return self.tint_components;
}

pub fn hasTextFollow(self: *World) []?component.TextFollow {
    return self.text_follow_components;
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
    const transform_components = try ComponentSet(component.Transform).init(allocator);
    const tint_components = try ComponentSet(component.Tint).init(allocator);
    const text_follow_components = try ComponentSet(component.TextFollow).init(allocator);
    const trigger_volume_components = try ComponentSet(component.TriggerVolume).init(allocator);

    const active_ids = std.AutoHashMap(usize, bool).init(allocator);
    var inactive_ids = std.AutoHashMap(usize, bool).init(allocator);

    for (0..component.max_entity_count) |entity_id| {
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
        .transform_components = transform_components,
        .tint_components = tint_components,
        .text_follow_components = text_follow_components,
        .trigger_volume_components = trigger_volume_components,
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
            const slice = try alloc.alloc(?T, component.max_entity_count);
            Self.initToNull(slice);
            return slice;
        }
    };
}

pub fn makeFreeComponentFunc() type {
    switch (@typeInfo(World)) {
        .Struct => |s| {
            return struct {
                pub fn freeEntity(w: World, entity_id: usize) void {
                    inline for (s.fields) |field| {
                        const is_component = comptime std.mem.endsWith(u8, field.name, "_components");

                        if (is_component == false) {
                            // TODO: panic here on compile
                            continue;
                        }

                        switch (@typeInfo(field.type)) {
                            .Pointer => |ptr| {
                                switch (ptr.size) {
                                    .Slice => {
                                        switch (@typeInfo(ptr.child)) {
                                            .Optional => {
                                                @field(w, field.name)[entity_id] = null;
                                            },
                                            else => @compileError("Expected that the component field pointer is a slice of optional"),
                                        }
                                    },
                                    else => @compileError("Expected that the component field pointer is a slice"),
                                }
                            },
                            else => @compileError("Expected that the component field would be a pointer"),
                        }
                    }
                }
            };
        },
        else => @compileError("Expected a struct"),
    }
}

pub fn freeEntity(self: *World, entity_id: usize) void {
    component.MakeFreeComponentFunc(*World).freeEntity(self, entity_id);
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
