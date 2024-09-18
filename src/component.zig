const rl = @import("raylib");
const tiled = @import("tiled.zig");
const Slice = @import("Slice.zig");

pub const TextRender = struct {
    text: Slice.Make(u8, 0, 256).T,
    delta_per_letter: f32 = 2,
    current_delta: f32 = false,
    current_letter: usize,
    is_completed: bool = false,
};

pub const BlockType = enum(u4) {
    XBlock,
    OBlock,
};

pub const IsBlock: type = BlockType;
pub const IsToggleFor: type = BlockType;

pub const Pressable: type = struct {
    pressed_by: ?usize = null,
    is_pressed: bool,
    did_just_press: bool,
};

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
