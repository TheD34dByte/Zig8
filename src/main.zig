const std = @import("std");
const fenster = @import("fenster");
const hardware = @import("hardware");
const window = @import("window.zig");
const instructions = @import("instructions/instructions.zig");

const CPU_CYCLES_PER_FRAME = 10; // ~600 Hz at 60 FPS

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <Chip8 ROM>\n", .{args[0]});
        return;
    }

    const program_file = args[1];

    // Open File
    // Load into RAM
    // Set registers
    // Loop

    _ = fenster.fenster_open(&window.window);
    defer fenster.fenster_close(&window.window);

    std.debug.print("filename: {s}\n", .{program_file});
    std.debug.print("Loading...\n", .{});

    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    // Open an existing file for reading and writing
    const file = try cwd.openFile(io, program_file, .{ .mode = .read_only });
    defer file.close(io);

    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(io, &read_buf);
    const reader = &file_reader.interface;

    var i: u16 = 0x200;
    while (true) {
        const byte = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        // Process each byte (e.g., print hex and ASCII representation)
        std.debug.print("{x:0>2}", .{byte});
        try hardware.memory.writeAt(i, byte);

        i += 1;
    }

    for (hardware.memory.FONTSET, 0..) |byte, offset| {
        const addr: u16 = @intCast(hardware.memory.FONTSET_START_ADDR + offset);
        try hardware.memory.writeAt(addr, byte);
    }

    std.debug.print("First bytes at 0x200: {x:0>2} {x:0>2}\n", .{
        hardware.memory.memory[0x200],
        hardware.memory.memory[0x201],
    });

    hardware.memory.pc = 0x200;
    std.debug.print("Ready!\n", .{});
    while (fenster.fenster_loop(&window.window) == 0) {
        const frame_start = fenster.fenster_time();

        // 1. Poll keyboard once per frame
        hardware.keypad.handleKeypresses(&window.window);

        // 2. Run ~10 CPU instructions per 60 Hz frame (~600 Hz)
        for (0..CPU_CYCLES_PER_FRAME) |_| {
            const pc = hardware.memory.pc;
            std.debug.print("0x{x:0>4}   ", .{pc});
            const opcode: u16 = (@as(u16, hardware.memory.memory[pc]) << 8) |
                @as(u16, hardware.memory.memory[pc + 1]);
            hardware.memory.pc += 2;

            instructions.decodeInstruction(opcode);

            // Ensure rising-edge keypresses only trigger on the first cycle of the frame
            @memset(&hardware.keypad.pressed_keys, false);
        }

        // 3. 60 Hz vBlank: tick timers once and upscale VRAM to Fenster buffer
        hardware.display.vBlank(&hardware.memory.delay_timer, &hardware.memory.sound_timer);

        // 4. Pace frame to ~16ms (60 Hz)
        const elapsed = fenster.fenster_time() - frame_start;
        if (elapsed < 16) {
            fenster.fenster_sleep(16 - elapsed);
        }
    }
}
