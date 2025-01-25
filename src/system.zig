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

    return entity_top_left_x < collision_bottom_right_x and
        entity_bottom_right_x > collision_top_left_x and
        entity_top_left_y < collision_bottom_right_y and
        entity_bottom_right_y > collision_top_left_y;
}

fn doesCollideRects(
    entity_rect: rl.Rectangle,
    collision_rect: rl.Rectangle,
) bool {
    return entity_rect.x < collision_rect.x + collision_rect.width and
        entity_rect.x + entity_rect.width > collision_rect.x and
        entity_rect.y < collision_rect.y + collision_rect.height and
        entity_rect.y + entity_rect.height > collision_rect.y;
}

pub fn MakeGoalTriggerSystem(
    comptime T: type,
    comptime getIsGoalComponents: component.HasComponent(T, component.IsGoal),
    comptime getTriggerVolumeComponents: component.HasComponent(T, component.TriggerVolume),
) type {
    return struct {
        pub fn run(w: *T) void {
            const is_goal_components = getIsGoalComponents(w);
            const trigger_volume_components = getTriggerVolumeComponents(w);

            for (
                is_goal_components,
                trigger_volume_components,
            ) |has_goal, has_trigger_volume| {
                if (has_goal == null) continue;
                const trigger_volume = has_trigger_volume orelse continue;

                if (trigger_volume.just_triggered) {
                    std.debug.print("Goal Triggered\n", .{});
                }
            }
        }
    };
}

pub fn MakeCheckRespawnSystem(
    comptime T: type,
    comptime getPositionComponents: component.HasComponent(T, component.Position),
    comptime getRespawnPointComponents: component.HasComponent(T, component.RespawnPoint),
    comptime getVelocityComponents: component.HasComponent(T, component.Velocity),
) type {
    return struct {
        pub fn run(w: *T) void {
            const position_components = getPositionComponents(w);
            const respawn_point_components = getRespawnPointComponents(w);
            const velocity_components = getVelocityComponents(w);

            for (
                0..,
                position_components,
                respawn_point_components,
                velocity_components,
            ) |entity_id, has_position, has_respawn, has_velocity| {
                const position = has_position orelse continue;
                const respawn = has_respawn orelse continue;
                if (has_velocity == null) continue;

                if (position.y > respawn.y + 1000) {
                    position_components[entity_id] = component.Position{
                        .x = respawn.x,
                        .y = respawn.y,
                    };

                    velocity_components[entity_id] = component.Velocity{
                        .dx = 0,
                        .dy = 0,
                    };
                }
            }
        }
    };
}

fn toggleXBlocks(
    is_block_components: []?component.IsBlock,
    animated_sprite_components: []?component.AnimatedSprite,
    collision_box_components: []?component.CollisionBox,
) void {
    for (
        0..,
        is_block_components,
        animated_sprite_components,
        collision_box_components,
    ) |
        block_id,
        has_block_type,
        has_block_sprite,
        has_collision_box,
    | {
        const block_type = has_block_type orelse continue;
        const block_sprite = has_block_sprite orelse continue;
        var block_collision_box = has_collision_box orelse continue;

        if (block_type == component.BlockType.XBlock) {
            var sprite = block_sprite;
            if (entity.isSameAnimationRect(sprite.animation_rects.@"0"[0], entity.x_block_active_animation.@"0"[0])) {
                sprite.animation_rects = entity.x_block_inactive_animation;
                block_collision_box.disable_collisions = true;
                collision_box_components[block_id] = block_collision_box;
            } else {
                sprite.animation_rects = entity.x_block_active_animation;
                block_collision_box.disable_collisions = false;
                collision_box_components[block_id] = block_collision_box;
            }
            animated_sprite_components[block_id] = sprite;
        }
    }
}

pub fn toggleOBlocks(
    is_block_components: []?component.IsBlock,
    animated_sprite_components: []?component.AnimatedSprite,
    collision_box_components: []?component.CollisionBox,
) void {
    for (
        0..,
        is_block_components,
        animated_sprite_components,
        collision_box_components,
    ) |
        block_id,
        has_block_type,
        has_block_sprite,
        has_collision_box,
    | {
        const block_type = has_block_type orelse continue;
        const block_sprite = has_block_sprite orelse continue;
        var block_collision_box = has_collision_box orelse continue;

        if (block_type == component.BlockType.OBlock) {
            var sprite = block_sprite;
            if (entity.isSameAnimationRect(sprite.animation_rects.@"0"[0], entity.o_block_active_animation.@"0"[0])) {
                sprite.animation_rects = entity.o_block_inactive_animation;
                block_collision_box.disable_collisions = true;
                collision_box_components[block_id] = block_collision_box;
            } else {
                sprite.animation_rects = entity.o_block_active_animation;
                block_collision_box.disable_collisions = false;
                collision_box_components[block_id] = block_collision_box;
            }
            animated_sprite_components[block_id] = sprite;
        }
    }
}

pub fn MakeTransformSystem(
    comptime T: type,
    comptime getTransformComponents: component.HasComponent(T, component.Transform),
) type {
    return struct {
        pub fn run(delta: f32, w: *T) void {
            var transform_components = getTransformComponents(w);
            for (0.., transform_components) |entity_id, has_transform| {
                var transform = has_transform orelse continue;

                transform.current_delta = transform.current_delta + delta;

                if (transform.current_delta < transform.delta_per_unit) {
                    transform_components[entity_id] = transform;
                    continue;
                }

                transform.current_delta = 0;

                if (transform.x > 0) {
                    transform.x = @max(0, transform.x - transform.unit);
                } else if (transform.x < 0) {
                    transform.x = @min(0, transform.x + transform.unit);
                }

                if (transform.y > 0) {
                    transform.y = @max(0, transform.y - transform.unit);
                } else if (transform.y < 0) {
                    transform.y = @min(0, transform.y + transform.unit);
                }

                if (transform.x == 0 and transform.y == 0) {
                    transform_components[entity_id] = null;
                    continue;
                }

                transform_components[entity_id] = transform;
            }
        }
    };
}

pub fn MakeEntityCollisionSystem(
    comptime T: type,
    comptime getIsToggleForComponents: component.HasComponent(T, component.IsToggleFor),
    comptime getBouncyComponents: component.HasComponent(T, component.Bouncy),
    comptime getVelocityComponents: component.HasComponent(T, component.Velocity),
    comptime getIsBlockComponents: component.HasComponent(T, component.IsBlock),
    comptime getTransformComponents: component.HasComponent(T, component.Transform),
    comptime getAnimatedSpriteComponents: component.HasComponent(T, component.AnimatedSprite),
    comptime getCollisionBoxComponents: component.HasComponent(T, component.CollisionBox),
    comptime getTriggerVolumeComponents: component.HasComponent(T, component.TriggerVolume),
) type {
    return struct {
        pub fn run(delta: f32, scene: Scene, w: *T) void {
            _ = delta;

            const is_toggle_for_components = getIsToggleForComponents(w);
            const bouncy_components = getBouncyComponents(w);
            var velocity_components = getVelocityComponents(w);
            const is_block_components = getIsBlockComponents(w);
            var transform_components = getTransformComponents(w);
            const animated_sprite_components = getAnimatedSpriteComponents(w);
            const collision_box_components = getCollisionBoxComponents(w);
            var trigger_volume_components = getTriggerVolumeComponents(w);

            var new_collisions_iterator = scene.entity_collisions_hash.iterator();

            for (0.., trigger_volume_components) |entity_id, has_trigger_volume| {
                var trigger_volume = has_trigger_volume orelse continue;
                trigger_volume.just_triggered = false;
                trigger_volume_components[entity_id] = trigger_volume;
            }

            while (new_collisions_iterator.next()) |new_collisions_entry| {
                const entity_collision = new_collisions_entry.key_ptr.*;
                if (scene.prev_entity_collisions_hash.get(new_collisions_entry.key_ptr.*) != null) {
                    continue;
                }

                const entity_a_is_player = if (scene.player_entity_id) |player_entity_id|
                    entity_collision.entity_a == player_entity_id
                else
                    false;

                check_trigger_volume: {
                    if (entity_a_is_player == false) {
                        break :check_trigger_volume;
                    }

                    var trigger_volume = trigger_volume_components[entity_collision.entity_b] orelse break :check_trigger_volume;

                    if (trigger_volume.is_triggered) {
                        break :check_trigger_volume;
                    }

                    trigger_volume.is_triggered = true;
                    trigger_volume.just_triggered = true;
                    trigger_volume_components[entity_collision.entity_b] = trigger_volume;
                }

                check_o_blocks: {
                    const toggle_for = is_toggle_for_components[entity_collision.entity_b] orelse break :check_o_blocks;

                    if (entity_a_is_player and
                        toggle_for == component.BlockType.OBlock and
                        entity_collision.atb_dir == component.Direction.Up)
                    {
                        toggleOBlocks(
                            is_block_components,
                            animated_sprite_components,
                            collision_box_components,
                        );
                        transform_components[entity_collision.entity_b] = component.Transform.make_bump_transform();
                    }
                }

                check_x_blocks: {
                    const toggle_for = is_toggle_for_components[entity_collision.entity_b] orelse break :check_x_blocks;

                    if (entity_a_is_player and toggle_for == component.BlockType.XBlock and
                        entity_collision.atb_dir == component.Direction.Up)
                    {
                        toggleXBlocks(
                            is_block_components,
                            animated_sprite_components,
                            collision_box_components,
                        );
                        transform_components[entity_collision.entity_b] = component.Transform.make_bump_transform();
                    }
                }

                check_player_bounce: {
                    if (entity_a_is_player == false) {
                        break :check_player_bounce;
                    }
                    const player_id = entity_collision.entity_a;
                    const bouncy = bouncy_components[entity_collision.entity_b] orelse break :check_player_bounce;

                    var player_velocity = velocity_components[player_id] orelse break :check_player_bounce;

                    if (entity_collision.atb_dir == component.Direction.Down) {
                        player_velocity.dy = bouncy.speed * -1;
                        velocity_components[player_id] = player_velocity;

                        transform_components[entity_collision.entity_b] = component.Transform.make_bump_transform();
                    }
                }
            }
        }
    };
}

pub fn MakeCollisionSystem(
    comptime T: type,
    comptime getPositionComponents: component.HasComponent(T, component.Position),
    comptime getCollisionBoxComponents: component.HasComponent(T, component.CollisionBox),
    comptime getVelocityComponents: component.HasComponent(T, component.Velocity),
    comptime getDirectionComponents: component.HasComponent(T, component.Direction),
    comptime getTriggerVolumeComponents: component.HasComponent(T, component.TriggerVolume),
) type {
    return struct {
        pub fn run(delta: f32, scene: *Scene, w: *T) error{OutOfMemory}!void {
            const position_components = getPositionComponents(w);
            var collision_box_components = getCollisionBoxComponents(w);
            const velocity_components = getVelocityComponents(w);
            const direction_components = getDirectionComponents(w);
            const trigger_volume_components = getTriggerVolumeComponents(w);

            for (
                0..,
                position_components,
                collision_box_components,
                velocity_components,
                direction_components,
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

                if (collision_box.did_touch_ground) {
                    on_edge = true;
                    if (has_direction) |direction| {
                        if (direction == component.Direction.Left) {
                            has_edge_collision_box = rl.Rectangle{
                                .x = entity_x1 - 1,
                                .y = entity_y2 + 3,
                                .width = 1,
                                .height = 48,
                            };
                        }
                        if (direction == component.Direction.Right) {
                            has_edge_collision_box = rl.Rectangle{
                                .x = entity_x2 + 1,
                                .y = entity_y2 + 3,
                                .width = 1,
                                .height = 48,
                            };
                        }
                    } else {
                        on_edge = false;
                    }
                }
                for (
                    0..,
                    position_components,
                    collision_box_components,
                    velocity_components,
                    trigger_volume_components,
                ) |
                    other_entity_id,
                    other_has_position,
                    other_has_collision_box,
                    other_has_velocity,
                    other_has_trigger_volume,
                | {
                    if (entityId == other_entity_id) {
                        continue;
                    }

                    const is_trigger_volume = if (other_has_trigger_volume != null) true else false;

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

                    if (will_collide_with_floor and entity_y2 != other_collision_rect.y + other_collision_rect.height) {
                        if (velocity.dy > 0 and !is_trigger_volume) {
                            position.y = other_collision_rect.y - other_collision_rect.height - (other_collision_rect.y - other_position.y);
                            touched_ground = true;
                        }
                        if (velocity.dy < 0 and !is_trigger_volume) {
                            position.y = other_collision_rect.y + other_collision_rect.height - collision_box.y_offset;
                        }
                        try scene.addCollision(component.EntityCollision{
                            .entity_a = entityId,
                            .entity_b = other_entity_id,
                            .atb_dir = if (velocity.dy > 0)
                                component.Direction.Down
                            else
                                component.Direction.Up,
                        });
                        if (!is_trigger_volume) velocity.dy = 0;
                    }

                    if (will_collide_with_wall) {
                        if (!is_trigger_volume) {
                            velocity.dx = 0;
                            touched_wall = true;
                        }
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

                    if (has_edge_collision_box) |edge_collision_box| {
                        const did_collide = doesCollide(
                            edge_collision_box.x,
                            edge_collision_box.y,
                            edge_collision_box.x + edge_collision_box.width,
                            edge_collision_box.y + edge_collision_box.height,
                            other_collision_rect,
                        );
                        if (did_collide and other_has_velocity == null) {
                            on_edge = false;
                        }
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
                        if (velocity.dy < 0) {
                            position.y = scene_collision_box.y + scene_collision_box.height - collision_box.y_offset;
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
                collision_box_components[entityId] = collision_box;
            }
        }
    };
}

pub fn MakeGravitySystem(
    comptime T: anytype,
    comptime getVelocityComponents: component.HasComponent(T, component.Velocity),
) type {
    return struct {
        pub fn run(delta: f32, w: *T) void {
            const velocity_components = getVelocityComponents(w);

            for (0.., velocity_components) |entityId, has_velocity| {
                var velocity = has_velocity orelse continue;

                if (velocity.flies) {
                    continue;
                }

                velocity.dy += (0.15 * delta);

                velocity_components[entityId] = velocity;
            }
        }
    };
}

pub fn MakeMovementSystem(
    comptime T: anytype,
    comptime getVelocityComponents: component.HasComponent(T, component.Velocity),
    comptime getPositionComponents: component.HasComponent(T, component.Position),
) type {
    return struct {
        const Self = @This();
        pub fn run(delta: f32, w: *T) void {
            const velocity_components = getVelocityComponents(w);
            var position_components = getPositionComponents(w);

            for (0.., velocity_components, position_components) |
                entityId,
                has_velocity,
                has_position,
            | {
                const velocity = has_velocity orelse continue;
                var position = has_position orelse continue;

                position.x += (velocity.dx * delta);
                position.y += (velocity.dy * delta);

                position_components[entityId] = position;
            }
        }
    };
}

pub fn MakePlayerControlsSystem(
    comptime T: type,
    comptime getVelocityComponents: component.HasComponent(T, component.Velocity),
    comptime getCollisionBoxComponents: component.HasComponent(T, component.CollisionBox),
) type {
    return struct {
        pub fn run(
            w: *T,
            keyboard: Keyboard,
            scene: Scene,
        ) void {
            const collision_box_components = getCollisionBoxComponents(w);
            const velocity_components = getVelocityComponents(w);

            if (scene.player_entity_id) |player_entity_id| {
                const has_collision_box = collision_box_components[player_entity_id];
                const has_velocity = velocity_components[player_entity_id];

                const collision_box = has_collision_box orelse return;
                var velocity = has_velocity orelse return;

                if (collision_box.did_touch_ground) {
                    if (keyboard.spacebar_pressed) {
                        velocity.dy = -3.5;
                    }
                }

                if (keyboard.left_is_down) {
                    velocity.dx = -1.10;
                } else if (keyboard.right_is_down) {
                    velocity.dx = 1.10;
                } else {
                    velocity.dx = 0;
                }

                velocity_components[player_entity_id] = velocity;
            }
        }
    };
}

pub fn MakeAnimationSystem(
    comptime T: anytype,
    comptime getAnimatedSpriteComponents: component.HasComponent(T, component.AnimatedSprite),
) type {
    return struct {
        pub fn run(delta: f32, w: *T) void {
            var animated_sprite_components = getAnimatedSpriteComponents(w);
            for (0.., animated_sprite_components) |
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

                animated_sprite_components[entity_id] = animated_sprite;
            }
        }
    };
}

pub fn MakeWanderSystem(
    comptime T: type,
    comptime getGroundedWanderComponents: component.HasComponent(T, component.GroundedWander),
    comptime getVelocityComponents: component.HasComponent(T, component.Velocity),
    comptime getDirectionComponents: component.HasComponent(T, component.Direction),
    comptime getCollisionBoxComponents: component.HasComponent(T, component.CollisionBox),
) type {
    return struct {
        pub fn run(delta: f32, scene: Scene, w: *T) void {
            const grounded_wander_components = getGroundedWanderComponents(w);
            var velocity_components = getVelocityComponents(w);
            const direction_components = getDirectionComponents(w);
            const collision_box_components = getCollisionBoxComponents(w);

            for (
                0..,
                grounded_wander_components,
                velocity_components,
                direction_components,
                collision_box_components,
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

                direction_components[entity_id] = direction;
                velocity_components[entity_id] = velocity;
            }
        }
    };
}

pub fn MakeCameraFollowSystem(
    comptime T: type,
    comptime getPositionComponents: component.HasComponent(T, component.Position),
) type {
    return struct {
        pub fn run(
            camera: *rl.Camera2D,
            scene: Scene,
            w: *T,
        ) void {
            const position_components = getPositionComponents(w);
            if (scene.player_entity_id) |player_entity_id| {
                const has_position = position_components[player_entity_id];
                const position = has_position orelse return;

                const eventual_target = rl.Vector2{
                    .x = position.x - 200,
                    .y = position.y - 150,
                };

                // the camera should move to the eventual target
                // in a sort of easing in fashion based on the current distance

                const current_target = camera.target;
                const distance = rl.Vector2{
                    .x = current_target.x - eventual_target.x,
                    .y = current_target.y - eventual_target.y,
                };

                const distance_magnitude = rl.Vector2{
                    .x = distance.x * distance.x,
                    .y = distance.y * distance.y,
                };

                const distance_sum = distance_magnitude.x + distance_magnitude.y;

                if (distance_sum > 100) {
                    camera.target = rl.Vector2{
                        .x = current_target.x - (distance.x * 0.05),
                        .y = current_target.y - (distance.y * 0.05),
                    };
                }
            }
        }
    };
}
