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
