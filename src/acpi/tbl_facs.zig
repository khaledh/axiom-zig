const acpi = @import("acpi.zig");
const io = @import("io.zig");
const print = io.print;
const println = io.println;

pub fn dumpFacs(facs: acpi.FACS) void {
    println("", .{});
    println("  ### FACS (Firmware ACPI Control Structure) ###", .{});
    println("", .{});

    const facs = @ptrCast(*align(1) const acpi.FACS, @intToPtr([*]const u8, fadt.firmware_ctrl & 0x00000000ffffffff));
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
