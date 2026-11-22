// https://github.com/zserge/fenster

pub const Fenster = extern struct {
    title: [*:0]const u8,
    width: c_int,
    height: c_int,
    buf: [*]u32,
    keys: [256]c_int,
    mod: c_int,
    x: c_int,
    y: c_int,
    mouse: c_int,
};

pub extern fn fenster_open(f: *Fenster) c_int;
pub extern fn fenster_loop(f: *Fenster) c_int;
pub extern fn fenster_close(f: *Fenster) void;
pub extern fn fenster_sleep(ms: i64) void;
pub extern fn fenster_time() i64;

pub const chip8_to_fenster = [16]u8{
    '0', '1', '2', '3', // 0x0 - 0x3 (ASCII 48..51)
    '4', '5', '6', '7', // 0x4 - 0x7 (ASCII 52..55)
    '8', '9', 'A', 'B', // 0x8 - 0xB (ASCII 56..57, 65..66)
    'C', 'D', 'E', 'F', // 0xC - 0xF (ASCII 67..70)
};
