const World = @import("World.zig");
const component = @import("component.zig");
const rl = @import("raylib");
const tiled = @import("tiled.zig");
const Slice = @import("Slice.zig");

const player_run_animation = Slice.Make(rl.Rectangle, 3, 10).init(.{
    rl.Rectangle{ .x = 16, .y = 192, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 32, .y = 192, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 48, .y = 192, .width = 16, .height = 16 },
});

const player_idle_animation = Slice.Make(rl.Rectangle, 1, 10).init(.{
    rl.Rectangle{ .x = 0, .y = 192, .width = 16, .height = 16 },
});

const player_jump_animation = Slice.Make(rl.Rectangle, 1, 10).init(.{
    rl.Rectangle{ .x = 64, .y = 192, .width = 16, .height = 16 },
});

pub fn makePlayerEntity(
    start_x: f32,
    start_y: f32,
    texture_map: tiled.TextureMap,
    world: *World,
) error{ OutOfMemory, TextureNotFound }!usize {
    const player = try world.createEntity();
    const texture = try (texture_map.get(tiled.TileSetID.TileMap) orelse error.TextureNotFound);

    world.animated_sprite_components[player] = component.AnimatedSprite{
        .texture = texture,
        .animation_rects = player_run_animation,
        .play_animation = null,
        .delta_per_frame = 10,
        .current_delta = 0,
        .current_frame = 0,
    };
    world.position_components[player] = component.Position{
        .x = start_x,
        .y = start_y,
    };
    world.velocity_components[player] = component.Velocity{
        .dx = 0,
        .dy = 0,
    };
    world.collision_box_components[player] = component.CollisionBox{
        .x_offset = 2,
        .y_offset = 4,
        .width = 12,
        .height = 12,
        .did_touch_ground = false,
    };

    return player;
}

const bouncer_default_animation = Slice.Make(rl.Rectangle, 3, 10).init(.{
    rl.Rectangle{ .x = 0, .y = 288, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 16, .y = 288, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 32, .y = 288, .width = 16, .height = 16 },
});

const bouncer_impact_animation = Slice.Make(rl.Rectangle, 6, 10).init(.{
    rl.Rectangle{ .x = 48, .y = 288, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 64, .y = 288, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 80, .y = 288, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 80, .y = 288, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 80, .y = 288, .width = 16, .height = 16 },
    rl.Rectangle{ .x = 80, .y = 288, .width = 16, .height = 16 },
});

pub fn makeBouncerEntity(
    start_x: f32,
    start_y: f32,
    texture_map: tiled.TextureMap,
    world: *World,
) !void {
    const bouncer = try world.createEntity();
    const texture = try (texture_map.get(tiled.TileSetID.TileMap) orelse error.TextureNotFound);

    world.animated_sprite_components[bouncer] = component.AnimatedSprite{
        .texture = texture,
        .animation_rects = bouncer_default_animation,
        .play_animation = null,
        .delta_per_frame = 10,
        .current_delta = 0,
        .current_frame = 0,
    };
    world.direction_components[bouncer] = component.Direction.Left;
    world.grounded_wander_components[bouncer] = component.GroundedWander{
        .speed = 0.333,
    };
    world.position_components[bouncer] = component.Position{
        .x = start_x,
        .y = start_y,
    };
    world.velocity_components[bouncer] = component.Velocity{
        .dx = 0,
        .dy = 0,
    };
    world.collision_box_components[bouncer] = component.CollisionBox{
        .x_offset = 2,
        .y_offset = 4,
        .width = 12,
        .height = 12,
        .did_touch_ground = false,
    };
}

const x_button_inactive_animation = Slice.Make(rl.Rectangle, 1, 10).init(.{
    rl.Rectangle{ .x = 160, .y = 0, .width = 16, .height = 16 },
});

const x_button_active_animation = Slice.Make(rl.Rectangle, 1, 10).init(.{
    rl.Rectangle{ .x = 160, .y = 16, .width = 16, .height = 16 },
});

pub fn makeXButtonEntity(start_x: f32, start_y: f32, texture_map: tiled.TextureMap, world: *World) !void {
    const x_button = try world.createEntity();
    const texture = try (texture_map.get(tiled.TileSetID.TileMap) orelse error.TextureNotFound);

    world.position_components[x_button] = component.Position{
        .x = start_x,
        .y = start_y,
    };

    world.animated_sprite_components[x_button] = component.AnimatedSprite{
        .texture = texture,
        .animation_rects = x_button_inactive_animation,
        .play_animation = null,
        .delta_per_frame = 60,
        .current_delta = 0,
        .current_frame = 0,
    };

    world.collision_box_components[x_button] = component.CollisionBox{
        .x_offset = 0,
        .y_offset = 0,
        .width = 16,
        .height = 16,
        .did_touch_ground = false,
    };
}

const x_block_active_animation = Slice.Make(rl.Rectangle, 1, 10).init(.{
    rl.Rectangle{ .x = 160, .y = 32, .width = 16, .height = 16 },
});

const x_block_inactive_animation = Slice.Make(rl.Rectangle, 1, 10).init(.{
    rl.Rectangle{ .x = 160, .y = 48, .width = 16, .height = 16 },
});

pub fn makeXBlockEntity(start_x: f32, start_y: f32, texture_map: tiled.TextureMap, world: *World) !void {
    const x_block = try world.createEntity();
    const texture = try (texture_map.get(tiled.TileSetID.TileMap) orelse error.TextureNotFound);

    world.position_components[x_block] = component.Position{
        .x = start_x,
        .y = start_y,
    };

    world.animated_sprite_components[x_block] = component.AnimatedSprite{
        .texture = texture,
        .animation_rects = x_block_inactive_animation,
        .play_animation = null,
        .delta_per_frame = 60,
        .current_delta = 0,
        .current_frame = 0,
    };

    world.collision_box_components[x_block] = component.CollisionBox{
        .x_offset = 0,
        .y_offset = 0,
        .width = 16,
        .height = 16,
        .did_touch_ground = false,
    };
}
