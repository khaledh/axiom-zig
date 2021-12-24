const std = @import("std");

const acpi = @import("acpi.zig");
const dumpMadt = @import("tbl_madt.zig").dumpMadt;
const MADT = @import("tbl_madt.zig").MADT;
const dumpFadt = @import("tbl_fadt.zig").dumpFadt;
const FADT = @import("tbl_fadt.zig").FADT;
const dumpBgrt = @import("tbl_bgrt.zig").dumpBgrt;
const BGRT = @import("tbl_bgrt.zig").BGRT;
const dumpFacs = @import("tbl_facs.zig").dumpFacs;
const FACS = @import("tbl_facs.zig").FACS;
const dumpDsdt = @import("tbl_dsdt.zig").dumpDsdt;

const io = @import("../io.zig");
const print = io.print;
const println = io.println;

// Extended System Description Table
pub const XSDT = packed struct {
    hdr: acpi.TableDescriptionHeader,

    pub fn entry(self: @This(), i: usize) *const acpi.TableDescriptionHeader {
        const ptr_loc = @ptrToInt(&self) + 36 + (i * 8);
        const u64_ptr = @intToPtr(*align(1) u64, ptr_loc);
        const hdr_ptr = @intToPtr(*acpi.TableDescriptionHeader, u64_ptr.*);
        return hdr_ptr;
    }
};

pub fn dumpXsdt(xsdt: *XSDT) void {
    println("", .{});
    println("  ### XSDT (eXtended System Description Table) ###", .{});
    println("", .{});

    const hdr = @ptrCast(*acpi.TableDescriptionHeader, &xsdt.hdr);
    acpi.printTableDescHeader(hdr);

    const n_entries: usize = @divExact(hdr.length - @bitSizeOf(acpi.TableDescriptionHeader) / 8, 8);
    println("  - Entries: [{}]", .{n_entries});

    var j: usize = 0;
    var fadt: *const FADT = undefined;
    var facs: *const FACS = undefined;
    var madt: *const MADT = undefined;
    var bgrt: *const BGRT = undefined;
    var dsdt: *const acpi.TableDescriptionHeader = undefined;

    while (j < n_entries) : (j += 1) {
        const entry = xsdt.entry(j);
        print("    [{X: >16}]", .{@ptrToInt(entry)});
        println(" \"{s}\"", .{entry.signature});

        if (std.mem.eql(u8, entry.signature[0..], "FACP")) {
            fadt = @ptrCast(*const FADT, entry);
            facs = @ptrCast(*const FACS, @intToPtr([*]const u8, fadt.firmware_ctrl & 0x00000000ffffffff));
            dsdt = @ptrCast(*const acpi.TableDescriptionHeader, @intToPtr([*]align(4) const u8, fadt.dsdt & 0x00000000ffffffff));
        }
        else if (std.mem.eql(u8, entry.signature[0..], "APIC")) {
            madt = @ptrCast(*const MADT, entry);
        }
        else if (std.mem.eql(u8, entry.signature[0..], "BGRT")) {
            bgrt = @ptrCast(*const BGRT, entry);
        }
    }

    dumpFadt(fadt);
    dumpFacs(facs);
    dumpMadt(madt);
    dumpBgrt(bgrt);
    dumpDsdt(dsdt);
}
