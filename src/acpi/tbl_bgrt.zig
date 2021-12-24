const acpi = @import("acpi.zig");
const io = @import("../io.zig");
const print = io.print;
const println = io.println;

// Boot Graphics Resource Table (BGRT)
pub const BGRT = packed struct {
    hdr: acpi.TableDescriptionHeader,

    version: u16,
    status: u8,
    image_type: u8,
    image_addr: u64,
    image_offset_x: u32,
    image_offset_y: u32,
};

pub fn dumpBgrt(bgrt: *const BGRT) void {
    println("", .{});
    println("  ### BGRT (Boot Graphics Resource Table) ###", .{});
    println("", .{});

    acpi.printTableDescHeader(@ptrCast(*const acpi.TableDescriptionHeader, &bgrt.hdr));
    println("  - Version:        {}", .{bgrt.version});
    println("  - Status:         0x{x:0>8}", .{bgrt.status});
    println("  - Image Type:     {}", .{bgrt.image_type});
    println("  - Image Address:  0x{x: >16}", .{bgrt.image_addr});
    println("  - Image Offset X: {}", .{bgrt.image_offset_x});
    println("  - Image Offset Y: {}", .{bgrt.image_offset_y});
}
