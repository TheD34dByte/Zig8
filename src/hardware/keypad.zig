const std = @import("std");
const f = @import("fenster");

pub var held_keys: [16]bool = @splat(false);
pub var pressed_keys: [16]bool = @splat(false);

pub fn checkIfAnyKeyPressed() bool {
    for (0..0xF) |i| {
        if (checkIfKeyPressed(@intCast(i))) return true;
    }
    return false;
}

pub fn getFirstKeyPressed() i8 {
    for (0..0xF) |i| {
        if (checkIfKeyPressed(@intCast(i))) return @intCast(i);
    }
    return -1;
}

pub fn waitForKeypress(w: *f.Fenster) i8 {
    while (!checkIfAnyKeyPressed(w)) {}
    return getFirstKeyPressed(w);
}

pub fn handleKeypresses(w: *f.Fenster) void {
    for (f.chip8_to_fenster, 0..) |value, i| {
        const is_down = w.keys[value] != 0;

        // True ONLY on the frame the key transitions from up (false) to down (true)
        pressed_keys[i] = is_down and !held_keys[i];

        // Save current state for the next frame's comparison
        held_keys[i] = is_down;
    }
}

pub fn checkIfKeyPressed(key: u4) bool {
    return pressed_keys[key];
}
