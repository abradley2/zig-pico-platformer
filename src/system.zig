const World = @import("World.zig");

pub fn runGravitySystem(delta: f32, w: World) void {
    for (
        0..,
        w.velocity_components,
    ) |entityId, has_velocity| {
        const velocity = has_velocity orelse continue;

        velocity.dy += 9.8 * delta;

        w.velocity_components[entityId] = velocity;
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
