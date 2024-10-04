const rl = @import("raylib");
const std = @import("std");
const World = @import("World.zig");
const component = @import("component.zig");
const entity = @import("entity.zig");
const system = @import("system.zig");
const tiled = @import("tiled.zig");
const Scene = @import("Scene.zig");
const Keyboard = @import("Keyboard.zig");

pub fn main() anyerror!void {
    var game_allocator = std.heap.GeneralPurposeAllocator(.{}){};

    var world = try World.init(game_allocator.allocator());

    var screenWidth: f32 = 1800;
    var screenHeight: f32 = 900;

    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .fullscreen_mode = false,
    });

    rl.initWindow(
        @intFromFloat(@round(screenWidth)),
        @intFromFloat(@round(screenHeight)),
        "raylib-zig [core] example - basic window",
    );

    var texture_map: tiled.TextureMap = tiled.TextureMap.init(game_allocator.allocator());

    var level_one_path = [2][]const u8{
        "levels",
        "level_01.json",
    };
    const tile_map = try tiled.TileMap.init(
        game_allocator.allocator(),
        &texture_map,
        &level_one_path,
    );
    defer tile_map.deinit();

    var scene: Scene = try Scene.init(
        game_allocator.allocator(),
        texture_map,
        tile_map,
        &world,
    );

    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(61); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var camera = rl.Camera2D{
        .offset = rl.Vector2{ .x = 0, .y = 0 },
        .target = rl.Vector2{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    const base_game_width: f32 = 800;
    var keyboard = Keyboard{};

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        keyboard = keyboard.updateKeyboard();

        if (rl.isWindowResized()) {
            screenWidth = @floatFromInt(rl.getScreenWidth());
            screenHeight = @floatFromInt(rl.getScreenHeight());
        }

        const delta = @max(0.5, @min(rl.getFrameTime() / 0.01667, 2));
        const zoom: f32 = screenWidth / base_game_width;

        camera.zoom = zoom;

        system.playerControlsSystems(keyboard, scene, world);
        system.runGravitySystem(delta, world);

        try system.runCollisionSystem(delta, &scene, world);
        system.runEntityCollisionSystem(delta, scene, world);
        system.runMovementSystem(delta, world);
        system.runAnimationSystem(delta, world);
        system.runWanderSystem(delta, scene, world);
        system.runCheckRespawnSysten(world);
        try scene.advanceCollisions();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.beginMode2D(camera);
        defer rl.endMode2D();

        rl.clearBackground(rl.Color.black);

        const tile_height: f32 = @as(f32, @floatFromInt(tile_map.tile_height));
        const tile_width: f32 = @as(f32, @floatFromInt(tile_map.tile_width));

        for (tile_map.layers) |layer| {
            if (layer.layer_type != tiled.LayerType.Display) {
                continue;
            }
            var column: f32 = 0;
            var row: f32 = 0;
            for (layer.tiles) |tile_slot| {
                if (tile_slot) |tile| {
                    const src_x = tile.tile_set_column * tile_map.tile_width;
                    const src_y = tile.tile_set_row * tile_map.tile_height;

                    const src_rect = rl.Rectangle{
                        .x = @floatFromInt(src_x),
                        .y = @floatFromInt(src_y),
                        .width = 16,
                        .height = 16,
                    };

                    const dst_x = column * tile_width;
                    const dst_y = row * tile_height;

                    const dst_rect = rl.Rectangle{
                        .x = dst_x,
                        .y = dst_y,
                        .width = @floatFromInt(tile_map.tile_width),
                        .height = @floatFromInt(tile_map.tile_height),
                    };

                    const texture = texture_map.get(tile.tile_set_id) orelse continue;
                    rl.drawTextureRec(
                        texture.*,
                        src_rect,
                        rl.Vector2{ .x = dst_rect.x, .y = dst_rect.y },
                        rl.Color.white,
                    );
                }

                column = column + 1;
                if (@as(u32, @intFromFloat(@round(column))) >= tile_map.columns) {
                    column = 0;
                    row = row + 1;
                }
            }
        }

        for (0.., world.position_components, world.collision_box_components, world.animated_sprite_components) |
            entity_id,
            has_position,
            has_collision_box,
            has_animated_sprite,
        | {
            _ = entity_id;
            const position = has_position orelse continue;
            const collision_box = has_collision_box orelse continue;
            const animated_sprite = has_animated_sprite orelse continue;
            _ = collision_box;
            const animation_rects = animated_sprite.animation_rects.@"0";
            const animation_rect = animation_rects[animated_sprite.current_frame];

            rl.drawTextureRec(
                animated_sprite.texture.*,
                animation_rect,
                rl.Vector2{
                    .x = position.x,
                    .y = position.y,
                },
                rl.Color.blue,
            );
        }

        rl.drawFPS(10, 10);
    }
}
