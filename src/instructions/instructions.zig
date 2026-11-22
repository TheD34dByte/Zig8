//! Chip8 instructions functions.

const std = @import("std");
const hardware = @import("hardware");
const f = @import("fenster");
const debugPrint = std.debug.print;

var prng = std.Random.DefaultPrng.init(0x1234_5678_9ABC_DEF0);

pub fn initRandom(seed: u64) void {
    prng = std.Random.DefaultPrng.init(seed);
}

pub fn decodeInstruction(opcode: u16) void {
    const nibbles: [4]u4 = @bitCast(opcode);
    const x: u4 = nibbles[2];
    const y: u4 = nibbles[1];
    const n: u4 = nibbles[0];
    const kk: u8 = @truncate(opcode & 0x00FF);
    const nnn: u12 = @truncate(opcode & 0x0FFF);

    // Whole opcodes
    debugPrint("0x{x:0>4} - ", .{opcode});
    switch (nibbles[3]) {
        0x0 => {
            if (opcode == 0x00E0) return clearScreen();
            if (opcode == 0x00EE) return returnFromSubroutine();
            return noOperation();
        },
        0x1 => return jumpTo(nnn),
        0x2 => return callSubroutine(nnn),
        0x3 => return skipIfEqual(x, kk),
        0x4 => return skipIfNotEqual(x, kk),
        0x5 => return skipIfEqual(x, hardware.memory.readRegister(y)),
        0x6 => return loadInRegister(x, kk),
        0x7 => return addToRegister(x, kk),
        0x8 => switch (n) {
            0x0 => return transferRegister(x, y),
            0x1 => return registerOr(x, y),
            0x2 => return registerAnd(x, y),
            0x3 => return registerXor(x, y),
            0x4 => return registerAdd(x, y),
            0x5 => return registerSub(x, y),
            0x6 => return registerShr(x, y),
            0x7 => return registerSubN(x, y),
            0xE => return registerShl(x, y),
            else => return noOperation(),
        },
        0x9 => return skipIfNotEqual(x, hardware.memory.readRegister(y)),
        0xA => return loadInIndex(nnn),
        0xB => return jumpToV0(nnn),
        0xC => return generateRandomNumber(x, kk),
        0xD => return drawSprite(x, y, n),
        0xE => switch (kk) {
            0x9E => return skipIfKeyHeld(x),
            0xA1 => return skipIfNotKeyHeld(x),
            else => return noOperation(),
        },
        0xF => switch (kk) {
            0x07 => return loadDelayTimerIntoRegister(x),
            0x0A => return waitForKeypressToRegister(x),
            0x15 => return setDelayTimerFromRegister(x),
            0x18 => return setSoundTimerFromRegister(x),
            0x1E => return addRegisterToIndex(x),
            0x29 => return loadFontAddressIntoIndex(x),
            0x33 => return storeBcdInMemory(x),
            0x55 => return storeMultipleRegisters(x),
            0x65 => return loadMultipleRegisters(x),
            else => return noOperation(),
        },
    }
}

pub fn noOperation() void {
    debugPrint("No Operation\n", .{});
}

// 00E0 - CLS
pub fn clearScreen() void {
    debugPrint("Clear screen\n", .{});
    hardware.display.clear();
}

// 00EE - RET
pub fn returnFromSubroutine() void {
    debugPrint("Returning from subroutine -> 0x{x:0>3}\n", .{hardware.memory.stack[hardware.memory.sp]});
    hardware.memory.pc = hardware.memory.stack[hardware.memory.sp];
    hardware.memory.sp -= 1;
}

// 1NNN - JP addr
pub fn jumpTo(addr: u12) void {
    debugPrint("Jumping to address 0x{x:0>3}\n", .{addr});
    hardware.memory.pc = addr;
}

// 2NNN - CALL addr
pub fn callSubroutine(addr: u12) void {
    debugPrint("Calling subroutine at 0x{x:0>3}\n", .{addr});
    hardware.memory.sp += 1;
    hardware.memory.stack[hardware.memory.sp] = hardware.memory.pc;
    hardware.memory.pc = addr;
}

// 3XKK / 5XY0 - SE
pub fn skipIfEqual(vx: u4, val: u8) void {
    debugPrint("Skip if V{x} == {}\n", .{ vx, val });
    if (hardware.memory.readRegister(vx) == val) {
        hardware.memory.pc += 2;
    }
}

// 4XKK / 9XY0 - SNE
pub fn skipIfNotEqual(vx: u4, val: u8) void {
    debugPrint("Skip if V{x} != {}\n", .{ vx, val });
    if (hardware.memory.readRegister(vx) != val) {
        hardware.memory.pc += 2;
    }
}

// 6XKK - LD Vx, byte
pub fn loadInRegister(vx: u4, val: u8) void {
    debugPrint("Load 0x{x:0>2} -> V{x}\n", .{ val, vx });
    hardware.memory.writeRegister(vx, val);
}

// 7XKK - ADD Vx, byte (no carry flag)
pub fn addToRegister(vx: u4, val: u8) void {
    debugPrint("Add 0x{x:0>2} -> V{x}\n", .{ val, vx });
    const result = hardware.memory.readRegister(vx) +% val;
    hardware.memory.writeRegister(vx, result);
}

// 8XY0 - LD Vx, Vy
pub fn transferRegister(vx: u4, vy: u4) void {
    debugPrint("V{x} <- V{x}\n", .{ vx, vy });
    hardware.memory.writeRegister(vx, hardware.memory.readRegister(vy));
}

// 8XY1 - OR Vx, Vy
pub fn registerOr(vx: u4, vy: u4) void {
    debugPrint("V{x} | V{x} -> V{x}\n", .{ vx, vy, vx });
    const result = hardware.memory.readRegister(vx) | hardware.memory.readRegister(vy);
    hardware.memory.writeRegister(vx, result);
}

// 8XY2 - AND Vx, Vy
pub fn registerAnd(vx: u4, vy: u4) void {
    debugPrint("V{x} & V{x} -> V{x}\n", .{ vx, vy, vx });
    const result = hardware.memory.readRegister(vx) & hardware.memory.readRegister(vy);
    hardware.memory.writeRegister(vx, result);
}

// 8XY3 - XOR Vx, Vy
pub fn registerXor(vx: u4, vy: u4) void {
    debugPrint("V{x} ^ V{x} -> V{x}\n", .{ vx, vy, vx });
    const result = hardware.memory.readRegister(vx) ^ hardware.memory.readRegister(vy);
    hardware.memory.writeRegister(vx, result);
}

// 8XY4 - ADD Vx, Vy (VF = carry)
pub fn registerAdd(vx: u4, vy: u4) void {
    debugPrint("V{x} + V{x} -> V{x}\n", .{ vx, vy, vx });
    const sum: u16 = @as(u16, hardware.memory.readRegister(vx)) + hardware.memory.readRegister(vy);
    const flag: u8 = if (sum > 0xFF) 1 else 0;
    hardware.memory.writeRegister(vx, @truncate(sum));
    hardware.memory.writeRegister(0xF, flag);
}

// 8XY5 - SUB Vx, Vy (VF = NOT borrow: 1 if Vx >= Vy)
pub fn registerSub(vx: u4, vy: u4) void {
    debugPrint("V{x} - V{x} -> V{x}\n", .{ vx, vy, vx });
    const x_val = hardware.memory.readRegister(vx);
    const y_val = hardware.memory.readRegister(vy);
    const flag: u8 = if (x_val >= y_val) 1 else 0;
    hardware.memory.writeRegister(vx, x_val -% y_val);
    hardware.memory.writeRegister(0xF, flag);
}

// 8XY6 - SHR Vx {, Vy} (VF = shifted-out LSB)
pub fn registerShr(vx: u4, vy: u4) void {
    debugPrint("V{x} >> 1 (from V{x})\n", .{ vx, vy });
    const val = hardware.memory.readRegister(vy);
    const flag: u8 = val & 0x01;
    hardware.memory.writeRegister(vx, val >> 1);
    hardware.memory.writeRegister(0xF, flag);
}

// 8XY7 - SUBN Vx, Vy (VF = NOT borrow: 1 if Vy >= Vx)
pub fn registerSubN(vx: u4, vy: u4) void {
    debugPrint("V{x} - V{x} -> V{x}\n", .{ vy, vx, vx });
    const x_val = hardware.memory.readRegister(vx);
    const y_val = hardware.memory.readRegister(vy);
    const flag: u8 = if (y_val >= x_val) 1 else 0;
    hardware.memory.writeRegister(vx, y_val -% x_val);
    hardware.memory.writeRegister(0xF, flag);
}

// 8XYE - SHL Vx {, Vy} (VF = shifted-out MSB)
pub fn registerShl(vx: u4, vy: u4) void {
    debugPrint("V{x} << 1 (from V{x})\n", .{ vx, vy });
    const val = hardware.memory.readRegister(vy);
    const flag: u8 = (val & 0x80) >> 7;
    hardware.memory.writeRegister(vx, val << 1);
    hardware.memory.writeRegister(0xF, flag);
}

// ANNN - LD I, addr
pub fn loadInIndex(val: u12) void {
    debugPrint("Load 0x{x:0>3} -> I\n", .{val});
    hardware.memory.index = val;
}

// BNNN - JP V0, addr
pub fn jumpToV0(addr: u12) void {
    const target = @as(u16, addr) + hardware.memory.readRegister(0);
    debugPrint("Jumping to V0 + 0x{x:0>3} (0x{x:0>3})\n", .{ addr, target });
    hardware.memory.pc = @truncate(target);
}

// CXKK - RND Vx, byte
pub fn generateRandomNumber(vx: u4, mask: u8) void {
    debugPrint("Generating random number (mask 0x{x:0>2}) -> V{x}\n", .{ mask, vx });
    const val = prng.random().int(u8);
    hardware.memory.writeRegister(vx, val & mask);
}

// DXYN - DRW Vx, Vy, nibble
pub fn drawSprite(vx: u4, vy: u4, height: u4) void {
    const x = hardware.memory.readRegister(vx);
    const y = hardware.memory.readRegister(vy);
    const idx = hardware.memory.index;
    debugPrint("Draw {}x8 sprite from 0x{x:0>3} at ({}, {})\n", .{ height, idx, x, y });

    const sprite = hardware.memory.memory[idx .. idx + height];
    const collision = hardware.display.drawSprite(x, y, sprite);
    hardware.memory.writeRegister(0xF, collision);
}

// EX9E - SKP Vx
pub fn skipIfKeyHeld(vx: u4) void {
    const key: u4 = @truncate(hardware.memory.readRegister(vx));
    debugPrint("Skip if key {x} (V{x}) is held\n", .{ key, vx });
    if (hardware.keypad.held_keys[key]) {
        hardware.memory.pc += 2;
    }
}

// EXA1 - SKNP Vx
pub fn skipIfNotKeyHeld(vx: u4) void {
    const key: u4 = @truncate(hardware.memory.readRegister(vx));
    debugPrint("Skip if key {x} (V{x}) is NOT held\n", .{ key, vx });
    if (!hardware.keypad.held_keys[key]) {
        hardware.memory.pc += 2;
    }
}

// FX07 - LD Vx, DT
pub fn loadDelayTimerIntoRegister(vx: u4) void {
    debugPrint("Load Delay Timer ({}) -> V{x}\n", .{ hardware.memory.delay_timer, vx });
    hardware.memory.writeRegister(vx, hardware.memory.delay_timer);
}

// FX0A - LD Vx, K (non-blocking wait for any key press)
pub fn waitForKeypressToRegister(vx: u4) void {
    for (0..16) |k| {
        const key: u4 = @intCast(k);
        if (hardware.keypad.pressed_keys[key]) {
            debugPrint("Key {c} pressed -> V{x}\n", .{ f.chip8_to_fenster[key], vx });
            hardware.memory.writeRegister(vx, key);
            return;
        }
    }
    debugPrint("Waiting for any keypress -> V{x}\n", .{vx});
    hardware.memory.pc -= 2;
}

// FX15 - LD DT, Vx
pub fn setDelayTimerFromRegister(vx: u4) void {
    const val = hardware.memory.readRegister(vx);
    debugPrint("Set Delay Timer = {} (from V{x})\n", .{ val, vx });
    hardware.memory.delay_timer = val;
}

// FX18 - LD ST, Vx
pub fn setSoundTimerFromRegister(vx: u4) void {
    const val = hardware.memory.readRegister(vx);
    debugPrint("Set Sound Timer = {} (from V{x})\n", .{ val, vx });
    hardware.memory.sound_timer = val;
}
// FX1E - ADD I, Vx
pub fn addRegisterToIndex(vx: u4) void {
    const val = hardware.memory.readRegister(vx);
    debugPrint("Add V{x} (0x{x:0>2}) -> I (0x{x:0>3})\n", .{ vx, val, hardware.memory.index });
    hardware.memory.index +%= val;
}
// FX29 - LD F, Vx
pub fn loadFontAddressIntoIndex(vx: u4) void {
    const digit: u4 = @truncate(hardware.memory.readRegister(vx));
    debugPrint("Load font sprite for {x} (V{x}) -> I\n", .{ digit, vx });
    hardware.memory.index = hardware.memory.FONTSET_START_ADDR + (@as(u16, digit) * 5);
}
// FX33 - LD B, Vx
pub fn storeBcdInMemory(vx: u4) void {
    const val = hardware.memory.readRegister(vx);
    const idx = hardware.memory.index;
    debugPrint("Store BCD of {} (V{x}) at I (0x{x:0>3})\n", .{ val, vx, idx });
    hardware.memory.memory[idx] = val / 100;
    hardware.memory.memory[idx + 1] = (val / 10) % 10;
    hardware.memory.memory[idx + 2] = val % 10;
}
// FX55 - LD [I], Vx
pub fn storeMultipleRegisters(vx: u4) void {
    const idx = hardware.memory.index;
    debugPrint("Store V0..V{x} at I (0x{x:0>3})\n", .{ vx, idx });
    for (0..@as(usize, vx) + 1) |offset| {
        hardware.memory.memory[idx + offset] = hardware.memory.readRegister(@intCast(offset));
    }
    hardware.memory.index += @as(u16, vx) + 1;
}
// FX65 - LD Vx, [I]
pub fn loadMultipleRegisters(vx: u4) void {
    const idx = hardware.memory.index;
    debugPrint("Load V0..V{x} from I (0x{x:0>3})\n", .{ vx, idx });
    for (0..@as(usize, vx) + 1) |offset| {
        hardware.memory.writeRegister(@intCast(offset), hardware.memory.memory[idx + offset]);
    }
    hardware.memory.index += @as(u16, vx) + 1;
}
