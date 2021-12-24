const acpi = @import("acpi.zig");
const io = @import("../io.zig");
const print = io.print;
const println = io.println;

pub fn dumpRsdp(rsdp: *acpi.RSDP) void {
    println("", .{});
    println("  ### RSDP (Root System Description Pointer) ###", .{});
    println("", .{});
    println("  - Signature:         \"{s}\"", .{rsdp.signature});
    println("  - Checksum:          {}", .{rsdp.checksum});
    println("  - OEM ID:            \"{s}\"", .{rsdp.oem_id});
    println("  - Revision:          {}", .{rsdp.revision});
    println("  - RSDT Address:      [{X: >16}]", .{rsdp.rsdt_address});
    println("  - Length:            {}", .{rsdp.length});
    println("  - XSDT Address:      [{X: >16}]", .{rsdp.xsdt_address});
    println("  - Extended Checksum: {}", .{rsdp.extended_checksum});
}
