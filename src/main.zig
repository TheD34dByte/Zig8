const std = @import("std");
const fenster = @import("fenster/fenster.zig");

const width = 320;
const height = 240;

const black: u32 = 0x000000;
const white: u32 = 0xFFFFFF;

pub fn main() void {
    var buf: [width * height]u32 = @splat(black);

    var window = std.mem.zeroInit(fenster.Fenster, .{
        .title = "Title",
        .width = width,
        .height = height,
        .buf = &buf,
    });

    _ = fenster.fenster_open(&window);
    defer fenster.fenster_close(&window);

    var player_x: usize = width / 2;
    var player_y: usize = height / 2;

    while (fenster.fenster_loop(&window) == 0) {
        const frame_start = fenster.fenster_time();

        // Exit on ESC (ASCII 27)
        if (window.keys[27] != 0) break;

        // Arrow keys: 17 = Up, 18 = Down, 19 = Right, 20 = Left
        if (window.keys[17] != 0 and player_y > 0) player_y -= 1;
        if (window.keys[18] != 0 and player_y < height - 1) player_y += 1;
        if (window.keys[19] != 0 and player_x < width - 1) player_x += 1;
        if (window.keys[20] != 0 and player_x > 0) player_x -= 1;

        @memset(&buf, black);
        drawRect(&buf, player_x, player_y, 4, 4, white);

        const elapsed = fenster.fenster_time() - frame_start;
        if (elapsed < 16) {
            fenster.fenster_sleep(16 - elapsed);
        }
    }
}

fn drawRect(buf: []u32, x: usize, y: usize, w: usize, h: usize, color: u32) void {
    var dy: usize = 0;
    while (dy < h) : (dy += 1) {
        var dx: usize = 0;
        while (dx < w) : (dx += 1) {
            const px = x + dx;
            const py = y + dy;
            if (px < width and py < height) {
                buf[py * width + px] = color;
            }
        }
    }
}
