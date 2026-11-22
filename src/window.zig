const std = @import("std");
const fenster = @import("fenster");
const hardware = @import("hardware");

pub var window: fenster.Fenster = .{
    .title = "Zig8",
    .width = hardware.display.WIDTH,
    .height = hardware.display.HEIGHT,
    .buf = &hardware.display.buffer,
    .keys = @splat(0),
    .mod = 0,
    .x = 0,
    .y = 0,
    .mouse = 0,
};
