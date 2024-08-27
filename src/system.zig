const std = @import("std");
const World = @import("World.zig");
const Scene = @import("Scene.zig");
const rl = @import("raylib");
const Keyboard = @import("Keyboard.zig");

fn does_collide(
    entity_x1: f32,
    entity_y1: f32,
    entity_x2: f32,
    entity_y2: f32,
    collision_box: rl.Rectangle,
) bool {
    const collision_x1 = collision_box.x;
    const collision_y1 = collision_box.y;
    const collision_x2 = collision_box.x + collision_box.width;
    const collision_y2 = collision_box.y + collision_box.height;

    return (entity_x1 < collision_x2 and
        entity_x2 > collision_x1 and
        entity_y1 < collision_y2 and
        entity_y2 > collision_y1);
}

pub fn runCollisionSystem(
    delta: f32,
    scene: Scene,
    w: World,
) void {
    _ = delta;
    for (
        0..,
        w.position_components,
        w.collision_box_components,
        w.velocity_components,
    ) |
        entityId,
        has_position,
        has_collision_box,
        has_velocity,
    | {
        var position = has_position orelse continue;
        var collision_box = has_collision_box orelse continue;
        var velocity = has_velocity orelse continue;

        const entity_x1 = position.x + collision_box.x_offset;
        const entity_y1 = position.y + collision_box.y_offset;
        const entity_x2 = entity_x1 + collision_box.width;
        const entity_y2 = entity_y1 + collision_box.height;

        var touched_ground = false;
        for (scene.collision_boxes.items) |scene_collision_box| {
            if (does_collide(entity_x1, entity_y1, entity_x2, entity_y2, scene_collision_box)) {
                velocity.dy = 0;
                position.y = scene_collision_box.y - scene_collision_box.height;
                collision_box.did_touch_ground = true;

                w.collision_box_components[entityId] = collision_box;
                w.velocity_components[entityId] = velocity;
                w.position_components[entityId] = position;
                touched_ground = true;
                break;
            }
        }
        if (touched_ground == false) {
            collision_box.did_touch_ground = false;
            w.collision_box_components[entityId] = collision_box;
        }
    }
}

pub fn runGravitySystem(delta: f32, w: World) void {
    for (
        0..,
        w.velocity_components,
        w.collision_box_components,
    ) |
        entityId,
        has_velocity,
        has_collision_box,
    | {
        var velocity = has_velocity orelse continue;
        const collision_box = has_collision_box orelse continue;

        if (collision_box.did_touch_ground == false) {
            velocity.dy += 0.25 * delta;

            w.velocity_components[entityId] = velocity;
        }
    }
}

pub fn runMovementSystem(delta: f32, w: World) void {
    for (
        0..,
        w.velocity_components,
        w.position_components,
    ) |
        entityId,
        has_velocity,
        has_position,
    | {
        const velocity = has_velocity orelse continue;
        var position = has_position orelse continue;

        position.x += velocity.dx * delta;
        position.y += velocity.dy * delta;

        w.position_components[entityId] = position;
    }
}

pub fn playerControlsSystems(
    keyboard: Keyboard,
    scene: Scene,
    world: World,
) void {
    if (scene.player_entity_id) |player_entity_id| {
        const has_collision_box = world.collision_box_components[player_entity_id];
        const has_velocity = world.velocity_components[player_entity_id];

        const collision_box = has_collision_box orelse return;
        var velocity = has_velocity orelse return;

        if (collision_box.did_touch_ground) {
            if (keyboard.spacebar_pressed) {
                velocity.dy = -6;
            }
        }

        if (keyboard.left_is_down) {
            velocity.dx = -2;
        } else if (keyboard.right_is_down) {
            velocity.dx = 2;
        } else {
            velocity.dx = 0;
        }

        world.velocity_components[player_entity_id] = velocity;
    }
}
