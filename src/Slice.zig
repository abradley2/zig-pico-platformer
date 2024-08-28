// useful utility for creating slices that can be stack allocated without the boilerplate
pub fn Make(
    comptime Item: type,
    comptime n: usize,
    comptime cap: usize,
) type {
    if (n > cap) {
        @compileError("n must be less than or equal to cap");
    }
    return struct {
        pub const T: type = struct { [cap]Item, usize };

        pub fn init(s: [n]Item) struct { [cap]Item, usize } {
            var arr: [cap]Item = undefined;
            for (s, 0..) |elem, i| {
                arr[i] = elem;
            }
            return .{ arr, n };
        }
    };
}
