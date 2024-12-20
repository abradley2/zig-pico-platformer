const rl = @import("raylib");
const tiled = @import("tiled.zig");
const Slice = @import("Slice.zig");

pub const Tint = rl.Color;

pub const TextFollow: type = struct {
    text: []const u8,
    current_char: usize,
    delta_per_char: f32 = 16,
    offset_x: f32,
    offset_y: f32,
};

pub const Transform: type = struct {
    x: f32,
    y: f32,
    current_delta: f32,
    delta_per_unit: f32,
    unit: f32,

    pub fn make_bump_transform() Transform {
        return Transform{
            .x = 0,
            .y = -5,
            .current_delta = 0,
            .delta_per_unit = 1,
            .unit = 0.25,
        };
    }
};

pub const BlockType = enum(u4) {
    XBlock,
    OBlock,
};

pub const IsBlock: type = BlockType;
pub const IsToggleFor: type = BlockType;

pub const EntityCollision: type = struct {
    entity_a: usize,
    entity_b: usize,
    atb_dir: Direction,
};

pub const Direction = enum(u4) {
    Left,
    Right,
    Up,
    Down,
};

pub const GroundedWander: type = struct {
    speed: f32,
};

pub const AnimatedSprite: type = struct {
    texture: *const rl.Texture2D,
    animation_rects: Slice.Make(rl.Rectangle, 0, 10).T,
    play_animation: ?Slice.Make(rl.Rectangle, 0, 10).T,
    delta_per_frame: f32,
    current_delta: f32,
    current_frame: usize,
};

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
    did_touch_ground: bool = false,
    did_touch_wall: bool = false,
    on_edge: ?bool = null,
    disable_collisions: bool = false,
};

pub const RespawnPoint: type = struct {
    x: f32,
    y: f32,
};

pub const Bouncy: type = struct {
    speed: f32,
};
