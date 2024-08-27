const rl = @import("raylib");

const Keyboard = @This();

left_is_down: bool = false,
left_pressed: bool = false,

right_is_down: bool = false,
right_pressed: bool = false,

spacebar_is_down: bool = false,
spacebar_pressed: bool = false,

pub fn updateKeyboard(self: Keyboard) Keyboard {
    const left_is_down = rl.isKeyPressed(rl.KeyboardKey.key_left);
    const left_pressed = left_is_down and !self.left_is_down;

    const right_is_down = rl.isKeyPressed(rl.KeyboardKey.key_right);
    const right_pressed = right_is_down and !self.right_is_down;

    const spacebar_is_down = rl.isKeyDown(rl.KeyboardKey.key_space);
    const spacebar_pressed = rl.isKeyPressed(rl.KeyboardKey.key_space);

    return Keyboard{
        .left_is_down = left_is_down,
        .left_pressed = left_pressed,
        .right_is_down = right_is_down,
        .right_pressed = right_pressed,
        .spacebar_is_down = spacebar_is_down,
        .spacebar_pressed = spacebar_pressed or spacebar_is_down,
    };
}
