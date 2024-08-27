const rl = @import("raylib");
const std = @import("std");
const World = @import("World.zig");
const component = @import("component.zig");
const entity = @import("entity.zig");
const system = @import("system.zig");
const tiled = @import("tiled.zig");
const Scene = @import("Scene.zig");

pub fn main() anyerror!void {
    var worldAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var world = try World.init(worldAllocator.allocator());

    var screenWidth: f32 = 1000;
    var screenHeight: f32 = 600;

    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
    });

    rl.initWindow(
        @intFromFloat(@round(screenWidth)),
        @intFromFloat(@round(screenHeight)),
        "raylib-zig [core] example - basic window",
    );

    var texture_map: tiled.TextureMap = tiled.TextureMap.init(worldAllocator.allocator());

    var level_one_path = [2][]const u8{
        "levels",
        "level_01.json",
    };
    const tile_map = try tiled.loadTileMap(
        worldAllocator.allocator(),
        &texture_map,
        &level_one_path,
    );

    _ = try Scene.init(worldAllocator.allocator(), tile_map, &world);

    // const map_texture = rl.loadTexture("assets/image/tile_map.png");

    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var camera = rl.Camera2D{
        .offset = rl.Vector2{ .x = 0, .y = 0 },
        .target = rl.Vector2{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    const base_game_width: f32 = 800;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        if (rl.isWindowResized()) {
            screenWidth = @floatFromInt(rl.getScreenWidth());
            screenHeight = @floatFromInt(rl.getScreenHeight());
        }

        const delta = rl.getFrameTime() / 0.01667;
        const zoom: f32 = screenWidth / base_game_width;

        camera.zoom = zoom;

        system.runMovementSystem(delta, world);

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

        for (
            world.debug_render_components,
            world.position_components,
        ) |
            has_debug_render,
            has_position,
        | {
            const debug_render = has_debug_render orelse continue;
            const position = has_position orelse continue;

            const rect = rl.Rectangle{
                .x = position.x,
                .y = position.y,
                .width = debug_render.width,
                .height = debug_render.height,
            };

            rl.drawRectanglePro(
                rect,
                rl.Vector2{ .x = 0, .y = 0 },
                0,
                debug_render.color,
            );
        }

        rl.drawFPS(10, 10);
    }
}
