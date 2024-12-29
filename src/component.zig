const std = @import("std");
const rl = @import("raylib");
const tiled = @import("tiled.zig");
const Slice = @import("Slice.zig");

pub const max_entity_count: usize = 512;

pub fn ComponentSet(
    comptime T: anytype,
) type {
    return struct {
        const Self = @This();
        pub fn initToNull(slice: []?T) void {
            for (0..slice.len) |idx| {
                slice[idx] = null;
            }
        }
        pub fn init(alloc: std.mem.Allocator) ![]?T {
            const slice = try alloc.alloc(?T, max_entity_count);
            Self.initToNull(slice);
            return slice;
        }
    };
}

pub fn MakeFreeComponentFunc(comptime World: type) type {
    switch (@typeInfo(World)) {
        .Struct => |s| {
            return struct {
                pub fn freeEntity(w: World, entity_id: usize) void {
                    inline for (s.fields) |field| {
                        const is_component = comptime std.mem.endsWith(u8, field.name, "_components");

                        if (is_component == false) {
                            // TODO: panic here on compile
                            continue;
                        }

                        const ptr_type = switch (@typeInfo(field.type)) {
                            .Pointer => |v| v.size,
                            else => @compileError("Expected that the component field would be a pointer"),
                        };

                        const slice_type = switch (ptr_type) {
                            .Slice => ptr_type.child,
                            else => @compileError("Expected that the component field pointer is a slice"),
                        };

                        _ = switch (@typeInfo(slice_type)) {
                            .Optional => slice_type.child,
                            else => @compileError("Expected that the child type of the slice is an optional"),
                        };

                        @field(w, field.name)[entity_id] = null;
                    }
                }
            };
        },
        else => @compileError("Expected a struct"),
    }
}

pub fn HasComponent(comptime T: type, comptime C: type) type {
    return fn (t: *T) []?C;
}

pub const Tint = rl.Color;

pub const DisplayText: type = struct {
    text: []const u8,
    font_size: f32,
    color: rl.Color,
};

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

pub const MenuCoords: type = struct {
    x: f32,
    y: f32,
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
