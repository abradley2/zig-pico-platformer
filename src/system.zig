const std = @import("std");
const World = @import("World.zig");
const Scene = @import("Scene.zig");
const rl = @import("raylib");
const Keyboard = @import("Keyboard.zig");
const component = @import("component.zig");

fn doesCollide(
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
        w.direction_components,
    ) |
        entityId,
        has_position,
        has_collision_box,
        has_velocity,
        has_direction,
    | {
        var position = has_position orelse continue;
        var collision_box = has_collision_box orelse continue;
        var velocity = has_velocity orelse continue;

        const entity_x1 = position.x + collision_box.x_offset;
        const entity_y1 = position.y + collision_box.y_offset;
        const entity_x2 = entity_x1 + collision_box.width;
        const entity_y2 = entity_y1 + collision_box.height;

        var touched_ground = false;
        var touched_wall = false;
        var on_edge: ?bool = null;

        var has_edge_collision_box: ?rl.Rectangle = null;
        // in order to detect if something is on a ledge, we put a collision box slightly to
        // the left or right and slightly below of the entity. If it _doesn't_ collide with
        // anything, then we know it is on the ledge. Therefore we will set the on_edge flag
        // to true by default, and set it to false once we detect a collision.
        if (velocity.dy == 0) {
            on_edge = true;
            if (has_direction) |direction| {
                if (direction == component.Direction.Left) {
                    has_edge_collision_box = rl.Rectangle{
                        .x = entity_x1 - 3,
                        .y = entity_y2 + 3,
                        .width = 1,
                        .height = 2,
                    };
                }
                if (direction == component.Direction.Right) {
                    has_edge_collision_box = rl.Rectangle{
                        .x = entity_x2 + 3,
                        .y = entity_y2 + 3,
                        .width = 1,
                        .height = 2,
                    };
                }
            } else {
                on_edge = false;
            }
        }
        for (scene.collision_boxes.items) |scene_collision_box| {
            if (has_edge_collision_box) |edge_collision_box| {
                const did_collide = doesCollide(
                    edge_collision_box.x,
                    edge_collision_box.y,
                    edge_collision_box.x + edge_collision_box.width,
                    edge_collision_box.y + edge_collision_box.height,
                    scene_collision_box,
                );
                if (did_collide) {
                    on_edge = false;
                }
            }
            if (doesCollide(
                entity_x1,
                entity_y1,
                entity_x2,
                entity_y2,
                scene_collision_box,
            )) {
                const is_floor = scene_collision_box.y > entity_y1;
                const is_wall = is_floor == false;

                if (is_floor) {
                    position.y = scene_collision_box.y - scene_collision_box.height;
                    velocity.dy = 0;
                    touched_ground = true;
                }

                if (is_wall) {
                    // need to check if it is a wall to the left or right first
                    if (entity_x1 < scene_collision_box.x) {
                        position.x = scene_collision_box.x - collision_box.width;
                    } else {
                        position.x = scene_collision_box.x + scene_collision_box.width;
                    }
                    velocity.dx = 0;
                    touched_wall = true;
                }

                w.collision_box_components[entityId] = collision_box;
                w.velocity_components[entityId] = velocity;
                w.position_components[entityId] = position;
            }
        }
        collision_box.on_edge = on_edge;
        collision_box.did_touch_ground = touched_ground;
        collision_box.did_touch_wall = touched_wall;
        w.collision_box_components[entityId] = collision_box;
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
            velocity.dy += 0.15 * delta;

            w.velocity_components[entityId] = velocity;
        }
    }
}

pub fn runMovementSystem(delta: f32, w: World) void {
    for (0.., w.velocity_components, w.position_components, w.collision_box_components) |
        entityId,
        has_velocity,
        has_position,
        has_collision,
    | {
        const velocity = has_velocity orelse continue;
        var position = has_position orelse continue;

        _ = has_collision;
        // TODO: only allow movement if not colliding with anything that is contrary to movement
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
                velocity.dy = -4;
            }
        }

        if (keyboard.left_is_down) {
            velocity.dx = -1.25;
        } else if (keyboard.right_is_down) {
            velocity.dx = 1.25;
        } else {
            velocity.dx = 0;
        }

        world.velocity_components[player_entity_id] = velocity;
    }
}

pub fn runAnimationSystem(delta: f32, world: World) void {
    for (0.., world.animated_sprite_components) |
        entity_id,
        has_animated_sprite,
    | {
        var animated_sprite = has_animated_sprite orelse continue;

        animated_sprite.current_delta += delta;
        if (animated_sprite.current_delta >= animated_sprite.delta_per_frame) {
            var next_frame = animated_sprite.current_frame + 1;
            const frame_len = animated_sprite.animation_rects.@"1";
            if (next_frame >= frame_len) {
                next_frame = 0;
            }
            animated_sprite.current_frame = next_frame;
            animated_sprite.current_delta = 0;
        }

        world.animated_sprite_components[entity_id] = animated_sprite;
    }
}

pub fn runWanderSystem(delta: f32, scene: Scene, world: World) void {
    for (
        0..,
        world.grounded_wander_components,
        world.velocity_components,
        world.direction_components,
        world.collision_box_components,
    ) |
        entity_id,
        has_grounded_wander,
        has_velocity,
        has_direction,
        has_collision_box,
    | {
        const grounded_wander = has_grounded_wander orelse continue;
        var velocity = has_velocity orelse continue;
        var direction = has_direction orelse continue;
        const collision_box = has_collision_box orelse continue;

        if (collision_box.did_touch_wall or (collision_box.on_edge orelse false)) {
            if (direction == component.Direction.Left) {
                direction = component.Direction.Right;
            } else {
                direction = component.Direction.Left;
            }
        }

        if (direction == component.Direction.Left) {
            velocity.dx = grounded_wander.speed * -1 * delta;
        } else {
            velocity.dx = grounded_wander.speed * delta;
        }

        _ = scene;

        world.direction_components[entity_id] = direction;
        world.velocity_components[entity_id] = velocity;
    }
}
