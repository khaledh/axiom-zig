const out16 = @import("cpu.zig").out16;

pub fn shutdown() noreturn {
    out16(0x604, 0x2000);
    unreachable;
}
