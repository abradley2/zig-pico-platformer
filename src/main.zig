const rl = @import("raylib");
const std = @import("std");

pub const HasTexture: type = struct {
    texture: *rl.Texture2D,
    src_width: f32,
    src_height: f32,
};

pub const HasPosition: type = struct {
    x: f32,
    y: f32,
};

pub const HasVelocity: type = struct {
    dx: f32,
    dy: f32,
};

pub const HasCollisionBox: type = struct {
    x_offset: f32,
    y_offset: f32,
    width: f32,
    height: f32,
};

pub const World: type = struct {
    has_texture_components: *[100]?HasTexture,
    has_position_components: *[100]?HasPosition,
    has_velocity_components: *[100]?HasVelocity,
    has_collision_box_components: *[100]?HasCollisionBox,
    pub fn init(allocator: std.mem.Allocator) error{OutOfMemory}!World {
        const texture_components = try allocator.alloc(?HasTexture, 100);
        const position_components = try allocator.alloc(?HasPosition, 100);
        const velocity_components = try allocator.alloc(?HasVelocity, 100);
        const collision_box_components = try allocator.alloc(?HasCollisionBox, 100);

        return World{
            .has_texture_components = texture_components,
            .has_position_components = position_components,
            .has_velocity_components = velocity_components,
            .has_collision_box_components = collision_box_components,
        };
    }
};

pub fn MakeSystem(
    comptime component_count: usize,
    comptime fields: [component_count][]const u8,
) type {
    // comptime var InputType: type = undefined;
    var input_type_fields: [fields.len]std.builtin.Type.StructField = undefined;

    const world_type_info = @typeInfo(World);

    inline for (0.., fields) |idx, field| {
        switch (world_type_info) {
            .Struct => |s| {
                var field_info: std.builtin.Type.StructField = undefined;

                for (s.fields) |struct_field| {
                    if (std.mem.eql(u8, field, struct_field.name)) {
                        field_info = struct_field;
                        break;
                    }
                }

                switch (@typeInfo(field_info.type)) {
                    .Pointer => |p| {
                        switch (@typeInfo(p.child)) {
                            .Array => |a| {
                                const step_type = a.child;
                                const as_struct_field = std.builtin.Type.StructField{
                                    .default_value = null,
                                    .name = field_info.name,
                                    .type = step_type,
                                    .is_comptime = false,
                                    .alignment = @alignOf(step_type),
                                };
                                input_type_fields[idx] = as_struct_field;
                            },
                            else => @compileError("All fields on world must be arrays"),
                        }
                    },
                    else => @compileError("All fields on world must be pointers"),
                }
            },
            else => @compileError("World must be a struct"),
        }
    }

    const decls: [0]std.builtin.Type.Declaration = .{};
    const input_meta_type: std.builtin.Type = std.builtin.Type{
        .Struct = std.builtin.Type.Struct{
            .fields = &input_type_fields,
            .layout = .auto,
            .is_tuple = false,
            .decls = &decls,
        },
    };
    const InputType: type = @Type(input_meta_type);

    return struct {
        pub const Self = @This();
        pub const T: type = InputType;
        pub fn run(self: Self, input: InputType) void {
            _ = self;
            _ = input;
        }
    };
}

const gravity_system_components: [2][]const u8 = .{
    "has_position_components",
    "has_velocity_components",
};
const GravitySystem = MakeSystem(2, gravity_system_components);

const gravity_system = GravitySystem{};

const w = World{
    .has_texture_components = undefined,
    .has_position_components = undefined,
    .has_velocity_components = undefined,
    .has_collision_box_components = undefined,
};

pub fn main() anyerror!void {
    const input: GravitySystem.T = GravitySystem.T{
        .has_position_components = null,
        .has_velocity_components = null,
    };
    gravity_system.run(input);

    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    const c = rl.Camera2D{
        .offset = rl.Vector2{ .x = 30, .y = 30 },
        .target = rl.Vector2{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.beginMode2D(c);
        defer rl.endMode2D();

        rl.clearBackground(rl.Color.white);

        rl.drawText("Congrats! You created your first window!", 0, 0, 20, rl.Color.light_gray);
        //----------------------------------------------------------------------------------

    }
}
