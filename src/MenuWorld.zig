const std = @import("std");
const component = @import("component.zig");

const MenuWorld = @This();

// TODO: lets make it so world has no non-component fields, let it all be in Scene
// this will make our macro guarantees stronger
active_ids: std.AutoHashMap(usize, bool),
inactive_ids: std.AutoHashMap(usize, bool),

position_components: []?component.Position,
menu_coords_components: []?component.MenuCoords,
texture_render_components: []?component.TextureRender,

pub fn init(allocator: *std.mem.Allocator) !MenuWorld {
    const active_ids = std.AutoHashMap(usize, bool).init(allocator);
    var inactive_ids = std.AutoHashMap(usize, bool).init(allocator);

    for (0..component.max_entity_count) |entity_id| {
        _ = try inactive_ids.put(entity_id, true);
    }

    const menu_world = MenuWorld{
        .active_ids = active_ids,
        .inactive_ids = inactive_ids,
        .position_components = component.PositionSet.init(allocator),
        .menu_coords_components = component.MenuCoordsSet.init(allocator),
        .texture_render_components = component.TextureRenderSet.init(allocator),
    };

    return menu_world;
}
