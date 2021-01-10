const std = @import("std");
const ansi = @import("ansi");
const zwincon = @import("zwincon");
const c = zwincon.c;

pub fn main() !void {
    var con = try zwincon.ConsoleApp.init();
    var before_input_mode = try con.getInputMode();
    var before_output_mode = try con.getOutputMode();

    try con.setInputMode(zwincon.InputMode{
        .enable_extended_flags = true, // Does things... docs aren't very clear but do say they should be used with quickedit = false
        .enable_processed_input = false, // False disables Windows handling Control + C, we do that ourselves
        .enable_mouse_input = true, // Allows mouse events to be processed
        .enable_quick_edit_mode = false // False disables auto drag selection
    });

    try con.setOutputMode(zwincon.OutputMode{
        .enable_virtual_terminal_processing = true, // Enables ANSI sequences - this demo was originally a paint app but I didn't want unnecessary external deps to plague this simple example
    });

    defer {
        con.setInputMode(before_input_mode) catch {};
        con.setOutputMode(before_output_mode) catch {};
    }

    std.debug.print("Move your mouse around and type on your keyboard to see what I do!\n", .{});
    main: while (true) {
        var event = try con.getEvent();

        // NOTE: Mouse events don't work in Windows Terminal because Microsoft is slacking
        switch (event) {
            .key => |key| {
                if (key.key == .ascii and key.key.ascii == 3) break :main;

                std.debug.print("Key Event | key: {} | is down: {}\n", .{
                    key.key, key.is_down
                });
            },
            .mouse => |mouse| {
                std.debug.print("Mouse Event | abs: {} | in viewport: {}", .{mouse.abs_coords, try con.viewportCoords(mouse.abs_coords, null)});
                if (mouse.mouse_flags.double_click) std.debug.print(" | double click", .{});
                if (mouse.mouse_flags.mouse_moved) std.debug.print(" | mouse moved", .{});
                if (mouse.mouse_flags.mouse_wheeled or mouse.mouse_flags.mouse_hwheeled) std.debug.print(" | mouse wheel: {}", .{mouse.mouse_scroll_direction.?});
                
                if (mouse.mouse_buttons.left_mouse_button) std.debug.print(" | left click", .{});
                if (mouse.mouse_buttons.middle_mouse_button) std.debug.print(" | middle click", .{});
                if (mouse.mouse_buttons.right_mouse_button) std.debug.print(" | right click", .{});

                std.debug.print("\n", .{});
            },
            .window_buffer_size => |wbz| {
                std.debug.print("Window Buffer Size | {}\n", .{wbz});
            },
            .menu => |menu| {
                std.debug.print("Menu Event | {}\n", .{menu});
            },
            .focus => |focused| {
                std.debug.print("Focused | {}\n", .{focused});
            }
        }
    }
}
