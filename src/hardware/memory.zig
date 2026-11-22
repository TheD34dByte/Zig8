pub const FONTSET_START_ADDR: u16 = 0x050;

pub const FONTSET = [80]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

pub var memory: [0x1000]u8 = @splat(0);
pub var registers: [16]u8 = @splat(0);
pub var index: u16 = 0;
pub var stack: [16]u12 = @splat(0);
pub var sp: u4 = 0;
pub var pc: u12 = 0;

pub var delay_timer: u8 = 0;
pub var sound_timer: u8 = 0;

pub const MemoryAccessError = error{ OutOfBoundRead, OutOfBoundWrite };

/// Returns the byte located at `addr`.
pub fn readAt(addr: u16) MemoryAccessError!u8 {
    if (addr > 0xFFF) return MemoryAccessError.OutOfBoundRead;
    return memory[addr];
}

/// Writes the byte `val` at `addr`.
pub fn writeAt(addr: u16, val: u8) MemoryAccessError!void {
    if (addr > 0xFFF) return MemoryAccessError.OutOfBoundWrite;
    memory[addr] = val;
}

/// Read value at register `VX`, where `X` is a number 0x0 - 0xF.
pub fn readRegister(vx: u4) u8 {
    return registers[vx];
}

/// Write value `val` at register `VX`, where `X` is a number 0x0 - 0xF.
pub fn writeRegister(vx: u4, val: u8) void {
    registers[vx] = val;
}

/// Read value at register `VX`, where `X` is a number 0x0 - 0xF.
pub fn readProgramCount() u16 {
    return pc;
}

pub fn tickDownTimer(timer: *u8) void {
    if (timer.* == 0) {
        timer.* = 255;
    } else {
        timer.* -= 1;
    }
}
