const std = @import("std");
const fenster = @import("fenster");

pub const CHIP8_WIDTH = 64;
pub const CHIP8_HEIGHT = 32;
pub const SCALE = 10;

pub const WIDTH = CHIP8_WIDTH * SCALE; // 640
pub const HEIGHT = CHIP8_HEIGHT * SCALE; // 320

const black: u32 = 0x000000;
const white: u32 = 0xFFFFFF;

/// Logical 64x32 monochrome screen (1 = white, 0 = black)
pub var vram: [CHIP8_WIDTH * CHIP8_HEIGHT]u1 = @splat(0);

/// 10x upscaled ARGB buffer passed to Fenster
pub var buffer: [WIDTH * HEIGHT]u32 = @splat(black);

pub var frame_timer: u8 = 0;
pub var draw_flag: bool = false;

/// Opcode 00E0 (CLS): Clears both logical VRAM and Fenster buffer
pub fn clear() void {
    @memset(&vram, 0);
    @memset(&buffer, black);
    draw_flag = true;
}

/// Opcode DXYN (DRW): XORs a sprite into 64x32 VRAM and returns VF collision (1 or 0)
pub fn drawSprite(start_x: u8, start_y: u8, sprite_bytes: []const u8) u8 {
    // Starting coordinates wrap modulo screen dimensions
    const origin_x = start_x % CHIP8_WIDTH;
    const origin_y = start_y % CHIP8_HEIGHT;
    var collision: u8 = 0;

    for (sprite_bytes, 0..) |row_byte, row| {
        const y = origin_y + row;
        if (y >= CHIP8_HEIGHT) break; // Sprites clip at the bottom edge

        // inline for unrolls the 8 horizontal pixel checks at compile time
        inline for (0..8) |col| {
            const x = origin_x + col;
            if (x >= CHIP8_WIDTH) break; // Sprites clip at the right edge

            const bit_shift: u3 = @intCast(7 - col);
            const sprite_pixel: u1 = @truncate((row_byte >> bit_shift) & 1);

            if (sprite_pixel == 1) {
                const idx = (y * CHIP8_WIDTH) + x;
                if (vram[idx] == 1) {
                    collision = 1;
                }
                vram[idx] ^= 1;
            }
        }
    }

    draw_flag = true;
    return collision;
}

/// Upscales 64x32 VRAM into the 640x320 Fenster buffer (10x10 blocks per pixel)
pub fn renderToBuffer() void {
    if (!draw_flag) return;
    draw_flag = false;

    for (0..CHIP8_HEIGHT) |cy| {
        for (0..CHIP8_WIDTH) |cx| {
            const color: u32 = if (vram[cy * CHIP8_WIDTH + cx] == 1) white else black;

            const base_x = cx * SCALE;
            const base_y = cy * SCALE;

            // Fill a 10x10 block in the output buffer
            for (0..SCALE) |dy| {
                const row_start = ((base_y + dy) * WIDTH) + base_x;
                @memset(buffer[row_start .. row_start + SCALE], color);
            }
        }
    }
}

pub fn vBlank(delay_timer: *u8, sound_timer: *u8) void {
    if (delay_timer.* > 0) delay_timer.* -= 1;
    if (sound_timer.* > 0) sound_timer.* -= 1;

    renderToBuffer();
    frame_timer +%= 1;
}
