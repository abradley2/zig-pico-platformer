const World = @import("World.zig");
const component = @import("component.zig");
const rl = @import("raylib");

pub fn makePlayerEntity(world: *World) error{OutOfMemory}!usize {
    const player = try world.createEntity();
    world.position_components[player] = component.Position{
        .x = 128,
        .y = 128,
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
