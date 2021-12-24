const dumpRsdp = @import("tbl_rsdp.zig").dumpRsdp;
const dumpXsdt = @import("tbl_xsdt.zig").dumpXsdt;
const XSDT = @import("tbl_xsdt.zig").XSDT;

const io = @import("../io.zig");
const print = io.print;
const println = io.println;

pub const TableDescriptionHeader = packed struct {
    signature: [4]u8,
    length: u32,
    revision: u8,
    checksum: u8,
    oem_id: [6]u8,
    oem_table_id: [8]u8,
    oem_revision: u32,
    creator_id: [4]u8,
    creator_revision: u32,
};

// Root System Description Pointer
pub const RSDP = packed struct {
    signature: [8]u8,
    checksum: u8,
    oem_id: [6]u8,
    revision: u8,
    rsdt_address: u32,
    length: u32,
    xsdt_address: u64,
    extended_checksum: u8,
    reserved: [3]u8,
};

pub fn printTableDescHeader(hdr: *const TableDescriptionHeader) void {
    println("  | Signature:        \"{s}\"", .{hdr.signature});
    println("  | Length:           {}", .{hdr.length});
    println("  | Revision:         {}", .{hdr.revision});
    println("  | Checksum:         {}", .{hdr.checksum});
    println("  | OEM ID:           \"{s}\"", .{hdr.oem_id});
    println("  | OEM Table ID:     \"{s}\"", .{hdr.oem_table_id});
    println("  | OEM REvision:     {}", .{hdr.oem_revision});
    println("  | Creator ID:       \"{s}\"", .{hdr.creator_id});
    println("  | Creator Revision: 0x{x}", .{hdr.creator_revision});
}

pub fn dumpAcpiTables(rsdp: *RSDP) void {
    println("", .{});
    println("### ACPI 2.0 Tables ###", .{});

    dumpRsdp(rsdp);

    const xsdt = @intToPtr(*XSDT, rsdp.xsdt_address);

    dumpXsdt(xsdt);

    // dumpFadt(fadt);
    // dumpFacs(facs);
    // dumpDsdt(dsdt);
    // dumpMadt(madt);
    // dumpBgrt(bgrt);

    println("", .{});
}