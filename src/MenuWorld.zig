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
display_text_components: []?component.DisplayText,

pub fn init(allocator: std.mem.Allocator) !MenuWorld {
    const active_ids = std.AutoHashMap(usize, bool).init(allocator);
    var inactive_ids = std.AutoHashMap(usize, bool).init(allocator);

    for (0..component.max_entity_count) |entity_id| {
        _ = try inactive_ids.put(entity_id, true);
    }

    const position_components = try component.ComponentSet(component.Position).init(allocator);
    const menu_coords_components = try component.ComponentSet(component.MenuCoords).init(allocator);
    const texture_render_components = try component.ComponentSet(component.TextureRender).init(allocator);
    const display_text_components = try component.ComponentSet(component.DisplayText).init(allocator);

    const menu_world = MenuWorld{
        .active_ids = active_ids,
        .inactive_ids = inactive_ids,
        .position_components = position_components,
        .menu_coords_components = menu_coords_components,
        .texture_render_components = texture_render_components,
        .display_text_components = display_text_components,
    };

    return menu_world;
}

pub fn createEntity(self: *MenuWorld) error{OutOfMemory}!usize {
    var inactive_id_iter = self.inactive_ids.iterator();
    if (inactive_id_iter.next()) |entity_id_entry| {
        const entity_id = entity_id_entry.key_ptr.*;
        _ = self.inactive_ids.remove(entity_id);
        try self.active_ids.put(entity_id, true);
        return entity_id;
    }
    return error.OutOfMemory;
}

pub fn freeEntity(self: *MenuWorld, entity_id: usize) void {
    component.MakeFreeComponentFunc(*MenuWorld).freeEntity(self, entity_id);
    self.active_ids.remove(entity_id);
    self.inactive_ids.put(entity_id, true);
}
