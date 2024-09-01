const std = @import("std");
const World = @import("World.zig");
const Scene = @import("Scene.zig");
const rl = @import("raylib");
const Keyboard = @import("Keyboard.zig");
const component = @import("component.zig");
const entity = @import("entity.zig");

fn doesCollide(
    entity_top_left_x: f32,
    entity_top_left_y: f32,
    entity_bottom_right_x: f32,
    entity_bottom_right_y: f32,
    collision_box: rl.Rectangle,
) bool {
    const collision_top_left_x = collision_box.x;
    const collision_top_left_y = collision_box.y;
    const collision_bottom_right_x = collision_box.x + collision_box.width;
    const collision_bottom_right_y = collision_box.y + collision_box.height;

    return (entity_top_left_x < collision_bottom_right_x and entity_bottom_right_x > collision_top_left_x and entity_top_left_y < collision_bottom_right_y and entity_bottom_right_y > collision_top_left_y);
}

fn doesCollideRects(
    entity_rect: rl.Rectangle,
    collision_rect: rl.Rectangle,
) bool {
    return (entity_rect.x < collision_rect.x + collision_rect.width and entity_rect.x + entity_rect.width > collision_rect.x and entity_rect.y < collision_rect.y + collision_rect.height and entity_rect.y + entity_rect.height > collision_rect.y);
}

fn doesTouchRects(
    entity_rect: rl.Rectangle,
    collision_rect: rl.Rectangle,
) bool {
    return (entity_rect.x <= collision_rect.x + collision_rect.width and entity_rect.x + entity_rect.width >= collision_rect.x and entity_rect.y <= collision_rect.y + collision_rect.height and entity_rect.y + entity_rect.height >= collision_rect.y);
}

pub fn runEntityCollisionSystem(
    delta: f32,
    scene: Scene,
    world: World,
) void {
    const entity_collisions: std.SinglyLinkedList(component.EntityCollision) = scene.entity_collisions;
    _ = delta;
    var entity_collision_slot = entity_collisions.first;
    while (entity_collision_slot) |entity_collision_node| {
        defer entity_collision_slot = entity_collision_node.next;

        const entity_collision = entity_collision_node.data;

        if (scene.player_entity_id) |world_player_entity_id| {
            if (entity_collision.entity_a == world_player_entity_id and (entity_collision.atb_dir == component.Direction.Down or entity_collision.atb_dir == component.Direction.Up)) {
                if (world.pressable_components[entity_collision.entity_b]) |_pressable| {
                    var pressable = _pressable;
                    const is_just_pressed = pressable.is_pressed == false;
                    pressable.is_pressed = true;
                    pressable.did_just_press = is_just_pressed;
                    pressable.pressed_by = entity_collision.entity_a;
                    world.pressable_components[entity_collision.entity_b] = pressable;

                    if (world.is_toggle_for_components[entity_collision.entity_b]) |is_toggle_for| {
                        switch (is_toggle_for) {
                            component.BlockType.XBlock => {
                                for (
                                    0..,
                                    world.is_block_components,
                                    world.animated_sprite_components,
                                    world.collision_box_components,
                                ) |
                                    block_id,
                                    has_block_type,
                                    has_block_sprite,
                                    has_collision_box,
                                | {
                                    if (is_just_pressed == false) continue;
                                    const block_type = has_block_type orelse continue;
                                    const block_sprite = has_block_sprite orelse continue;
                                    var block_collision_box = has_collision_box orelse continue;

                                    if (block_type == component.BlockType.XBlock) {
                                        var sprite = block_sprite;
                                        if (entity.isSameAnimationRect(sprite.animation_rects.@"0"[0], entity.x_block_active_animation.@"0"[0])) {
                                            sprite.animation_rects = entity.x_block_inactive_animation;
                                            block_collision_box.disable_collisions = true;
                                            world.collision_box_components[block_id] = block_collision_box;
                                        } else {
                                            sprite.animation_rects = entity.x_block_active_animation;
                                            block_collision_box.disable_collisions = false;
                                            world.collision_box_components[block_id] = block_collision_box;
                                        }
                                        world.animated_sprite_components[block_id] = sprite;
                                    }
                                }
                            },
                            component.BlockType.OBlock => {
                                for (
                                    0..,
                                    world.is_block_components,
                                    world.animated_sprite_components,
                                    world.collision_box_components,
                                ) |
                                    block_id,
                                    has_block_type,
                                    has_block_sprite,
                                    has_collision_box,
                                | {
                                    if (is_just_pressed == false) continue;
                                    const block_type = has_block_type orelse continue;
                                    const block_sprite = has_block_sprite orelse continue;
                                    var block_collision_box = has_collision_box orelse continue;

                                    if (block_type == component.BlockType.XBlock) {
                                        var sprite = block_sprite;
                                        if (entity.isSameAnimationRect(sprite.animation_rects.@"0"[0], entity.x_block_active_animation.@"0"[0])) {
                                            sprite.animation_rects = entity.x_block_inactive_animation;
                                            block_collision_box.disable_collisions = true;
                                            world.collision_box_components[block_id] = block_collision_box;
                                        } else {
                                            sprite.animation_rects = entity.x_block_active_animation;
                                            block_collision_box.disable_collisions = false;
                                            world.collision_box_components[block_id] = block_collision_box;
                                        }
                                        world.animated_sprite_components[block_id] = sprite;
                                    }
                                }
                            },
                        }
                    }
                }
            }
        }
    }
}

pub fn runPressableReleaseCheck(
    delta: f32,
    world: World,
) void {
    for (
        0..,
        world.pressable_components,
        world.position_components,
        world.collision_box_components,
    ) |entity_id_b, has_pressable, has_position, has_collision_box| {
        var pressable = has_pressable orelse continue;
        const position = has_position orelse continue;
        const collision_box = has_collision_box orelse continue;
        const entity_id_a = pressable.pressed_by orelse continue;

        const entity_a_position = world.position_components[entity_id_a] orelse continue;
        const entity_a_collision_box = world.collision_box_components[entity_id_a] orelse continue;
        const entity_a_velocity = world.velocity_components[entity_id_a] orelse continue;

        const does_collide = doesTouchRects(
            rl.Rectangle{
                .x = entity_a_position.x + entity_a_collision_box.x_offset + (entity_a_velocity.dx * delta),
                .y = entity_a_position.y + entity_a_collision_box.y_offset + (entity_a_velocity.dy * delta),
                .width = entity_a_collision_box.width,
                .height = entity_a_collision_box.height,
            },
            rl.Rectangle{
                .x = position.x + collision_box.x_offset,
                .y = position.y + collision_box.y_offset,
                .width = collision_box.width,
                .height = collision_box.height,
            },
        );

        if (does_collide == false) {
            std.debug.print("Entity {} no longer touches entity {}\n", .{ entity_id_a, entity_id_b });
            pressable.is_pressed = false;
            pressable.did_just_press = false;
            pressable.pressed_by = null;
            world.pressable_components[entity_id_b] = pressable;
        }
    }
}

pub fn runCollisionSystem(
    delta: f32,
    scene: *Scene,
    w: World,
) !void {
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

        if (collision_box.disable_collisions) {
            continue;
        }

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
                        .x = entity_x1 - 1,
                        .y = entity_y2 + 3,
                        .width = 1,
                        .height = 100,
                    };
                }
                if (direction == component.Direction.Right) {
                    has_edge_collision_box = rl.Rectangle{
                        .x = entity_x2 + 1,
                        .y = entity_y2 + 3,
                        .width = 1,
                        .height = 100,
                    };
                }
            } else {
                on_edge = false;
            }
        }
        for (
            0..,
            w.position_components,
            w.collision_box_components,
        ) |
            other_entity_id,
            other_has_position,
            other_has_collision_box,
        | {
            if (entityId == other_entity_id) {
                continue;
            }

            const other_position = other_has_position orelse continue;
            const other_collision_box = other_has_collision_box orelse continue;
            const other_collision_rect = rl.Rectangle{
                .x = other_position.x + other_collision_box.x_offset,
                .y = other_position.y + other_collision_box.y_offset,
                .width = other_collision_box.width,
                .height = other_collision_box.height,
            };

            if (other_collision_box.disable_collisions) {
                continue;
            }

            const will_collide_with_floor = doesCollide(
                entity_x1,
                entity_y1 + (velocity.dy * delta),
                entity_x2,
                entity_y2 + (velocity.dy * delta),
                other_collision_rect,
            );

            const will_collide_with_wall = doesCollide(
                entity_x1 + (velocity.dx * delta),
                entity_y1,
                entity_x2 + (velocity.dx * delta),
                entity_y2,
                other_collision_rect,
            );

            if (will_collide_with_floor) {
                if (velocity.dy > 0) {
                    position.y = other_collision_rect.y - other_collision_rect.height - (other_collision_rect.y - other_position.y);
                    touched_ground = true;
                }
                velocity.dy = 0;
                try scene.addCollision(component.EntityCollision{
                    .entity_a = entityId,
                    .entity_b = other_entity_id,
                    .atb_dir = if (velocity.dy > 0)
                        component.Direction.Down
                    else
                        component.Direction.Up,
                });
            }

            if (will_collide_with_wall) {
                velocity.dx = 0;
                touched_wall = true;
                const atb_dir = if (velocity.dx > 0)
                    component.Direction.Right
                else
                    component.Direction.Left;
                try scene.addCollision(component.EntityCollision{
                    .entity_a = entityId,
                    .entity_b = other_entity_id,
                    .atb_dir = atb_dir,
                });
            }

            w.velocity_components[entityId] = velocity;
            w.position_components[entityId] = position;
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

            const will_collide_with_floor = doesCollide(
                entity_x1,
                entity_y1 + (velocity.dy * delta),
                entity_x2,
                entity_y2 + (velocity.dy * delta),
                scene_collision_box,
            );

            const will_collide_with_wall = doesCollide(
                entity_x1 + (velocity.dx * delta),
                entity_y1,
                entity_x2 + (velocity.dx * delta),
                entity_y2,
                scene_collision_box,
            );

            if (will_collide_with_floor) {
                if (velocity.dy > 0) {
                    position.y = scene_collision_box.y - scene_collision_box.height;
                    touched_ground = true;
                }
                velocity.dy = 0;
            }

            if (will_collide_with_wall) {
                velocity.dx = 0;
                touched_wall = true;
            }

            w.velocity_components[entityId] = velocity;
            w.position_components[entityId] = position;
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
    ) |
        entityId,
        has_velocity,
    | {
        var velocity = has_velocity orelse continue;

        velocity.dy += (0.15 * delta);

        w.velocity_components[entityId] = velocity;
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
        position.x += (velocity.dx * delta);
        position.y += (velocity.dy * delta);

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
                velocity.dy = -3.5;
            }
        }

        if (keyboard.left_is_down) {
            velocity.dx = -1;
        } else if (keyboard.right_is_down) {
            velocity.dx = 1;
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
        _ = delta;
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
            velocity.dx = grounded_wander.speed * -1;
        } else {
            velocity.dx = grounded_wander.speed;
        }

        if (collision_box.did_touch_ground == false) {
            velocity.dx = 0;
        }

        _ = scene;

        world.direction_components[entity_id] = direction;
        world.velocity_components[entity_id] = velocity;
    }
}
