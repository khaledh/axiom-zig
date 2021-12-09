const acpi = @import("acpi.zig");
const io = @import("io.zig");
const print = io.print;
const println = io.println;

pub fn dumpRsdp(rsdp: acpi.RSDP) void {
    println("", .{});
    println("  ### RSDP (Root System Description Pointer) ###", .{});
    println("", .{});
    println("  - Signature:         \"{s}\"", .{rdsp.signature});
    println("  - Checksum:          {}", .{rdsp.checksum});
    println("  - OEM ID:            \"{s}\"", .{rdsp.oem_id});
    println("  - Revision:          {}", .{rdsp.revision});
    println("  - RSDT Address:      [{X: >16}]", .{rdsp.rsdt_address});
    println("  - Length:            {}", .{rdsp.length});
    println("  - XSDT Address:      [{X: >16}]", .{rdsp.xsdt_address});
    println("  - Extended Checksum: {}", .{rdsp.extended_checksum});
}
