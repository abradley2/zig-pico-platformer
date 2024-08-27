const World = @import("World.zig");
const component = @import("component.zig");
const rl = @import("raylib");

pub fn makePlayerEntity(start_x: f32, start_y: f32, world: *World) error{OutOfMemory}!usize {
    const player = try world.createEntity();
    world.position_components[player] = component.Position{
        .x = start_x,
        .y = start_y,
    };
    world.velocity_components[player] = component.Velocity{
        .dx = 0,
        .dy = 0,
    };
    world.debug_render_components[player] = component.DebugRender{
        .color = rl.Color.red,
        .width = 16,
        .height = 16,
    };
    return player;
}
