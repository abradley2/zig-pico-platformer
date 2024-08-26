const rl = @import("raylib");

pub const TextureRender: type = struct {
    texture: *rl.Texture2D,
    src_width: f32,
    src_height: f32,
};

pub const DebugRender: type = struct {
    color: rl.Color,
    width: f32,
    height: f32,
};

pub const Position: type = struct {
    x: f32,
    y: f32,
};

pub const Velocity: type = struct {
    dx: f32,
    dy: f32,
};

pub const CollisionBox: type = struct {
    x_offset: f32,
    y_offset: f32,
    width: f32,
    height: f32,
};
