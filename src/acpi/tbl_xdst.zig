const acpi = @import("acpi.zig");
const io = @import("io.zig");
const print = io.print;
const println = io.println;

pub fn dumpXdst(xdst: acpi.XDST) void {
    println("", .{});
    println("  ### XDST (eXtended System Description Table) ###", .{});
    println("", .{});

    printTableDescHeader(@ptrCast(*acpi.TableDescriptionHeader, &xdst.hdr));

    const n_entries: usize = @divExact(xdst.hdr.length - @bitSizeOf(acpi.TableDescriptionHeader) / 8, 8);
    println("  - Entries: [{}]", .{n_entries});

    var j: usize = 0;
    var fadt: *align(1) const acpi.FADT = undefined;
    var madt: *align(1) const acpi.MADT = undefined;
    var bgrt: *align(1) const acpi.BGRT = undefined;

    while (j < n_entries) : (j += 1) {
        const entry = xdst.entry(j);
        print("    [{X: >16}]", .{@ptrToInt(entry)});
        println(" \"{s}\"", .{entry.signature});

        if (std.mem.eql(u8, entry.signature[0..], "FACP")) {
            fadt = @ptrCast(*align(1) const acpi.FADT, entry);
        }
        else if (std.mem.eql(u8, entry.signature[0..], "APIC")) {
            madt = @ptrCast(*align(1) const acpi.MADT, entry);
        }
        else if (std.mem.eql(u8, entry.signature[0..], "BGRT")) {
            bgrt = @ptrCast(*align(1) const acpi.BGRT, entry);
        }
    }
}
