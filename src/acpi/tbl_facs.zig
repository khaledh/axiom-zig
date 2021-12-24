const acpi = @import("acpi.zig");
const io = @import("../io.zig");
const print = io.print;
const println = io.println;

// Firmware ACPI Control Structure (FACS)
pub const FACS = packed struct {
    signature: [4]u8,
    length: u32,
    hw_signature: u32,
    fw_walking_vector: u32,
    global_lock: u32,
    flags: u32,
    x_fw_walking_vector: u64,
    version: u8,
    reserved1: [3]u8,
    ospm_flags: u32,
    reserved2: [24]u8,
};

pub fn dumpFacs(facs: *const FACS) void {
    println("", .{});
    println("  ### FACS (Firmware ACPI Control Structure) ###", .{});
    println("", .{});

    println("  | Signature:          \"{s}\"", .{facs.signature});
    println("  | Length:             {}", .{facs.length});
    println("  - HW Signature:       0x{x:0>8}", .{facs.hw_signature});
    println("  - FW Waking Vector:   0x{x:0>8}", .{facs.fw_walking_vector});
    println("  - Global Lock:        0x{x:0>8}", .{facs.global_lock});
    println("  - Flags:              0x{x:0>8}", .{facs.flags});
    println("  - X FW Waking Vector: 0x{x:0>16}", .{facs.x_fw_walking_vector});
    println("  - Version:            {}", .{facs.version});
    println("  - OSPM Flags:         0x{x:0>8}", .{facs.ospm_flags});
}
